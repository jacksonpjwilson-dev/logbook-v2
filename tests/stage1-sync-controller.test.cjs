const test=require('node:test'),assert=require('node:assert/strict');
const {OfflineStore,memoryAdapter}=require('../preview-widget/stage1-store.js');
const {createCoordinator}=require('../preview-widget/stage1-sync-controller.js');
const {record}=require('../preview-widget/safety-core.js');
function transport(){
 let current={revision:0,records:{}};let inject=null;
 return {mode:'emulator-only',setInject(f){inject=f},state(){return current},
 async pullVersioned(){return JSON.parse(JSON.stringify(current))},
 async compareAndSwap(expected,desired,{history=[]}={}){if(inject){const f=inject;inject=null;f(current)}
 if(current.revision!==expected.revision)return {accepted:false,remote:current};
 current={revision:current.revision+1,records:JSON.parse(JSON.stringify(desired)),history:JSON.parse(JSON.stringify(history))};
 return {accepted:true,revision:current.revision}}};
}
test('isolated sync successfully confirms queued synthetic records',async()=>{
 const store=new OfflineStore(memoryAdapter());await store.init();await store.edit('w:1',{done:false});
 const cloud=transport(),out=await createCoordinator(store,cloud).sync();
 assert.equal(out.status,'synced');assert.equal(cloud.state().records['w:1'].value.done,false);
 assert.equal(store.snapshot().pending.length,0);
});
test('concurrent different record merges after CAS failure',async()=>{
 const store=new OfflineStore(memoryAdapter());await store.init();await store.edit('w:1',1);
 const cloud=transport();
 cloud.setInject(x=>{x.revision++;x.records['w:2']=record('w:2',2)});
 const out=await createCoordinator(store,cloud).sync();
 assert.equal(out.status,'synced');assert.equal(cloud.state().records['w:1'].value,1);
 assert.equal(cloud.state().records['w:2'].value,2);
});
test('concurrent same record flags conflict without silent overwrite',async()=>{
 const store=new OfflineStore(memoryAdapter());await store.init();
 const cloud=transport();await store.edit('w:1',1);
 cloud.setInject(x=>{x.revision++;x.records['w:1']=record('w:1',2)});
 const out=await createCoordinator(store,cloud).sync();
 assert.equal(out.status,'conflict');assert.equal(cloud.state().records['w:1'].value,2);
 assert.equal(store.snapshot().records['w:1'].value,1);
});
test('network failure leaves pending local edits durable',async()=>{
 const store=new OfflineStore(memoryAdapter());await store.init();await store.edit('x',1);
 const out=await createCoordinator(store,{mode:'emulator-only',async pullVersioned(){throw Error('offline')}}).sync();
 assert.equal(out.status,'offline');assert.equal(store.snapshot().pending.length,1);
});

test('edit during successful upload remains pending without false next-sync conflict',async()=>{
 const store=new OfflineStore(memoryAdapter());await store.init();await store.edit('x',1);
 const cloud=transport(),cas=cloud.compareAndSwap;
 cloud.compareAndSwap=async(...args)=>{await store.edit('x',2);return cas(...args)};
 const coordinator=createCoordinator(store,cloud);
 assert.equal((await coordinator.sync()).status,'pending');
 assert.equal(store.snapshot().baseline.x.value,1);
 cloud.compareAndSwap=cas;
 assert.equal((await coordinator.sync()).status,'synced');
 assert.equal(cloud.state().records.x.value,2);assert.equal(store.snapshot().conflicts.length,0);
});
test('unrelated edits sync while another record awaits conflict review',async()=>{
 const store=new OfflineStore(memoryAdapter());await store.init();await store.edit('x',1);await store.edit('y',4);
 const cloud=transport();cloud.setInject(x=>{x.revision++;x.records.x=record('x',2)});
 assert.equal((await createCoordinator(store,cloud).sync()).status,'conflict');
 assert.equal(cloud.state().records.y.value,4);assert.equal(cloud.state().records.x.value,2);
 await store.resolve({x:'local'});
 assert.equal((await createCoordinator(store,cloud).sync()).status,'synced');
});
test('tombstone survives stale offline rejoin, edit-versus-delete requires choice',async()=>{
 const cloud=transport(),a=new OfflineStore(memoryAdapter()),b=new OfflineStore(memoryAdapter());await a.init();await b.init();
 const sa=createCoordinator(a,cloud),sb=createCoordinator(b,cloud);
 await a.edit('x',1);await sa.sync();await sb.sync();
 await a.edit('x',null,{deleted:true});await sa.sync();await b.edit('x',2);
 assert.equal((await sb.sync()).status,'conflict');assert.equal(cloud.state().records.x.deleted,true);
 await b.resolve({x:'remote'});assert.equal((await sb.sync()).status,'synced');assert.equal(b.snapshot().records.x.deleted,true);
});
test('fresh device recovers cloud-synchronized prior and deleted versions',async()=>{
 const cloud=transport(),a=new OfflineStore(memoryAdapter());await a.init();const sync=createCoordinator(a,cloud);
 await a.edit('x',{note:'first'});await sync.sync();await a.edit('x',{note:'second'});await sync.sync();await a.edit('x',null,{deleted:true});await sync.sync();
 const fresh=new OfflineStore(memoryAdapter());await fresh.init();await createCoordinator(fresh,cloud).sync();
 assert.equal(fresh.snapshot().records.x.deleted,true);
 assert.ok(fresh.recoverableHistory().some(e=>e.previous?.value?.note==='first'));
 assert.ok(fresh.recoverableHistory().some(e=>e.previous?.value?.note==='second'&&e.next.deleted));
 const count=fresh.snapshot().history.length;await createCoordinator(fresh,cloud).sync();assert.equal(fresh.snapshot().history.length,count);
});
