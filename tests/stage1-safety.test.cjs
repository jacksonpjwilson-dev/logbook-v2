/* Synthetic-only tests: node --test tests/stage1-safety.test.cjs */
const test=require('node:test'),assert=require('node:assert/strict');
const s=require('../preview-widget/safety-core.js');
const r=(id,v)=>s.record(id,v);
test('compatible concurrent edits merge independently',()=>{
 const b={a:r('a',1),b:r('b',1)};
 const l={...b,a:r('a',2)},c={...b,b:r('b',3)};
 const x=s.threeWay(b,l,c);assert.equal(x.blocked,false);
 assert.deepEqual(x.merged,{a:l.a,b:c.b});
});
test('same-record divergent updates require review',()=>{
 const b={a:r('a',1)},l={a:r('a',2)},c={a:r('a',3)};
 const x=s.threeWay(b,l,c);assert.equal(x.conflicts.length,1);
 assert.deepEqual(x.merged.a,b.a);assert.equal(s.resolve(x,{}).blocked,true);
 assert.deepEqual(s.resolve(x,{a:'remote'}).merged.a,c.a);
});
test('delete versus update never silently wins',()=>{
 const b={a:r('a',1)},l={a:s.record('a',null,2,true)},c={a:r('a',2)};
 assert.equal(s.threeWay(b,l,c).conflicts[0].kind,'delete-edit');
});
test('matching simultaneous changes do not conflict',()=>{
 const b={a:r('a',1)},l={a:r('a',2)};
 assert.equal(s.threeWay(b,l,s.clone(l)).conflicts.length,0);
});
test('no base item handles inserts and conflicts',()=>{
 assert.equal(s.threeWay({}, {a:r('a',1)},{}).blocked,false);
 assert.equal(s.threeWay({}, {a:r('a',1)},{a:r('a',2)}).blocked,true);
});
test('backup restore requires confirmation, creates rollback',()=>{
 const before={a:r('a',1)},incoming=s.backup({b:r('b',3)});
 const plan=s.restorePlan(before,incoming);
 assert.throws(()=>s.commitRestore(plan,false),/confirmation/);
 const out=s.commitRestore(plan,true);assert.deepEqual(out.records,incoming.records);
 assert.deepEqual(out.rollback.records,before);
});
test('corrupted backup is rejected',()=>{
 assert.throws(()=>s.validateSnapshot({schema:2,records:{a:{id:'WRONG',version:1,deleted:false}}}),/Invalid backup record/);
});
test('version history retention & rollback',()=>{
 let h=s.historyAppend([],'a',r('a',1),r('a',2),10000000000);
 h=s.historyAppend(h,'a',r('a',2),r('a',3),10000000001);
 assert.equal(s.historyAt(h,10000000001).length,2);
 assert.deepEqual(s.historyRestore(h,'a',0,10000000001),r('a',1));
 assert.equal(s.historyAt(h,10000000000+s.RETENTION_MS+2).length,0);
});
test('migration preserves original, blocks ambiguous same-name exercise',()=>{
 const legacy={version:1,lib:[{id:'x1',name:'Curl'},{id:'x2',name:'Curl'}],workouts:[{id:'w1',exercises:[{name:'Curl',sets:[{w:20,r:10,done:false}]}]}],food:{'2026-10-01':[]}};
 const p=s.migrateLegacy(legacy);
 assert.equal(p.ready,false);assert.equal(p.ambiguous[0].type,'exercise-identity');
 assert.deepEqual(p.original,legacy);
 assert.throws(()=>s.migrationCommit(p,false,true),/review/);
 assert.throws(()=>s.migrationCommit(p,true,false),/backup/);
 assert.equal(s.migrationCommit(p,true,true).schema,2);
 assert.deepEqual(p.snapshot.records['workouts:w1'].value.legacy.exercises[0].sets[0],{w:20,r:10,done:false});
});
test('duplicate legacy IDs cannot replace data silently',()=>{
 const p=s.migrateLegacy({foods:[{id:'f1',name:'A'},{id:'f1',name:'B'}]});
 assert.equal(p.ready,false);
 assert.equal(p.snapshot.records['foods:f1'].value.legacy.name,'A');
 assert.equal(p.ambiguous[0].type,'record-id');
});

test('migration retains unknown fields and explicitly supplied water/layout data',()=>{
 const legacy={version:1,customFutureSetting:{enabled:true},workouts:[]};
 const aux={'lb2w:water':{'2026-10-25':500},'lb2w:pages6':[{name:'Daily'}],'lb2w:theme':'premium-glass'};
 const plan=s.migrateLegacy(legacy,{auxiliary:aux});
 assert.deepEqual(plan.snapshot.records['field:customFutureSetting'].value.legacy,{enabled:true});
 assert.equal(plan.snapshot.records['aux:lb2w:water'].value.legacy['2026-10-25'],500);
 assert.equal(plan.snapshot.records['aux:lb2w:pages6'].value.legacy[0].name,'Daily');
 assert.equal(plan.snapshot.records['aux:lb2w:theme'].value.legacy,'premium-glass');
 assert.deepEqual(plan.original,legacy);
});
test('migration excludes authentication and sync metadata sidecars',()=>{
 const plan=s.migrateLegacy({version:1},{auxiliary:{'lb2w:sync':{uid:'fake'},'lb2w:signedin':'1','lb2w:session':'owner'}});
 assert.ok(!Object.keys(plan.snapshot.records).some(k=>k.includes('sync')||k.includes('signedin')||k.includes('session')));
});
