/* Logbook v2 data safety primitives — Stage 1, isolated (not loaded by production HTML).
   No Firebase SDK, network, browser storage or production credentials. */
(function(root,factory){
  const api=factory();
  if(typeof module==='object'&&module.exports)module.exports=api;
  else root.LogbookSafety=api;
})(typeof globalThis!=='undefined'?globalThis:this,function(){
  'use strict';
  const SCHEMA=2, RETENTION_MS=30*24*60*60*1000;
  const own=(o,k)=>Object.prototype.hasOwnProperty.call(o,k);
  const clone=x=>x===undefined?undefined:JSON.parse(JSON.stringify(x));
  const sorted=x=>{
    if(Array.isArray(x))return x.map(sorted);
    if(x&&typeof x==='object'){const v={};for(const k of Object.keys(x).sort())v[k]=sorted(x[k]);return v}
    return x;
  };
  const equal=(a,b)=>JSON.stringify(sorted(a))===JSON.stringify(sorted(b));
  const assert=(ok,msg)=>{if(!ok)throw new Error(msg)};
  const validId=x=>typeof x==='string'&&/^[a-zA-Z0-9_:@.-]{1,160}$/.test(x);
  const record=(id,value,version=1,deleted=false)=>{assert(validId(id),'Invalid record ID');assert(Number.isSafeInteger(version)&&version>0,'Invalid record version');return {id,version,deleted:!!deleted,value:deleted?null:clone(value)}};
  const has=(r,id)=>own(r,id);
  function threeWay(base,local,remote){
    const merged={},conflicts=[],ids=new Set([...Object.keys(base||{}),...Object.keys(local||{}),...Object.keys(remote||{})]);
    for(const id of [...ids].sort()){
      assert(validId(id),'Invalid record key');
      const b=has(base||{},id)?base[id]:undefined;
      const l=has(local||{},id)?local[id]:undefined;
      const r=has(remote||{},id)?remote[id]:undefined;
      const lc=!equal(l,b),rc=!equal(r,b);
      if(!lc&&!rc){if(b!==undefined)merged[id]=clone(b)}
      else if(lc&&!rc){if(l!==undefined)merged[id]=clone(l)}
      else if(!lc&&rc){if(r!==undefined)merged[id]=clone(r)}
      else if(equal(l,r)){if(l!==undefined)merged[id]=clone(l)}
      else {
        conflicts.push({id,base:clone(b),local:clone(l),remote:clone(r),kind:(l===undefined||r===undefined||l&&l.deleted||r&&r.deleted)?'delete-edit':'edit-edit'});
        // Do not choose a winner or silently overwrite either side.
        if(b!==undefined)merged[id]=clone(b);
      }
    }
    return {merged,conflicts,blocked:conflicts.length>0};
  }
  function resolve(result,decisions){
    const out=clone(result.merged),unresolved=[];
    for(const conflict of result.conflicts){
      if(!own(decisions||{},conflict.id)){unresolved.push(conflict.id);continue}
      const selected=decisions[conflict.id];
      assert(['local','remote','base'].includes(selected),'Invalid explicit conflict decision');
      const value=conflict[selected];
      if(value===undefined)delete out[conflict.id];else out[conflict.id]=clone(value);
    }
    return {merged:out,unresolved,blocked:unresolved.length>0};
  }
  function validateSnapshot(s){
    assert(s&&s.schema===SCHEMA&&s.records&&typeof s.records==='object'&&!Array.isArray(s.records),'Unsupported backup schema');
    for(const [id,r] of Object.entries(s.records)){
      assert(validId(id)&&r&&r.id===id&&Number.isSafeInteger(r.version)&&r.version>0,'Invalid backup record');
      assert(typeof r.deleted==='boolean','Missing deletion flag');
    }
    return true;
  }
  function backup(records,metadata={}){
    assert(records&&typeof records==='object'&&!Array.isArray(records),'Invalid source');
    const s={schema:SCHEMA,createdAt:new Date().toISOString(),records:clone(records),metadata:clone(metadata)};
    validateSnapshot(s);return s;
  }
  function restorePlan(current,snapshot){
    validateSnapshot(snapshot);
    return {preview:{existing:Object.keys(current||{}).length,incoming:Object.keys(snapshot.records).length},
      before:backup(current,{reason:'pre-restore rollback'}),
      incoming:clone(snapshot.records)};
  }
  function commitRestore(plan,explicit){
    assert(explicit===true,'Explicit restoration confirmation required');
    validateSnapshot(plan.before);
    return {records:clone(plan.incoming),rollback:clone(plan.before)};
  }
  function historyAppend(log,id,previous,now,at){
    assert(validId(id),'Invalid ID');assert(Number.isFinite(at)&&at>=0,'Invalid time');
    const entry={id,at,previous:clone(previous),next:clone(now)};
    return (log||[]).concat([entry]);
  }
  function historyAt(log,now){
    return (log||[]).filter(e=>e&&Number.isFinite(e.at)&&e.at<=now&&e.at>=now-RETENTION_MS);
  }
  function historyRestore(log,id,index,now){
    const matches=historyAt(log,now).filter(e=>e.id===id);
    assert(index>=0&&index<matches.length,'Recovery version unavailable');
    return clone(matches[index].previous);
  }
  function migrateLegacy(legacy,options={}){
    assert(legacy&&typeof legacy==='object'&&!Array.isArray(legacy),'Invalid legacy input');
    const previous=clone(legacy),records={},ambiguous=[],seen=new Set();
    const lib=Array.isArray(legacy.lib)?legacy.lib:[];
    const names=new Map();
    for(const item of lib)if(item&&typeof item.name==='string'){
      const key=item.name.trim().toLowerCase(),ids=names.get(key)||[];
      if(item.id!==undefined)ids.push(String(item.id));
      names.set(key,ids);
    }
    const add=(prefix,id,value)=>{
      let key=prefix+':'+String(id);
      if(!validId(key)||seen.has(key)){ambiguous.push({type:'record-id',source:prefix,legacyId:String(id)});return}
      seen.add(key);records[key]=record(key,{legacy:clone(value),source:prefix});
    };
    for(const key of ['lib','workouts','foods','sleep','weight','templates','savedMeals']){
      const arr=legacy[key];if(!Array.isArray(arr))continue;
      arr.forEach((v,i)=>add(key, v&&v.id!=null?v.id:key==='sleep'||key==='weight'?v&&v.date||i:i,v));
    }
    for(const key of ['food','schedule']){
      const map=legacy[key];if(!map||typeof map!=='object'||Array.isArray(map))continue;
      for(const [date,value] of Object.entries(map))add(key,date,value);
    }
    for(const k of ['profile','active','split','splitMarks','supplements','mealSlots','pantry']){
      if(own(legacy,k))add('field',k,legacy[k]);
    }
    const visit=(ex,context)=>{
      if(!ex||typeof ex.name!=='string')return;
      const candidates=names.get(ex.name.trim().toLowerCase())||[];
      if(candidates.length!==1)ambiguous.push({type:'exercise-identity',context,name:ex.name,candidates:clone(candidates)});
    };
    (legacy.workouts||[]).forEach((w,i)=>(w.exercises||[]).forEach(e=>visit(e,'workouts/'+i)));
    (legacy.templates||[]).forEach((t,i)=>(t.exercises||[]).forEach(e=>visit(typeof e==='string'?{name:e}:e,'templates/'+i)));
    return {snapshot:backup(records,{legacyVersion:legacy.version??null,source:'legacy-preview',verified:false}),
      original:previous,ambiguous,ready:ambiguous.length===0};
  }
  function migrationCommit(plan,reviewed,backupVerified){
    assert(backupVerified===true,'Verified durable backup required');
    assert(plan&&plan.snapshot,'Missing migration plan');
    assert(plan.ambiguous.length===0||reviewed===true,'Ambiguous identifiers require explicit review');
    validateSnapshot(plan.snapshot);
    return clone(plan.snapshot);
  }
  return {SCHEMA,RETENTION_MS,clone,equal,record,threeWay,resolve,backup,validateSnapshot,restorePlan,commitRestore,historyAppend,historyAt,historyRestore,migrateLegacy,migrationCommit};
});
