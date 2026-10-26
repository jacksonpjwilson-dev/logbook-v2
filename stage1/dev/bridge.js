(async()=>{
'use strict';
const status=document.getElementById('development-status'),review=document.getElementById('development-review');
if(!['localhost','127.0.0.1','::1','[::1]'].includes(location.hostname)){document.body.textContent='Loopback-only development integration';return}
const s=LogbookSafety,codec=LogbookLegacyCodec;
const suffix=new URLSearchParams(location.search).get('fixture')||'default';if(!/^[a-zA-Z0-9_-]{1,60}$/.test(suffix))throw Error('Synthetic fixture namespace required');
const adapter=key=>LogbookIndexedDB.createAdapter({indexedDB,dbName:'logbook-v2-stage1-legacy-development',key:'synthetic-'+suffix+'-'+key});
const store=new LogbookOfflineStore.OfflineStore(adapter('records')),backup=adapter('backup'),seedBackup=adapter('seed-backup');await store.init();
if(!Object.keys(store.snapshot().records).some(id=>id.startsWith('legacy.root.'))){
 const response=await fetch('generated/fixture.json');if(!response.ok)throw Error('Build fixtures with node stage1/build-dev.cjs');
 const fixture=await response.json();
 // Independent verified full-source backup before the first projection.
 const envelope={synthetic:true,source:fixture,sha256:await LogbookMigration.digest(fixture)};const prior=await seedBackup.read();
 if(prior&&!s.equal(prior,envelope))throw Error('An earlier seed backup exists; choose a new synthetic namespace');
 if(!prior&&!await seedBackup.compareAndSwap(null,envelope))throw Error('Concurrent seed backup; reopen');
 if(!s.equal(await seedBackup.read(),envelope))throw Error('Synthetic seed backup readback failed');
 await store.applyRecords(store.snapshot().records,codec.project(fixture).records);
}
let coordinator=null,cloudTail=Promise.resolve();
let data=codec.materialize(store.snapshot().records),tail=Promise.resolve(),sidecars={};
for(const record of Object.values(store.snapshot().records))if(!record.deleted&&record.value?.kind==='sidecar')sidecars[record.value.key]=record.value.value;
function refresh(message='Saved in isolated IndexedDB'){
 const state=store.snapshot();status.textContent=message+' · '+state.pending.length+' pending · '+state.conflicts.length+' conflicts';drawConflicts(state);
}
function enqueue(fn){const result=tail.then(fn);tail=result.catch(error=>{status.textContent='Not saved: '+error.message});return result}
const memoryStorage=()=>{const values={};return {getItem:k=>values[k]??null,setItem:(k,v)=>{values[k]=String(v)},removeItem:k=>{delete values[k]}}};
window.Stage1SessionStorage=memoryStorage();
window.Stage1Storage={getItem:key=>sidecars[key]??null,setItem(key,value){
 if(!['lb2w:theme','lb2w:pages6','lb2w:layout','lb2w:water','lb2w:vr'].includes(key))throw Error('Unsupported synthetic sidecar');
 const text=String(value);enqueue(async()=>{await store.edit('sidecar:'+key,{kind:'sidecar',key,value:text});sidecars[key]=text;refresh()});
},removeItem(){throw Error('Sidecar deletion is disabled in this synthetic build')}};
window.DB={iso:d=>{const value=new Date(d);value.setMinutes(value.getMinutes()-value.getTimezoneOffset());return value.toISOString().slice(0,10)},dayOff(n){const value=new Date();value.setDate(value.getDate()+n);value.setMinutes(value.getMinutes()-value.getTimezoneOffset());return value.toISOString().slice(0,10)},
 init:()=>data,get:()=>data,canEdit:()=>true,currentUser:()=>({id:'synthetic-owner',name:'Synthetic Developer',role:'owner'}),
 mutate(fn){return enqueue(async()=>{
  const base=store.snapshot(),candidate=s.clone(data);fn(candidate);
  const plan=codec.project(candidate,base.records);await store.applyRecords(base.records,plan.records);data=codec.materialize(store.snapshot().records);refresh(plan.warnings.length?'Saved; ambiguous arrays preserved for review':'Saved in isolated IndexedDB');if(coordinator)queueMicrotask(()=>syncCloud().catch(error=>{status.textContent='Demo sync paused: '+error.message}));
 })},replace(){throw Error('External imports disabled; synthetic fixtures only')},reset(){throw Error('Synthetic reset disabled')},onChange(){}
};
const denied=()=>Promise.reject(Error('Real accounts are disabled in this synthetic build'));
window.SYNC={state:{status:'local',user:{uid:'synthetic-owner',name:'Synthetic Developer',email:'synthetic@example.invalid'}},on(){},prepare(){},google:denied,email:denied,reset:denied,signOut:denied,syncNow(){refresh('No cloud transport is attached to this legacy harness')}};
function run(fn){return async()=>{try{await fn()}catch(error){status.textContent=error.message}}}
function redrawLegacy(){sidecars={};for(const record of Object.values(store.snapshot().records))if(!record.deleted&&record.value?.kind==='sidecar')sidecars[record.value.key]=record.value.value;data=codec.materialize(store.snapshot().records);window.__lbRemote?.()}
function drawConflicts(state){
 review.replaceChildren();for(const conflict of state.conflicts){
  const section=document.createElement('section'),heading=document.createElement('strong');heading.textContent='Review conflicting '+conflict.id;section.append(heading);
  const sides=document.createElement('div');sides.className='development-sides';
  for(const side of ['local','remote']){const panel=document.createElement('div'),pre=document.createElement('pre'),button=document.createElement('button');pre.textContent=JSON.stringify(conflict[side]?.value,null,2)||'Deleted';button.textContent='Keep '+side;
   button.onclick=run(async()=>{await store.resolve({[conflict.id]:side});redrawLegacy();refresh('Conflict resolved')});panel.append(pre,button);sides.append(panel)}
  section.append(sides);review.append(section);
 }
}
document.getElementById('development-backup').onclick=run(async()=>{await tail;const snapshot=s.backup(store.snapshot().records,{synthetic:true});await backup.write({synthetic:true,snapshot});if(!s.equal((await backup.read()).snapshot,snapshot))throw Error('Backup verification failed');refresh('Synthetic backup verified')});
document.getElementById('development-restore').onclick=run(async()=>{
 await tail;const saved=await backup.read();if(!saved?.snapshot)throw Error('Create a synthetic backup first');const expected=store.snapshot().records;
 review.replaceChildren();const text=document.createElement('pre');text.textContent=JSON.stringify(store.previewRestore(saved.snapshot),null,2);const button=document.createElement('button');button.textContent='Confirm synthetic restore';button.onclick=run(async()=>{if(!s.equal(store.snapshot().records,expected))throw Error('Preview changed; review again');await store.restore(saved.snapshot,{confirmed:true,expectedRecords:expected});redrawLegacy();refresh('Synthetic restore complete')});review.append(text,button);
});
document.getElementById('development-undo').onclick=run(async()=>{const entries=store.snapshot().rollbackBackups;let i=entries.length-1;while(i>=0&&entries[i].undone)i--;await store.undoRestore(i,{confirmed:true});redrawLegacy();refresh('Restore undone')});
async function connectEmulators(){
 const sessions=adapter('demo-auth-session'),saved=await sessions.read();
 const transport=await LogbookStage1Rest.createTransport({pageHostname:location.hostname,session:saved||undefined});
 if(!saved)await sessions.write(transport.session);
 coordinator=LogbookStage1Sync.createCoordinator(store,transport);return syncCloud();
}
function syncCloud(){
 const operation=cloudTail.then(async()=>{
  await tail;if(!coordinator)throw Error('Connect the local demo emulators first');
  const result=await coordinator.sync();redrawLegacy();refresh('Demo emulator: '+result.status);return result;
 });cloudTail=operation.catch(()=>{});return operation;
}
document.getElementById('development-connect').onclick=run(connectEmulators);
document.getElementById('development-sync').onclick=run(syncCloud);
const autoSync=()=>{if(coordinator)syncCloud().catch(error=>{status.textContent='Demo sync paused: '+error.message})};
setInterval(autoSync,30000);addEventListener('online',autoSync);
window.stage1Legacy={store,flush:()=>tail,getData:()=>s.clone(data),connectEmulators,syncCloud};
refresh('Synthetic legacy integration ready');
if('serviceWorker'in navigator){
 const registration=await navigator.serviceWorker.register('sw.js',{scope:'./'});await navigator.serviceWorker.ready;
 window.stage1Legacy.offlineReady=true;
 registration.update().catch(()=>{});
}
const script=document.createElement('script');script.src='generated/legacy-app.js';script.onerror=()=>{status.textContent='Build development sources with node stage1/build-dev.cjs'};document.body.append(script);
})().catch(error=>{document.getElementById('development-status').textContent='Development integration stopped: '+error.message});
