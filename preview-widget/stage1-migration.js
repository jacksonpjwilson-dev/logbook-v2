/* Synthetic migration rehearsal only. No storage discovery, network or real-data access. */
(function(root,factory){const api=factory(typeof module==='object'&&module.exports?require('./safety-core.js'):root.LogbookSafety);if(typeof module==='object'&&module.exports)module.exports=api;else root.LogbookMigration=api})(globalThis,function(s){
'use strict';
async function digest(value){
 const bytes=new TextEncoder().encode(JSON.stringify(value));
 return Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',bytes)),b=>b.toString(16).padStart(2,'0')).join('');
}
async function rehearse({legacy,auxiliary={},backupAdapter,store,confirmed=false,reviewed=false}){
 if(!backupAdapter?.compareAndSwap||!store||confirmed!==true)throw Error('Separate atomic backup adapter and explicit confirmation required');
 const plan=s.migrateLegacy(legacy,{auxiliary});
 // Entire source is retained, including duplicate/invalid IDs and malformed legacy fields.
 const source={legacy:s.clone(legacy),auxiliary:s.clone(plan.snapshot.metadata.auxiliaryOriginal)};
 const envelope={schema:1,source,sha256:await digest(source)};
 const existing=await backupAdapter.read();
 if(existing&&!s.equal(existing,envelope))throw Error('Backup namespace already holds a different source');
 if(!existing&&!await backupAdapter.compareAndSwap(null,envelope))throw Error('Concurrent backup; retry');
 const verified=await backupAdapter.read();
 if(!verified||await digest(verified.source)!==envelope.sha256||!s.equal(verified,envelope))throw Error('Backup verification failed');
 const incoming=s.migrationCommit(plan,reviewed,true);
 const state=store.snapshot();
 if(Object.keys(state.records).length){
  if(s.equal(state.records,incoming.records))return {status:'already-migrated',sha256:envelope.sha256};
  throw Error('Migration requires an empty isolated target; existing data is protected');
 }
 await store.restore(incoming,{confirmed:true});
 return {status:'migrated',sha256:envelope.sha256,records:Object.keys(incoming.records).length};
}
return {digest,rehearse};
});
