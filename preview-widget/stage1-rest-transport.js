/* Explicit loopback + demo-only Auth/Firestore transport. No production configuration or SDK. */
(function(root,factory){const api=factory(typeof module==='object'&&module.exports?require('./stage1-emulator.js'):root.LogbookStage1Emulator);if(typeof module==='object'&&module.exports)module.exports=api;else root.LogbookStage1Rest=api})(globalThis,function(guard){
'use strict';
const encode=value=>{
 if(value===null)return {nullValue:null};
 if(Array.isArray(value))return {arrayValue:{values:value.map(encode)}};
 if(typeof value==='object')return {mapValue:{fields:Object.fromEntries(Object.entries(value).map(([k,v])=>[k,encode(v)]))}};
 if(typeof value==='string')return {stringValue:value};
 if(typeof value==='boolean')return {booleanValue:value};
 if(typeof value==='number'&&Number.isFinite(value))return Number.isSafeInteger(value)?{integerValue:String(value)}:{doubleValue:value};
 throw Error('Only finite JSON data can sync');
};
const decode=value=>{
 if('nullValue'in value)return null;
 if('mapValue'in value)return Object.fromEntries(Object.entries(value.mapValue.fields||{}).map(([k,v])=>[k,decode(v)]));
 if('arrayValue'in value)return (value.arrayValue.values||[]).map(decode);
 if('integerValue'in value)return Number(value.integerValue);
 if('doubleValue'in value)return value.doubleValue;
 if('stringValue'in value)return value.stringValue;
 if('booleanValue'in value)return value.booleanValue;
 throw Error('Unsupported emulator field');
};
const CHUNK_BYTES=192*1024,MAX_ITEM_BYTES=768*1024;
async function hash(kind,payload){const bytes=new TextEncoder().encode(kind+'\n'+payload);return Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',bytes)),b=>b.toString(16).padStart(2,'0')).join('')}
async function pack(kind,items){
 const groups=[];let current=[],bytes=2;
 for(const item of items){const encoded=JSON.stringify(item),size=new TextEncoder().encode(encoded).length;if(size>MAX_ITEM_BYTES)throw Error('A single record exceeds the safe emulator document limit; local data remains queued');if(current.length&&bytes+size+1>CHUNK_BYTES){groups.push(current);current=[];bytes=2}current.push(item);bytes+=size+1}
 if(current.length)groups.push(current);
 return Promise.all(groups.map(async group=>{const payload=JSON.stringify(group),sha256=await hash(kind,payload);return {id:(kind==='records'?'r-':'h-')+sha256,kind,payload,sha256,synthetic:true}}));
}
async function createTransport({pageHostname,host='127.0.0.1',port=8080,authHost='127.0.0.1',authPort=9099,projectId='demo-logbook-stage1',session,fetch:request=globalThis.fetch}={}){
 guard.assertLocal(pageHostname,host,port);guard.assertLocal(pageHostname,authHost,authPort);
 if(!/^demo-[a-z0-9-]+$/.test(projectId))throw Error('Demo project required');
 const createdSession=!session;
 const send=(url,options={})=>request(url,{...options,...(typeof AbortSignal!=='undefined'&&typeof AbortSignal.timeout==='function'?{signal:AbortSignal.timeout(15000)}:{})});
 const address=(h,p)=>'http://'+(h==='::1'?'[::1]':h)+':'+p;
 const authEndpoint=address(authHost,authPort);
 if(session){if(session.projectId!==projectId||session.authEndpoint!==authEndpoint||!session.uid||!session.token)throw Error('Isolated emulator session required')}
 else {
  const response=await send(authEndpoint+'/identitytoolkit.googleapis.com/v1/accounts:signUp?key=synthetic-only',{method:'POST',redirect:'error',headers:{'content-type':'application/json'},body:JSON.stringify({returnSecureToken:true})});
  if(!response.ok)throw Error('Local emulator authentication failed: '+response.status);
  const data=await response.json();session={uid:data.localId,token:data.idToken,projectId,authEndpoint};
 }
 if(session.uid.includes('/'))throw Error('Invalid emulator user');
 const base=address(host,port)+'/v1/projects/'+projectId+'/databases/(default)/documents';
 const name='projects/'+projectId+'/databases/(default)/documents/syntheticLogbookV2/'+session.uid;
 const headers={'content-type':'application/json',authorization:'Bearer '+session.token};
 async function chunkRead(item){
  if(!item||!['records','history'].includes(item.kind)||!new RegExp('^'+(item.kind==='records'?'r':'h')+'-[a-f0-9]{64}$').test(item.id))throw Error('Invalid snapshot chunk reference');
  const response=await send(base+'/syntheticLogbookV2/'+encodeURIComponent(session.uid)+'/chunks/'+item.id,{headers,redirect:'error'});
  if(!response.ok)throw Error('Snapshot chunk unavailable: '+response.status);
  const raw=await response.json(),chunk=decode({mapValue:{fields:raw.fields}});
  if(chunk.kind!==item.kind||chunk.sha256!==item.id.slice(2)||typeof chunk.payload!=='string'||await hash(chunk.kind,chunk.payload)!==chunk.sha256)throw Error('Snapshot chunk integrity check failed');
  const entries=JSON.parse(chunk.payload);if(!Array.isArray(entries))throw Error('Malformed snapshot chunk');return entries;
 }
 async function chunkWrite(chunk){
  const {id,...body}=chunk;
  const response=await send(base+':commit',{method:'POST',headers,redirect:'error',body:JSON.stringify({writes:[{update:{name:name+'/chunks/'+id,fields:encode(body).mapValue.fields},currentDocument:{exists:false}}]})});
  if(response.ok)return;
  const failure=await response.json();
  if(['ALREADY_EXISTS','FAILED_PRECONDITION','PERMISSION_DENIED'].includes(failure.error?.status)){
   // A racing upload/retry may have staged this immutable content already.
   const existing=await chunkRead(chunk);if(JSON.stringify(existing)!==chunk.payload)throw Error('Staged snapshot chunk mismatch');return;
  }
  throw Error('Snapshot staging failed: '+response.status);
 }
 async function pullVersioned(){
  const response=await send(base+'/syntheticLogbookV2/'+encodeURIComponent(session.uid),{headers,redirect:'error'});
  if(response.status===404)return {revision:0,records:{},history:[]};
  if(!response.ok)throw Error('Local emulator read failed: '+response.status);
  const data=await response.json(),value=decode({mapValue:{fields:data.fields}});
  if(!Number.isSafeInteger(value.revision)||value.revision<1||!value.records||!Array.isArray(value.history))throw Error('Malformed emulator state');
  if(value.manifest!==undefined){
   if(!Array.isArray(value.manifest)||value.manifest.length>6000)throw Error('Invalid snapshot manifest');
   const records={},history=[],seen=new Set();
   for(const item of value.manifest){if(seen.has(item.id))throw Error('Duplicate snapshot chunk');seen.add(item.id);const entries=await chunkRead(item);if(item.kind==='history')history.push(...entries);else for(const pair of entries){if(!Array.isArray(pair)||pair.length!==2||typeof pair[0]!=='string'||Object.hasOwn(records,pair[0])||['__proto__','constructor','prototype'].includes(pair[0]))throw Error('Invalid or duplicate snapshot record');Object.defineProperty(records,pair[0],{value:pair[1],enumerable:true,writable:true,configurable:true})}}
   return {revision:value.revision,records,history,manifest:value.manifest,updateTime:data.updateTime};
  }
  return {...value,updateTime:data.updateTime};
 }
 return {mode:'emulator-only',session,createdSession,pullVersioned,async compareAndSwap(expected,records,{history=[]}={}){
  if(!Number.isSafeInteger(expected?.revision)||expected.revision<0)throw Error('Expected revision required');
  const current=await pullVersioned();if(current.revision!==expected.revision)return {accepted:false,remote:current};
  encode({records,history}); // Validate finite JSON before staging any content.
  const chunks=[...await pack('records',Object.entries(records).sort(([a],[b])=>a<b?-1:a>b?1:0)),...await pack('history',history)];
  if(chunks.length>6000)throw Error('Snapshot manifest capacity exceeded; local data remains queued');
  const alreadyStaged=new Set((current.manifest||[]).map(item=>item.id));
  for(const chunk of chunks)if(!alreadyStaged.has(chunk.id))await chunkWrite(chunk);
  // Root CAS is the only publication point. An interrupted staging phase cannot
  // replace the prior complete snapshot; unused immutable chunks are harmless.
  const payload={revision:current.revision+1,records:{},history:[],manifest:chunks.map(({id,kind})=>({id,kind})),synthetic:true};
  const response=await send(base+':commit',{method:'POST',headers,redirect:'error',body:JSON.stringify({writes:[{update:{name,fields:encode(payload).mapValue.fields},currentDocument:current.updateTime?{updateTime:current.updateTime}:{exists:false}}]})});
  if(!response.ok){const error=await response.json();if(['FAILED_PRECONDITION','ABORTED','ALREADY_EXISTS'].includes(error.error?.status))return {accepted:false};
   // Rules can reject a stale sequential revision before checking updateTime.
   // Retry only when an authenticated read proves the cloud actually advanced.
   if(error.error?.status==='PERMISSION_DENIED'){
    const latest=await pullVersioned();if(latest.revision!==current.revision)return {accepted:false,remote:latest};
   }throw Error('Local emulator write failed: '+response.status)}
  return {accepted:true,revision:payload.revision};
 }};
}
return {createTransport};
});
