/* Local Auth + Firestore only; no production SDK or credentials. */
const test=require('node:test'),assert=require('node:assert/strict');
const {assertLocal}=require('../preview-widget/stage1-emulator.js');
const HOST=process.env.FIRESTORE_EMULATOR_HOST,AUTH=process.env.FIREBASE_AUTH_EMULATOR_HOST;
test('Firestore CAS and authenticated user isolation on demo emulators',async t=>{
 if(!HOST&&!process.env.LOGBOOK_REQUIRE_EMULATORS){t.skip('Emulators not running');return}
 assert.ok(HOST&&AUTH,'Both Auth and Firestore emulators required');
 for(const endpoint of [HOST,AUTH]){const [host,port]=endpoint.split(':');assertLocal('localhost',host,Number(port))}
 const project=process.env.GCLOUD_PROJECT;assert.match(project||'',/^demo-/);
 const signup=async()=>{
  const response=await fetch('http://'+AUTH+'/identitytoolkit.googleapis.com/v1/accounts:signUp?key=synthetic-only',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({returnSecureToken:true})});
  assert.equal(response.status,200);return response.json();
 };
 const [a,b]=await Promise.all([signup(),signup()]);
 const base='http://'+HOST+'/v1/projects/'+project+'/databases/(default)/documents/';
 const path='syntheticLogbookV2/'+a.localId;
 const request=(token,method='GET',body,query='',resource=path)=>fetch(base+resource+query,{method,headers:{'content-type':'application/json',...(token?{authorization:'Bearer '+token}:{})},body:body?JSON.stringify(body):undefined});
 const payload=revision=>({fields:{revision:{integerValue:String(revision)},synthetic:{booleanValue:true},records:{mapValue:{fields:{}}},history:{arrayValue:{values:[]}}}});
 const first=await request(a.idToken,'PATCH',payload(1));assert.equal(first.status,200,await first.text());
 const orig=await request(a.idToken);assert.equal(orig.status,200);const original=await orig.json();
 const conditional=revision=>fetch(base.slice(0,-1)+':commit',{method:'POST',headers:{'content-type':'application/json',authorization:'Bearer '+a.idToken},body:JSON.stringify({writes:[{update:{name:'projects/'+project+'/databases/(default)/documents/'+path,...payload(revision)},currentDocument:{updateTime:original.updateTime}}]})});
 const second=await conditional(2);assert.equal(second.status,200,await second.text());
 const stale=await conditional(3);assert.ok([400,409,412].includes(stale.status),'Stale write accepted');
 assert.equal((await request()).status,403,'Anonymous read must fail');
 assert.equal((await request(b.idToken)).status,403,'Other account read must fail');
 assert.equal((await request(b.idToken,'PATCH',payload(3))).status,403,'Other account write must fail');
 assert.equal((await request(a.idToken,'PATCH',payload(9))).status,403,'Invalid revision must fail');
 assert.equal((await request(a.idToken,'GET',undefined,'','logbookV2/'+a.localId)).status,403,'Production collection must fail');
});
test('real emulator transport synchronizes independent devices and recoverable history',async t=>{
 if(!HOST&&!process.env.LOGBOOK_REQUIRE_EMULATORS){t.skip('Emulators not running');return}
 assert.ok(HOST&&AUTH);const [host,port]=HOST.split(':'),[authHost,authPort]=AUTH.split(':');
 const {createTransport}=require('../preview-widget/stage1-rest-transport.js');
 const {OfflineStore,memoryAdapter}=require('../preview-widget/stage1-store.js');
 const {createCoordinator}=require('../preview-widget/stage1-sync-controller.js');
 const options={pageHostname:'localhost',host,port:+port,authHost,authPort:+authPort,projectId:process.env.GCLOUD_PROJECT};
 const cloud=await createTransport(options),other=await createTransport({...options,session:cloud.session});
 const a=new OfflineStore(memoryAdapter()),b=new OfflineStore(memoryAdapter());await a.init();await b.init();
 const sa=createCoordinator(a,cloud),sb=createCoordinator(b,other);
 const synced=async coordinator=>{const result=await coordinator.sync();assert.equal(result.status,'synced',JSON.stringify(result))};
 await a.edit('x',{note:'first',sets:[{done:false,w:45.5}]});await synced(sa);await synced(sb);
 await a.edit('left',1);await b.edit('right',2);const concurrent=await Promise.all([sa.sync(),sb.sync()]);for(const result of concurrent)assert.ok(['synced','retry-needed'].includes(result.status),JSON.stringify(result));await synced(sa);await synced(sb);
 assert.equal(a.snapshot().records.right.value,2);assert.equal(b.snapshot().records.left.value,1);
 await a.edit('x',{note:'device A'});await b.edit('x',{note:'device B'});await sa.sync();assert.equal((await sb.sync()).status,'conflict');
 await b.resolve({x:'remote'});await sb.sync();await a.edit('x',null,{deleted:true});await sa.sync();
 const fresh=new OfflineStore(memoryAdapter());await fresh.init();await createCoordinator(fresh,other).sync();
 assert.equal(fresh.snapshot().records.x.deleted,true);
 assert.ok(fresh.recoverableHistory().some(e=>e.previous?.value?.note==='first'));
 const current=await cloud.pullVersioned();assert.ok(current.history.length>0);
});
