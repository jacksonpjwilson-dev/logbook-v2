const test=require('node:test'),assert=require('node:assert/strict');
const fs=require('node:fs/promises'),os=require('node:os'),path=require('node:path');
const {OfflineStore}=require('../preview-widget/stage1-store.js');
const {createTempAdapter}=require('./support/stage1-node-adapter.cjs');
const idb=require('../preview-widget/stage1-indexeddb.js');
const emu=require('../preview-widget/stage1-emulator.js');
test('offline writes survive disk reload',async()=>{const dir=await fs.mkdtemp(path.join(os.tmpdir(),'lb-stage1-'));
try{const one=new OfflineStore(createTempAdapter(dir));await one.init();await one.edit('workout:synthetic1',{sets:[{done:false}]});
const two=new OfflineStore(createTempAdapter(dir));await two.init();assert.equal(two.snapshot().records['workout:synthetic1'].value.sets[0].done,false);assert.equal(two.snapshot().pending.length,1)}
finally{await fs.rm(dir,{recursive:true,force:true})}});
test('browser adapter refuses production storage',()=>{const fake={open(){}};
assert.throws(()=>idb.createAdapter({indexedDB:fake,dbName:'lb2w:data9'}),/test-only/);
assert.throws(()=>idb.createAdapter({indexedDB:fake,key:'owner'}),/test-only/)});
test('emulator denies non-loopback before touching sdk',()=>{let calls=0;
const fake={useEmulator(){calls++},collection(){calls++}};
assert.throws(()=>emu.createTransport({pageHostname:'example.com',db:fake}),/non-loopback/);
assert.throws(()=>emu.createTransport({pageHostname:'localhost',host:'firestore.googleapis.com',db:fake}),/non-loopback/);
assert.equal(calls,0)});
test('emulator uses only synthetic collection and requires revision',async()=>{
const calls=[],db={useEmulator(h,p){calls.push(['emulator',h,p])},collection(n){calls.push(['collection',n]);return {doc(id){return {get:async()=>({exists:false})}}}}};
const t=emu.createTransport({pageHostname:'localhost',db});
assert.deepEqual(await t.pullVersioned(),{revision:0,records:{}});
assert.ok(calls.some(x=>x[1]==='syntheticLogbookV2'));
await assert.rejects(t.compareAndSwap(null,{}),/revision/)});
