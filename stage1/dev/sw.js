/* Synthetic development scope only. Never reads/deletes production app caches. */
const CACHE='logbook-stage1-synthetic-dev-v1';
const ASSETS=['./','index.html','bridge.js','generated/legacy-app.js','generated/fixture.json',
 '../../preview-widget/styles.css','../../preview-widget/lib.js','../../preview-widget/safety-core.js',
 '../../preview-widget/stage1-store.js','../../preview-widget/stage1-indexeddb.js','../../preview-widget/stage1-legacy-codec.js',
 '../../preview-widget/stage1-migration.js','../../preview-widget/stage1-emulator.js','../../preview-widget/stage1-rest-transport.js','../../preview-widget/stage1-sync-controller.js'];
const urls=ASSETS.map(path=>new URL(path,self.location.href).href);
self.addEventListener('install',event=>event.waitUntil((async()=>{await (await caches.open(CACHE)).addAll(urls);await self.skipWaiting()})()));
self.addEventListener('activate',event=>event.waitUntil(self.clients.claim()));
self.addEventListener('fetch',event=>{
 const request=event.request,url=new URL(request.url);if(request.method!=='GET'||url.origin!==self.location.origin)return;
 const navigation=request.mode==='navigate'&&url.pathname.startsWith(new URL('./',self.location.href).pathname);
 if(!navigation&&!urls.includes(url.href))return;
 event.respondWith((async()=>{
  const cache=await caches.open(CACHE);
  try{const response=await fetch(request);if(response.ok)await cache.put(request,response.clone());return response}
  catch(error){const cached=await cache.match(request)||navigation&&await cache.match(new URL('index.html',self.location.href));if(cached)return cached;throw error}
 })());
});
