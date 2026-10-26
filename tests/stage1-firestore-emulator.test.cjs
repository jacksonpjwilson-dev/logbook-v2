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
 await b.resolve({x:'remote'});await synced(sb);await synced(sa);await a.edit('x',null,{deleted:true});await synced(sa);
 const fresh=new OfflineStore(memoryAdapter());await fresh.init();await createCoordinator(fresh,other).sync();
 assert.equal(fresh.snapshot().records.x.deleted,true);
 assert.ok(fresh.recoverableHistory().some(e=>e.previous?.value?.note==='first'));
 const current=await cloud.pullVersioned();assert.ok(current.history.length>0);
});
test('chunked snapshots exceed 1 MiB safely and interrupted staging cannot publish partial data',async t=>{
 if(!HOST&&!process.env.LOGBOOK_REQUIRE_EMULATORS){t.skip('Emulators not running');return}assert.ok(HOST&&AUTH);assert.match(process.env.GCLOUD_PROJECT||'',/^demo-/);
 const {createTransport}=require('../preview-widget/stage1-rest-transport.js'),{OfflineStore,memoryAdapter}=require('../preview-widget/stage1-store.js'),{createCoordinator}=require('../preview-widget/stage1-sync-controller.js');
 const [host,port]=HOST.split(':'),[authHost,authPort]=AUTH.split(':'),options={pageHostname:'localhost',host,port:+port,authHost,authPort:+authPort,projectId:process.env.GCLOUD_PROJECT},cloud=await createTransport(options),store=new OfflineStore(memoryAdapter());await store.init();
 for(let i=0;i<20;i++)await store.edit('large:'+i,{fixture:i,note:'Synthetic '.repeat(7000)});
 assert.ok(Buffer.byteLength(JSON.stringify(store.snapshot().records))>1024*1024);
 let staged=0,interrupt=true;
 const faulty=await createTransport({...options,session:cloud.session,fetch:async(url,request)=>{
  if(interrupt&&url.endsWith(':commit')&&JSON.parse(request.body).writes[0].update.name.includes('/chunks/')){if(++staged===2){interrupt=false;throw Error('Synthetic interrupted staging')}}return fetch(url,request);
 }});
 const sync=createCoordinator(store,faulty);assert.equal((await sync.sync()).status,'offline');assert.equal((await cloud.pullVersioned()).revision,0);assert.equal(store.snapshot().pending.length,20);
 assert.equal((await sync.sync()).status,'synced');const pulled=await cloud.pullVersioned();assert.equal(Object.keys(pulled.records).length,20);assert.ok(pulled.manifest.length>1);assert.equal(pulled.records['large:19'].value.note,'Synthetic '.repeat(7000));
 const fresh=new OfflineStore(memoryAdapter());await fresh.init();assert.equal((await createCoordinator(fresh,cloud).sync()).status,'synced');assert.equal(fresh.recoverableHistory().length,20);
 const root='http://'+HOST+'/v1/projects/'+process.env.GCLOUD_PROJECT+'/databases/(default)/documents/syntheticLogbookV2/'+cloud.session.uid;
 const response=await fetch(root,{headers:{authorization:'Bearer '+cloud.session.token}}),body=await response.json();assert.ok(Buffer.byteLength(JSON.stringify(body))<1024*1024);assert.ok(body.fields.manifest.arrayValue.values.length>1);
 assert.equal((await fetch(root+'/chunks/'+pulled.manifest[0].id)).status,403,'Anonymous chunk read must fail');
 const other=await createTransport(options);assert.equal((await fetch(root+'/chunks/'+pulled.manifest[0].id,{headers:{authorization:'Bearer '+other.session.token}})).status,403,'Other-user chunk read must fail');
 let dropAck=true;const lostAck=await createTransport({...options,session:cloud.session,fetch:async(url,request)=>{
  const response=await fetch(url,request);if(dropAck&&url.endsWith(':commit')&&!JSON.parse(request.body).writes[0].update.name.includes('/chunks/')&&response.ok){dropAck=false;throw Error('Synthetic lost root acknowledgment')}return response;
 }});
 await store.edit('lost-ack',{note:'Synthetic committed-but-unacknowledged write'});const beforeRevision=(await cloud.pullVersioned()).revision,lostSync=createCoordinator(store,lostAck);
 assert.equal((await lostSync.sync()).status,'offline');assert.equal(store.snapshot().pending.length,1);assert.equal((await cloud.pullVersioned()).revision,beforeRevision+1);
 assert.equal((await lostSync.sync()).status,'synced');assert.equal(store.snapshot().pending.length,0);assert.equal((await cloud.pullVersioned()).revision,beforeRevision+1,'Retry published a duplicate root revision');

 const tampered=await createTransport({...options,session:cloud.session,fetch:async(url,request)=>{
  const response=await fetch(url,request);if(url.includes('/chunks/')&&response.ok){const body=await response.json();body.fields.payload.stringValue='[]';return new Response(JSON.stringify(body),{status:200})}return response;
 }});
 await assert.rejects(tampered.pullVersioned(),/integrity/);
});
test('restoring another device backup with merge and Undo preserves unrelated cloud records',async t=>{
 if(!HOST&&!process.env.LOGBOOK_REQUIRE_EMULATORS){t.skip('Emulators not running');return}assert.ok(HOST&&AUTH);assert.match(process.env.GCLOUD_PROJECT||'',/^demo-/);
 const {createTransport}=require('../preview-widget/stage1-rest-transport.js'),{OfflineStore,memoryAdapter}=require('../preview-widget/stage1-store.js'),{createCoordinator}=require('../preview-widget/stage1-sync-controller.js'),s=require('../preview-widget/safety-core.js');
 const [host,port]=HOST.split(':'),[authHost,authPort]=AUTH.split(':'),options={pageHostname:'localhost',host,port:+port,authHost,authPort:+authPort,projectId:process.env.GCLOUD_PROJECT},cloud=await createTransport(options),other=await createTransport({...options,session:cloud.session});
 const a=new OfflineStore(memoryAdapter()),b=new OfflineStore(memoryAdapter());await a.init();await b.init();const sa=createCoordinator(a,cloud),sb=createCoordinator(b,other),sync=async c=>{const result=await c.sync();assert.equal(result.status,'synced',JSON.stringify(result))};
 await a.edit('x',1);await sync(sa);await sync(sb);const backup=s.backup(a.snapshot().records);await a.edit('later-device-a',4);
 await b.edit('x',2);await b.edit('unrelated-device-b',3);await b.restore(backup,{confirmed:true,mode:'merge'});assert.equal(b.snapshot().records['unrelated-device-b'].value,3);await sync(sb);await sync(sa);
 await b.undoRestore(0,{confirmed:true});await sync(sb);const state=await cloud.pullVersioned();assert.equal(state.records.x.value,2);assert.equal(state.records['unrelated-device-b'].value,3);assert.equal(state.records['later-device-a'].value,4);
});
test('a different demo account cannot silently replace a linked local dataset',async t=>{
 if(!HOST&&!process.env.LOGBOOK_REQUIRE_EMULATORS){t.skip('Emulators not running');return}assert.ok(HOST&&AUTH);assert.match(process.env.GCLOUD_PROJECT||'',/^demo-/);
 const {createTransport}=require('../preview-widget/stage1-rest-transport.js'),{OfflineStore,memoryAdapter}=require('../preview-widget/stage1-store.js'),{createCoordinator}=require('../preview-widget/stage1-sync-controller.js');
 const [host,port]=HOST.split(':'),[authHost,authPort]=AUTH.split(':'),options={pageHostname:'localhost',host,port:+port,authHost,authPort:+authPort,projectId:process.env.GCLOUD_PROJECT},first=await createTransport(options),second=await createTransport(options),store=new OfflineStore(memoryAdapter());await store.init();await store.edit('private-fixture',{note:'Synthetic owner-only record'});
 assert.equal((await createCoordinator(store,first).sync()).status,'synced');const before=store.snapshot(),result=await createCoordinator(store,second).sync();assert.equal(result.status,'offline');assert.match(result.error,/account changed/);assert.deepEqual(store.snapshot(),before);assert.deepEqual((await second.pullVersioned()).records,{});
});
