const test=require('node:test'),assert=require('node:assert/strict');
const s=require('../preview-widget/safety-core.js');
const {OfflineStore,memoryAdapter}=require('../preview-widget/stage1-store.js');
const {rehearse}=require('../preview-widget/stage1-migration.js');
test('migration preserves malformed legacy shapes and all raw duplicate entries in backup',()=>{
 const source={version:1,demo:false,workouts:[null,{id:'a',exercises:null}],templates:null,foods:[{id:'same',x:1},{id:'same',x:2}]};
 const plan=s.migrateLegacy(source);assert.deepEqual(plan.snapshot.metadata.legacyOriginal,source);
 assert.throws(()=>s.migrationCommit(plan,true,true),/remapping/);
});
test('durable backup readback precedes migration and survives ambiguous-identity refusal',async()=>{
 const store=new OfflineStore(memoryAdapter());await store.init();const backup=memoryAdapter();
 const legacy={foods:[{id:'x'},{id:'x'}]};
 await assert.rejects(rehearse({legacy,backupAdapter:backup,store,confirmed:true}),/remapping/);
 assert.deepEqual((await backup.read()).source.legacy,legacy);assert.deepEqual(store.snapshot().records,{});
});
test('corrupt backup readback prevents migration writes',async()=>{
 const store=new OfflineStore(memoryAdapter());await store.init();let saved=null;
 const backup={async read(){return saved&&{...saved,sha256:'bad'}},async compareAndSwap(_,value){saved=value;return true}};
 await assert.rejects(rehearse({legacy:{version:1},backupAdapter:backup,store,confirmed:true}),/verification/);
 assert.deepEqual(store.snapshot().records,{});
});
test('migration never overwrites populated target or a different source backup',async()=>{
 const store=new OfflineStore(memoryAdapter());await store.init();await store.edit('x',1);
 const backup=memoryAdapter();
 await assert.rejects(rehearse({legacy:{version:1},backupAdapter:backup,store,confirmed:true}),/empty/);
 await assert.rejects(rehearse({legacy:{version:2},backupAdapter:backup,store,confirmed:true}),/different source/);
 assert.equal(store.snapshot().records.x.value,1);
});
test('verified synthetic migration is idempotent and source hash is stable',async()=>{
 const store=new OfflineStore(memoryAdapter());await store.init();const backup=memoryAdapter();
 const options={legacy:{version:1,workouts:[],profile:{name:'Fictional'}},backupAdapter:backup,store,confirmed:true};
 const first=await rehearse(options),second=await rehearse(options);
 assert.equal(first.status,'migrated');assert.equal(second.status,'already-migrated');assert.equal(first.sha256,second.sha256);
});
