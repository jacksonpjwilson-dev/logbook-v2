/* Cloud login + sync (Firebase Auth + Firestore), local-first.
   Data lives ONLY at logbookV2/{uid} in Firestore. Nothing else in the project is read or written.
   Records: each workout/food/day/etc. is a record with a timestamp; merges are last-write-wins per record. */
(function(){
const CFG={apiKey:"AIzaSyAe50ZOlninoeHPIrxq9aylnLROi3SFekY",authDomain:"logbook-e784a.firebaseapp.com",projectId:"logbook-e784a",storageBucket:"logbook-e784a.firebasestorage.app",messagingSenderId:"901165633464",appId:"1:901165633464:web:f201b53121ccf05f04c94d"};
const COLL='logbookV2',META='lb2w:sync',WKEY='lb2w:water',SDK='https://www.gstatic.com/firebasejs/10.13.2/';
const ARRID={workouts:'id',foods:'id',lib:'id',sleep:'date',weight:'date'},MAPS=['food','schedule'],SKIP=['accounts','demo','version'];
const st={status:'signedout',user:null,at:null,err:null,busy:false,writes:0},subs=[];
const emit=()=>subs.forEach(f=>{try{f(st)}catch(e){}});
const meta=()=>{try{return JSON.parse(localStorage.getItem(META))||{h:{},t:{}}}catch(e){return {h:{},t:{}}}},saveMeta=m=>localStorage.setItem(META,JSON.stringify(m));
const water=()=>{try{return JSON.parse(localStorage.getItem(WKEY)||'{}')}catch(e){return {}}};
function canon(x){if(x===null||typeof x!=='object')return JSON.stringify(x)??'null';if(Array.isArray(x))return '['+x.map(canon).join(',')+']';return '{'+Object.keys(x).sort().map(k=>JSON.stringify(k)+':'+canon(x[k])).join(',')+'}'}
const chash=x=>hash(canon(x));
function hash(s){let h=2166136261;for(let i=0;i<s.length;i++){h^=s.charCodeAt(i);h=Math.imul(h,16777619)}return (h>>>0).toString(36)+s.length}
function flatten(d,w){const r={};for(const k of Object.keys(d)){if(SKIP.includes(k))continue;const v=d[k];
  if(ARRID[k]&&Array.isArray(v))v.forEach((x,i)=>{const id=x&&x[ARRID[k]];if(id!=null)r[k+'#'+id]={v:x,o:i}});
  else if(MAPS.includes(k)&&v&&typeof v==='object')Object.keys(v).forEach(dt=>{r[k+'@'+dt]={v:v[dt]}});
  else r[k]={v}}
 Object.keys(w||{}).forEach(dt=>r['water@'+dt]={v:w[dt]});return r}
function unflatten(recs,base){const d={};SKIP.forEach(k=>{if(base[k]!==undefined)d[k]=base[k]});const arr={};
 Object.keys(ARRID).forEach(k=>arr[k]=[]);MAPS.forEach(k=>d[k]={});const w={};
 for(const rid of Object.keys(recs)){const x=recs[rid];if(x.d)continue;const val=typeof x.v==='string'?JSON.parse(x.v):x.v;
  let m;if((m=rid.match(/^([a-zA-Z]+)#(.*)$/))&&ARRID[m[1]])arr[m[1]].push({v:val,o:x.o??0});
  else if((m=rid.match(/^([a-zA-Z]+)@(.*)$/))){if(m[1]==='water')w[m[2]]=val;else (d[m[1]]=d[m[1]]||{})[m[2]]=val}
  else d[rid]=val}
 Object.keys(arr).forEach(k=>{d[k]=arr[k].sort((a,b)=>a.o-b.o).map(z=>z.v)});return {d,w}}
/* stamp local changes: compare record hashes with last known; changed -> now, removed -> tombstone */
function stamp(first){const m=meta(),f=flatten(DB.get(),water()),now=Date.now();
 for(const rid of Object.keys(f)){const h=chash(f[rid]);if(m.h[rid]!==h){m.h[rid]=h;m.t[rid]=first?0:now}}
 for(const rid of Object.keys(m.h)){if(!f[rid]&&m.h[rid]!==null){m.h[rid]=null;m.t[rid]=now}}saveMeta(m);return {m,f}}
function stampChanged(){const before=JSON.stringify(meta().t);stamp(false);return JSON.stringify(meta().t)!==before}
function localRecords(){const {m,f}=stamp(false),out={};for(const rid of Object.keys(m.h)){if(m.h[rid]===null)out[rid]={d:true,t:m.t[rid]||0};else if(f[rid])out[rid]={v:JSON.stringify(f[rid].v),o:f[rid].o??0,t:m.t[rid]||0}}return out}
/* merge: per record, newest t wins. firstMerge: food days are unioned so nothing logged on either device is lost */
function merge(L,C,firstMerge){const out={},ids=new Set([...Object.keys(L),...Object.keys(C)]);
 for(const rid of ids){const a=L[rid],b=C[rid];if(!a){out[rid]=b;continue}if(!b){out[rid]=a;continue}
  if(firstMerge&&/^food@/.test(rid)&&!a.d&&!b.d){const A=JSON.parse(a.v),B=JSON.parse(b.v),seen=new Set(B.map(e=>JSON.stringify(e)));out[rid]={v:JSON.stringify(B.concat(A.filter(e=>!seen.has(JSON.stringify(e))))),t:Math.max(a.t,b.t)};continue}
  if(firstMerge&&!/[#@]/.test(rid)&&a.t===0)out[rid]=b; else out[rid]=(b.t>a.t)?b:a}
 return out}
function applyRecords(recs){const base=DB.get(),{d,w}=unflatten(recs,base);const merged=Object.assign({},base,d);
 const changed=chash(flatten(merged,w))!==chash(flatten(base,water()));
 if(changed){DB.replace(merged);localStorage.setItem(WKEY,JSON.stringify(w))}
 const m={h:{},t:{}};const f=flatten(merged,w);for(const rid of Object.keys(recs)){const x=recs[rid];m.t[rid]=x.t||0;m.h[rid]=x.d?null:(f[rid]?chash(f[rid]):null)}m.uid=st.user&&st.user.uid;saveMeta(m);
 if(changed&&window.__lbRemote)window.__lbRemote();return changed}
let fb=null,unsub=null,pushT=null,applying=false,lastRemote='';
function load(src){return new Promise((res,rej)=>{const s=document.createElement('script');s.src=SDK+src;s.onload=res;s.onerror=()=>rej(new Error('Could not load Firebase (offline?)'));document.head.appendChild(s)})}
async function init(){if(fb)return fb;if(!window.firebase){await load('firebase-app-compat.js');await load('firebase-auth-compat.js');await load('firebase-firestore-compat.js')}
 const app=firebase.apps&&firebase.apps.length?firebase.app():firebase.initializeApp(CFG);fb={auth:firebase.auth(),db:firebase.firestore()};
 fb.auth.onAuthStateChanged(u=>{if(u){st.user={uid:u.uid,email:u.email,name:u.displayName};localStorage.setItem('lb2w:signedin','1');start()}else{st.user=null;st.status='signedout';localStorage.removeItem('lb2w:signedin');if(unsub){unsub();unsub=null}emit()}});
 try{await fb.auth.getRedirectResult()}catch(e){}return fb}
const ref=()=>fb.db.collection(COLL).doc(st.user.uid);
function errMsg(e){const c=e&&e.code||'';return /permission/.test(c)?'Cloud access denied: the Firestore rules need to allow logbookV2/{uid} (see Settings note).':/unavailable|network/.test(c)?'Offline. Changes are saved on this device and will sync later.':(e&&e.message)||String(e)}
async function sync(){if(!fb||!st.user||st.busy)return;st.busy=true;st.status='syncing';emit();
 try{const m=meta(),first=m.uid!==st.user.uid;const L=localRecords();let out;
  await fb.db.runTransaction(async tx=>{const snap=await tx.get(ref());const C=(snap.exists&&snap.data().r)||{};out=merge(L,C,first);if(snap.exists&&chash(out)===chash(C))return;st.writes=(st.writes||0)+1;tx.set(ref(),{r:out,at:Date.now(),v:1})});
  applying=true;applyRecords(out);applying=false;lastRemote=chash(out);st.status='synced';st.at=Date.now();st.err=null}
 catch(e){st.status='error';st.err=errMsg(e);console.warn('sync',e)}st.busy=false;emit()}
function start(){st.status='syncing';emit();sync().then(()=>{if(unsub)unsub();unsub=ref().onSnapshot(s=>{if(!s.exists||st.busy||(s.metadata&&s.metadata.hasPendingWrites))return;const C=s.data().r||{};const h=chash(C);if(h===lastRemote)return;lastRemote=h;
  const L=localRecords(),out=merge(L,C,false);applying=true;applyRecords(out);applying=false;
  if(chash(out)!==h)schedule();else if(st.status!=='synced'){st.status='synced';st.at=Date.now();emit()}},e=>{st.status='error';st.err=errMsg(e);emit()})})}
function schedule(){if(!st.user)return;clearTimeout(pushT);pushT=setTimeout(sync,1500)}
window.SYNC={get state(){return st},on(f){subs.push(f)},
 async google(){await init();const p=new firebase.auth.GoogleAuthProvider();const standalone=navigator.standalone||matchMedia('(display-mode: standalone)').matches;
  try{if(standalone){localStorage.setItem('lb2w:signedin','1');await fb.auth.signInWithRedirect(p)}else await fb.auth.signInWithPopup(p)}catch(e){if(/popup-blocked|operation-not-supported/.test(e.code||'')){localStorage.setItem('lb2w:signedin','1');await fb.auth.signInWithRedirect(p)}else throw e}},
 async email(email,pass,create){await init();return create?fb.auth.createUserWithEmailAndPassword(email,pass):fb.auth.signInWithEmailAndPassword(email,pass)},
 async reset(email){await init();return fb.auth.sendPasswordResetEmail(email)},
 async signOut(){if(fb)await fb.auth.signOut();const m=meta();delete m.uid;saveMeta(m)},
 syncNow:()=>sync(),_canon:canon,_merge:merge,_flatten:flatten,_unflatten:unflatten,COLL};
/* hook local writes */
window.addEventListener('load',()=>{DB.onChange(()=>{if(applying)return;if(stampChanged())schedule()});if(!localStorage.getItem(META))stamp(true);
 if(localStorage.getItem('lb2w:signedin'))init().catch(e=>{st.status='error';st.err=errMsg(e);emit()})});
window.addEventListener('online',()=>schedule());
window.__lbLocalChange=()=>{if(stampChanged())schedule()};
})();
