const test=require('node:test'),assert=require('node:assert/strict'),T=require('../stage2/training-core.js');
let sequence=0;const newId=()=>`synthetic-${++sequence}`,copy=value=>JSON.parse(JSON.stringify(value));
function base(){let state=T.empty();for(const [id,name,group] of [['e1','Bench','Chest'],['e2','Row','Back'],['e3','Squat','Legs']])state=T.putExercise(state,{id,name,group,equip:'Barbell'});for(let n=1;n<=3;n++)state=T.saveTemplate(state,{id:'t'+n,name:'Workout '+n,exercises:[{id:'p'+n,exerciseId:'e'+n,sets:[{id:'s'+n+'1',reps:8},{id:'s'+n+'2',reps:8}]}]});return T.setRotation(state,['t1','t2','t3'])}
const start=(state=base(),template='t1',now=1000,localDate='2026-10-01')=>T.start(state,template,{now,localDate,newId});
function done(state,index=0,weight=50,reps=8,now=2000,entryIndex=0){const entry=state.active.exercises[entryIndex],set=entry.sets[index];state=T.editSet(state,entry.id,set.id,{weightKg:weight,reps});return T.toggleComplete(state,entry.id,set.id,now)}
function completed(state,template='t1',weight=50,day='2026-10-01',now=1000){state=start(state,template,now,day);state=done(state,0,weight,8,now+100).state;state=done(state,1,weight,8,now+200).state;return T.finish(state,{now:now+1000})}
test('T01 rest and discard never advance, only explicit Finish & Save advances',()=>{
 let state=start();const rotation=copy(state.rotation);assert.deepEqual(T.restDay(state).rotation,rotation);assert.deepEqual(T.discard(state).rotation,rotation);assert.equal(Object.keys(T.discard(state).workouts).length,0);
 state=done(state).state;const result=T.finish(state,{now:4000,confirmedIncomplete:true});assert.equal(result.state.rotation.next,1);assert.equal(Object.keys(result.state.workouts).length,1);
});
test('T01 one active session and maximum eight rotation positions',()=>{const state=start();assert.throws(()=>start(state),/existing session/);assert.throws(()=>T.setRotation(base(),Array.from({length:9},(_,i)=>'t'+i)),/eight/)});
test('T02 completing later position records skipped positions without fabricated workouts',()=>{
 let state=start(base(),'t3');state=done(state).state;const result=T.finish(state,{now:4000,confirmedIncomplete:true}),event=result.state.rotation.events[0];assert.deepEqual(event.skipped,[0,1]);assert.equal(result.state.rotation.next,0);assert.equal(Object.keys(result.state.workouts).length,1);assert.equal(event.templateId,'t3');
});
test('T03 historical correction never changes rotation; separate adjustment requires explicit confirmation',()=>{
 const finished=completed(base()),before=copy(finished.state.rotation),id=finished.sessionId;
 const corrected=T.correct(finished.state,id,{date:'2026-09-20'},{confirmed:true});assert.deepEqual(corrected.state.rotation,before);assert.equal(corrected.canUpdateRotation,true);
 assert.throws(()=>T.updateRotation(corrected.state,2,{now:5000,localDate:'2026-10-01'}),/confirmation/);
 const adjusted=T.updateRotation(corrected.state,2,{confirmed:true,now:5000,localDate:'2026-10-01'});assert.equal(adjusted.rotation.next,2);assert.equal(adjusted.rotation.events.at(-1).kind,'manual-adjustment');
});
test('T04/T05 template versions and exercise renames cannot mutate active or historical snapshots',()=>{
 let state=start(),snapshot=copy(state.active.templateSnapshot);state=T.putExercise(state,{id:'e1',name:'Renamed Bench',group:'Chest'});state=T.saveTemplate(state,{...state.templates.t1,name:'Changed template'});
 assert.deepEqual(state.active.templateSnapshot,snapshot);assert.equal(state.active.exercises[0].name,'Bench');assert.equal(state.templates.t1.version,2);assert.equal(state.templates.t1.versions[0].name,'Workout 1');
 state=done(state).state;const result=T.finish(state,{now:4000,confirmedIncomplete:true});assert.deepEqual(result.state.workouts[result.sessionId].templateSnapshot,snapshot);
});
test('T07 prefills use real stable-ID history and never mark sets done',()=>{
 let state=completed(base(),'t1',70).state;state=T.putExercise(state,{id:'e1',name:'Renamed Bench',group:'Chest'});state=start(state,'t1',10000,'2026-10-02');
 assert.equal(state.active.exercises[0].sets[0].weightKg,70);assert.equal(state.active.exercises[0].sets.every(set=>!set.done),true);assert.equal(state.active.exercises[0].sets[0].previous.weightKg,70);
});
test('T07/T08 invalid input cannot complete a set; session additions leave template intact',()=>{
 let state=start(),entry=state.active.exercises[0],set=entry.sets[0];assert.throws(()=>T.toggleComplete(state,entry.id,set.id,2000),/valid weight/);
 const snapshot=copy(state.templates.t1);state=T.addExercise(state,'e2',{newId});assert.equal(state.active.exercises.length,2);assert.deepEqual(state.templates.t1,snapshot);
});
test('T09 substitution keeps original performed sets and unfinished plan with separate attribution',()=>{
 let state=start(),template=copy(state.templates.t1);state=done(state,0,50,8).state;const originalId=state.active.exercises[0].id;state=T.substitute(state,originalId,'e2',{newId});
 const [original,replacement]=state.active.exercises;assert.equal(original.sets[0].done,true);assert.equal(original.sets[1].done,false);assert.equal(original.sets[1].omittedBySubstitution,true);assert.equal(replacement.replaces,original.id);assert.equal(original.supersededBy,replacement.id);assert.equal(replacement.sets[0].done,false);
 state=done(state,0,30,8,3000,1).state;assert.deepEqual(T.stats(state.active).muscleVolume,{Chest:400,Back:240});assert.equal(T.stats(state.active).volumeKg,640);assert.deepEqual(state.templates.t1,template);assert.equal(T.completion(state.active).incomplete,0);
});
test('T10 superset starts rest only when all existing sets in the round complete',()=>{
 let state=start();state=T.addExercise(state,'e2',{newId});state=T.groupSession(state,state.active.exercises.map(e=>e.id),'group-1');state=done(state,0,50,8,2000,0).state;assert.equal(state.active.rest,null);state=done(state,0,30,8,3000,1).state;assert.equal(T.restRemaining(state.active,3000),90000);
 state=T.changeRest(state,'skip',3000);state=done(state,1,50,8,4000,0).state;assert.equal(state.active.rest,null);
});
test('T11 rest adjustment and base duration are session-only and timestamp based',()=>{
 let state=start(),before=state.restSeconds;state=T.baseRest(state,120);state=done(state).state;assert.equal(T.restRemaining(state.active,12000),110000);state=T.changeRest(state,15,12000);assert.equal(T.restRemaining(state.active,12000),125000);state=T.changeRest(state,-15,12000);assert.equal(state.restSeconds,before);assert.equal(state.active.restSeconds,120);
});
test('T12/T13 backgrounding does not auto-pause; manual pause freezes rest and persists active/elapsed time',()=>{
 let state=done(start()).state;state=T.pause(state,12000);state=copy(state);assert.equal(T.restRemaining(state.active,112000),80000);assert.deepEqual(T.durations(state.active,112000),{elapsedMs:111000,pausedMs:100000,activeMs:11000});
 state=T.resume(state,112000);assert.equal(T.restRemaining(state.active,122000),70000);assert.equal(T.durations(state.active,122000).activeMs,21000);assert.equal(T.durations(start().active,61000).activeMs,60000);
});
test('T13 manual rest pause survives workout pause/resume and clock reversal stays nonnegative',()=>{
 let state=done(start()).state;state=T.changeRest(state,'pause',12000);state=T.pause(state,13000);state=T.resume(state,100000);assert.equal(T.restRemaining(state.active,200000),80000);state=T.changeRest(state,'resume',200000);assert.equal(T.restRemaining(state.active,210000),70000);state=T.pause(state,220000);state=T.resume(state,1000);assert.ok(T.durations(state.active,0).activeMs>=0);
});
test('T14 incomplete confirmation retains every planned set while analytics count only completed working sets',()=>{
 let state=done(start()).state;assert.throws(()=>T.finish(state,{now:4000}),error=>error.code==='INCOMPLETE'&&error.counts.incomplete===1);
 const result=T.finish(state,{now:4000,confirmedIncomplete:true}),session=result.state.workouts[result.sessionId];assert.equal(session.exercises[0].sets.length,2);assert.equal(session.exercises[0].sets[1].done,false);assert.equal(result.summary.sets,1);assert.equal(result.summary.volumeKg,400);
});
test('T14 warmups are preserved but excluded from volume and PRs',()=>{
 let state=start(),entry=state.active.exercises[0];state=T.editSet(state,entry.id,entry.sets[0].id,{weightKg:20,reps:10,kind:'warmup'});const result=T.toggleComplete(state,entry.id,entry.sets[0].id,2000);assert.equal(result.celebration,null);assert.equal(T.stats(result.state.active).sets,0);assert.equal(T.completion(result.state.active).done,1);
});
test('T15 comparison requires equivalent snapshot/version/conditions and a genuinely earlier session',()=>{
 let first=completed(base()),state=start(first.state,'t1',10000,'2026-10-02');state=done(state,0,60,8,11000).state;state=done(state,1,60,8,12000).state;const second=T.finish(state,{now:14000});assert.equal(second.summary.comparison.sessionId,first.sessionId);assert.equal(second.summary.comparison.volumeDeltaKg,160);
 state=T.saveTemplate(second.state,{...second.state.templates.t1,name:'New version'});const third=completed(state,'t1',50,'2026-10-03',20000);assert.equal(third.summary.comparison,null);assert.equal(T.summary(first.state.workouts[first.sessionId],second.state.workouts).comparison,null);
});
test('T16 correcting sets recalculates downstream PRs while preserving identity and original snapshot',()=>{
 const first=completed(base(),'t1',100),second=completed(first.state,'t1',90,'2026-10-02',10000),old=second.state.workouts[first.sessionId],snapshot=copy(old.templateSnapshot),exercises=copy(old.exercises);for(const entry of exercises)for(const set of entry.sets)set.weightKg=80;
 assert.throws(()=>T.correct(second.state,first.sessionId,{exercises}),/confirmation/);
 const result=T.correct(second.state,first.sessionId,{exercises},{confirmed:true});assert.equal(result.state.workouts[first.sessionId].id,first.sessionId);assert.equal(result.state.workouts[first.sessionId].version,2);assert.deepEqual(result.state.workouts[first.sessionId].templateSnapshot,snapshot);assert.ok(result.state.workouts[second.sessionId].achievements.some(record=>record.categories.includes('Heaviest weight')));assert.deepEqual(result.state.rotation,second.state.rotation);
});
test('T17 one rep equals actual weight, 1–15 Epley only; 16+ still counts for volume and actual/rep PR',()=>{
 const set=(reps)=>({weightKg:100,reps,done:true,kind:'working'});assert.equal(T.estimate(set(1)),100);assert.equal(T.estimate(set(15)),150);assert.equal(T.estimate(set(16)),null);
 const result=done(start(),0,100,16);assert.deepEqual(result.celebration.categories,['Heaviest weight','16-rep record']);assert.equal(T.stats(result.state.active).volumeKg,1600);
});
test('T18 one consolidated celebration per qualifying set, attributed by permanent exercise ID',()=>{
 const result=done(start(),0,100,8);assert.equal(result.celebration.categories.length,3);assert.equal(result.celebration.setId,result.state.active.exercises[0].sets[0].id);assert.equal(result.celebration.formula,T.FORMULA);
 const entry=result.state.active.exercises[0],unmarked=T.toggleComplete(result.state,entry.id,entry.sets[0].id,3000);assert.equal(unmarked.celebration,null);assert.equal(unmarked.state.active.setAchievements[entry.sets[0].id],undefined);
});
test('T19 history has real observations only and excludes invented estimated zeros',()=>{
 assert.deepEqual(T.exerciseHistory(base(),'e1'),[]);let state=start();state=done(state,0,100,16).state;const result=T.finish(state,{now:4000,confirmedIncomplete:true}),history=T.exerciseHistory(result.state,'e1');assert.equal(history.length,1);assert.equal(history[0].estimated1RM,null);assert.equal(history[0].volumeKg,1600);assert.deepEqual(T.exerciseHistory(result.state,'e2'),[]);
});
test('local dates are explicit and stable independent of elapsed timestamp/day boundaries',()=>{let state=start(base(),'t1',Date.UTC(2026,9,2,1),'2026-10-01');state=done(state,0,50,8,Date.UTC(2026,9,3)).state;const result=T.finish(state,{now:Date.UTC(2026,9,4),confirmedIncomplete:true});assert.equal(result.state.workouts[result.sessionId].date,'2026-10-01');assert.throws(()=>start(base(),'t1',1000,'2026-02-30'),/Valid local date/)});
test('regrouping supersets clears orphaned single-exercise groups',()=>{
 let state=start();state=T.addExercise(state,'e2',{newId});state=T.addExercise(state,'e3',{newId});const ids=state.active.exercises.map(e=>e.id);state=T.groupSession(state,ids,'old-group');state=T.groupSession(state,ids.slice(0,2),'new-group');assert.equal(state.active.exercises[2].supersetId,null);assert.equal(state.active.exercises[0].supersetId,'new-group');
});
test('warm-up rows never inherit a prior working-set weight',()=>{
 let state=completed(base(),'t1',100).state;const template=copy(state.templates.t1);template.exercises[0].sets[0].kind='warmup';template.exercises[0].sets[0].weightKg=20;state=T.saveTemplate(state,template);state=start(state,'t1',10000,'2026-10-02');assert.equal(state.active.exercises[0].sets[0].weightKg,20);assert.equal(state.active.exercises[0].sets[0].previous,null);assert.equal(state.active.exercises[0].sets[1].weightKg,100);
});
