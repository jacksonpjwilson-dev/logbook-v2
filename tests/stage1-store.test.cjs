const test=require('node:test'),assert=require('node:assert/strict');
const safety=require('../preview-widget/safety-core.js');
const {OfflineStore,memoryAdapter}=require('../preview-widget/stage1-store.js');
test('offline edits survive store reload and queue persists',async()=>{
 const a=memoryAdapter(),one=new OfflineStore(a,()=>10000000000);await one.init();
 await one.edit('workout:1',{sets:[{done:false,w:100}]});
 const two=new OfflineStore(a,()=>10000000010);await two.init();
 assert.equal(two.snapshot().records['workout:1'].value.sets[0].done,false);
 assert.equal(two.snapshot().pending.length,1);
});
test('failed durable write cannot expose uncommitted edit',async()=>{
 let data=null;const a={read:async()=>data,write:async(v)=>{if(v.pending.length)throw Error('disk unavailable');data=v}};
 const one=new OfflineStore(a);await one.init();
 await assert.rejects(one.edit('x',1),/disk/);
 assert.equal(Object.keys(one.snapshot().records).length,0);
});
test('conflicting offline edits preserve local and require explicit resolution',async()=>{
 const a=memoryAdapter(),one=new OfflineStore(a);await one.init();
 const base={x:safety.record('x',1)};
 await one.ingest(base);await one.edit('x',2);
 await one.ingest({x:safety.record('x',3)});
 assert.equal(one.snapshot().conflicts.length,1);
 assert.equal(one.snapshot().records.x.value,2);
 await one.resolve({x:'remote'});
 assert.equal(one.snapshot().records.x.value,3);
 assert.equal(one.snapshot().conflicts.length,0);
});
test('acknowledging cloud requires exact confirmed state and no conflicts',async()=>{
 const one=new OfflineStore(memoryAdapter());await one.init();
 await one.edit('food:1',{kcal:100});
 await assert.rejects(one.acknowledge({}),/differs/);
 await one.acknowledge(one.snapshot().records);
 assert.equal(one.snapshot().pending.length,0);
});
test('restore requires confirmation and returns rollback',async()=>{
 const one=new OfflineStore(memoryAdapter(),()=>10000000000);await one.init();
 await one.edit('x',1);
 const incoming=safety.backup({y:safety.record('y',2)});
 await assert.rejects(one.restore(incoming),/confirmation/);
 const result=await one.restore(incoming,{confirmed:true});
 assert.equal(result.rollback.records.x.value,1);
 assert.equal(one.snapshot().records.y.value,2);
});

test('idempotent edit does not increment version or duplicate queue',async()=>{
 const one=new OfflineStore(memoryAdapter());await one.init();await one.edit('x',{value:42});
 const before=one.snapshot();await one.edit('x',{value:42});const after=one.snapshot();
 assert.equal(after.records.x.version,before.records.x.version);
 assert.equal(after.pending.length,before.pending.length);
});
test('restore records removal, persists rollback across reload',async()=>{
 const adapter=memoryAdapter(),one=new OfflineStore(adapter,()=>10000000000);await one.init();
 await one.edit('remove-me',{reps:8});
 await one.restore(safety.backup({keep:safety.record('keep',{reps:10})}),{confirmed:true});
 const reopened=new OfflineStore(adapter,()=>10000000001);await reopened.init();
 assert.equal(reopened.snapshot().rollbackBackups.length,1);
 assert.equal(reopened.rollbackHistory()[0].snapshot.records['remove-me'].value.reps,8);
 assert.equal(reopened.snapshot().records['remove-me'],undefined);
 const deletion=reopened.recoverableHistory().find(e=>e.id==='remove-me'&&e.next===undefined);
 assert.ok(deletion);
});
test('unresolved conflict prevents restore',async()=>{
 const one=new OfflineStore(memoryAdapter());await one.init();
 await one.ingest({x:safety.record('x',1)});await one.edit('x',2);
 await one.ingest({x:safety.record('x',3)});
 await assert.rejects(one.restore(safety.backup({}),{confirmed:true}),/Resolve conflicts/);
});

test('choosing local conflict version does not flag same remote change again',async()=>{
 const one=new OfflineStore(memoryAdapter());await one.init();
 await one.ingest({x:safety.record('x',1)});
 await one.edit('x',2);
 const remote={x:safety.record('x',3)};
 await one.ingest(remote);
 assert.equal(one.snapshot().conflicts.length,1);
 await one.resolve({x:'local'});
 assert.equal(one.snapshot().conflicts.length,0);
 await one.ingest(remote);
 assert.equal(one.snapshot().conflicts.length,0);
 assert.equal(one.snapshot().records.x.value,2);
});
