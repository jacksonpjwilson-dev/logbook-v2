/* Lossless legacy projection for the synthetic development bridge. No storage/network. */
(function(root,factory){const api=factory(typeof module==='object'&&module.exports?require('./safety-core.js'):root.LogbookSafety);if(typeof module==='object'&&module.exports)module.exports=api;else root.LogbookLegacyCodec=api})(globalThis,function(s){
'use strict';
const token=value=>btoa(unescape(encodeURIComponent(String(value)))).replaceAll('+','-').replaceAll('/','_').replaceAll('=','');
const rootId=key=>'legacy.root.'+token(key);
function project(data,previous={}){
 if(!data||Array.isArray(data)||typeof data!=='object')throw Error('Legacy object required');
 const values={},warnings=[];
 for(const [field,value] of Object.entries(data)){
  const id=rootId(field);
  if(Array.isArray(value)){
   const keys=value.map(item=>item&&typeof item==='object'?(item.id??(['weight','sleep'].includes(field)?item.date:undefined)):undefined);
   const ids=keys.map(key=>'legacy.item.'+token(field)+'.'+token(key));
   const separable=keys.every(key=>key!==undefined&&key!==null)&&new Set(keys.map(String)).size===keys.length&&ids.every(x=>x.length<=160);
   if(separable){
    values[id]={kind:'array',field,ids};
    value.forEach((legacy,i)=>{values[ids[i]]={kind:'item',field,sourceId:keys[i],legacy:s.clone(legacy)}});
   }else{
    // Never infer identity from names or invent IDs for ambiguous legacy entries.
    values[id]={kind:'field',field,legacy:s.clone(value)};
    if(value.length&&['lib','workouts','foods','sleep','weight','templates','savedMeals'].includes(field))warnings.push({field,reason:'Missing, duplicate, or unsupported identities; preserved as an opaque array'});
   }
  }else if(['food','schedule'].includes(field)&&value&&typeof value==='object'){
   const keys=Object.keys(value),ids=keys.map(key=>'legacy.map.'+token(field)+'.'+token(key));
   values[id]={kind:'map',field,keys,ids};
   keys.forEach((key,i)=>{values[ids[i]]={kind:'map-item',field,key,legacy:s.clone(value[key])}});
  }else values[id]={kind:'field',field,legacy:s.clone(value)};
 }
 const records=s.clone(previous);
 for(const [id,value] of Object.entries(values)){
  const before=previous[id];records[id]=before&&!before.deleted&&s.equal(before.value,value)?s.clone(before):s.record(id,value,(before?.version||0)+1);
 }
 for(const [id,before] of Object.entries(previous))if(id.startsWith('legacy.')&&!(id in values)&&!before.deleted)records[id]=s.record(id,null,before.version+1,true);
 return {records,warnings};
}
function materialize(records){
 s.validateSnapshot({schema:s.SCHEMA,records});const entries=[];
 for(const [id,record] of Object.entries(records)){
  if(!id.startsWith('legacy.root.')||record.deleted)continue;const header=record.value;
  if(rootId(header.field)!==id)throw Error('Legacy source key mismatch');
  if(header.kind==='field')entries.push([header.field,s.clone(header.legacy)]);
  else if(header.kind==='array'||header.kind==='map'){
   const items=header.ids.map(itemId=>{const item=records[itemId];if(!item||item.deleted||item.value.field!==header.field)throw Error('Legacy reference is missing: '+itemId);return s.clone(item.value.legacy)});
   entries.push([header.field,header.kind==='array'?items:Object.fromEntries(header.keys.map((key,i)=>[key,items[i]]))]);
  }else throw Error('Unsupported legacy header');
 }
 return Object.fromEntries(entries);
}
return {project,materialize};
});
