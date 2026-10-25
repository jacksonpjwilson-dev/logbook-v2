const test=require('node:test'),assert=require('node:assert/strict');
const {OfflineStore,memoryAdapter}=require('../preview-widget/stage1-store.js');
const {createCoordinator}=require('../preview-widget/stage1-sync-controller.js');
const {record}=require('../preview-widget/safety-core.js');
function transport(){
 let current={revision:0,records:{}};let inject=null;
 return {mode:'emulator-only',setInject(f){inject=f},state(){return current},
 async pullVersioned(){return JSON.parse(JSON.stringify(current))},
 async compareAndSwap(expected,desired){if(inject){const f=inject;inject=null;f(current)}
 if(current.revision!==expected.revision)return {accepted:false,remote:current};
 current={revision:current.revision+1,records:JSON.parse(JSON.stringify(desired))};
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
