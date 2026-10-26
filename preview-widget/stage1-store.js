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
    return {async read(){return s.clone(saved)},async write(v){saved=s.clone(v)}};
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
      else {this.state=baseState();await this.adapter.write(this.state)}
      return this.snapshot();
    }
    snapshot(){assert(this.state,'Not initialized');return s.clone(this.state)}
    async commit(next){
      // Only swap the visible state after the adapter confirms persistence.
      await this.adapter.write(next);this.state=s.clone(next);return this.snapshot();
    }
    async edit(id,value,{deleted=false}={}){
      const next=this.snapshot();
      const previous=next.records[id];const version=previous?previous.version+1:1;
      const updated=s.record(id,value,version,deleted);
      if(previous&&previous.deleted===!!deleted&&(deleted||s.equal(previous.value,value)))return next;
      next.records[id]=updated;
      next.history=s.historyAppend(next.history,id,previous,updated,this.clock());
      const op={op:'edit',id,sequence:++next.sequence,record:s.clone(updated)};
      next.pending.push(op);
      return this.commit(next);
    }
    async ingest(remote){
      const next=this.snapshot();
      const m=s.threeWay(next.baseline,next.records,remote);
      next.conflicts=m.conflicts;
      // Preserve local changes, including conflicts, until resolved. Compatible remote changes merge.
      for(const [id,v] of Object.entries(m.merged))if(!m.conflicts.some(c=>c.id===id))next.records[id]=s.clone(v);
      for(const id of Object.keys(next.records))if(!(id in m.merged)&&!m.conflicts.some(c=>c.id===id))delete next.records[id];
      // A new remote baseline is accepted only for conflict-free items.
      for(const id of new Set([...Object.keys(next.baseline),...Object.keys(remote)])){
        if(m.conflicts.some(c=>c.id===id))continue;
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
        if(conflict.id in res.merged)next.records[conflict.id]=s.clone(res.merged[conflict.id]);
        else delete next.records[conflict.id];
        // The latest remote value becomes the comparison baseline regardless
        // of the user's choice. Choosing local creates an intentional pending
        // change against that baseline, rather than re-triggering the conflict.
        if(conflict.remote!==undefined)next.baseline[conflict.id]=s.clone(conflict.remote);
        else delete next.baseline[conflict.id];
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
    async restore(snapshot,{confirmed=false}={}){
      const next=this.snapshot();
      assert(!next.conflicts.length,'Resolve conflicts before restoration');
      const plan=s.restorePlan(next.records,snapshot);
      const result=s.commitRestore(plan,confirmed);
      // Persist rollback independently of the caller so interrupted restores remain reversible.
      next.rollbackBackups=(next.rollbackBackups||[]).concat([{at:this.clock(),snapshot:s.clone(result.rollback)}]);
      const ids=new Set([...Object.keys(next.records),...Object.keys(result.records)]);
      for(const id of ids){
        const before=next.records[id],after=result.records[id];
        if(!s.equal(before,after))next.history=s.historyAppend(next.history,id,before,after,this.clock());
      }
      next.records=result.records;next.pending.push({op:'restore',sequence:++next.sequence});
      await this.commit(next);
      return {snapshot:this.snapshot(),rollback:result.rollback};
    }
    recoverableHistory(){return s.historyAt(this.snapshot().history,this.clock())}
    rollbackHistory(){return (this.snapshot().rollbackBackups||[]).filter(e=>e.at>=this.clock()-s.RETENTION_MS)}
  }
  // Every state-changing operation runs against the latest committed snapshot.
  // Without serialization, two asynchronous IndexedDB writes can both read
  // the same snapshot and the slower write can erase the other change.
  const mutating=['edit','ingest','resolve','acknowledge','restore'];
  for(const method of mutating){
    const original=OfflineStore.prototype[method];
    OfflineStore.prototype[method]=function(...args){
      const previous=this._mutationTail||Promise.resolve();
      const operation=previous.then(()=>original.apply(this,args));
      // A rejected write must not permanently block later recovery attempts.
      this._mutationTail=operation.then(()=>undefined,()=>undefined);
      return operation;
    };
  }
  return {OfflineStore,memoryAdapter};
});
