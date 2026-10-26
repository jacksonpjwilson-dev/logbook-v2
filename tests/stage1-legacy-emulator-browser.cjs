const assert=require('node:assert/strict'),{chromium}=require('playwright-core');
(async()=>{
 assert.match(process.env.GCLOUD_PROJECT||'',/^demo-/);assert.equal(process.env.FIRESTORE_EMULATOR_HOST,'127.0.0.1:8080');assert.equal(process.env.FIREBASE_AUTH_EMULATOR_HOST,'127.0.0.1:9099');
 const browser=await chromium.launch({executablePath:process.env.CHROMIUM_PATH||'/usr/bin/chromium',headless:true,args:['--no-sandbox']});
 try{
 const context=await browser.newContext(),page=await context.newPage();
 await context.route('**/*',route=>new URL(route.request().url()).hostname==='127.0.0.1'?route.continue():route.abort());
 await page.goto('http://127.0.0.1:8765/stage1/dev/?fixture=emulator-'+Date.now());await page.waitForFunction(()=>window.stage1Legacy?.offlineReady&&document.querySelector('.dock'));
 let result=await page.evaluate(()=>stage1Legacy.connectEmulators());assert.equal(result.status,'synced',JSON.stringify(result));
 await page.evaluate(()=>DB.mutate(data=>{data.weight=[{date:'2026-10-01',kg:70.25}]}));await page.waitForFunction(()=>stage1Legacy.store.snapshot().pending.length===0);
 await context.setOffline(true);await page.evaluate(()=>DB.mutate(data=>{data.weight[0].kg=71.5}));await page.waitForFunction(()=>stage1Legacy.store.snapshot().pending.length>0);
 assert.equal(await page.evaluate(()=>stage1Legacy.getData().weight[0].kg),71.5);
 await context.setOffline(false);await page.waitForFunction(()=>stage1Legacy.store.snapshot().pending.length===0);
 await page.reload();await page.waitForFunction(()=>window.stage1Legacy?.offlineReady&&document.querySelector('.dock'));
 result=await page.evaluate(()=>stage1Legacy.connectEmulators());assert.equal(result.status,'synced',JSON.stringify(result));assert.equal(await page.evaluate(()=>stage1Legacy.getData().weight[0].kg),71.5);
 await page.evaluate(()=>DB.mutate(data=>{data.weight=[]}));await page.waitForFunction(()=>stage1Legacy.store.snapshot().pending.length===0);
 assert.equal(await page.evaluate(()=>stage1Legacy.store.snapshot().history.some(entry=>entry.previous?.value?.legacy?.kg===71.5&&entry.next?.deleted)),true);
 assert.equal(await page.evaluate(()=>navigator.serviceWorker.getRegistrations().then(entries=>entries.every(entry=>new URL(entry.scope).pathname==='/stage1/dev/'))),true);
 console.log('PASS legacy UI + actual emulators: demo auth, automatic sync, offline durable edit/rejoin, reload, deletion recovery, isolated development SW only');await context.close();
 }finally{await browser.close()}
})().catch(error=>{console.error(error);process.exitCode=1});
