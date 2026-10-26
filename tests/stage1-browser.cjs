/* Real Chromium/IndexedDB tests. Install playwright-core separately or via CI. */
const assert=require('node:assert/strict');
const {chromium}=require('playwright-core');
(async()=>{
 const browser=await chromium.launch({executablePath:process.env.CHROMIUM_PATH||'/usr/bin/chromium',headless:true,args:['--no-sandbox']});
 try{
 const context=await browser.newContext();
 // Every browser request is constrained to the synthetic loopback harness.
 await context.route('**/*',route=>new URL(route.request().url()).hostname==='127.0.0.1'?route.continue():route.abort());
 const page=await context.newPage();await page.goto('http://127.0.0.1:8765/stage1/harness.html');
 const key='synthetic-browser-'+Date.now();
 const init=key=>{window.adapter=LogbookIndexedDB.createAdapter({indexedDB,dbName:'logbook-v2-stage1-browser-regression',key});window.store=new LogbookOfflineStore.OfflineStore(adapter);return store.init()};
 await page.evaluate(init,key);await page.evaluate(()=>store.edit('a',{done:false,weight:50}));
 await page.reload();await page.evaluate(init,key);
 assert.equal(await page.evaluate(()=>store.snapshot().records.a.value.done),false);
 const second=await context.newPage();await second.goto(page.url());await second.evaluate(init,key);
 await Promise.all([page.evaluate(()=>store.edit('b',2)),second.evaluate(()=>store.edit('c',3))]);
 await page.reload();await page.evaluate(init,key);
 const state=await page.evaluate(()=>store.snapshot());assert.equal(state.records.b.value,2);assert.equal(state.records.c.value,3);assert.equal(state.pending.length,3);
 await second.reload();await second.evaluate(init,key);
 await page.evaluate(()=>store.edit('a',{value:'tab-one'}));await second.evaluate(()=>store.edit('a',{value:'tab-two'}));
 const conflict=await second.evaluate(()=>store.snapshot().conflicts[0]);assert.equal(conflict.local.value.value,'tab-two');assert.equal(conflict.remote.value.value,'tab-one');
 await second.evaluate(()=>store.resolve({a:'remote'}));
 await context.setOffline(true);await second.evaluate(()=>store.edit('offline',true));await context.setOffline(false);
 await second.reload();await second.evaluate(init,key);assert.equal(await second.evaluate(()=>store.snapshot().records.offline.value),true);
 // Abort an actual write transaction, rather than mocking persistence.
 assert.equal(await second.evaluate(async key=>{
   const before=await adapter.read();
   const db=await new Promise((resolve,reject)=>{const r=indexedDB.open('logbook-v2-stage1-browser-regression');r.onsuccess=()=>resolve(r.result);r.onerror=()=>reject(r.error)});
   await new Promise(resolve=>{const tx=db.transaction('snapshots','readwrite');tx.objectStore('snapshots').put({bad:true},key);tx.onabort=resolve;tx.abort()});db.close();
   return LogbookSafety.equal(before,await adapter.read());
 },key),true);
 // Browser-facing quota failure leaves visible and durable state unchanged.
 assert.equal(await second.evaluate(async()=>{
  const failing={read:()=>adapter.read(),write(){throw new DOMException('Quota exceeded','QuotaExceededError')}};
  const failed=new LogbookOfflineStore.OfflineStore(failing);await failed.init();
  try{await failed.edit('quota',true);return false}catch(e){return e.name==='QuotaExceededError'&&!failed.snapshot().records.quota}
 }),true);
 console.log('PASS Chromium: reload, pending queue, concurrent tabs, explicit conflict, offline edit, aborted IDB transaction, quota failure');
 const ui=await context.newPage();await ui.goto('http://127.0.0.1:8765/stage1/workbench.html');
 await ui.waitForFunction(()=>window.stage1Workbench);
 await ui.locator('#record-value').fill('Synthetic browser value');await ui.getByRole('button',{name:'Save locally',exact:true}).click();
 await ui.waitForFunction(()=>stage1Workbench.store.snapshot().records['workout:synthetic-1']?.value.note==='Synthetic browser value');
 await ui.locator('#backup').click();await ui.waitForFunction(()=>document.getElementById('status').textContent.startsWith('Synthetic backup saved'));
 await ui.locator('#conflict').click();await ui.getByRole('button',{name:'Keep remote',exact:true}).waitFor();
 await ui.getByRole('button',{name:'Keep remote',exact:true}).click();await ui.waitForFunction(()=>!stage1Workbench.store.snapshot().conflicts.length);
 await ui.locator('#preview').click();await ui.locator('#restore').waitFor({state:'visible'});await ui.locator('#restore').click();
 await ui.waitForFunction(()=>document.getElementById('status').textContent.startsWith('Restore saved'));
 assert.equal(await ui.evaluate(()=>stage1Workbench.store.snapshot().records['workout:synthetic-1'].value.note),'Synthetic browser value');
 await ui.locator('#undo').click();await ui.waitForFunction(()=>document.getElementById('status').textContent.startsWith('Restore undone'));
 assert.equal(await ui.evaluate(()=>stage1Workbench.store.snapshot().records['workout:synthetic-1'].value.note),'Fictional other-device change');
 await require('node:fs/promises').mkdir('stage1/artifacts',{recursive:true});
 await ui.screenshot({path:'stage1/artifacts/workbench.png',fullPage:true});
 console.log('PASS workbench UI: add, backup, side-by-side conflict choice, restore preview/confirmation, Undo');
 await context.close();
 }finally{await browser.close()}
})().catch(e=>{console.error(e);process.exitCode=1});
