/* Per-entity projection into the isolated Stage 1 store. */
(function(root,factory){const api=factory(typeof module==='object'&&module.exports?require('../preview-widget/safety-core.js'):root.LogbookSafety,typeof module==='object'&&module.exports?require('./training-core.js'):root.LogbookTraining);if(typeof module==='object'&&module.exports)module.exports=api;else root.LogbookTrainingRecords=api})(globalThis,function(s,T){
'use strict';
const mappings={catalog:'exercise',templates:'template',workouts:'workout'};
function project(state,previous={}){
 const values={};for(const [field,prefix] of Object.entries(mappings))for(const [id,value] of Object.entries(state[field])){if(!T.validId(id)||value.id!==id)throw Error('Stable entity identity mismatch');values['training.'+prefix+':'+id]=s.clone(value)}
 const {events,...rotation}=state.rotation;values['training.rotation']=s.clone(rotation);
 for(const event of events){if(!event.id)throw Error('Permanent rotation event identity required');values['training.event:'+event.id]=s.clone(event)}
 values['training.active']=s.clone(state.active);const settings=Object.create(null);for(const [key,value] of Object.entries(state))if(!['catalog','templates','workouts','rotation','active'].includes(key))settings[key]=s.clone(value);values['training.settings']=settings;
 const records=s.clone(previous);for(const [id,value] of Object.entries(values)){const before=previous[id];records[id]=before&&!before.deleted&&s.equal(before.value,value)?s.clone(before):s.record(id,value,(before?.version||0)+1)}
 for(const [id,before] of Object.entries(previous))if(id.startsWith('training.')&&!(id in values)&&!before.deleted)records[id]=s.record(id,null,before.version+1,true);
 return records;
}
function materialize(records){
 s.validateSnapshot({schema:s.SCHEMA,records});const state=T.empty();
 for(const [id,record] of Object.entries(records)){if(record.deleted||!id.startsWith('training.'))continue;const value=s.clone(record.value);
  if(id==='training.active')state.active=value;
  else if(id==='training.settings'){for(const [key,item] of Object.entries(value)){if(['catalog','templates','workouts','rotation','active'].includes(key))throw Error('Invalid Training settings field');Object.defineProperty(state,key,{value:item,enumerable:true,writable:true,configurable:true})}}
  else if(id==='training.rotation')state.rotation={...value,events:[]};
  else for(const [field,prefix] of Object.entries(mappings))if(id.startsWith('training.'+prefix+':')){const key=id.slice(('training.'+prefix+':').length);if(!T.validId(key)||value.id!==key)throw Error('Stable entity identity mismatch');state[field][key]=value}
 }
 state.rotation.events=Object.entries(records).filter(([id,r])=>id.startsWith('training.event:')&&!r.deleted).map(([,r])=>s.clone(r.value)).sort((a,b)=>a.at-b.at||a.id.localeCompare(b.id));if(state.schema!==1)throw Error('Unsupported Training schema');return state;
}
return {project,materialize};
});
