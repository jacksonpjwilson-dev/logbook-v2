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
async function createTransport({pageHostname,host='127.0.0.1',port=8080,authHost='127.0.0.1',authPort=9099,projectId='demo-logbook-stage1',session,fetch:request=globalThis.fetch}={}){
 guard.assertLocal(pageHostname,host,port);guard.assertLocal(pageHostname,authHost,authPort);
 if(!/^demo-[a-z0-9-]+$/.test(projectId))throw Error('Demo project required');
 const address=(h,p)=>'http://'+(h==='::1'?'[::1]':h)+':'+p;
 const authEndpoint=address(authHost,authPort);
 if(session){if(session.projectId!==projectId||session.authEndpoint!==authEndpoint||!session.uid||!session.token)throw Error('Isolated emulator session required')}
 else {
  const response=await request(authEndpoint+'/identitytoolkit.googleapis.com/v1/accounts:signUp?key=synthetic-only',{method:'POST',redirect:'error',headers:{'content-type':'application/json'},body:JSON.stringify({returnSecureToken:true})});
  if(!response.ok)throw Error('Local emulator authentication failed: '+response.status);
  const data=await response.json();session={uid:data.localId,token:data.idToken,projectId,authEndpoint};
 }
 if(session.uid.includes('/'))throw Error('Invalid emulator user');
 const base=address(host,port)+'/v1/projects/'+projectId+'/databases/(default)/documents';
 const name='projects/'+projectId+'/databases/(default)/documents/syntheticLogbookV2/'+session.uid;
 const headers={'content-type':'application/json',authorization:'Bearer '+session.token};
 async function pullVersioned(){
  const response=await request(base+'/syntheticLogbookV2/'+encodeURIComponent(session.uid),{headers,redirect:'error'});
  if(response.status===404)return {revision:0,records:{},history:[]};
  if(!response.ok)throw Error('Local emulator read failed: '+response.status);
  const data=await response.json(),value=decode({mapValue:{fields:data.fields}});
  if(!Number.isSafeInteger(value.revision)||value.revision<1||!value.records||!Array.isArray(value.history))throw Error('Malformed emulator state');
  return {...value,updateTime:data.updateTime};
 }
 return {mode:'emulator-only',session,pullVersioned,async compareAndSwap(expected,records,{history=[]}={}){
  if(!Number.isSafeInteger(expected?.revision)||expected.revision<0)throw Error('Expected revision required');
  const current=await pullVersioned();if(current.revision!==expected.revision)return {accepted:false,remote:current};
  const payload={revision:current.revision+1,records,history,synthetic:true};
  const response=await request(base+':commit',{method:'POST',headers,redirect:'error',body:JSON.stringify({writes:[{update:{name,fields:encode(payload).mapValue.fields},currentDocument:current.updateTime?{updateTime:current.updateTime}:{exists:false}}]})});
  if(!response.ok){const error=await response.json();if(['FAILED_PRECONDITION','ABORTED','ALREADY_EXISTS'].includes(error.error?.status))return {accepted:false};throw Error('Local emulator write failed: '+response.status)}
  return {accepted:true,revision:payload.revision};
 }};
}
return {createTransport};
});
