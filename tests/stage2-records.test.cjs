const test=require('node:test'),assert=require('node:assert/strict'),T=require('../stage2/training-core.js'),R=require('../stage2/training-records.js'),{OfflineStore,memoryAdapter}=require('../preview-widget/stage1-store.js');
function seed(){let state=T.putExercise(T.empty(),{id:'e1',name:'Bench',group:'Chest'});state=T.saveTemplate(state,{id:'t1',name:'Fictional workout',exercises:[{id:'p1',exerciseId:'e1',sets:[{id:'s1',weightKg:50,reps:8}]}]});return T.setRotation(state,['t1'])}
test('Training entity projection roundtrips active snapshots and independently persisted rotation events',()=>{
 let state=T.start(seed(),'t1',{now:1000,localDate:'2026-10-01'}),entry=state.active.exercises[0];state=T.toggleComplete(state,entry.id,entry.sets[0].id,2000).state;state=T.finish(state,{now:3000}).state;
 const records=R.project(state);assert.deepEqual(R.materialize(records),state);assert.equal(Object.keys(records).filter(id=>id.startsWith('training.event:')).length,1);
});
test('independent Training entity edits merge across stale tabs',async()=>{
 const adapter=memoryAdapter(),a=new OfflineStore(adapter),b=new OfflineStore(adapter);await a.init();await a.applyRecords({},R.project(seed()));await b.init();const base=a.snapshot().records;
 const left=T.putExercise(R.materialize(base),{id:'e1',name:'Renamed',group:'Chest'}),right=T.saveTemplate(R.materialize(base),{...seed().templates.t1,name:'Changed template'});
 await a.applyRecords(base,R.project(left,base));await b.applyRecords(base,R.project(right,base));const result=R.materialize((await adapter.read()).records);assert.equal(result.catalog.e1.name,'Renamed');assert.equal(result.templates.t1.name,'Changed template');assert.equal(b.snapshot().conflicts.length,0);
});
test('corrected workout versions are recoverable through the durable store',async()=>{
 let state=T.start(seed(),'t1',{now:1000,localDate:'2026-10-01'}),entry=state.active.exercises[0];state=T.toggleComplete(state,entry.id,entry.sets[0].id,2000).state;const finished=T.finish(state,{now:3000});
 const adapter=memoryAdapter(),store=new OfflineStore(adapter);await store.init();await store.applyRecords({},R.project(finished.state));const base=store.snapshot().records;
 const corrected=T.correct(finished.state,finished.sessionId,{notes:'Explicit correction'},{confirmed:true}).state;await store.applyRecords(base,R.project(corrected,base));
 const entryHistory=store.recoverableHistory().find(event=>event.id==='training.workout:'+finished.sessionId&&event.previous);assert.equal(entryHistory.previous.value.notes,'');assert.equal(entryHistory.next.value.notes,'Explicit correction');
 const reopened=new OfflineStore(adapter);await reopened.init();assert.equal(R.materialize(reopened.snapshot().records).workouts[finished.sessionId].version,2);
});
test('unknown literal settings fields survive projection without modifying prototypes',()=>{
 const state=seed();Object.defineProperty(state,'__proto__',{value:{futureSetting:true},enumerable:true});const restored=R.materialize(R.project(state));assert.equal(Object.hasOwn(restored,'__proto__'),true);assert.deepEqual(restored.__proto__,{futureSetting:true});assert.equal(Object.getPrototypeOf(restored),Object.prototype);
});
