/* Experimental Stage 1 atomic browser adapter: test namespace only, never loaded by existing app. */
(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;else root.LogbookIndexedDB=api;})(typeof globalThis!=='undefined'?globalThis:this,function(){
'use strict';
function createAdapter({indexedDB,dbName='logbook-v2-stage1-test',key='synthetic'}={}){
 if(!indexedDB||typeof indexedDB.open!=='function')throw Error('IndexedDB unavailable');
 if(!dbName.startsWith('logbook-v2-stage1-')||!key.startsWith('synthetic'))throw Error('Stage 1 test-only database and synthetic key required');
 let promise;
 function db(){if(!promise)promise=new Promise((resolve,reject)=>{
  const req=indexedDB.open(dbName,1);
  req.onupgradeneeded=()=>{if(!req.result.objectStoreNames.contains('snapshots'))req.result.createObjectStore('snapshots')};
  req.onsuccess=()=>resolve(req.result);
  req.onerror=()=>reject(req.error||Error('Open failed'));
  req.onblocked=()=>reject(Error('IndexedDB blocked'));
 }).catch(e=>{promise=null;throw e});return promise}
 async function tx(mode,action){const database=await db();return new Promise((resolve,reject)=>{
  let result;const transaction=database.transaction('snapshots',mode);
  transaction.oncomplete=()=>resolve(result);
  transaction.onerror=()=>reject(transaction.error||Error('Transaction failed'));
  transaction.onabort=()=>reject(transaction.error||Error('Transaction aborted'));
  try{const request=action(transaction.objectStore('snapshots'));request.onsuccess=()=>{result=request.result}}catch(e){try{transaction.abort()}catch(_){}reject(e)}
 })}
 async function compareAndSwap(expected,next){
  const database=await db();
  return new Promise((resolve,reject)=>{
   const transaction=database.transaction('snapshots','readwrite');
   const store=transaction.objectStore('snapshots');let accepted=false;
   transaction.oncomplete=()=>resolve(accepted);
   transaction.onerror=()=>reject(transaction.error||Error('Transaction failed'));
   transaction.onabort=()=>reject(transaction.error||Error('Transaction aborted'));
   const request=store.get(key);
   request.onsuccess=()=>{
    // The read and conditional write share one IDB transaction across tabs.
    if(JSON.stringify(request.result??null)!==JSON.stringify(expected??null))return;
    store.put(JSON.parse(JSON.stringify(next)),key);accepted=true;
   };
  });
 }
 return {compareAndSwap,read:()=>tx('readonly',s=>s.get(key)),write:async v=>{await tx('readwrite',s=>s.put(JSON.parse(JSON.stringify(v)),key))},async close(){if(promise)(await promise).close();promise=null}};
}
return {createAdapter};
});
