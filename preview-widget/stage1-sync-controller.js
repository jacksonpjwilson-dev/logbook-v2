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
    if(state.conflicts.length)return {status:'conflict',conflicts:state.conflicts};
    const desired=state.records;
    // If already synchronized, clear only the confirmed pending batch.
    const equal=JSON.stringify(desired)===JSON.stringify(remote.records||{});
    if(equal){await store.acknowledge(desired);return {status:'synced',revision:remote.revision}}
    const response=await transport.compareAndSwap({revision:remote.revision},desired);
    if(!response.accepted)continue;
    // Never acknowledge edits that arrived while the cloud request was pending.
    state=store.snapshot();
    if(JSON.stringify(state.records)!==JSON.stringify(desired))return {status:'pending',revision:response.revision};
    await store.acknowledge(desired);
    return {status:'synced',revision:response.revision};
   }
   return {status:'retry-needed'};
  }catch(e){return {status:'offline',error:String(e)}}
  finally{running=false}
 }};
}
return {createCoordinator};
});
