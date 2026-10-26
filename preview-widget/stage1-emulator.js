/* Stage 1 emulator-only Firestore transport: injected SDK, never production configuration. */
(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;else root.LogbookStage1Emulator=api;})(typeof globalThis!=='undefined'?globalThis:this,function(){
'use strict';
const LOOPBACK=new Set(['localhost','127.0.0.1','::1','[::1]']);
function assertLocal(page,host,port){
 if(!LOOPBACK.has(page)||!LOOPBACK.has(host))throw Error('Stage 1 refuses non-loopback page or endpoint');
 if(!Number.isSafeInteger(port)||port<1024||port>65535)throw Error('Invalid local port');
}
function createTransport({pageHostname,host='127.0.0.1',port=8080,db,projectId='demo-logbook-stage1',uid='synthetic-stage1',collection='syntheticLogbookV2'}={}){
 assertLocal(pageHostname,host,port);
 if(!/^demo-[a-z0-9-]+$/.test(projectId))throw Error('Demo project required');
 if(db?.app?.options?.projectId&&db.app.options.projectId!==projectId)throw Error('SDK project does not match isolated demo');
 if(typeof uid!=='string'||!uid||uid.includes('/'))throw Error('Explicit isolated user ID required');
 if(!/^synthetic[A-Za-z0-9_-]*$/.test(collection))throw Error('Synthetic collection required');
 if(!db||typeof db.useEmulator!=='function'||typeof db.collection!=='function')throw Error('Firestore emulator SDK required');
 db.useEmulator(host,port);
 const ref=()=>db.collection(collection).doc(uid);
 return {mode:'emulator-only',
 async pullVersioned(){const s=await ref().get();return s.exists?s.data():{revision:0,records:{}}},
 async compareAndSwap(expected,desired,{history=[]}={}){
  if(!expected||!Number.isSafeInteger(expected.revision))throw Error('Expected revision required');
  return db.runTransaction(async tx=>{
   const snap=await tx.get(ref()),remote=snap.exists?snap.data():{revision:0,records:{}};
   if(remote.revision!==expected.revision)return {accepted:false,remote};
   tx.set(ref(),{revision:remote.revision+1,records:desired,history,synthetic:true});
   return {accepted:true,revision:remote.revision+1};
  })
 }};
}
return {assertLocal,createTransport};
});
