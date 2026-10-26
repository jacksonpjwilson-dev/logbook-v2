(async()=>{
'use strict';
const $=id=>document.getElementById(id),s=LogbookSafety;
if(!['localhost','127.0.0.1','::1','[::1]'].includes(location.hostname)){document.body.textContent='Loopback-only synthetic workbench';return}
const adapter=key=>LogbookIndexedDB.createAdapter({indexedDB,dbName:'logbook-v2-stage1-workbench',key:'synthetic-'+key});
const store=new LogbookOfflineStore.OfflineStore(adapter('local'));await store.init();
const cloud=adapter('cloud'),backup=adapter('backup');let offline=false,preview=null;
const transport={mode:'emulator-only', // Local simulation of the emulator contract, never a network transport.
 async pullVersioned(){if(offline)throw Error('Simulated offline');return await cloud.read()||{revision:0,records:{}}},
 async compareAndSwap(expected,records,{history=[]}={}){if(offline)throw Error('Simulated offline');const current=await cloud.read();
 if((current?.revision||0)!==expected.revision)return {accepted:false};
 const next={revision:expected.revision+1,records:s.clone(records),history:s.clone(history)};
 return {accepted:await cloud.compareAndSwap(current,next),revision:next.revision};
 }};
const coordinator=LogbookStage1Sync.createCoordinator(store,transport);
function draw(message='Saved locally'){
 const state=store.snapshot();$('status').textContent=message+' · '+state.pending.length+' pending · '+state.conflicts.length+' conflicts';
 $('records').textContent=JSON.stringify(state.records,null,2);$('conflicts').replaceChildren();
 for(const c of state.conflicts){
  const card=document.createElement('section'),heading=document.createElement('h3');heading.textContent=c.id;card.append(heading);
  const sides=document.createElement('div');sides.className='sides';
  for(const side of ['local','remote']){const panel=document.createElement('div'),title=document.createElement('h4'),text=document.createElement('pre'),button=document.createElement('button');
   title.textContent=side==='local'?'Your local edit':'Competing edit';text.textContent=JSON.stringify(c[side],null,2)||'Deleted';button.textContent='Keep '+side;
   button.onclick=run(async()=>{await store.resolve({[c.id]:side});draw('Conflict resolved; sync to confirm')});panel.append(title,text,button);sides.append(panel)}
  card.append(sides);$('conflicts').append(card);
 }
}
function run(fn){return async event=>{event?.preventDefault();try{await fn()}catch(e){$('status').textContent=e.message}}}
$('edit').onsubmit=run(async()=>{await store.edit($('record-id').value,{note:$('record-value').value});draw()});
$('delete').onclick=run(async()=>{await store.edit($('record-id').value,null,{deleted:true});draw('Deleted; recoverable for 30 days')});
$('sync').onclick=run(async()=>{const result=await coordinator.sync();draw('Simulation: '+result.status)});
$('offline').onclick=()=>{offline=!offline;$('offline').setAttribute('aria-pressed',String(offline));draw(offline?'Simulation is offline':'Simulation is online')};
$('conflict').onclick=run(async()=>{
 const id=$('record-id').value,base=await transport.pullVersioned();await store.ingest(base.records);
 if(!store.snapshot().records[id])await store.edit(id,{note:'Fictional original'});
 await coordinator.sync();await store.edit(id,{note:'Fictional local change'});
 const current=await cloud.read(),records=s.clone(current.records);records[id]=s.record(id,{note:'Fictional other-device change'},(records[id]?.version||0)+1);
 if(!await cloud.compareAndSwap(current,{revision:current.revision+1,records,history:current.history||[]}))throw Error('Simulation changed; retry');
 await coordinator.sync();draw('Compare both fictional versions below');
});
$('backup').onclick=run(async()=>{await backup.write(s.backup(store.snapshot().records,{synthetic:true}));draw('Synthetic backup saved')});
$('preview').onclick=run(async()=>{
 const incoming=await backup.read();if(!incoming)throw Error('Save a synthetic backup first');
 preview={incoming,expected:store.snapshot().records,mode:$('restore-mode').value};const plan=store.previewRestore(incoming,{mode:preview.mode}),resurrects=plan.changes.filter(change=>change.resurrects).length;$('restore-preview').textContent=(resurrects?resurrects+' deleted records would be restored. Review before confirming.\n':'')+JSON.stringify(plan,null,2);$('restore').hidden=false;
});
$('restore-mode').onchange=()=>{preview=null;$('restore').hidden=true;$('restore-preview').textContent='Preview the selected mode before restoring'};
$('restore').onclick=run(async()=>{
 if(!preview||!s.equal(store.snapshot().records,preview.expected))throw Error('Preview is stale; preview again');
 await store.restore(preview.incoming,{confirmed:true,expectedRecords:preview.expected,mode:preview.mode});preview=null;$('restore').hidden=true;draw('Restore saved; Undo available');
});
$('undo').onclick=run(async()=>{const entries=store.snapshot().rollbackBackups;let i=entries.length-1;while(i>=0&&entries[i].undone)i--;await store.undoRestore(i,{confirmed:true});draw('Restore undone')});
window.stage1Workbench={store,coordinator};draw('Isolated workbench ready');
})().catch(e=>{document.getElementById('status').textContent='Storage unavailable: '+e.message});
