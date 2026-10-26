const assert=require('node:assert/strict'),{chromium}=require('playwright-core');
(async()=>{
 const browser=await chromium.launch({executablePath:process.env.CHROMIUM_PATH||'/usr/bin/chromium',headless:true,args:['--no-sandbox']});
 try{
 const context=await browser.newContext({viewport:{width:390,height:844}}),requests=[],errors=[];
 await context.route('**/*',route=>{const request=route.request();requests.push(request.url());return new URL(request.url()).hostname==='127.0.0.1'?route.continue():route.abort()});
 const page=await context.newPage();page.on('pageerror',e=>errors.push(e.message));await page.goto('http://127.0.0.1:8765/stage1/harness.html');
 await page.evaluate(()=>{localStorage.setItem('lb2w:data9','synthetic-production-key-sentinel');localStorage.setItem('lb2w:water','synthetic-sidecar-sentinel')});
 const url='http://127.0.0.1:8765/stage1/dev/?fixture=browser-'+Date.now();await page.goto(url);
 const ready=p=>p.waitForFunction(()=>window.stage1Legacy?.offlineReady&&document.querySelector('.dock'));
 await ready(page);await page.locator('.dock [data-app="train"]').click();
 await page.locator('[data-act="start"][data-t="Fictional Push"]').first().click();await page.locator('input[data-f="w"]').first().waitFor();
 await page.locator('input[data-f="w"]').first().fill('50');await page.locator('input[data-f="w"]').first().press('Tab');
 await page.evaluate(()=>stage1Legacy.flush());await page.locator('[data-act="done"]').first().click();await page.evaluate(()=>stage1Legacy.flush());
 await page.locator('#snote').fill('Synthetic unfinished plan');await page.locator('#snote').press('Tab');await page.evaluate(()=>stage1Legacy.flush());
 await context.setOffline(true);await page.reload();await ready(page);await page.locator('.fab-live').waitFor();await context.setOffline(false);
 let data=await page.evaluate(()=>stage1Legacy.getData());assert.equal(data.active.exercises[0].sets.length,3);assert.equal(data.active.exercises[0].sets[0].done,true);assert.equal(data.active.exercises[0].sets[1].done,false);assert.equal(data.active.notes,'Synthetic unfinished plan');
 await page.locator('#development-backup').click();await page.waitForFunction(()=>document.getElementById('development-status').textContent.startsWith('Synthetic backup verified'));
 await page.evaluate(()=>DB.mutate(d=>{d.active.notes='Changed after backup'}));
 await page.locator('#development-restore').click();await page.getByRole('button',{name:'Confirm synthetic restore',exact:true}).click();
 await page.waitForFunction(()=>stage1Legacy.getData().active.notes==='Synthetic unfinished plan');
 await page.locator('#development-undo').click();await page.waitForFunction(()=>stage1Legacy.getData().active.notes==='Changed after backup');
 const other=await context.newPage();other.on('pageerror',e=>errors.push(e.message));await other.goto(url);await ready(other);
 await page.evaluate(()=>DB.mutate(d=>{d.profile.name='Synthetic independent edit'}));
 await other.evaluate(()=>DB.mutate(d=>{d.active.notes='Other tab note'}));
 assert.equal(await other.evaluate(()=>stage1Legacy.getData().profile.name),'Synthetic independent edit');
 // Both tabs share a reviewed baseline before producing competing session edits.
 await page.reload();await ready(page);await other.reload();await ready(other);
 await page.evaluate(()=>DB.mutate(d=>{d.active.notes='First tab intention'}));
 await other.evaluate(()=>DB.mutate(d=>{d.active.notes='Second tab intention'}));
 await other.getByRole('button',{name:'Keep remote',exact:true}).waitFor();
 const conflict=await other.evaluate(()=>stage1Legacy.store.snapshot().conflicts[0]);assert.equal(conflict.local.value.legacy.notes,'Second tab intention');assert.equal(conflict.remote.value.legacy.notes,'First tab intention');
 await other.getByRole('button',{name:'Keep remote',exact:true}).click();await other.waitForFunction(()=>stage1Legacy.store.snapshot().conflicts.length===0);
 assert.equal(await other.evaluate(()=>stage1Legacy.getData().active.notes),'First tab intention');
 assert.deepEqual(await page.evaluate(()=>[localStorage.getItem('lb2w:data9'),localStorage.getItem('lb2w:water')]),['synthetic-production-key-sentinel','synthetic-sidecar-sentinel']);
 assert.ok(!requests.some(url=>/\/sync\.js|\/data\.js|firebase|googleapis/.test(url)),'Legacy Firebase/data script requested');assert.deepEqual(errors,[]);
 await require('node:fs/promises').mkdir('stage1/artifacts',{recursive:true});await other.screenshot({path:'stage1/artifacts/legacy-integration.png',fullPage:true});
 console.log('PASS legacy integration: real legacy UI, IDB session recovery with unfinished sets, backup/restore/Undo, independent edits, visible conflict choice, original storage sentinels untouched, offline reopening, no production Firebase/SW');
 await context.close();
 }finally{await browser.close()}
})().catch(error=>{console.error(error);process.exitCode=1});
