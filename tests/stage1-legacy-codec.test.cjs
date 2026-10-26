const test=require('node:test'),assert=require('node:assert/strict');
const codec=require('../preview-widget/stage1-legacy-codec.js'),s=require('../preview-widget/safety-core.js');
const {OfflineStore,memoryAdapter}=require('../preview-widget/stage1-store.js');
const source={version:1,lib:[{id:'x1',name:'Bench'}],templates:[{name:'No legacy ID',exercises:['Bench']}],active:{id:'active-1',exercises:[{name:'Bench',sets:[{w:'',r:8,done:false}]}]},workouts:[{id:'w1',date:'2026-10-01',exercises:[]}],food:{'2026-10-01':[{fid:'f1',q:2}]},weight:[{date:'2026-10-01',kg:70}],sleep:[],unknown:{nested:[null,false,0,'']}};
test('legacy codec roundtrips actual-shaped objects, unknown fields and missing IDs without guessing',()=>{
 const result=codec.project(source);assert.deepEqual(codec.materialize(result.records),source);assert.equal(result.warnings[0].field,'templates');
});
test('duplicate IDs remain lossless opaque data and are flagged rather than guessed',()=>{
 const data={lib:[{id:'same',name:'A'},{id:'same',name:'B'}]};const result=codec.project(data);assert.deepEqual(codec.materialize(result.records),data);assert.equal(result.warnings.length,1);
});
test('stable identities survive renames, preserve array order, and tombstone deletions',()=>{
 const initial=codec.project({lib:[{id:'a',name:'Old'},{id:'b',name:'Other'}]});
 const update=codec.project({lib:[{id:'b',name:'Other'},{id:'a',name:'New'}]},initial.records);
 const oldId=Object.keys(initial.records).find(id=>initial.records[id].value?.sourceId==='a');assert.equal(update.records[oldId].value.legacy.name,'New');
 assert.deepEqual(codec.materialize(update.records).lib.map(x=>x.id),['b','a']);
 const removed=codec.project({lib:[{id:'b',name:'Other'}]},update.records);assert.equal(removed.records[oldId].deleted,true);assert.equal(codec.materialize(removed.records).lib.length,1);
});
test('atomic legacy batch retains independent field edits from stale tabs',async()=>{
 const adapter=memoryAdapter(),a=new OfflineStore(adapter),b=new OfflineStore(adapter);await a.init();
 await a.applyRecords({},codec.project(source).records);await b.init();const base=a.snapshot().records;
 const one=s.clone(source),two=s.clone(source);one.profile={name:'fictional'};two.active.notes='fictional note';
 await a.applyRecords(base,codec.project(one,base).records);await b.applyRecords(base,codec.project(two,base).records);
 const restored=codec.materialize((await adapter.read()).records);assert.equal(restored.profile.name,'fictional');assert.equal(restored.active.notes,'fictional note');
});
test('atomic legacy batch keeps both competing edits for explicit review',async()=>{
 const adapter=memoryAdapter(),a=new OfflineStore(adapter),b=new OfflineStore(adapter);await a.init();await a.applyRecords({},codec.project(source).records);await b.init();const base=a.snapshot().records;
 const one=s.clone(source),two=s.clone(source);one.active.notes='one';two.active.notes='two';
 await a.applyRecords(base,codec.project(one,base).records);await b.applyRecords(base,codec.project(two,base).records);
 const c=b.snapshot().conflicts[0];assert.equal(c.local.value.legacy.notes,'two');assert.equal(c.remote.value.legacy.notes,'one');
});
test('every field in the actual legacy seed roundtrips through the development bridge',()=>{
 const fs=require('node:fs'),vm=require('node:vm'),path=require('node:path'),memory=new Map();
 const context={window:{},localStorage:{getItem:key=>memory.get(key)||null,setItem:(key,value)=>memory.set(key,value)},Date};vm.createContext(context);
 for(const name of ['lib.js','data.js'])vm.runInContext(fs.readFileSync(path.join(__dirname,'../preview-widget',name),'utf8'),context);
 const original=s.clone(context.window.DB.init()),plan=codec.project(original);
 assert.deepEqual(codec.materialize(plan.records),original);assert.equal(original.lib.length>100,true);
});
test('merge restore keeps new legacy array/map entities visible through their indexes',async()=>{
 const original={workouts:[{id:'a',date:'2026-10-01'}],food:{'2026-10-01':[{fid:'f1'}]}},before=codec.project(original).records;
 const current={workouts:[...original.workouts,{id:'b',date:'2026-10-02'}],food:{...original.food,'2026-10-02':[{fid:'f2'}]}},records=codec.project(current,before).records;
 const plan=s.restorePlan(records,s.backup(before),{mode:'merge'}),result=s.commitRestore(plan,true);assert.deepEqual(codec.materialize(result.records),current);
});
