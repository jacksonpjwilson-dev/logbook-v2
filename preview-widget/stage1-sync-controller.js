/* Stage 1 synthetic-only synchronization coordinator. No production Firebase imports.
   Transport must be emulator-only and implement pullVersioned/compareAndSwap. */
(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;else root.LogbookStage1Sync=api;})(typeof globalThis!=='undefined'?globalThis:this,function(){
'use strict';
function createCoordinator(store,transport){
 if(!store||!transport||transport.mode!=='emulator-only')throw Error('Isolated emulator transport required');
 let running=false;
 return {async sync({maxRetries=3}={}){
  if(running)return {status:'busy'};
  running=true;
  try{
   for(let attempt=0;attempt<maxRetries;attempt++){
    const remote=await transport.pullVersioned();
    await store.ingest(remote.records||{});
    let state=store.snapshot();
    const conflicts=state.conflicts;
    // Upload unrelated records while keeping each conflicted remote value intact.
    const blocked=new Set(conflicts.map(c=>c.id));
    const desired=JSON.parse(JSON.stringify(state.records));
    for(const id of blocked){if(id in (remote.records||{}))desired[id]=remote.records[id];else delete desired[id]}
    // If already synchronized, clear only the confirmed pending batch.
    const equal=JSON.stringify(desired)===JSON.stringify(remote.records||{});
    if(equal){
      const uploaded=Object.fromEntries(Object.entries(desired).filter(([id])=>!blocked.has(id)));
      await store.confirmUpload(uploaded,{sequence:conflicts.length?0:state.sequence});
      return {status:conflicts.length?'conflict':store.snapshot().pending.length?'pending':'synced',conflicts,revision:remote.revision};
    }
    const response=await transport.compareAndSwap({revision:remote.revision},desired);
    if(!response.accepted)continue;
    // Never acknowledge edits that arrived while the cloud request was pending.
    await store.confirmUpload(Object.fromEntries(Object.entries(desired).filter(([id])=>!blocked.has(id))),{sequence:conflicts.length?0:state.sequence});
    state=store.snapshot();
    return {status:state.conflicts.length?'conflict':state.pending.length?'pending':'synced',conflicts:state.conflicts,revision:response.revision};
   }
   return {status:'retry-needed'};
  }catch(e){return {status:'offline',error:String(e)}}
  finally{running=false}
 }};
}
return {createCoordinator};
});
