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
 assert.equal(reopened.snapshot().records['remove-me'].deleted,true);
 const deletion=reopened.recoverableHistory().find(e=>e.id==='remove-me'&&e.next?.deleted===true);
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

test('parallel edits cannot erase each other across asynchronous writes',async()=>{
 let durable=null;
 const adapter={read:async()=>durable,write:async v=>{
   await new Promise(resolve=>setTimeout(resolve,v.records&&v.records.a?8:1));
   durable=safety.clone(v);
 }};
 const one=new OfflineStore(adapter);await one.init();
 await Promise.all([one.edit('a',1),one.edit('b',2),one.edit('c',3)]);
 assert.equal(one.snapshot().records.a.value,1);
 assert.equal(one.snapshot().records.b.value,2);
 assert.equal(one.snapshot().records.c.value,3);
 const reopened=new OfflineStore(adapter);await reopened.init();
 assert.equal(reopened.snapshot().pending.length,3);
 assert.equal(reopened.snapshot().records.c.value,3);
});
test('a rejected write does not poison subsequent updates',async()=>{
 let durable=null,fail=true;
 const adapter={read:async()=>durable,write:async v=>{
   if(fail&&v.pending&&v.pending.length){fail=false;throw Error('disk error')}
   durable=safety.clone(v)
 }};
 const one=new OfflineStore(adapter);await one.init();
 await assert.rejects(one.edit('a',1),/disk/);
 await one.edit('b',2);
 assert.equal(one.snapshot().records.a,undefined);
 assert.equal(one.snapshot().records.b.value,2);
});

test('two store instances retain independent concurrent edits',async()=>{
 const adapter=memoryAdapter(),a=new OfflineStore(adapter),b=new OfflineStore(adapter);
 await Promise.all([a.init(),b.init()]);
 await Promise.all([a.edit('a',1),b.edit('b',2)]);
 const reopened=new OfflineStore(adapter);await reopened.init();
 assert.equal(reopened.snapshot().records.a.value,1);assert.equal(reopened.snapshot().records.b.value,2);
 assert.equal(reopened.snapshot().pending.length,2);
});
test('stale tab same-record edit preserves both intentions for review',async()=>{
 const adapter=memoryAdapter(),a=new OfflineStore(adapter),b=new OfflineStore(adapter);
 await a.init();await a.edit('x',0);await b.init();
 await a.edit('x',1);await b.edit('x',2);
 const c=b.snapshot().conflicts[0];assert.equal(c.local.value,2);assert.equal(c.remote.value,1);assert.equal(c.base.value,0);
 await b.ingest({});assert.equal(b.snapshot().conflicts.length,1);
});
test('retention includes exactly 30 days and retains ordinary history records',async()=>{
 let time=10000000000;const store=new OfflineStore(memoryAdapter(),()=>time);await store.init();
 await store.edit('x',1);time+=safety.RETENTION_MS;
 assert.equal(store.recoverableHistory().length,1);time++;
 assert.equal(store.recoverableHistory().length,0);assert.equal(store.snapshot().records.x.value,1);
});

test('restore Undo preserves unrelated records created after restore',async()=>{
 const store=new OfflineStore(memoryAdapter());await store.init();await store.edit('x',1);
 await store.restore(safety.backup({x:safety.record('x',2)}),{confirmed:true});
 await store.edit('unrelated',7);await store.undoRestore(0,{confirmed:true});
 assert.equal(store.snapshot().records.x.value,1);assert.equal(store.snapshot().records.unrelated.value,7);
});
test('restore Undo refuses to overwrite later edits of affected records',async()=>{
 const store=new OfflineStore(memoryAdapter());await store.init();await store.edit('x',1);
 await store.restore(safety.backup({x:safety.record('x',2)}),{confirmed:true});await store.edit('x',3);
 await assert.rejects(store.undoRestore(0,{confirmed:true}),/changed after/);assert.equal(store.snapshot().records.x.value,3);
});
test('stale-tab restore cannot overwrite another tab edit',async()=>{
 const adapter=memoryAdapter(),a=new OfflineStore(adapter),b=new OfflineStore(adapter);await a.init();await b.init();
 await a.edit('x',1);
 await assert.rejects(b.restore(safety.backup({}),{confirmed:true}),/stale/);
 assert.equal((await adapter.read()).records.x.value,1);
});
test('stale conflict choice cannot select a newer unreviewed version',async()=>{
 const adapter=memoryAdapter(),a=new OfflineStore(adapter);await a.init();await a.ingest({x:safety.record('x',1)});await a.edit('x',2);await a.ingest({x:safety.record('x',3)});
 const b=new OfflineStore(adapter);await b.init();await b.ingest({x:safety.record('x',4)});
 await assert.rejects(a.resolve({x:'remote'}),/Conflict changed/);
 assert.equal((await adapter.read()).conflicts[0].remote.value,4);
});
test('restore requested during an in-flight edit cannot overwrite an unreviewed queued change',async()=>{
 const adapter=memoryAdapter(),store=new OfflineStore(adapter);await store.init();await store.edit('x',1);
 const write=adapter.compareAndSwap;let unblock,started;
 const blocked=new Promise(resolve=>{started=resolve}),gate=new Promise(resolve=>{unblock=resolve});
 adapter.compareAndSwap=async(...args)=>{if(args[1].records.x?.value===2){started();await gate}return write(...args)};
 const edit=store.edit('x',2);await blocked;const restoration=store.restore(safety.backup({x:safety.record('x',1)}),{confirmed:true});unblock();await edit;
 await assert.rejects(restoration,/stale/);assert.equal(store.snapshot().records.x.value,2);
});
test('explicitly reviewed conflict snapshot cannot resolve a changed comparison',async()=>{
 const one=new OfflineStore(memoryAdapter());await one.init();await one.ingest({x:safety.record('x',1)});await one.edit('x',2);await one.ingest({x:safety.record('x',3)});const reviewed=one.snapshot().conflicts;await one.ingest({x:safety.record('x',4)});
 await assert.rejects(one.resolve({x:'remote'},{expectedConflicts:reviewed}),/Conflict changed/);assert.equal(one.snapshot().conflicts[0].remote.value,4);
});
