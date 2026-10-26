const assert=require('node:assert/strict'),{chromium}=require('playwright-core');
(async()=>{
 assert.match(process.env.GCLOUD_PROJECT||'',/^demo-/);assert.equal(process.env.FIRESTORE_EMULATOR_HOST,'127.0.0.1:8080');assert.equal(process.env.FIREBASE_AUTH_EMULATOR_HOST,'127.0.0.1:9099');
 const browser=await chromium.launch({executablePath:process.env.CHROMIUM_PATH||'/usr/bin/chromium',headless:true,args:['--no-sandbox']});
 try{
 const context=await browser.newContext(),page=await context.newPage(),namespace='training-cloud-'+Date.now();await context.route('**/*',route=>new URL(route.request().url()).hostname==='127.0.0.1'?route.continue():route.abort());
 await page.goto('http://127.0.0.1:8765/stage2/?fixture='+namespace);await page.waitForFunction(()=>window.stage2Training?.offlineReady);await page.getByRole('button',{name:'Demo sync',exact:true}).click();await page.waitForFunction(()=>stage2Training.store.snapshot().pending.length===0);
 await page.getByRole('button',{name:'Start workout',exact:true}).click();await page.locator('[data-field="weightKg"]').first().waitFor();await page.waitForFunction(()=>stage2Training.store.snapshot().pending.length===0);
 await page.locator('[data-field="weightKg"]').first().fill('75');
 await page.evaluate(async namespace=>{
  const adapter=LogbookIndexedDB.createAdapter({indexedDB,dbName:'logbook-v2-stage1-training-development',key:'synthetic-'+namespace+'-demo-session'}),session=await adapter.read();
  const transport=await LogbookStage1Rest.createTransport({pageHostname:location.hostname,session}),other=new LogbookOfflineStore.OfflineStore(LogbookOfflineStore.memoryAdapter());await other.init();const sync=LogbookStage1Sync.createCoordinator(other,transport);let result=await sync.sync();if(result.status!=='synced')throw Error(JSON.stringify(result));const base=other.snapshot(),state=LogbookTrainingRecords.materialize(base.records);state.active.notes='Synthetic remote note';await other.applyRecords(base.records,LogbookTrainingRecords.project(state,base.records));result=await sync.sync();if(result.status!=='synced')throw Error(JSON.stringify(result));
 },namespace);
 await page.evaluate(()=>stage2Training.syncCloud());assert.equal(await page.locator('[data-field="weightKg"]').first().inputValue(),'75','Background sync erased a partially typed entry');
 await page.locator('[data-field="weightKg"]').first().press('Tab');await page.evaluate(()=>stage2Training.flush());await page.waitForFunction(()=>stage2Training.store.snapshot().conflicts.length>0);
 await page.getByRole('button',{name:'Review conflicts',exact:true}).click();const dialog=page.getByRole('dialog');assert.ok((await dialog.innerText()).includes('Synthetic remote note'));assert.ok((await dialog.innerText()).includes('75'));await dialog.getByRole('button',{name:'Keep local',exact:true}).click();await page.waitForFunction(()=>stage2Training.store.snapshot().conflicts.length===0&&stage2Training.store.snapshot().pending.length===0);
 assert.equal(await page.evaluate(()=>stage2Training.getState().active.exercises[0].sets[0].weightKg),75);
 await context.setOffline(true);await page.reload();await page.waitForFunction(()=>window.stage2Training?.offlineReady);await page.locator('.resume').waitFor();await context.setOffline(false);await page.getByRole('button',{name:'Demo sync',exact:true}).click();await page.waitForFunction(()=>stage2Training.store.snapshot().pending.length===0);
 console.log('PASS Training + actual emulators: durable per-entity sync, background sync preserves typed input, competing changes retained for visible choice, resolution stays resolved, offline reload/rejoin');await context.close();
 }finally{await browser.close()}
})().catch(error=>{console.error(error);process.exitCode=1});
