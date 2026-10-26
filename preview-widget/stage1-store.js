/* Stage 1 experimental offline store. NOT wired into existing DB/SYNC. No credentials/network.
   Adapters must provide async read() and write(value) with atomic durable writes. */
(function(root,factory){
  const api=factory(typeof module==='object'&&module.exports?require('./safety-core.js'):root.LogbookSafety);
  if(typeof module==='object'&&module.exports)module.exports=api;
  else root.LogbookOfflineStore=api;
})(typeof globalThis!=='undefined'?globalThis:this,function(s){
  'use strict';
  function memoryAdapter(seed){
    let saved=s.clone(seed===undefined?null:seed);
    return {async read(){return s.clone(saved)},async write(v){saved=s.clone(v)},async compareAndSwap(expected,next){if(!s.equal(saved,expected))return false;saved=s.clone(next);return true}};
  }
  function assert(c,m){if(!c)throw new Error(m)}
  const baseState=()=>({schema:s.SCHEMA,records:{},baseline:{},pending:[],history:[],conflicts:[],rollbackBackups:[],sequence:0});
  class OfflineStore{
    constructor(adapter, clock=Date.now){
      assert(adapter&&typeof adapter.read==='function'&&typeof adapter.write==='function','Durable adapter required');
      this.adapter=adapter;this.clock=clock;this.state=null;
    }
    async init(){
      const saved=await this.adapter.read();
      if(saved!=null){assert(saved.schema===s.SCHEMA,'Unsupported local state');this.state=s.clone(saved)}
      else {
        const initial=baseState();
        if(this.adapter.compareAndSwap){
          if(await this.adapter.compareAndSwap(null,initial))this.state=initial;
          else this.state=s.clone(await this.adapter.read());
        }else {await this.adapter.write(initial);this.state=initial}
      }
      s.validateSnapshot(this.state);
      return this.snapshot();
    }
    snapshot(){assert(this.state,'Not initialized');return s.clone(this.state)}
    async commit(next){
      // Only swap the visible state after the adapter confirms persistence.
      if(this.adapter.compareAndSwap){
        if(!await this.adapter.compareAndSwap(this.state,next)){
          const error=Error('Local state changed concurrently');error.code='LOCAL_CAS';throw error;
        }
      }else await this.adapter.write(next);
      this.state=s.clone(next);return this.snapshot();
    }
    async edit(id,value,{deleted=false,_observed,_checkObserved=false}={}){
      const next=this.snapshot();
      const previous=next.records[id];const version=previous?previous.version+1:1;
      const updated=s.record(id,value,version,deleted);
      if(previous&&previous.deleted===!!deleted&&(deleted||s.equal(previous.value,value)))return next;
      if(_checkObserved&&!s.equal(previous,_observed)){
        // Keep both user intentions when another tab edited this record.
        next.conflicts=next.conflicts.filter(c=>c.id!==id).concat([{
          id,scope:'local',base:s.clone(_observed),local:s.clone(updated),remote:s.clone(previous),
          kind:deleted||previous?.deleted?'delete-edit':'edit-edit'
        }]);
      }else assert(!next.conflicts.some(c=>c.id===id),'Resolve this record conflict before editing');
      next.records[id]=updated;
      next.history=s.historyAppend(next.history,id,previous,updated,this.clock());
      const op={op:'edit',id,sequence:++next.sequence,record:s.clone(updated)};
      next.pending.push(op);
      return this.commit(next);
    }
    async applyRecords(base,desired){
      s.validateSnapshot({schema:s.SCHEMA,records:base});s.validateSnapshot({schema:s.SCHEMA,records:desired});
      const next=this.snapshot(),merge=s.threeWay(base,desired,next.records);
      const conflicts=new Map(next.conflicts.map(c=>[c.id,c]));
      const changed=new Set([...Object.keys(base),...Object.keys(desired)].filter(id=>!s.equal(base[id],desired[id])));
      for(const id of changed)assert(!conflicts.has(id),'Resolve this record conflict before editing');
      for(const conflict of merge.conflicts){
        conflicts.set(conflict.id,{...conflict,scope:'local'});
        if(conflict.local!==undefined)merge.merged[conflict.id]=s.clone(conflict.local);
        else delete merge.merged[conflict.id];
      }
      for(const id of new Set([...Object.keys(next.records),...Object.keys(merge.merged)])){
        const before=next.records[id],after=merge.merged[id];if(s.equal(before,after))continue;
        next.history=s.historyAppend(next.history,id,before,after,this.clock());
        if(after!==undefined)next.records[id]=s.clone(after);else delete next.records[id];
        next.pending.push({op:'batch-edit',id,sequence:++next.sequence});
      }
      next.conflicts=[...conflicts.values()];return this.commit(next);
    }
    async ingest(remote,remoteHistory=[]){
      const next=this.snapshot();
      s.validateSnapshot({schema:s.SCHEMA,records:remote});
      assert(Array.isArray(remoteHistory),'Invalid remote recovery history');
      for(const entry of remoteHistory){
        assert(entry&&Number.isFinite(entry.at)&&entry.at>=0,'Invalid recovery timestamp');s.record(entry.id,null);
        for(const value of [entry.previous,entry.next])if(value!==undefined)s.validateSnapshot({schema:s.SCHEMA,records:{[entry.id]:value}});
        if(!next.history.some(existing=>s.equal(existing,entry)))next.history.push(s.clone(entry));
      }
      const m=s.threeWay(next.baseline,next.records,remote);
      // Existing conflicts remain explicit even if a later pull equals baseline.
      const existing=new Map(next.conflicts.map(c=>[c.id,c]));
      for(const c of m.conflicts)if(!existing.has(c.id))existing.set(c.id,c);
      next.conflicts=[...existing.values()].map(c=>({...c,local:s.clone(next.records[c.id]),remote:c.scope==='local'?c.remote:s.clone(remote[c.id])}));
      const blocked=new Set(next.conflicts.map(c=>c.id));
      // Preserve local changes, including conflicts, until resolved. Compatible remote changes merge.
      for(const [id,v] of Object.entries(m.merged))if(!blocked.has(id)){
        if(!s.equal(next.records[id],v))next.history=s.historyAppend(next.history,id,next.records[id],v,this.clock());
        next.records[id]=s.clone(v);
      }
      for(const id of Object.keys(next.records))if(!(id in m.merged)&&!blocked.has(id))delete next.records[id];
      // A new remote baseline is accepted only for conflict-free items.
      for(const id of new Set([...Object.keys(next.baseline),...Object.keys(remote)])){
        if(blocked.has(id))continue;
        if(id in remote)next.baseline[id]=s.clone(remote[id]);else delete next.baseline[id];
      }
      return this.commit(next);
    }
    async resolve(decisions){
      const next=this.snapshot();
      const prior={merged:next.records,conflicts:next.conflicts};
      const res=s.resolve(prior,decisions);
      for(const conflict of next.conflicts){
        if(!(conflict.id in (decisions||{})))continue;
        const before=next.records[conflict.id],selected=res.merged[conflict.id];
        if(!s.equal(before,selected))next.history=s.historyAppend(next.history,conflict.id,before,selected,this.clock());
        if(conflict.id in res.merged)next.records[conflict.id]=s.clone(selected);
        else delete next.records[conflict.id];
        // The latest remote value becomes the comparison baseline regardless
        // of the user's choice. Choosing local creates an intentional pending
        // change against that baseline, rather than re-triggering the conflict.
        if(conflict.scope!=='local'){
          if(conflict.remote!==undefined)next.baseline[conflict.id]=s.clone(conflict.remote);
          else delete next.baseline[conflict.id];
        }
        next.pending.push({op:'resolution',id:conflict.id,sequence:++next.sequence,decision:decisions[conflict.id]});
      }
      next.conflicts=next.conflicts.filter(c=>res.unresolved.includes(c.id));
      return this.commit(next);
    }
    async acknowledge(remote){
      const next=this.snapshot();
      assert(!next.conflicts.length,'Cannot acknowledge unresolved conflicts');
      // Caller must provide cloud state confirmed by a successful transaction.
      assert(s.equal(next.records,remote),'Server acknowledgment differs from local state');
      next.baseline=s.clone(remote);next.pending=[];
      return this.commit(next);
    }
    async confirmUpload(uploaded,{sequence=0}={}){
      const next=this.snapshot();
      for(const [id,value] of Object.entries(uploaded)){
        next.baseline[id]=s.clone(value);
      }
      next.pending=next.pending.filter(op=>op.id?!s.equal(next.records[op.id],uploaded[op.id]):op.sequence>sequence);
      return this.commit(next);
    }
    async restore(snapshot,{confirmed=false}={}){
      const next=this.snapshot();
      assert(!next.conflicts.length,'Resolve conflicts before restoration');
      const plan=s.restorePlan(next.records,snapshot);
      const result=s.commitRestore(plan,confirmed);
      // Persist rollback independently of the caller so interrupted restores remain reversible.
      const rollback={at:this.clock(),snapshot:s.clone(result.rollback)};
      const ids=new Set([...Object.keys(next.records),...Object.keys(result.records)]);
      for(const id of ids){
        const before=next.records[id],after=result.records[id];
        if(s.equal(before,after))continue;
        result.records[id]=s.record(id,after?.value,before?Math.max(before.version,after?.version||0)+1:after.version,!after||after.deleted);
      }
      for(const id of ids){
        const before=next.records[id],after=result.records[id];
        if(!s.equal(before,after))next.history=s.historyAppend(next.history,id,before,after,this.clock());
      }
      rollback.after=s.clone(result.records);
      next.rollbackBackups=(next.rollbackBackups||[]).concat([rollback]);
      next.records=result.records;next.pending.push({op:'restore',sequence:++next.sequence});
      await this.commit(next);
      return {snapshot:this.snapshot(),rollback:result.rollback};
    }
    previewRestore(snapshot){return s.restorePlan(this.snapshot().records,snapshot).preview}
    async undoRestore(index,{confirmed=false}={}){
      assert(confirmed,'Explicit restoration Undo confirmation required');
      const next=this.snapshot(),entry=next.rollbackBackups[index];
      assert(entry&&!entry.undone&&entry.after&&entry.at>=this.clock()-s.RETENTION_MS,'Recovery version unavailable');
      assert(!next.conflicts.length,'Resolve conflicts before restoration');
      const ids=new Set([...Object.keys(entry.snapshot.records),...Object.keys(entry.after)]);
      for(const id of ids){
        const before=entry.snapshot.records[id],after=entry.after[id];
        if(s.equal(before,after))continue;
        assert(s.equal(next.records[id],after),'Record changed after restore; review before Undo');
        const restored=s.record(id,before?.value,(after?.version||0)+1,!before||before.deleted);
        next.history=s.historyAppend(next.history,id,next.records[id],restored,this.clock());
        next.records[id]=restored;next.pending.push({op:'undo-restore',id,sequence:++next.sequence});
      }
      entry.undone=true;return this.commit(next);
    }
    recoverableHistory(){return s.historyAt(this.snapshot().history,this.clock())}
    rollbackHistory(){return (this.snapshot().rollbackBackups||[]).filter(e=>e.at>=this.clock()-s.RETENTION_MS)}
  }
  // Every state-changing operation runs against the latest committed snapshot.
  // Without serialization, two asynchronous IndexedDB writes can both read
  // the same snapshot and the slower write can erase the other change.
  const mutating=['edit','applyRecords','ingest','resolve','acknowledge','confirmUpload','restore','undoRestore'];
  for(const method of mutating){
    const original=OfflineStore.prototype[method];
    OfflineStore.prototype[method]=function(...args){
      const previous=this._mutationTail||Promise.resolve();
      const conflictObserved=method==='resolve'?this.snapshot().conflicts:null;
      const restoreObserved=method==='restore'?s.clone(args[1]?.expectedRecords??this.snapshot().records):null;
      const operation=previous.then(async()=>{
        let observed;
        if(method==='edit')observed=s.clone(this.snapshot().records[args[0]]);
        for(let attempt=0;attempt<12;attempt++){
          if(this.adapter.compareAndSwap){
            const latest=await this.adapter.read();s.validateSnapshot(latest);this.state=s.clone(latest);
          }
          if(method==='resolve'&&!s.equal(this.state.conflicts,conflictObserved))throw Error('Conflict changed; compare current versions before choosing');
          if(method==='restore'&&!s.equal(this.state.records,restoreObserved))throw Error('Restore preview is stale; review current changes');
          const input=method==='edit'?[args[0],args[1],{...args[2],_observed:observed,_checkObserved:true}]:args;
          try{return await original.apply(this,input)}catch(e){if(e.code!=='LOCAL_CAS')throw e}
        }
        throw Error('Local storage is busy; retry the change');
      });
      // A rejected write must not permanently block later recovery attempts.
      this._mutationTail=operation.then(()=>undefined,()=>undefined);
      return operation;
    };
  }
  return {OfflineStore,memoryAdapter};
});
