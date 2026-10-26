const test=require('node:test'),assert=require('node:assert/strict');
const {createTransport}=require('../preview-widget/stage1-rest-transport.js');
const session={uid:'synthetic-owner',token:'synthetic-not-a-real-token',projectId:'demo-logbook-stage1',authEndpoint:'http://127.0.0.1:9099'};
const document=revision=>({fields:{revision:{integerValue:String(revision)},records:{mapValue:{fields:{}}},history:{arrayValue:{values:[]}}},updateTime:'2026-10-26T00:00:00Z'});
test('rules rejection from concurrent revision is retryable only after proving cloud advancement',async()=>{
 let reads=0;
 const cloud=await createTransport({pageHostname:'localhost',session,fetch:async(url,options)=>{
  if(url.endsWith(':commit'))return new Response(JSON.stringify({error:{status:'PERMISSION_DENIED'}}),{status:403});
  return new Response(JSON.stringify(document(++reads)));
 }});
 const result=await cloud.compareAndSwap({revision:1},{},{history:[]});
 assert.equal(result.accepted,false);assert.equal(result.remote.revision,2);assert.equal(reads,2);
});
test('genuine permission denial is surfaced when cloud revision has not advanced',async()=>{
 const cloud=await createTransport({pageHostname:'localhost',session,fetch:async url=>url.endsWith(':commit')?new Response(JSON.stringify({error:{status:'PERMISSION_DENIED'}}),{status:403}):new Response(JSON.stringify(document(1)))});
 await assert.rejects(cloud.compareAndSwap({revision:1},{}),/write failed: 403/);
});
test('oversized single records fail before staging and retain the caller data',async()=>{
 let writes=0;const cloud=await createTransport({pageHostname:'localhost',session,fetch:async(url)=>{if(url.endsWith(':commit'))writes++;return new Response(JSON.stringify(document(1)))}});
 const records={large:{id:'large',version:1,deleted:false,value:'synthetic '.repeat(100000)}};
 await assert.rejects(cloud.compareAndSwap({revision:1},records),/single record exceeds/);assert.equal(writes,0);assert.equal(records.large.value.length,1000000);
});
