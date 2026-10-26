/* Pure Training domain. No storage, network, accounts, or production imports. */
(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;else root.LogbookTraining=api})(globalThis,function(){
'use strict';
const clone=value=>JSON.parse(JSON.stringify(value)),assert=(ok,message)=>{if(!ok)throw Error(message)};
const validId=id=>typeof id==='string'&&/^[A-Za-z0-9_:@.-]{1,120}$/.test(id)&&!['__proto__','constructor','prototype'].includes(id);
const uid=()=>crypto.randomUUID(),FORMULA='epley-1-to-15-v1';
function date(value){assert(typeof value==='string'&&/^\d{4}-\d{2}-\d{2}$/.test(value)&&new Date(value+'T12:00:00Z').toISOString().slice(0,10)===value,'Valid local date required');return value}
function time(value){assert(Number.isFinite(value)&&value>=0,'Valid timestamp required');return value}
const stamp=(session,now)=>Math.max(time(now),session.lastEventAt||session.startedAt);
const validSet=set=>!!set&&typeof set.weightKg==='number'&&Number.isFinite(set.weightKg)&&set.weightKg>=0&&Number.isInteger(set.reps)&&set.reps>0;
const working=set=>set.done===true&&set.kind==='working'&&validSet(set);
function estimate(set){if(!working(set)||set.reps>15)return null;return set.reps===1?set.weightKg:set.weightKg*(1+set.reps/30)}
function empty(){return {schema:1,catalog:{},templates:{},rotation:{templateIds:[],next:0,events:[]},active:null,workouts:{},favorites:[],restSeconds:90}}
function snapshotTemplate(template){const {versions,...body}=template;return clone(body)}
function putExercise(state,exercise){const next=clone(state);assert(exercise&&validId(exercise.id)&&exercise.name,'Exercise identity and name required');const before=next.catalog[exercise.id];next.catalog[exercise.id]={...(before?clone(before):{}),...clone(exercise),version:(before?.version||0)+1};return next}
function seedBuiltins(state,library,registry){
 const aliases=new Map(),seen=new Set();for(const definition of registry){assert(validId(definition.id)&&Array.isArray(definition.names),'Invalid built-in identity registry');for(const name of definition.names){assert(typeof name==='string'&&!aliases.has(name),'Duplicate built-in alias');aliases.set(name,definition.id)}}
 let next=clone(state);for(const exercise of library){const id=aliases.get(exercise.name);assert(id,'Built-in identity needs an explicit registry entry');assert(!seen.has(id),'Built-in identity collision');seen.add(id);if(!Object.hasOwn(next.catalog,id))next=putExercise(next,{...clone(exercise),id,source:'legacy-built-in-seed'})}return next;
}
function saveTemplate(state,input){
 const next=clone(state),previous=next.templates[input.id];assert(validId(input.id)&&input.name?.trim(),'Template identity and name required');assert(Array.isArray(input.exercises),'Template plan required');
 const exercises=input.exercises.map(entry=>{
  const exercise=next.catalog[entry.exerciseId];assert(exercise,'Unknown stable exercise ID');
  assert(Array.isArray(entry.sets)&&entry.sets.length,'At least one prescribed set required');
  return {...clone(entry),name:exercise.name,primaryMuscle:exercise.group||'Other',id:entry.id||uid(),sets:entry.sets.map(set=>({...clone(set),id:set.id||uid(),kind:set.kind||'working',weightKg:set.weightKg??null,reps:set.reps??8,done:false}))};
 });
 assert(new Set(exercises.map(entry=>entry.id)).size===exercises.length,'Template exercise entries require distinct identities');for(const entry of exercises){assert(validId(entry.id),'Invalid plan identity');for(const set of entry.sets)assert(validId(set.id)&&['working','warmup'].includes(set.kind),'Invalid prescribed set')}
 const groups=new Set(exercises.map(entry=>entry.supersetId).filter(Boolean));for(const group of groups)assert(exercises.filter(entry=>entry.supersetId===group).length>=2,'Superset requires two or more exercises');
 const versions=previous?[...(previous.versions||[]),snapshotTemplate(previous)]:[];
 next.templates[input.id]={...(previous?snapshotTemplate(previous):{}),...clone(input),id:input.id,name:input.name.trim(),version:(previous?.version||0)+1,exercises,versions};return next;
}
function setRotation(state,ids){assert(Array.isArray(ids)&&ids.length<=8&&new Set(ids).size===ids.length,'Rotation supports up to eight unique workouts');const next=clone(state);for(const id of ids)assert(next.templates[id],'Unknown rotation template');const suggested=next.rotation.templateIds[next.rotation.next];next.rotation.templateIds=clone(ids);next.rotation.next=Math.max(0,ids.indexOf(suggested));return next}
function previousSets(state,exerciseId,sourcePlanId,equipment=state.catalog[exerciseId]?.equip||''){
 const sessions=Object.values(state.workouts).filter(w=>w.finishedAt!=null).sort((a,b)=>b.date.localeCompare(a.date)||b.finishedAt-a.finishedAt);
 for(const session of sessions){const matches=session.exercises.filter(e=>e.exerciseId===exerciseId&&(e.equipment||'')===equipment),entry=matches.find(e=>e.sourcePlanId===sourcePlanId)||matches[0];if(entry){const sets=entry.sets.filter(working);if(sets.length)return clone(sets)}}return [];
}
function newEntry(state,planned,newId){
 const exercise=state.catalog[planned.exerciseId];assert(exercise,'Unknown exercise');const previous=previousSets(state,exercise.id,planned.id);let workingIndex=0;
 return {id:newId(),sourcePlanId:planned.id||null,exerciseId:exercise.id,exerciseVersion:exercise.version,name:exercise.name,primaryMuscle:exercise.group||'Other',equipment:exercise.equip||'',supersetId:planned.supersetId||null,notes:'',
  sets:planned.sets.map(set=>{const prior=set.kind==='warmup'?null:previous[workingIndex++];return {id:newId(),sourceSetId:set.id||null,kind:set.kind||'working',weightKg:prior?.weightKg??set.weightKg??null,reps:prior?.reps??set.reps??8,previous:prior?{weightKg:prior.weightKg,reps:prior.reps}:null,done:false}})};
}
function start(state,templateId,{now,localDate,newId=uid}={}){
 assert(!state.active,'Resume or discard the existing session first');const next=clone(state),template=next.templates[templateId];assert(template,'Unknown template');time(now);
 next.active={id:newId(),templateId,templateVersion:template.version,templateSnapshot:snapshotTemplate(template),name:template.name,date:date(localDate),startedAt:now,lastEventAt:now,pausedAt:null,pausedMs:0,pauses:[],rest:null,restSeconds:next.restSeconds||90,notes:'',exercises:template.exercises.map(entry=>newEntry(next,entry,newId)),setAchievements:{}};return next;
}
function durations(session,now){const at=stamp(session,now),elapsedMs=Math.max(0,(session.finishedAt??at)-session.startedAt),currentPause=session.pausedAt==null?0:Math.max(0,(session.finishedAt??at)-session.pausedAt);return {elapsedMs,pausedMs:session.pausedMs+currentPause,activeMs:Math.max(0,elapsedMs-session.pausedMs-currentPause)}}
function restRemaining(session,now){if(!session.rest)return 0;return Math.max(0,session.rest.pausedRemainingMs??session.rest.expiresAt-stamp(session,now))}
function startRest(session,now,origin){const ms=session.restSeconds*1000;session.rest={expiresAt:now+ms,pausedRemainingMs:session.pausedAt==null?null:ms,userPaused:false,origin}}
function pause(state,now){const next=clone(state),session=next.active;assert(session,'No active session');const at=stamp(session,now);assert(session.pausedAt==null,'Session already paused');if(session.rest)session.rest.pausedRemainingMs=restRemaining(session,at);session.pausedAt=at;session.lastEventAt=at;return next}
function resume(state,now){const next=clone(state),session=next.active;assert(session&&session.pausedAt!=null,'Session is not paused');const at=stamp(session,now);session.pausedMs+=at-session.pausedAt;session.pauses.push({from:session.pausedAt,to:at});session.pausedAt=null;if(session.rest&&!session.rest.userPaused){session.rest.expiresAt=at+session.rest.pausedRemainingMs;session.rest.pausedRemainingMs=null}session.lastEventAt=at;return next}
function changeRest(state,action,now){const next=clone(state),session=next.active;assert(session,'No active session');const at=stamp(session,now),remaining=restRemaining(session,at);if(action==='skip')session.rest=null;
 else if(typeof action==='number'){assert(Number.isFinite(action),'Invalid rest adjustment');const ms=Math.max(0,remaining+action*1000);if(!session.rest)startRest(session,at,null);session.rest.expiresAt=at+ms;session.rest.pausedRemainingMs=session.pausedAt!=null||session.rest.userPaused?ms:null}
 else {assert(session.rest,'No rest timer');if(action==='pause'){session.rest.pausedRemainingMs=remaining;session.rest.userPaused=true}else if(action==='resume'){session.rest.userPaused=false;if(session.pausedAt==null){session.rest.expiresAt=at+remaining;session.rest.pausedRemainingMs=null}}else throw Error('Unknown rest action')}
 session.lastEventAt=at;return next;
}
function baseRest(state,seconds){assert(Number.isFinite(seconds)&&seconds>=0&&seconds<=1800,'Rest must be 0–1800 seconds');const next=clone(state);assert(next.active,'No active session');next.active.restSeconds=seconds;return next}
function findSet(session,entryId,setId){const entry=session.exercises.find(item=>item.id===entryId),set=entry?.sets.find(item=>item.id===setId);assert(set,'Unknown session set');return {entry,set}}
function editSet(state,entryId,setId,patch){const next=clone(state);assert(next.active,'No active session');const {set}=findSet(next.active,entryId,setId);for(const field of ['weightKg','reps','kind'])if(field in patch)set[field]=patch[field];if(set.done&&!validSet(set))set.done=false;delete next.active.setAchievements[setId];return next}
function stats(session){let sets=0,volumeKg=0;const muscleVolume={};for(const entry of session.exercises)for(const set of entry.sets)if(working(set)){sets++;const volume=set.weightKg*set.reps;volumeKg+=volume;muscleVolume[entry.primaryMuscle]=(muscleVolume[entry.primaryMuscle]||0)+volume}return {sets,volumeKg,muscleVolume}}
function completion(session){let done=0,incomplete=0,omitted=0;for(const entry of session.exercises)for(const set of entry.sets){if(set.omittedBySubstitution&&!set.done)omitted++;else if(set.done&&validSet(set))done++;else incomplete++}return {done,incomplete,omitted}}
function bestSets(workouts,exerciseId,active,excludeSet){const values=[];for(const session of workouts)for(const entry of session.exercises)if(entry.exerciseId===exerciseId)values.push(...entry.sets.filter(working));if(active)for(const entry of active.exercises)if(entry.exerciseId===exerciseId)values.push(...entry.sets.filter(set=>set.id!==excludeSet&&working(set)));return values}
function achievements(set,prior){if(!working(set))return [];const categories=[];if(!prior.length||set.weightKg>Math.max(...prior.map(value=>value.weightKg)))categories.push('Heaviest weight');const matching=prior.filter(value=>value.reps===set.reps);if(!matching.length||set.weightKg>Math.max(...matching.map(value=>value.weightKg)))categories.push(set.reps+'-rep record');const value=estimate(set),estimates=prior.map(estimate).filter(value=>value!=null);if(value!=null&&(!estimates.length||value>Math.max(...estimates)))categories.push('Estimated 1RM');return categories}
function toggleComplete(state,entryId,setId,now){
 const next=clone(state),session=next.active;assert(session,'No active session');const {entry,set}=findSet(session,entryId,setId),at=stamp(session,now);assert(!set.omittedBySubstitution,'Original plan is retained under its substitution link');
 if(set.done){set.done=false;delete session.setAchievements[set.id];session.rest=null;session.lastEventAt=at;return {state:next,celebration:null}}
 assert(validSet(set),'Enter a valid weight and positive whole-number reps first');const prior=bestSets(Object.values(next.workouts),entry.exerciseId,session,set.id);set.done=true;
 const categories=achievements(set,prior);session.setAchievements[set.id]={categories,formula:FORMULA,estimated1RM:estimate(set)};
 const round=entry.sets.indexOf(set),members=entry.supersetId?session.exercises.filter(e=>e.supersetId===entry.supersetId&&!e.supersededBy):[entry];
 if(members.every(e=>!e.sets[round]||e.sets[round].done&&validSet(e.sets[round])))startRest(session,at,{group:entry.supersetId,round});session.lastEventAt=at;
 return {state:next,celebration:categories.length?{setId:set.id,categories,formula:FORMULA}:null};
}
function addExercise(state,exerciseId,{newId=uid}={}){const next=clone(state);assert(next.active,'No active session');const planned={exerciseId,sets:[{reps:8},{reps:8},{reps:8}]};next.active.exercises.push(newEntry(next,planned,newId));return next}
function substitute(state,entryId,replacementId,{newId=uid}={}){
 const next=clone(state),session=next.active;assert(session,'No active session');const original=session.exercises.find(entry=>entry.id===entryId);assert(original&&!original.supersededBy,'Select a current exercise');assert(next.catalog[replacementId]&&replacementId!==original.exerciseId,'Select a different stable exercise');
 const unfinished=original.sets.filter(set=>!set.done),planned={exerciseId:replacementId,supersetId:original.supersetId,sets:(unfinished.length?unfinished:[{reps:8}]).map(set=>({reps:set.reps,kind:set.kind}))};
 const replacement=newEntry(next,planned,newId);replacement.replaces=original.id;original.supersededBy=replacement.id;for(const set of unfinished)set.omittedBySubstitution=true;
 session.exercises.splice(session.exercises.indexOf(original)+1,0,replacement);return next;
}
function groupSession(state,ids,groupId=uid()){const next=clone(state);assert(next.active&&ids.length>=2&&new Set(ids).size===ids.length,'Select at least two different exercises');for(const id of ids){const entry=next.active.exercises.find(e=>e.id===id);assert(entry&&!entry.supersededBy,'Unknown current exercise');entry.supersetId=groupId}for(const group of new Set(next.active.exercises.map(entry=>entry.supersetId).filter(Boolean)))if(next.active.exercises.filter(entry=>entry.supersetId===group&&!entry.supersededBy).length<2)for(const entry of next.active.exercises)if(entry.supersetId===group)entry.supersetId=null;return next}
function planShape(session){return JSON.stringify(session.exercises.map(e=>({exerciseId:e.exerciseId,equipment:e.equipment||'',sets:e.sets.map(set=>set.kind),supersetId:e.supersetId?session.exercises.filter(x=>x.supersetId===e.supersetId).map(x=>x.exerciseId):null,superseded:!!e.supersededBy})))}
function comparable(session,workouts){return Object.values(workouts).filter(prior=>prior.id!==session.id&&prior.finishedAt!=null&&(prior.date<session.date||prior.date===session.date&&prior.finishedAt<(session.finishedAt??session.lastEventAt))&&prior.templateId===session.templateId&&prior.templateVersion===session.templateVersion&&planShape(prior)===planShape(session)).sort((a,b)=>b.date.localeCompare(a.date)||b.finishedAt-a.finishedAt)[0]||null}
function summary(session,workouts){const metrics=stats(session),prior=comparable(session,workouts);return {...metrics,...durations(session,session.finishedAt??session.lastEventAt),completion:completion(session),comparison:prior?{sessionId:prior.id,volumeDeltaKg:metrics.volumeKg-stats(prior).volumeKg,completedSetsDelta:metrics.sets-stats(prior).sets}:null,achievements:clone(session.achievements||[])}}
function recalculate(workouts){
 const result=clone(workouts),best=new Map();
 for(const session of Object.values(result).sort((a,b)=>a.date.localeCompare(b.date)||a.finishedAt-b.finishedAt||a.id.localeCompare(b.id))){
  session.achievements=[];
  for(const entry of session.exercises)for(const set of entry.sets){
   if(!working(set))continue;const prior=best.get(entry.exerciseId)||{weight:null,reps:new Map(),estimate:null},categories=[],estimated=estimate(set);
   if(prior.weight==null||set.weightKg>prior.weight)categories.push('Heaviest weight');
   if(!prior.reps.has(set.reps)||set.weightKg>prior.reps.get(set.reps))categories.push(set.reps+'-rep record');
   if(estimated!=null&&(prior.estimate==null||estimated>prior.estimate))categories.push('Estimated 1RM');
   if(categories.length)session.achievements.push({exerciseId:entry.exerciseId,setId:set.id,categories,formula:FORMULA,estimated1RM:estimated});
   prior.weight=Math.max(prior.weight??0,set.weightKg);prior.reps.set(set.reps,Math.max(prior.reps.get(set.reps)??0,set.weightKg));if(estimated!=null)prior.estimate=Math.max(prior.estimate??0,estimated);best.set(entry.exerciseId,prior);
  }
 }return result;
}
function finish(state,{now,confirmedIncomplete=false,previousVersion=0}={}){
 const next=clone(state),session=next.active;assert(session,'No active session');const counts=completion(session);if(counts.incomplete&&!confirmedIncomplete){const error=Error('Incomplete workout requires confirmation');error.code='INCOMPLETE';error.counts=counts;throw error}
 const prior=next.workouts[session.id],priorEvent=next.rotation.events.find(event=>event.kind==='completion'&&event.sessionId===session.id),updatedExisting=!!prior||!!priorEvent;assert(Number.isSafeInteger(previousVersion)&&previousVersion>=0,'Invalid previous version');
 const at=stamp(session,now);session.finishedAt=at;session.lastEventAt=at;if(session.pausedAt!=null){session.pausedMs+=at-session.pausedAt;session.pauses.push({from:session.pausedAt,to:at});session.pausedAt=null}session.version=Math.max(prior?.version||0,session.version||0,previousVersion)+1;if(prior){session.templateSnapshot=clone(prior.templateSnapshot);session.templateId=prior.templateId;session.templateVersion=prior.templateVersion}if(prior?.completionEvent||priorEvent)session.completionEvent=clone(prior?.completionEvent||priorEvent);
 const rotation=next.rotation,index=rotation.templateIds.indexOf(session.templateId),skipped=[];if(index>=0&&!updatedExisting){for(let cursor=rotation.next;cursor!==index;cursor=(cursor+1)%rotation.templateIds.length)skipped.push(cursor);const event={id:'completion:'+session.id,rotationIds:clone(rotation.templateIds),kind:'completion',sessionId:session.id,templateId:session.templateId,date:session.date,at,completedPosition:index,skipped};rotation.events.push(event);session.completionEvent=clone(event);rotation.next=(index+1)%rotation.templateIds.length}
 next.workouts[session.id]=session;next.workouts=recalculate(next.workouts);next.active=null;return {state:next,summary:summary(next.workouts[session.id],next.workouts),sessionId:session.id,updatedExisting};
}
function discard(state){const next=clone(state);next.active=null;return next}
function restDay(state){return clone(state)}
function correct(state,id,patch,{confirmed=false}={}){assert(confirmed,'Save Changes confirmation required');const next=clone(state),before=next.workouts[id];assert(before,'Unknown historical session');for(const key of Object.keys(patch))assert(['date','notes','exercises','name'].includes(key),'Historical template snapshots and identities are immutable');if(patch.date)date(patch.date);const original=clone(before.templateSnapshot);next.workouts[id]={...before,...clone(patch),id,version:before.version+1,templateSnapshot:original};for(const entry of next.workouts[id].exercises)assert(next.catalog[entry.exerciseId]||before.exercises.some(old=>old.exerciseId===entry.exerciseId),'Historical exercise ID unavailable');next.workouts=recalculate(next.workouts);return {state:next,rotationUnchanged:true,canUpdateRotation:true}}
function deleteWorkout(state,sessionId,{confirmed=false}={}){
 assert(confirmed,'Explicit workout deletion confirmation required');const next=clone(state);assert(next.workouts[sessionId],'Workout unavailable');assert(next.active?.id!==sessionId,'Finish or discard its active copy before deleting the saved version');delete next.workouts[sessionId];next.workouts=recalculate(next.workouts);return next;
}
function restoreWorkout(state,snapshot,{confirmed=false}={}){
 assert(confirmed,'Explicit workout recovery required');assert(snapshot&&validId(snapshot.id),'Invalid workout identity');const next=clone(state);assert(!next.workouts[snapshot.id],'Workout is already present');assert(next.active?.id!==snapshot.id,'Review the active copy before restoring its saved version');const restored=clone(snapshot);restored.version=(restored.version||0)+1;next.workouts[restored.id]=restored;next.workouts=recalculate(next.workouts);return next;
}
function updateRotation(state,position,{confirmed=false,now,localDate}={}){assert(confirmed,'Explicit Update Rotation confirmation required');const next=clone(state);assert(Number.isInteger(position)&&position>=0&&position<next.rotation.templateIds.length,'Invalid next rotation position');next.rotation.events.push({id:uid(),rotationIds:clone(next.rotation.templateIds),kind:'manual-adjustment',from:next.rotation.next,to:position,at:time(now),date:date(localDate)});next.rotation.next=position;return next}
function exerciseHistory(state,exerciseId){return Object.values(state.workouts).filter(session=>session.exercises.some(entry=>entry.exerciseId===exerciseId&&entry.sets.some(working))).sort((a,b)=>a.date.localeCompare(b.date)||a.finishedAt-b.finishedAt).map(session=>{
 const sets=session.exercises.filter(entry=>entry.exerciseId===exerciseId).flatMap(entry=>entry.sets.filter(working)),estimates=sets.map(estimate).filter(value=>value!=null);
 return {sessionId:session.id,date:session.date,name:session.name,weightKg:Math.max(...sets.map(set=>set.weightKg)),reps:Math.max(...sets.map(set=>set.reps)),volumeKg:sets.reduce((total,set)=>total+set.weightKg*set.reps,0),estimated1RM:estimates.length?Math.max(...estimates):null,sets:clone(sets)};
 })}
return {FORMULA,empty,putExercise,saveTemplate,setRotation,start,previousSets,durations,restRemaining,pause,resume,changeRest,baseRest,editSet,toggleComplete,addExercise,substitute,groupSession,stats,completion,estimate,finish,discard,restDay,summary,correct,updateRotation,exerciseHistory,validSet,working,validId,deleteWorkout,restoreWorkout,seedBuiltins};
});
