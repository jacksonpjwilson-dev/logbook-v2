/* Run ONLY under firebase emulators:exec with a demo project. No production SDK. */
const test=require('node:test'),assert=require('node:assert/strict');
const {assertLocal}=require('../preview-widget/stage1-emulator.js');
const HOST=process.env.FIRESTORE_EMULATOR_HOST;
test('Firestore emulator provides revision-based CAS isolation',async t=>{
 if(!HOST){t.skip('Emulator not running');return}
 const [host,port]=HOST.split(':');assertLocal('localhost',host,Number(port));
 assert.match(process.env.GCLOUD_PROJECT||'',/^demo-/);
 const base='http://'+host+':'+port+'/v1/projects/'+process.env.GCLOUD_PROJECT+'/databases/(default)/documents/syntheticLogbookV2/synthetic-rest-test';
 // REST preconditions guarantee that a stale write fails rather than overwriting remote work.
 const get=()=>fetch(base),post=(body,query='')=>fetch(base+query,{method:'PATCH',headers:{'content-type':'application/json'},body:JSON.stringify(body)});
 const payload=v=>({fields:{revision:{integerValue:String(v)},synthetic:{booleanValue:true}}});
 const first=await post(payload(1));assert.equal(first.status,200,await first.text());
 const orig=await get();assert.equal(orig.status,200);const original=await orig.json();
 const second=await post(payload(2),'?currentDocument.updateTime='+encodeURIComponent(original.updateTime));
 assert.equal(second.status,200,await second.text());
 const stale=await post(payload(3),'?currentDocument.updateTime='+encodeURIComponent(original.updateTime));
 assert.equal(stale.status,400,await stale.text());
});
