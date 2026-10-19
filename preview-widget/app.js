const PREVIEW_VER='w12';
/* themed promise-based dialogs: await ui.confirm({title,message,action,destructive}), ui.prompt({...}) -> string|null, ui.alert({...}) */
const ui=(()=>{const esc_=t=>String(t??'').replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
 function open({title='',message='',action='OK',cancel='Cancel',destructive,input,value='',placeholder='',noCancel}){return new Promise(res=>{const prev=document.activeElement;const w=document.createElement('div');w.className='uim';w.setAttribute('role','alertdialog');w.setAttribute('aria-modal','true');
  const red=destructive??/^(delete|remove|discard|erase|clear|reset)/i.test(action);
  w.innerHTML=`<div class="uim-bd"></div><div class="uim-box"><div class="uim-body"><b class="uim-t">${esc_(title)}</b>${message?`<p class="uim-m">${esc_(message)}</p>`:''}${input?`<input class="uim-in" value="${esc_(value)}" placeholder="${esc_(placeholder)}" autocomplete="off">`:''}</div><div class="uim-acts ${noCancel?'one':''}">${noCancel?'':`<button class="uim-b uim-cancel">${esc_(cancel)}</button>`}<button class="uim-b uim-ok ${red?'red':''}">${esc_(action)}</button></div></div>`;
  document.body.appendChild(w);requestAnimationFrame(()=>w.classList.add('on'));const inp=w.querySelector('.uim-in');setTimeout(()=>{(inp||w.querySelector('.uim-ok')).focus();if(inp)inp.select()},60);
  const done=v=>{w.classList.remove('on');w.classList.add('off');document.removeEventListener('keydown',key,true);setTimeout(()=>{w.remove();prev&&prev.focus&&prev.focus()},220);res(v)};
  const ok=()=>done(input?inp.value:true),no=()=>done(input?null:false);
  const key=e=>{if(e.key==='Escape'){e.preventDefault();e.stopPropagation();no()}else if(e.key==='Enter'){e.preventDefault();e.stopPropagation();ok()}};document.addEventListener('keydown',key,true);
  w.querySelector('.uim-ok').onclick=ok;const c=w.querySelector('.uim-cancel');if(c)c.onclick=no;w.querySelector('.uim-bd').onclick=no})}
 function menu({title='',message='',actions=[]}){return new Promise(res=>{const w=document.createElement('div');w.className='uim uimenu';w.innerHTML=`<div class="uim-bd"></div><div class="uim-box"><div class="uim-body"><b class="uim-t">${esc_(title)}</b>${message?`<p class="uim-m">${esc_(message)}</p>`:''}</div><div class="uim-list">${actions.map((x,i)=>`<button class="uim-b ${x.destructive?'red':''}" data-i="${i}">${esc_(x.label)}</button>`).join('')}<button class="uim-b uim-cancel" data-i="-1">Cancel</button></div></div>`;
  document.body.appendChild(w);requestAnimationFrame(()=>w.classList.add('on'));const done=v=>{w.classList.remove('on');w.classList.add('off');setTimeout(()=>w.remove(),220);res(v)};
  w.querySelector('.uim-bd').onclick=()=>done(null);w.querySelectorAll('[data-i]').forEach(b=>b.onclick=()=>{const i=+b.dataset.i;done(i<0?null:actions[i].value)})})}
 return {confirm:o=>open(o),menu,prompt:o=>open(Object.assign({action:'OK'},o,{input:true})),alert:o=>open(Object.assign({action:'OK'},o,{noCancel:true,destructive:false}))}})();
window.ui=ui;
(function(){
'use strict';
const $=s=>document.querySelector(s);
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const {iso,dayOff}=DB;
let D=DB.init();
const S={tab:'today',foodSeg:'log',progSeg:'lifts',foodDate:iso(new Date()),liftEx:'Bench Press',calMonth:0,onb:null};
const ICON={
 today:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/></svg>',
 train:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><path d="M6.5 6.5v11M17.5 6.5v11M3 9v6M21 9v6M6.5 12h11"/></svg>',
 food:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><path d="M4 11h16a8 8 0 0 1-16 0zM8 7c0-2 2-2 2-4M12 7c0-2 2-2 2-4"/></svg>',
 progress:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><path d="M3 20h18M6 16l4-5 3 3 5-7"/></svg>',
 me:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><circle cx="12" cy="8" r="4"/><path d="M4 21c1.5-4 4.5-6 8-6s6.5 2 8 6"/></svg>'};
const CW={
0:{n:"Neutral greyscale",fh:"-apple-system,system-ui,sans-serif",fb:"-apple-system,system-ui,sans-serif",pair:"System",L:{bg:"#f2f2f2",card:"#fff",fg:"#111",mut:"#777",line:"#ddd",a:"#333",a2:"#777",a3:"#aaa",on:"#fff"},Dk:{bg:"#111",card:"#1e1e1e",fg:"#eee",mut:"#888",line:"#333",a:"#ddd",a2:"#999",a3:"#666",on:"#111"}},
1:{n:"Midnight Navy & Gold",fh:"'Playfair Display',Georgia,serif",fb:"'Inter',-apple-system,sans-serif",pair:"Playfair Display + Inter",L:{bg:"#f6f3ea",card:"#fff",fg:"#0f1b33",mut:"#6b7280",line:"#e6dfcc",a:"#0f1b33",a2:"#c9a227",a3:"#8aa0c8",on:"#f6e7b0"},Dk:{bg:"#0a1326",card:"#13203d",fg:"#f3ead2",mut:"#8d97ad",line:"#22325a",a:"#d4af37",a2:"#8aa0c8",a3:"#f3ead2",on:"#0a1326"}},
2:{n:"Forest & Cream",fh:"'Fraunces',Georgia,serif",fb:"'Source Sans 3',-apple-system,sans-serif",pair:"Fraunces + Source Sans 3",L:{bg:"#f4efe3",card:"#fbf8f0",fg:"#1f3a2b",mut:"#7a7a68",line:"#e2dac6",a:"#2f5d43",a2:"#a3b18a",a3:"#d9a441",on:"#f4efe3"},Dk:{bg:"#13221a",card:"#1c3126",fg:"#efe8d6",mut:"#93a08f",line:"#2c4436",a:"#a3c49a",a2:"#d9a441",a3:"#efe8d6",on:"#13221a"}},
3:{n:"Sunset Coral",fh:"'Poppins',-apple-system,sans-serif",fb:"'Poppins',-apple-system,sans-serif",pair:"Poppins (600/400)",L:{bg:"#fff5f0",card:"#fff",fg:"#3b1f1a",mut:"#9a7268",line:"#fbd9cc",a:"#ff6b57",a2:"#ffb347",a3:"#c2549c",on:"#fff"},Dk:{bg:"#24120f",card:"#341c17",fg:"#ffe9e1",mut:"#b88a7e",line:"#4a2a22",a:"#ff7a66",a2:"#ffb347",a3:"#e077b6",on:"#24120f"}},
4:{n:"Mono + Red",fh:"'Helvetica Neue',Helvetica,Arial,sans-serif",fb:"'Helvetica Neue',Helvetica,Arial,sans-serif",pair:"Helvetica Neue / Inter Tight",L:{bg:"#fff",card:"#fff",fg:"#000",mut:"#666",line:"#000",a:"#e10600",a2:"#000",a3:"#999",on:"#fff"},Dk:{bg:"#000",card:"#000",fg:"#fff",mut:"#999",line:"#fff",a:"#ff2a1f",a2:"#fff",a3:"#666",on:"#000"}},
5:{n:"Arctic",fh:"'Manrope',-apple-system,sans-serif",fb:"'Manrope',-apple-system,sans-serif",pair:"Manrope",L:{bg:"#eef6fb",card:"#fff",fg:"#0d2a3d",mut:"#6c8799",line:"#d4e6f1",a:"#2b8fd6",a2:"#7cc8f0",a3:"#b6dcf2",on:"#fff"},Dk:{bg:"#0a1a26",card:"#11283a",fg:"#e6f4fc",mut:"#7e9db0",line:"#1e3c52",a:"#6cc4f5",a2:"#b6e3fa",a3:"#3a7fae",on:"#0a1a26"}},
6:{n:"Sand & Terracotta",fh:"'DM Serif Display',Georgia,serif",fb:"'DM Sans',-apple-system,sans-serif",pair:"DM Serif Display + DM Sans",L:{bg:"#f3ebdf",card:"#faf5ec",fg:"#3d2a20",mut:"#93806f",line:"#e3d6c2",a:"#c4643f",a2:"#d9a87e",a3:"#7f8f6a",on:"#fff"},Dk:{bg:"#221812",card:"#33241b",fg:"#f3e6d6",mut:"#a8927e",line:"#46342a",a:"#e07b52",a2:"#d9a87e",a3:"#9fb087",on:"#221812"}},
7:{n:"Electric Violet",fh:"'Space Grotesk',-apple-system,sans-serif",fb:"'Inter',-apple-system,sans-serif",pair:"Space Grotesk + Inter",L:{bg:"#f5f2ff",card:"#fff",fg:"#1a1033",mut:"#7a6f99",line:"#e4dcff",a:"#7c3aed",a2:"#22d3ee",a3:"#f472b6",on:"#fff"},Dk:{bg:"#0e0820",card:"#1a1236",fg:"#efeaff",mut:"#9a8fc0",line:"#2c2257",a:"#a26bff",a2:"#22d3ee",a3:"#f472b6",on:"#0e0820"}},
8:{n:"Graphite & Mint",fh:"'IBM Plex Sans',-apple-system,sans-serif",fb:"'IBM Plex Sans',-apple-system,sans-serif",pair:"IBM Plex Sans + Plex Mono numerals",L:{bg:"#eceeee",card:"#fff",fg:"#1f2326",mut:"#6d7579",line:"#d8dcdd",a:"#12b886",a2:"#3a4045",a3:"#9ad9c3",on:"#fff"},Dk:{bg:"#16191b",card:"#22272a",fg:"#e8eceb",mut:"#8a9397",line:"#33393d",a:"#3ee6b0",a2:"#9aa4a8",a3:"#1f7a5e",on:"#16191b"}},
9:{n:"Aviator",fh:"'Barlow Condensed','Arial Narrow',sans-serif",fb:"'Barlow',-apple-system,sans-serif",pair:"Barlow Condensed + Barlow",L:{bg:"#f2f4f7",card:"#fff",fg:"#0b1f3a",mut:"#5d6b80",line:"#d9dfe7",a:"#ff6a13",a2:"#0b1f3a",a3:"#7f93ad",on:"#fff"},Dk:{bg:"#07142a",card:"#0e2140",fg:"#f4f6fa",mut:"#8796ad",line:"#1d3560",a:"#ff7a26",a2:"#f4f6fa",a3:"#4f6d99",on:"#07142a"}},
10:{n:"Rose & Charcoal",fh:"'Cormorant Garamond',Georgia,serif",fb:"'Lato',-apple-system,sans-serif",pair:"Cormorant Garamond + Lato",L:{bg:"#f7eeee",card:"#fff",fg:"#2b2b2e",mut:"#8a7f80",line:"#ead8d8",a:"#c0687a",a2:"#2b2b2e",a3:"#e3b3bc",on:"#fff"},Dk:{bg:"#1c1c1f",card:"#2a2a2e",fg:"#f2e6e7",mut:"#9a9093",line:"#3a3a3f",a:"#e48a9c",a2:"#f2e6e7",a3:"#7d4b56",on:"#1c1c1f"}}};
CW.teal={n:'Logbook Teal',fh:'-apple-system,system-ui,sans-serif',fb:'-apple-system,system-ui,sans-serif',L:{bg:'#f6f7fb',card:'#fff',fg:'#0f172a',mut:'#64748b',line:'#e2e8f0',a:'#0d9488',a2:'#6366f1',a3:'#ec4899',on:'#fff'},Dk:{bg:'#0b0d12',card:'#151922',fg:'#f1f5f9',mut:'#94a3b8',line:'#263041',a:'#2dd4bf',a2:'#818cf8',a3:'#f472b6',on:'#042f2e'}};
CW.grey=Object.assign({},CW[0],{n:'Grey'});delete CW[0];
const CW_ORDER=['teal',1,2,3,4,5,6,7,8,9,10,'grey'].map(String);
const TH_KEY='lb2w:theme',LY_KEY='lb2w:layout';
const TH=Object.assign({cw:'teal',mode:'auto'},JSON.parse(localStorage.getItem(TH_KEY)||'{}'));
const PAGES=[['today','Home'],['train','Training'],['food','Food'],['recovery','Sleep & body'],['progress','History'],['me','Settings']];

/* ---------- helpers ---------- */
const P=()=>D.profile, U=()=>P().units;
const toDisp=kg=>U()==='lb'?Math.round(kg*2.20462*10)/10:kg;
const fromDisp=v=>U()==='lb'?Math.round(v/2.20462*100)/100:+v;
const uid=()=>Math.random().toString(36).slice(2,9);
const food=id=>normFood(D.foods.find(f=>f.id===id)||{name:'(deleted)',kcal:0,p:0,c:0,f:0});
/* units: mass (base g) and volume (base ml); no cross-family conversion */
const UNITS={g:['m',1],kg:['m',1000],mg:['m',.001],oz:['m',28.349523125],lb:['m',453.59237],ml:['v',1],L:['v',1000],'fl oz':['v',29.5735295625],cup:['v',240],tbsp:['v',14.78676478125],tsp:['v',4.92892159375]};
const UNIT_LIST=Object.keys(UNITS),famUnits=u=>UNIT_LIST.filter(k=>UNITS[k][0]===UNITS[u][0]);
const convU=(v,from,to)=>{const a=UNITS[from],b=UNITS[to];if(!a||!b||a[0]!==b[0])return null;return v*a[1]/b[1]};
const unitNorm=u=>{u=(u||'').toLowerCase().trim();return u==='l'?'L':u==='floz'||u==='fl. oz'?'fl oz':u==='cups'?'cup':UNITS[u]?u:null};
function normFood(f){if(f.kind)return f;const src=(f.serving||'')+' '+f.name,all=[...src.matchAll(/(\d+(?:\.\d+)?)\s*(fl\.? ?oz|kg|mg|g|oz|lb|ml|l|cups?|tbsp|tsp)\b/gi)],m=all.sort((x,y)=>(/^(g|kg|mg|ml|l)$/i.test(y[2])?1:0)-(/^(g|kg|mg|ml|l)$/i.test(x[2])?1:0))[0];const u=m&&unitNorm(m[2].replace('.',''));
 return u?Object.assign({},f,{kind:'measured',size:+m[1],unit:u}):Object.assign({},f,{kind:'item'})}
const entryQ=(f,e)=>f.kind==='measured'&&e.amt!=null?(convU(+e.amt,e.unit,f.unit)??0)/(f.size||1):e.q;
const amtTxt=e=>e.amt!=null?' · '+r1(+e.amt)+' '+e.unit:(e.q!==1?' ×'+e.q:'');
const fmtNum=v=>Math.round(v*10)/10;
function amountSheet(fid,{title,init,cta},done){const f=food(fid),meas=f.kind==='measured',fam=meas?famUnits(f.unit):[];let q=init&&init.q||1,amt=init&&init.amt!=null?+init.amt:(meas?f.size:null),unit=init&&init.unit&&fam.includes(init.unit)?init.unit:(meas?f.unit:null);
 sheet(`<h3>${esc(title||f.name)}</h3><p class="muted" style="margin-top:0">${meas?`Label: ${f.kcal} kcal per ${fmtNum(f.size)} ${f.unit}`:`Whole item: ${f.kcal} kcal each`}</p>
 ${meas?`<label class="f">Amount eaten</label><div class="row" style="gap:8px"><input id="aamt" inputmode="decimal" value="${amt}" style="flex:1"><select id="aunit" style="width:110px">${fam.map(u=>`<option ${u===unit?'selected':''}>${u}</option>`).join('')}</select></div>`
 :`<label class="f">How many?</label><div class="stepper"><button class="icon-btn" id="aminus">−</button><b id="aq">${q}</b><button class="icon-btn" id="aplus">＋</button><label class="tgl" style="margin:0 0 0 12px"><input type="checkbox" id="ahalf" ${q%1?'checked':''}> allow ½</label></div>`}
 <div class="card livebox" id="alive"></div><button class="btn block" id="ago">${cta||'Log'}</button>`,el=>{const $$=i=>el.querySelector(i);
  const cur=()=>meas?{amt:+$$('#aamt').value||0,unit:$$('#aunit').value}:{q};
  const live=()=>{const c=cur(),k=meas?entryQ(f,c):c.q;$$('#alive').innerHTML=`<b style="font-size:22px">${Math.round(f.kcal*k)} kcal</b><div class="muted">P ${fmtNum(f.p*k)} g · C ${fmtNum(f.c*k)} g · F ${fmtNum(f.f*k)} g${meas?` · ${fmtNum(k*(f.size||1))} ${f.unit} of label`:''}</div>`};
  if(meas){$$('#aamt').oninput=live;$$('#aunit').onchange=live}else{const st=()=>$$('#ahalf').checked?.5:1;$$('#aminus').onclick=()=>{q=Math.max(st(),+(q-st()).toFixed(1));$$('#aq').textContent=q;live()};$$('#aplus').onclick=()=>{q=+(q+st()).toFixed(1);$$('#aq').textContent=q;live()};$$('#ahalf').onchange=()=>{if(!$$('#ahalf').checked)q=Math.max(1,Math.round(q));$$('#aq').textContent=q;live()}}
  live();$$('#ago').onclick=()=>{const c=cur();if(meas&&!(c.amt>0))return toast('Enter an amount');const e=meas?{amt:c.amt,unit:c.unit,q:entryQ(f,c)}:{q:c.q};closeSheet();done(e)}})}
const totals=list=>list.reduce((t,e)=>{const f=food(e.fid),q=entryQ(f,e);t.kcal+=f.kcal*q;t.p+=f.p*q;t.c+=f.c*q;t.f+=f.f*q;return t},{kcal:0,p:0,c:0,f:0});
const prettyDate=d=>new Date(d+'T12:00').toLocaleDateString(undefined,{weekday:'short',month:'short',day:'numeric'});
const epley=(w,r)=>r>0?w*(1+r/30):0;
const canEdit=()=>DB.canEdit();
function toast(m){const t=$('#toast');t.textContent=m;t.classList.add('on');clearTimeout(t._h);t._h=setTimeout(()=>t.classList.remove('on'),1800)}
/* effective-dated goals: D.profile.goalHist=[{from:'YYYY-MM-DD',t:{kcal,p,c,f}}] */
function goalFor(ds){const h=(P().goalHist||[]).slice().sort((a,b)=>a.from.localeCompare(b.from));let g=null;for(const e of h){if(e.from<=ds)g=e.t;else break}return g||(h[0]&&h[0].t)||P().targets}
function setGoal(d,from,t){d.profile.goalHist=(d.profile.goalHist||[]).filter(e=>e.from<from);d.profile.goalHist.push({from,t});const td=iso(new Date());const h=d.profile.goalHist.slice().sort((a,b)=>a.from.localeCompare(b.from));let cur=t;for(const e of h)if(e.from<=td)cur=e.t;d.profile.targets=Object.assign({},cur)}
function goalsSheet(ds){ds=ds||iso(new Date());const g=Object.assign({},goalFor(ds)),auto=!!P().goalAuto,td=iso(new Date());
 sheet(`<h3>Daily goals</h3><p class="muted">Applies to <b>${ds===td?'today':prettyDate(ds)}</b> and every day after. Earlier days keep the goals they had.</p>
 <div class="grid2"><div><label class="f">Protein (g)</label><input id="gp" inputmode="numeric" value="${g.p}"></div><div><label class="f">Carbs (g)</label><input id="gc" inputmode="numeric" value="${g.c}"></div><div><label class="f">Fat (g)</label><input id="gf" inputmode="numeric" value="${g.f}"></div><div><label class="f">Calories (kcal)</label><input id="gk" inputmode="numeric" value="${g.kcal}" ${auto?'disabled':''}></div></div>
 <label class="tgl"><input type="checkbox" id="gauto" ${auto?'checked':''}> Auto-calculate calories from macros (4/4/9)</label><p class="muted" id="gcalc"></p>
 <button class="btn block" id="gsave" style="margin-top:8px">Save goals</button>`,el=>{const $$=i=>el.querySelector(i),num=i=>Math.max(0,Math.round(+$$(i).value||0));
  const upd=()=>{const k=num('#gp')*4+num('#gc')*4+num('#gf')*9;$$('#gcalc').textContent=`Macros add up to ${k} kcal`;if($$('#gauto').checked){$$('#gk').value=k;$$('#gk').disabled=true}else $$('#gk').disabled=false};
  ['#gp','#gc','#gf'].forEach(i=>$$(i).oninput=upd);$$('#gauto').onchange=upd;upd();
  $$('#gsave').onclick=()=>{const t={kcal:num('#gk'),p:num('#gp'),c:num('#gc'),f:num('#gf')};if(!t.kcal)return toast('Calories required');save(d=>{d.profile.goalAuto=$$('#gauto').checked;setGoal(d,ds,t)},'Goals saved from '+(ds===td?'today':prettyDate(ds)));closeSheet();if(OV)drawOV()}})}
const authErr=e=>{const c=(e&&e.code)||'';return /wrong-password|invalid-credential|invalid-login/.test(c)?'Email or password is incorrect':/user-not-found/.test(c)?'No account with that email':/email-already/.test(c)?'That email already has an account. Sign in instead.':/weak-password/.test(c)?'Password must be at least 6 characters':/invalid-email/.test(c)?'That email doesn’t look right':/popup-closed|cancelled/.test(c)?'Sign-in cancelled':/too-many/.test(c)?'Too many attempts. Wait a minute and try again.':/user-disabled/.test(c)?'This account has been disabled':/network/.test(c)?'No connection. Check your internet and try again.':(e&&e.message)||'Sign-in failed'};
window.__lbRemote=()=>{try{const w=JSON.parse(localStorage.getItem('lb2w:water')||'{}');Object.keys(WATER).forEach(k=>delete WATER[k]);Object.assign(WATER,w)}catch(e){}D=DB.get();render();if(OV)drawOV()};
function save(fn,msg){try{DB.mutate(fn);D=DB.get();if(msg)toast(msg);render()}catch(e){toast('Read-only account — editing is disabled')}}
function applyTheme(){const dark=TH.mode==='dark'||(TH.mode==='auto'&&matchMedia('(prefers-color-scheme: dark)').matches);const c=CW[TH.cw]||CW.teal,v=dark?c.Dk:c.L,r=document.documentElement;
 r.dataset.theme=dark?'dark':'light';const mix=(a,b,p)=>`color-mix(in srgb,${a} ${p}%,${b})`;
 const set={'--bg':v.bg,'--card':v.card,'--card2':mix(v.line,v.card,55),'--text':v.fg,'--muted':v.mut,'--line':v.line,'--accent':v.a,'--accent2':v.a2,'--accent3':v.a3,'--on':v.on,'--accentSoft':mix(v.a,v.card,22),'--p':v.a2,'--c':v.a3,'--f':v.a,'--fh':c.fh,'--fb':c.fb};
 for(const k in set)r.style.setProperty(k,set[k]);document.querySelectorAll('meta[name=theme-color]').forEach(x=>x.setAttribute('content',v.bg))}
function saveTheme(){localStorage.setItem(TH_KEY,JSON.stringify(TH));applyTheme()}
matchMedia('(prefers-color-scheme: dark)').addEventListener?.('change',()=>{applyTheme()});
function pantryStatus(p){return p.qty<=0?'out':p.qty<=p.min?'low':'ok'}
function ring(val,goal,label,size=112){const r=size/2-9,c=2*Math.PI*r,pct=Math.min(1,goal?val/goal:0);
 return `<div class="ring" style="width:${size}px;height:${size}px"><svg width="${size}" height="${size}"><circle cx="${size/2}" cy="${size/2}" r="${r}" stroke="var(--card2)" stroke-width="12" fill="none"/><circle cx="${size/2}" cy="${size/2}" r="${r}" stroke="var(--accent)" stroke-width="12" fill="none" stroke-linecap="round" stroke-dasharray="${c}" stroke-dashoffset="${c*(1-pct)}"/></svg><div class="c"><b>${Math.round(val)}</b><span>${label}</span></div></div>`}
function macroBars(t,g){g=g||P().targets;return [['Protein','p','var(--p)'],['Carbs','c','var(--c)'],['Fat','f','var(--f)']].map(([n,k,col])=>`<div class="macro"><span>${n}</span><div class="bar"><i style="width:${Math.min(100,t[k]/g[k]*100)}%;background:${col}"></i></div><span class="muted">${Math.round(t[k])}/${g[k]}g</span></div>`).join('')}
function lineChart(pts,{h=150,color='var(--accent)',fmt=v=>v}={}){
 if(pts.length<2)return '<div class="empty">Not enough data yet</div>';
 const W=340,pad=26,ys=pts.map(p=>p.y),mn=Math.min(...ys),mx=Math.max(...ys),rg=(mx-mn)||1;
 const X=i=>pad+i*(W-pad-8)/(pts.length-1),Y=v=>h-18-(v-mn)/rg*(h-36);
 const d=pts.map((p,i)=>(i?'L':'M')+X(i).toFixed(1)+' '+Y(p.y).toFixed(1)).join(' ');
 return `<svg class="chart" viewBox="0 0 ${W} ${h}" role="img"><text x="0" y="14" font-size="10" fill="var(--muted)">${fmt(mx)}</text><text x="0" y="${h-18}" font-size="10" fill="var(--muted)">${fmt(mn)}</text>
 <path d="${d} L${X(pts.length-1)} ${h-18} L${X(0)} ${h-18}Z" fill="${color}" opacity=".12"/><path d="${d}" fill="none" stroke="${color}" stroke-width="2.5" stroke-linejoin="round" stroke-linecap="round"/>
 ${pts.map((p,i)=>`<circle cx="${X(i)}" cy="${Y(p.y)}" r="3" fill="${color}"/>`).join('')}
 <text x="${pad}" y="${h-2}" font-size="10" fill="var(--muted)">${esc(pts[0].x)}</text><text x="${W-8}" y="${h-2}" font-size="10" text-anchor="end" fill="var(--muted)">${esc(pts[pts.length-1].x)}</text></svg>`}
function barChart(pts,{h=130,goal=null}={}){
 if(!pts.length)return '<div class="empty">No data</div>';
 const W=340,mx=Math.max(...pts.map(p=>Math.max(p.y,p.g||0)),goal||0)||1,bw=(W-8)/pts.length;
 return `<svg class="chart" viewBox="0 0 ${W} ${h}">${goal?`<line x1="0" x2="${W}" y1="${h-16-goal/mx*(h-26)}" y2="${h-16-goal/mx*(h-26)}" stroke="var(--accent2)" stroke-dasharray="4 4"/>`:''}
 ${pts.map((p,i)=>{const bh=p.y/mx*(h-26);return `<rect x="${4+i*bw+bw*.18}" y="${h-16-bh}" width="${bw*.64}" height="${Math.max(bh,1)}" rx="4" fill="var(--accent)"/>${p.g?`<line x1="${4+i*bw+bw*.08}" x2="${4+i*bw+bw*.92}" y1="${h-16-p.g/mx*(h-26)}" y2="${h-16-p.g/mx*(h-26)}" stroke="var(--accent2)" stroke-width="2.5" stroke-linecap="round"/>`:''}<text x="${4+i*bw+bw/2}" y="${h-3}" font-size="9" text-anchor="middle" fill="var(--muted)">${esc(p.x)}</text>`}).join('')}</svg>`}

/* ---------- sheets ---------- */
function sheet(html,onMount){const root=$('#sheet-root');root.innerHTML=`<div class="sheet-bg"><div class="sheet" role="dialog"><div class="grab"></div>${html}</div></div>`;
 const bg=root.firstChild;bg.addEventListener('click',e=>{if(e.target===bg)closeSheet()});onMount&&onMount(bg.firstChild)}
function closeSheet(){$('#sheet-root').innerHTML=''}

/* ---------- TODAY ---------- */
function coachTips(){const tips=[],today=iso(new Date()),t=totals(D.food[today]||[]),g=P().targets;
 const wk=D.workouts.filter(w=>(new Date()-new Date(w.date))/864e5<7).length;
 if(wk<P().weekGoal)tips.push(`${wk}/${P().weekGoal} workouts this week — ${P().weekGoal-wk} to go.`);
 if(t.p<g.p*0.5)tips.push(`Protein is at ${Math.round(t.p)} g. Front-load it at your next meal.`);
 const ls=D.sleep.slice(-3);if(ls.length&&ls.reduce((a,s)=>a+s.hours,0)/ls.length<P().sleepGoal-1)tips.push('Sleep has been short the last 3 nights. Aim for an earlier lights-out.');
 return tips}
function vToday(){const today=iso(new Date()),t=totals(D.food[today]||[]),g=P().targets;
 const sl=D.sleep.find(s=>s.date===today),wt=D.weight.find(w=>w.date===today);
 const supps=D.supplements.log[today]||[];const done=D.workouts.find(w=>w.date===today);
 const nextT=nextTpl()||{name:'—',exercises:[]};
 return `<div class="card"><h2>Fuel <small>${Math.round(g.kcal-t.kcal)} kcal left</small></h2><div class="row">${ring(t.kcal,g.kcal,'of '+g.kcal+' kcal')}<div class="grow">${macroBars(t)}</div></div>
 <button class="btn ghost block sm" style="margin-top:10px" data-edit data-act="addfood">＋ Log food</button></div>
 <div class="card"><h2>Training <small>${done?'Done ✓':''}</small></h2>${D.active?`<p class="muted">Session in progress: <b>${esc(D.active.name)}</b></p><button class="btn block" data-go="train">Resume session</button>`:done?`<p class="muted">${esc(done.name)} · ${done.exercises.length} exercise${done.exercises.length===1?"":"s"} · ${vol(done)} ${U()} volume</p>`:`<p class="muted">Suggested next: <b>${esc(nextT.name)}</b> (${nextT.exercises.join(', ')})</p><button class="btn block" data-edit data-act="start" data-t="${esc(nextT.name)}">Start ${esc(nextT.name)}</button>`}</div>
 <div class="grid2"><div class="card" style="margin:0 0 12px"><h2>Sleep</h2><b style="font-size:26px">${sl?sl.hours+' h':'—'}</b><div class="muted">${sl?'★'.repeat(sl.quality)+'☆'.repeat(5-sl.quality):'Not logged'}</div><button class="btn ghost sm block" style="margin-top:8px" data-edit data-act="sleep">${sl?'Edit':'Log'}</button></div>
 <div class="card" style="margin:0 0 12px"><h2>Weight</h2><b style="font-size:26px">${wt?toDisp(wt.kg)+' '+U():'—'}</b><div class="muted">${wt?'Today':'Not logged'}</div><button class="btn ghost sm block" style="margin-top:8px" data-edit data-act="weight">${wt?'Edit':'Log'}</button></div></div>
 <div class="card"><h2>Supplements <small>${supps.length}/${D.supplements.list.length}</small></h2><div class="chips">${D.supplements.list.length?'':'<span class="muted">No supplements yet. Add the ones you take.</span>'}${D.supplements.list.map(s=>`<button class="chip ${supps.includes(s)?'on':''}" data-act="supp" data-s="${esc(s)}" ${canEdit()?'':'disabled'}>${supps.includes(s)?'✓ ':''}${esc(s)}</button>`).join('')}<button class="chip" data-edit data-act="addsupp">＋</button></div></div>
 <div class="card"><h2>Coach</h2>${coachTips().map(x=>`<div class="tip">${esc(x)}</div>`).join('')||'<div class="muted">All on track. Nice.</div>'}</div>`}
const vol=w=>Math.round(w.exercises.reduce((a,e)=>a+e.sets.reduce((b,s)=>b+(s.done?toDisp(s.w)*s.r:0),0),0));

/* ---------- TRAIN ---------- */
/* ---------- EXERCISE LIBRARY + WORKOUTS ---------- */
const GROUPS=['Chest','Back','Shoulders','Biceps','Triceps','Quads','Hamstrings','Glutes','Calves','Core','Cardio','Forearms'];
const EQUIP=['Barbell','Dumbbell','Cable','Machine','Smith machine','EZ bar','Bodyweight','Landmine','Cardio machine','Kettlebell','Band','Other'];
const LIB=()=>D.lib||(D.lib=[]);
const libBy=n=>LIB().find(e=>e.name.toLowerCase()===String(n).toLowerCase());
const groupOf=n=>(libBy(n)||{}).group||'Other';
const DOW=['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
const splitOf=()=>Array.isArray(D.split)&&D.split.some(x=>x&&x!=='rest')?D.split:null;
/* Rotating split: D.split = ['Push','Pull','rest',...] (N days, 1-14). Position = last completed split day (workout matching a day, or a manual rest/skip mark). */
function splitPos(){const sp=splitOf();if(!sp)return {pos:-1,last:null};const N=sp.length,ev=[...D.workouts.map(w=>({d:w.date,n:w.name,t:w.ts||0})),...(D.splitMarks||[]).map(m=>({d:m.date,i:m.idx,t:m.ts||0}))].sort((a,b)=>a.d.localeCompare(b.d)||a.t-b.t);
 let pos=-1,last=null;for(const e of ev){if(e.i!=null){pos=e.i%N;last=e.d;continue}for(let k=1;k<=N;k++){const j=(pos+k+N)%N;if(sp[j]===e.n){pos=j;last=e.d;break}}}return {pos,last}}
const splitNext=()=>{const sp=splitOf();if(!sp)return -1;return (splitPos().pos+1)%sp.length};
function splitProj(days){const sp=splitOf(),m={};if(!sp)return m;const td=iso(new Date()),{last}=splitPos();let i=splitNext(),k=(last===td)?1:0;for(;k<days;k++){m[dayOff(k)]=i;i=(i+1)%sp.length}return m}
const dayLbl=(i)=>{const sp=splitOf();return sp?`Day ${i+1}`:''};
const dayName=(i)=>{const sp=splitOf();const n=sp&&sp[i];return !n||n==='rest'?'Rest':n};
function nextTpl(){if(!D.templates.length)return null;{const td=iso(new Date());if(!D.workouts.some(w=>w.date===td)){const p=plannedOn(td);if(p)return D.templates.find(t=>t.name===p)}for(let k=1;k<8;k++){const p=plannedOn(dayOff(k));if(p)return D.templates.find(t=>t.name===p)}}const sp=splitOf();
 if(sp){const s0=splitNext();for(let k=0;k<sp.length;k++){const n=sp[(s0+k)%sp.length];const t=n&&D.templates.find(x=>x.name===n);if(t)return t}}
 return D.templates[D.workouts.length%D.templates.length]}
function exRow(e){return `<button class="item exrow" data-act="exinfo" data-n="${esc(e.name)}">${e.photo?`<img class="exthumb" src="${e.photo}" alt="">`:`<span class="exthumb ph">${esc(e.group[0])}</span>`}<div class="grow"><div class="t">${esc(e.name)}${e.builtin?'':' <span class="pill">Custom</span>'}</div><div class="s">${esc(e.equip||'')}${e.secondary&&e.secondary.length?' · also '+esc(e.secondary.join(', ')):''}</div></div><span class="muted">›</span></button>`}
function libAccordion(q,opts={}){q=(q||'').trim().toLowerCase();const first=opts.first;const gs=[...GROUPS,...new Set(LIB().map(e=>e.group).filter(g=>!GROUPS.includes(g)))];if(first){gs.splice(gs.indexOf(first),1);gs.unshift(first)}
 const html=gs.map(g=>{const list=LIB().filter(e=>e.group===g&&(!q||e.name.toLowerCase().includes(q)||(e.equip||'').toLowerCase().includes(q)||g.toLowerCase().includes(q))).sort((a,b)=>a.name.localeCompare(b.name));if(!list.length)return '';
  const open=q||(first&&g===first)||(S.libOpen||{})[g];return `<details class="acc" data-g="${g}" ${open?'open':''}><summary><b>${g}</b><span class="muted">${list.length} exercise${list.length===1?'':'s'}</span></summary><div class="list">${list.map(e=>opts.pick?`<button class="item exrow" data-pick="${esc(e.name)}">${e.photo?`<img class="exthumb" src="${e.photo}" alt="">`:`<span class="exthumb ph">${esc(g[0])}</span>`}<div class="grow"><div class="t">${esc(e.name)}</div><div class="s">${esc(e.equip||'')}</div></div><span class="pill">${opts.pickLabel||'Pick'}</span></button>`:exRow(e)).join('')}</div></details>`}).join('');
 return html||'<div class="empty">No exercises match. Add it as a custom exercise.</div>'}
function dateBanner(ds,act){const td=iso(new Date());if(!ds||ds===td)return '';return `<div class="datebanner" role="status"><span>📅 Logging for <b>${new Date(ds+'T12:00').toLocaleDateString(undefined,{weekday:'short',month:'short',day:'numeric'})}</b></span><button class="btn sm" data-act="${act}">Go to today</button></div>`}
function trDayCard(){const td=iso(new Date()),ds=S.trDate||td,ws=D.workouts.filter(w=>w.date===ds),plan=plannedOn(ds);
 return `<div class="card daycard"><div class="row"><button class="icon-btn" data-act="td" data-n="-1" aria-label="Previous day">‹</button><div class="grow" style="text-align:center;font-weight:650">${ds===td?'Today':prettyDate(ds)}</div><button class="icon-btn" data-act="td" data-n="1" aria-label="Next day" ${ds>=td?'disabled':''}>›</button></div>
 ${ws.length?`<div class="list" style="margin-top:8px">${ws.map(w=>`<button class="item linkish" data-act="openw" data-id="${w.id}" style="width:100%;text-align:left"><div class="grow"><div class="t">${esc(w.name)}</div><div class="s">${w.exercises.length} exercises${w.notes?' · 📝 '+esc(w.notes.slice(0,60)):''}</div></div><span class="muted">›</span></button>`).join('')}</div>`:`<p class="muted" style="text-align:center;margin:8px 0">${plan?'Planned: <b>'+esc(plan)+'</b>':'No workout logged'}</p>`}
 <button class="btn block" data-edit data-act="start" data-t="${esc(plan||'')}" style="margin-top:8px">${ds===td?'Start a workout':'Log a workout for this day'}</button></div>`}
function vTrain(){const a=D.active;
 if(a){return `<div class="card"><h2>${esc(a.name)} <small id="elapsed"></small></h2><input data-edit id="sname" value="${esc(a.name)}" aria-label="Session name"><label class="f">Date</label><input data-edit type="date" id="sdate" value="${a.date}" max="${iso(new Date())}" aria-label="Session date">${a.date!==iso(new Date())?`<p class="muted">Logging for <b>${prettyDate(a.date)}</b></p>`:''}<label class="f">Session notes</label><textarea data-edit id="snote" rows="2" placeholder="How did it feel? Energy, pain, PRs…">${esc(a.notes||'')}</textarea></div>
 ${a.exercises.map((e,ei)=>`<div class="card"><h2>${esc(e.name)} <span class="hbtns"><button class="pillbtn sm" data-edit data-act="repl" data-ei="${ei}">⇄ Replace</button><button class="icon-btn" data-edit data-act="rmex" data-ei="${ei}" aria-label="Remove exercise">✕</button></span></h2>
 <div class="muted" style="margin-bottom:4px">${esc(groupOf(e.name))} · ${lastFor(e.name)}</div>
 <div class="set muted" style="font-size:12px"><span class="n">Set</span><span class="n">${U()}</span><span class="n">Reps</span><span></span></div>
 ${e.sets.map((s,si)=>`<div class="set"><span class="n">${si+1}</span><input inputmode="decimal" data-f="w" data-ei="${ei}" data-si="${si}" value="${s.w===''?'':toDisp(s.w)}" aria-label="Weight"><input inputmode="numeric" data-f="r" data-ei="${ei}" data-si="${si}" value="${s.r}" aria-label="Reps"><button class="chk ${s.done?'on':''}" data-act="done" data-ei="${ei}" data-si="${si}" aria-label="Mark set done">✓</button></div>`).join('')}
 <button class="btn ghost sm block" data-act="addset" data-ei="${ei}">＋ Add set</button><textarea data-edit class="exnote" data-exnote="${ei}" rows="1" placeholder="Exercise note (e.g. seat 4, slow eccentric)">${esc(e.note||'')}</textarea></div>`).join('')}
 <button class="btn ghost block" data-act="pickex">＋ Add exercise</button>
 <div class="grid2" style="margin-top:12px"><button class="btn danger" data-act="discard">Discard</button><button class="btn" data-act="finish">Finish workout</button></div>`}
 const sp=Array.isArray(D.split)?D.split:[],nx=splitOf()?splitNext():-1;
 const tpls=D.templates.length?`<div class="list">${D.templates.map((t,i)=>`<div class="item"><button class="grow linkish" data-act="tpl" data-i="${i}"><div class="t">${esc(t.name)}</div><div class="s">${t.exercises.length} exercises · ${esc(t.exercises.slice(0,3).join(' · '))}${t.exercises.length>3?'…':''}</div></button><button class="btn sm" data-edit data-act="start" data-t="${esc(t.name)}">Start</button></div>`).join('')}</div>`
  :`<div class="emptystate"><div class="big">🏋️</div><b>No workouts yet</b><p class="muted">Create your first workout, then add exercises from the library.</p><button class="btn block" data-edit data-act="newtpl">＋ Create workout</button></div>`;
 return dateBanner(S.trDate||iso(new Date()),'tdtoday')+trCalendar()+trDayCard()+`<button class="btn block gohist" data-go="progress">📈 Go to History ›</button><div class="card"><h2>Workouts <small>${D.templates.length}</small></h2>${tpls}${D.templates.length?`<div class="grid2" data-edit style="margin-top:8px"><button class="btn ghost sm" data-act="newtpl">＋ Create workout</button><button class="btn ghost sm" data-act="start" data-t="">Empty session</button></div>`:''}</div>
 <div class="card" id="spliteditor"><h2>Split <small>${sp.length?sp.length+'-day cycle':'not set'}</small></h2><p class="muted" style="margin-top:0">Your split repeats in order, not by weekday. The next day follows the last one you logged.</p>
 <div class="row" style="gap:8px;align-items:center"><label class="f" style="margin:0">Days in cycle</label><select data-splitn ${canEdit()?'':'disabled'}>${Array.from({length:14},(_,i)=>`<option ${sp.length===i+1?'selected':''}>${i+1}</option>`).join('')}</select></div>
 ${sp.length?`<div class="splitgrid">${sp.map((x,i)=>`<label class="${i===nx?'today':''}"><span>Day ${i+1}${i===nx?' · next':''}</span><select data-split="${i}" ${canEdit()?'':'disabled'}><option value="rest">Rest</option>${D.templates.map(t=>`<option ${x===t.name?'selected':''}>${esc(t.name)}</option>`).join('')}</select></label>`).join('')}</div>
 <div class="grid2" data-edit style="margin-top:10px"><button class="btn ghost sm" data-act="splitskip">Skip / mark rest (Day ${nx+1})</button><button class="btn ghost sm" data-act="splitreset">Restart at Day 1</button></div>`:'<p class="muted">Pick how many days your split has, then choose a workout or Rest for each day.</p>'}</div>
 <div class="card"><h2>Exercise library <small>${LIB().length}</small></h2><input id="libq" type="search" placeholder="Search ${LIB().length} exercises" autocomplete="off" value="${esc(S.libQ||'')}"><div id="libacc" class="accwrap">${libAccordion(S.libQ)}</div>
 <button class="btn ghost block" data-edit data-act="exform" style="margin-top:10px">＋ Add custom exercise</button></div>
 <div class="card" data-edit><button class="btn ghost block sm" data-act="clearw">Clear all workouts (start blank)</button></div>`}
function pickExercise({title='Add exercise',first=null,label='Pick'},cb){sheet(`<h3>${esc(title)}</h3>${first?`<p class="muted">${esc(first)} exercises first.</p>`:''}<input id="pq" type="search" placeholder="Search exercises" autocomplete="off"><div id="pacc" class="accwrap">${libAccordion('',{pick:1,first,pickLabel:label})}</div>`,el=>{
 el.querySelector('#pq').oninput=e=>{el.querySelector('#pacc').innerHTML=libAccordion(e.target.value,{pick:1,first,pickLabel:label})};
 el.addEventListener('click',e=>{const b=e.target.closest('[data-pick]');if(b){closeSheet();cb(b.dataset.pick)}})})}
function tplSheet(i){const t=D.templates[i];if(!t)return;const ro=!canEdit();
 sheet(`<h3>${esc(t.name)}</h3><p class="muted">${t.exercises.length} exercises</p><div class="list">${t.exercises.map((n,j)=>`<div class="item"><div class="grow"><div class="t">${esc(n)}</div><div class="s">${esc(groupOf(n))}${t.orig&&t.orig[j]&&t.orig[j]!==n?' · original: '+esc(t.orig[j]):''}</div></div>${ro?'':`<button class="pillbtn sm" data-r="${j}">⇄ Replace</button><button class="icon-btn" data-rm="${j}" aria-label="Remove">✕</button>`}</div>`).join('')||'<div class="empty">No exercises yet</div>'}</div>
 ${ro?'':`<button class="btn ghost block" id="tadd" style="margin-top:8px">＋ Add exercise</button><div class="grid2" style="margin-top:10px"><button class="btn danger" id="tdel">Delete workout</button><button class="btn" id="tstart">Start</button></div>`}`,el=>{
 el.addEventListener('click',e=>{const r=e.target.closest('[data-r]'),rm=e.target.closest('[data-rm]');
  if(r){const j=+r.dataset.r;pickExercise({title:'Replace '+t.exercises[j],first:groupOf(t.exercises[j]),label:'Use'},n=>{save(d=>{d.templates[i].exercises[j]=n;if(d.templates[i].orig)d.templates[i].orig[j]=null},'Replaced with '+n);tplSheet(i)})}
  if(rm){save(d=>{d.templates[i].exercises.splice(+rm.dataset.rm,1);d.templates[i].orig&&d.templates[i].orig.splice(+rm.dataset.rm,1)});tplSheet(i)}});
 el.querySelector('#tadd')&&(el.querySelector('#tadd').onclick=()=>pickExercise({title:'Add to '+t.name,label:'Add'},n=>{save(d=>{d.templates[i].exercises.push(n);d.templates[i].orig&&d.templates[i].orig.push(null)},'Added');tplSheet(i)}));
 el.querySelector('#tdel')&&(el.querySelector('#tdel').onclick=async()=>{if(await ui.confirm({title:'Delete “'+t.name+'”?',message:'The workout is removed and any split days using it become rest days.',action:'Delete'})){save(d=>{d.templates.splice(i,1);d.split=(d.split||[]).map(x=>x===t.name?'rest':x)},'Workout deleted');closeSheet()}});
 el.querySelector('#tstart')&&(el.querySelector('#tstart').onclick=()=>{closeSheet();startSession(t.name)})})}
function exDetail(name){const e=libBy(name);if(!e)return;
 sheet(`${e.photo?`<img class="exphoto" src="${e.photo}" alt="${esc(e.name)}">`:`<div class="exphoto ph">${esc(e.group)}</div>`}<h3>${esc(e.name)}</h3>
 <div class="chips"><span class="chip on">${esc(e.group)}</span>${(e.secondary||[]).map(g=>`<span class="chip">${esc(g)}</span>`).join('')}<span class="chip">${esc(e.equip||'Other')}</span>${e.builtin?'':'<span class="chip">Custom</span>'}</div>
 <p>${esc(e.desc||'No description yet.')}</p><p class="muted">${lastFor(e.name)}</p>
 <div data-edit><label class="f">Add to workout</label><div class="row"><select id="addto">${D.templates.map((t,i)=>`<option value="${i}">${esc(t.name)}</option>`).join('')}${D.active?'<option value="active">Current session</option>':''}<option value="new">＋ New workout…</option></select><button class="btn sm" id="addgo">Add</button></div>
 <div class="grid2" style="margin-top:12px">${e.builtin?'<span></span>':'<button class="btn danger" id="exdel">Delete</button>'}<button class="btn ghost" id="exed">Edit</button></div></div>`,el=>{
 el.querySelector('#exed')&&(el.querySelector('#exed').onclick=()=>exForm(e.name));
 el.querySelector('#exdel')&&(el.querySelector('#exdel').onclick=async()=>{if(await ui.confirm({title:'Delete “'+e.name+'”?',message:'This removes the exercise from your library.',action:'Delete'})){save(d=>{d.lib=d.lib.filter(x=>x!==e&&x.name!==e.name)},'Exercise deleted');closeSheet()}});
 el.querySelector('#addgo')&&(el.querySelector('#addgo').onclick=()=>{const v=el.querySelector('#addto').value;
  if(v==='active'){save(d=>d.active.exercises.push(newEx(e.name)),'Added to session');closeSheet();return}
  if(v==='new'){ui.prompt({title:'New workout',message:'Name the workout. '+e.name+' will be added to it.',placeholder:'e.g. Upper A',action:'Create'}).then(n=>{if(!n||!n.trim())return;save(d=>d.templates.push({name:n.trim(),exercises:[e.name]}),'Created '+n.trim());closeSheet()});return}
  save(d=>d.templates[+v].exercises.push(e.name),'Added to '+D.templates[+v].name);closeSheet()})})}
function resizePhoto(file){return new Promise((res,rej)=>{const img=new Image(),url=URL.createObjectURL(file);img.onload=()=>{const max=480,sc=Math.min(1,max/Math.max(img.width,img.height)),c=document.createElement('canvas');c.width=Math.round(img.width*sc);c.height=Math.round(img.height*sc);c.getContext('2d').drawImage(img,0,0,c.width,c.height);
 let q=.8,d=c.toDataURL('image/jpeg',q);while(d.length>160000&&q>.3){q-=.1;d=c.toDataURL('image/jpeg',q)}URL.revokeObjectURL(url);d.length>160000?rej(new Error('too big')):res(d)};img.onerror=()=>rej(new Error('bad image'));img.src=url})}
function exForm(name){const e=name?libBy(name):null;let photo=e?e.photo||'':'';
 sheet(`<h3>${e?'Edit exercise':'Add exercise'}</h3><label class="f">Name</label><input id="efn" value="${esc(e?e.name:'')}" placeholder="e.g. Cable crossover">
 <div class="grid2"><div><label class="f">Primary muscle</label><select id="efg">${GROUPS.map(g=>`<option ${e&&e.group===g?'selected':''}>${g}</option>`).join('')}</select></div><div><label class="f">Equipment</label><select id="efe">${EQUIP.map(g=>`<option ${e&&e.equip===g?'selected':''}>${g}</option>`).join('')}</select></div></div>
 <label class="f">Secondary muscles (optional)</label><div class="chips" id="efs">${GROUPS.map(g=>`<button class="chip ${e&&(e.secondary||[]).includes(g)?'on':''}" data-g="${g}">${g}</button>`).join('')}</div>
 <label class="f">Description</label><textarea id="efd" rows="3" placeholder="How to do it, cues…">${esc(e?e.desc||'':'')}</textarea>
 <label class="f">Photo</label><div class="row"><div id="efp" class="exthumb big ${photo?'':'ph'}">${photo?`<img src="${photo}" alt="">`:'📷'}</div><label class="btn ghost sm">Choose / take photo<input type="file" accept="image/*" capture="environment" id="eff" hidden></label>${photo?'<button class="btn ghost sm" id="efx">Remove</button>':''}</div>
 <p class="muted" style="font-size:12px">Photos are shrunk to 480 px and saved on this device (max about 120 KB each).</p>
 <button class="btn block" id="efsave" style="margin-top:12px">${e?'Save changes':'Add to library'}</button>`,el=>{
 el.querySelector('#efs').onclick=ev=>{const c=ev.target.closest('[data-g]');if(c)c.classList.toggle('on')};
 el.querySelector('#eff').onchange=async ev=>{const f=ev.target.files[0];if(!f)return;try{photo=await resizePhoto(f);el.querySelector('#efp').className='exthumb big';el.querySelector('#efp').innerHTML=`<img src="${photo}" alt="">`;toast('Photo added')}catch(x){toast('Could not use that photo')}};
 el.querySelector('#efx')&&(el.querySelector('#efx').onclick=()=>{photo='';el.querySelector('#efp').className='exthumb big ph';el.querySelector('#efp').textContent='📷'});
 el.querySelector('#efsave').onclick=()=>{const n=el.querySelector('#efn').value.trim();if(!n)return toast('Name required');const g=el.querySelector('#efg').value;
  if(libBy(n)&&(!e||libBy(n)!==e))return toast('An exercise with that name exists');
  const rec={name:n,group:g,secondary:[...el.querySelectorAll('#efs .chip.on')].map(c=>c.dataset.g).filter(x=>x!==g),equip:el.querySelector('#efe').value,desc:el.querySelector('#efd').value.trim(),photo};
  try{save(d=>{if(e){const x=d.lib.find(z=>z.name===e.name);Object.assign(x,rec);if(e.name!==n){d.templates.forEach(t=>t.exercises=t.exercises.map(z=>z===e.name?n:z))}}else d.lib.push({id:'c'+uid(),...rec,builtin:false});d.exerciseLib=d.lib.map(z=>z.name)},e?'Saved':'Added to library');closeSheet();setTimeout(()=>exDetail(n),50)}catch(x){toast('Storage full. Try a smaller photo')}}})}

function lastFor(name){const w=[...D.workouts].reverse().find(w=>w.exercises.some(e=>e.name===name));if(!w)return 'First time — set a baseline';
 const e=w.exercises.find(e=>e.name===name);return 'Last: '+e.sets.map(s=>toDisp(s.w)+'×'+s.r).join(', ')}
/* ---------- TRAINING CALENDAR ---------- */
const plannedOn=d=>{if(D.schedule&&D.schedule[d]!==undefined)return D.schedule[d]||null;const sp=splitOf();if(!sp)return null;const pj=splitProj(70),i=pj[d];if(i==null)return null;const n=sp[i];return n&&n!=='rest'&&D.templates.some(t=>t.name===n)?n:null};
function trCalendar(){const now=new Date(),m=new Date(now.getFullYear(),now.getMonth()+(S.trMonth||0),1),first=(m.getDay()+6)%7,dim=new Date(m.getFullYear(),m.getMonth()+1,0).getDate(),today=iso(now);
 let cells='';for(let i=0;i<first;i++)cells+='<div class="x"></div>';
 for(let d=1;d<=dim;d++){const ds=iso(new Date(m.getFullYear(),m.getMonth(),d)),logged=D.workouts.some(w=>w.date===ds),plan=ds>=today?plannedOn(ds):null;
  cells+=`<button class="cd ${ds===today?'today':''} ${ds>today?'fut':''}" data-act="calday" data-d="${ds}" aria-label="${ds}${logged?' workout logged':''}${plan?' planned '+esc(plan):''}"><span>${d}</span>${logged?'<i class="dot"></i>':plan?'<i class="ring"></i>':'<i></i>'}${(D.supplements.log[ds]||[]).length?'<b class="smark" title="Supplements taken"></b>':''}</button>`}
 const cnt=D.workouts.filter(w=>w.date.startsWith(iso(m).slice(0,7))).length;
 return `<div class="card"><div class="row"><button class="icon-btn" data-act="trm" data-n="-1" aria-label="Previous month">‹</button><div class="grow" style="text-align:center;font-weight:700">${m.toLocaleDateString('en-CA',{month:'long',year:'numeric'})}</div><button class="icon-btn" data-act="trm" data-n="1" aria-label="Next month">›</button></div>
 <div class="tcal">${['M','T','W','T','F','S','S'].map(x=>`<div class="x muted">${x}</div>`).join('')}${cells}</div>
 <div class="legend"><span><i class="dot"></i>Logged</span><span><i class="ring"></i>Planned</span><span><i class="tsq"></i>Today</span>${D.supplements.list.length?'<span><b class="smark"></b>Supps</span>':''}<span class="muted">${cnt} this month</span></div></div>`}
function daySheet(ds){const today=iso(new Date()),ws=D.workouts.filter(w=>w.date===ds),plan=plannedOn(ds),fut=ds>today,label=new Date(ds+'T12:00').toLocaleDateString('en-CA',{weekday:'long',month:'long',day:'numeric'});
 const opts=D.templates.map(t=>`<option ${plan===t.name?'selected':''}>${esc(t.name)}</option>`).join('');
 sheet(`<h3>${label}</h3>${fut?`<p class="muted">${plan?`Planned: <b>${esc(plan)}</b>`:'Nothing planned'}</p><div data-edit>${D.templates.length?`<label class="f">Schedule a workout</label><select id="dsel">${opts}</select><div class="grid2" style="margin-top:10px"><button class="btn ghost" id="dclr">Clear day</button><button class="btn" id="dsch">Schedule</button></div>`:'<p class="muted">Create a workout first.</p>'}</div>`
  :`${ws.length?`<div class="list">${ws.map(w=>`<button class="item exrow" data-w="${w.id}"><div class="grow"><div class="t">${esc(w.name)}</div><div class="s">${w.exercises.length} exercises · ${vol(w).toLocaleString()} ${U()}</div></div><span class="muted">›</span></button>`).join('')}</div>`:'<p class="muted">No workout logged this day.</p>'}
  <div data-edit><label class="f">Log a workout for this day</label><select id="dsel"><option value="">Empty session</option>${D.templates.map(t=>`<option ${plan===t.name?'selected':''}>${esc(t.name)}</option>`).join('')}</select><button class="btn block" id="dlog" style="margin-top:10px">${D.active?'A session is already in progress':'Start logging'}</button></div>`}`,el=>{
 el.querySelectorAll('[data-w]').forEach(b=>b.onclick=()=>{closeSheet();openWorkout(b.dataset.w)});
 el.querySelector('#dsch')&&(el.querySelector('#dsch').onclick=()=>{save(d=>{d.schedule=d.schedule||{};d.schedule[ds]=el.querySelector('#dsel').value},'Scheduled');closeSheet()});
 el.querySelector('#dclr')&&(el.querySelector('#dclr').onclick=()=>{save(d=>{d.schedule=d.schedule||{};d.schedule[ds]=''},'Day cleared');closeSheet()});
 el.querySelector('#dlog')&&(el.querySelector('#dlog').onclick=()=>{if(D.active)return toast('Finish or discard the current session first');closeSheet();startSession(el.querySelector('#dsel').value,ds)})})}
function openWorkout(id){const w=D.workouts.find(x=>x.id===id);if(!w)return;sheet(`<h3>${esc(w.name)}</h3><p class="muted">${vol(w).toLocaleString()} ${U()} volume</p>
 <div data-edit><label class="f">Date</label><input type="date" id="wdate" value="${w.date}" max="${iso(new Date())}"></div>
 <label class="f">Session notes</label>${canEdit()?`<textarea id="wnote" rows="2" placeholder="Add a note">${esc(w.notes||'')}</textarea>`:`<p>${esc(w.notes||'—')}</p>`}
 ${w.exercises.map((e,ei)=>`<div class="card"><h2>${esc(e.name)}</h2><div class="muted">${e.sets.map(s=>toDisp(s.w)+' × '+s.r).join(' · ')}</div>${canEdit()?`<textarea class="exnote" data-wexnote="${ei}" rows="1" placeholder="Exercise note">${esc(e.note||'')}</textarea>`:(e.note?`<p class="wnote">📝 ${esc(e.note)}</p>`:'')}</div>`).join('')}
 <div class="grid2" data-edit><button class="btn danger" id="delw">Delete</button><button class="btn ghost" id="cl">Close</button></div>${canEdit()?'':'<button class="btn ghost block" id="cl2">Close</button>'}`,el=>{
 el.querySelector('#wnote')&&(el.querySelector('#wnote').onchange=e=>save(d=>{d.workouts.find(x=>x.id===id).notes=e.target.value.trim()},'Note saved'));el.querySelectorAll('[data-wexnote]').forEach(t=>t.onchange=()=>save(d=>{d.workouts.find(x=>x.id===id).exercises[+t.dataset.wexnote].note=t.value.trim()},'Note saved'));
 el.querySelector('#wdate')&&(el.querySelector('#wdate').onchange=e=>{const v=e.target.value;if(!v||v>iso(new Date()))return toast('Pick today or a past date');save(d=>d.workouts.find(x=>x.id===id).date=v,'Date changed')});
 el.querySelector('#cl')&&(el.querySelector('#cl').onclick=closeSheet);el.querySelector('#cl2')&&(el.querySelector('#cl2').onclick=closeSheet);
 el.querySelector('#delw')&&(el.querySelector('#delw').onclick=async()=>{if(await ui.confirm({title:'Delete this workout?',message:'This logged session will be permanently removed.',action:'Delete'})){save(d=>d.workouts=d.workouts.filter(x=>x.id!==id),'Deleted');closeSheet()}})})}
/* ---------- FOOD: scanner + custom food ---------- */
let scanStream=null;
function stopScan(){if(scanStream){scanStream.getTracks().forEach(t=>t.stop());scanStream=null}}
async function lookupBarcode(code){const local=D.foods.find(f=>f.barcode===code);if(local)return {local};
 const r=await fetch(`https://world.openfoodfacts.org/api/v2/product/${code}.json?fields=product_name,brands,nutriments,serving_size,quantity,nutrition_data_per`);const j=await r.json();if(!j.product)throw new Error('nf');const n=j.product.nutriments||{},ser=!!n['energy-kcal_serving'];
 const vol=/\b(ml|cl|l|fl ?oz)\b/i.test(j.product.quantity||'')||/ml/i.test(j.product.serving_size||'')&&!/g\b/i.test(j.product.serving_size||'');
 return {off:{name:[j.product.product_name,j.product.brands&&j.product.brands.split(',')[0]].filter(Boolean).join(' · ')||'Scanned item',kind:'measured',size:100,unit:vol?'ml':'g',serving:vol?'100 ml':'100 g',kcal:Math.round(n['energy-kcal_100g']||0),p:fmtNum(n.proteins_100g||0),c:fmtNum(n.carbohydrates_100g||0),f:fmtNum(n.fat_100g||0),barcode:code}}}
function scanSheet(meal){meal=meal||mealNow();sheet(`<h3>Scan a barcode</h3><div class="scanbox"><video id="sv" playsinline muted></video><div class="scanline"></div></div><p class="muted" id="sst">Starting camera…</p>
 <label class="f">Or type the barcode</label><div class="row"><input id="sc" inputmode="numeric" placeholder="e.g. 737628064502"><button class="btn sm" id="sgo">Look up</button></div><div id="sres"></div>`,async el=>{
 const st=el.querySelector('#sst'),go=async code=>{if(!/^\d{6,14}$/.test(code))return toast('Enter a valid barcode');el.querySelector('#sc').value=code;st.textContent='Looking up '+code+'…';
  try{const r=await lookupBarcode(code);stopScan();if(r.local){st.textContent='Found in Food archive';el.querySelector('#sres').innerHTML=`<div class="card"><b>${esc(r.local.name)}</b><div class="muted">${r.local.kcal} kcal · P${r.local.p} C${r.local.c} F${r.local.f}</div><button class="btn block" id="slog" style="margin-top:8px">＋ Log to ${meal}</button></div>`;el.querySelector('#slog').onclick=()=>{closeSheet();logAsk(r.local.id,meal)}}
   else{st.textContent='Found on Open Food Facts. Check the numbers, then save.';closeSheet();customFoodSheet(r.off,meal)}}catch(x){st.textContent='Not found (or offline). You can add it as a custom food.';el.querySelector('#sres').innerHTML=`<button class="btn ghost block" id="scust">＋ Add as custom food</button>`;el.querySelector('#scust').onclick=()=>{closeSheet();customFoodSheet({barcode:code},meal)}}};
 el.querySelector('#sgo').onclick=()=>go(el.querySelector('#sc').value.trim());
 const bg=el.closest('.sheet-bg');bg.addEventListener('click',e=>{if(e.target===bg)stopScan()});
 try{if(!navigator.mediaDevices?.getUserMedia)throw 0;scanStream=await navigator.mediaDevices.getUserMedia({video:{facingMode:'environment'}});const v=el.querySelector('#sv');v.srcObject=scanStream;await v.play();
  if('BarcodeDetector' in window){st.textContent='Point the camera at a barcode';const det=new BarcodeDetector({formats:['ean_13','ean_8','upc_a','upc_e','code_128']});const loop=async()=>{if(!scanStream||!document.body.contains(v))return stopScan();try{const c=await det.detect(v);if(c&&c[0])return go(c[0].rawValue)}catch(_){}requestAnimationFrame(loop)};loop()}
  else st.textContent='This browser can show the camera but can’t read barcodes live (iPhone Safari). Type the number below.'}catch(x){st.textContent='Camera not available or blocked. Type the barcode below.';el.querySelector('.scanbox').style.display='none'}})}
const mealNow=()=>{const day=D.food[S.foodDate||iso(new Date())]||[];return MEALS.find(m=>!day.some(e=>e.meal===m))||MEALS[MEALS.length-1]};
function logFood(fid,meal,e){e=typeof e==='object'&&e?e:{q:e||1};save(d=>{(d.food[S.foodDate]=d.food[S.foodDate]||[]).push(Object.assign({fid,meal},e))},'Added to '+MLBL(meal))}
function logAsk(fid,meal){amountSheet(fid,{cta:'Log to '+MLBL(meal)},e=>logFood(fid,meal,e))}
function customFoodSheet(pre={},meal){pre=pre||{};const ed=pre.id&&D.foods.find(f=>f.id===pre.id);const p0=pre.name?normFood(pre):Object.assign({kind:'item'},pre);let kind=p0.kind||'item';
 sheet(`<h3>${ed?'Edit food':'Add to food archive'}</h3><p class="muted">Saved to <b>Food archive</b> so you can search and log it any time.</p>
 <label class="f">Name</label><input id="cn" value="${esc(pre.name||'')}" placeholder="e.g. Banana or Greek yogurt">
 <label class="f">Food type</label><div class="seg" id="ckind"><button data-k="item" class="${kind==='item'?'on':''}">Whole item</button><button data-k="measured" class="${kind==='measured'?'on':''}">Measured</button></div>
 <p class="muted" id="ckhint"></p>
 <div id="cmeas"><label class="f">Label serving size</label><div class="row" style="gap:8px"><input id="csz" inputmode="decimal" value="${p0.size??100}" style="flex:1"><select id="cun" style="width:110px">${UNIT_LIST.map(u=>`<option ${u===(p0.unit||'g')?'selected':''}>${u}</option>`).join('')}</select></div></div>
 <div class="grid2"><div><label class="f">Calories (kcal)</label><input id="ck" inputmode="decimal" value="${pre.kcal??''}"></div><div><label class="f">Protein (g)</label><input id="cp" inputmode="decimal" value="${pre.p??''}"></div><div><label class="f">Carbs (g)</label><input id="cc" inputmode="decimal" value="${pre.c??''}"></div><div><label class="f">Fat (g)</label><input id="cf" inputmode="decimal" value="${pre.f??''}"></div></div>
 <label class="f">Barcode (optional)</label><input id="cb" inputmode="numeric" value="${esc(pre.barcode||'')}" placeholder="Scan or type">
 <div class="grid2" style="margin-top:12px"><button class="btn ghost" id="csave">Save to Food archive</button><button class="btn" id="clog">Save & log${meal?' to '+MLBL(meal):''}</button></div>`,el=>{const $$=i=>el.querySelector(i);
 const sync=()=>{el.querySelectorAll('#ckind button').forEach(b=>b.classList.toggle('on',b.dataset.k===kind));$$('#cmeas').style.display=kind==='measured'?'':'none';$$('#ckhint').textContent=kind==='measured'?`Nutrition for the label serving (e.g. per 100 g). When logging you enter the exact amount eaten and it scales.`:'Nutrition for 1 whole item. You log a count (1, 2, 3…).'};
 $$('#ckind').onclick=e=>{const b=e.target.closest('[data-k]');if(b){kind=b.dataset.k;sync()}};sync();
 const make=()=>{const n=$$('#cn').value.trim();if(!n){toast('Name required');return null}const num=q=>Math.max(0,+$$(q).value||0),bc=$$('#cb').value.trim();if(bc&&!/^\d{6,14}$/.test(bc)){toast('Barcode should be 6–14 digits');return null}
  const sz=num('#csz'),un=$$('#cun').value;if(kind==='measured'&&!sz){toast('Enter the label serving size');return null}
  const body={name:n,kind,size:kind==='measured'?sz:undefined,unit:kind==='measured'?un:undefined,serving:kind==='measured'?`${fmtNum(sz)} ${un}`:'1 item',kcal:num('#ck'),p:num('#cp'),c:num('#cc'),f:num('#cf'),barcode:bc||undefined};
  const id=ed?ed.id:'f'+uid();if(ed){save(d=>{const f=d.foods.find(x=>x.id===id);Object.assign(f,body);if(kind==='item'){delete f.size;delete f.unit}},'Food updated');return id}save(d=>d.foods.push(Object.assign({id,custom:true},body)),'Saved to Food archive');return id};
 $$('#csave').onclick=()=>{if(make())closeSheet()};$$('#clog').onclick=()=>{const id=make();if(id){closeSheet();logAsk(id,meal||mealNow())}}})}

function startSession(tname,date){const t=D.templates.find(x=>x.name===tname);
 save(d=>{d.active={id:'w'+uid(),date:date||iso(new Date()),start:Date.now(),name:t?t.name:'Workout',exercises:(t?t.exercises:[]).map(n=>newEx(n))}},'Session started');goPage('train')}
function newEx(n){const w=[...D.workouts].reverse().find(w=>w.exercises.some(e=>e.name===n));const prev=w&&w.exercises.find(e=>e.name===n);
 return {name:n,sets:prev?prev.sets.map(s=>({w:s.w,r:s.r,done:false})):[{w:'',r:8,done:false},{w:'',r:8,done:false},{w:'',r:8,done:false}]}}
let restT=null;
function restTimer(sec=90){clearInterval(restT);let left=sec;const tick=()=>{toast(left>0?`Rest ${Math.floor(left/60)}:${String(left%60).padStart(2,'0')}`:'Rest over — next set');if(left--<=0){clearInterval(restT);navigator.vibrate?.(200)}};tick();restT=setInterval(tick,1000)}

/* ---------- FOOD ---------- */
function vFood(){return dateBanner(S.foodDate,'fdtoday')+`<div class="quick3"><button class="btn scanbtn" data-edit data-act="scan">▥ Scan barcode</button><button class="btn ghost" data-edit data-act="customfood">＋ Custom food</button></div><button class="btn block gohist" data-go="progress">📈 Go to History ›</button><div class="seg">${[['log','Today'],['archive','Food archive'],['plan','Saved meals']].map(([k,n])=>`<button class="${S.foodSeg===k?'on':''}" data-seg="foodSeg" data-v="${k}">${n}</button>`).join('')}</div>`+
 (S.foodSeg==='log'?vFoodLog():S.foodSeg==='plan'?vSaved():vArchive())}
const MEALS=[];const slots=()=>(D.mealSlots&&D.mealSlots.length?D.mealSlots:[{id:'m1',name:'Meal 1'},{id:'m2',name:'Meal 2'},{id:'m3',name:'Meal 3'}]);
function syncMeals(){MEALS.length=0;slots().forEach(x=>MEALS.push(x.id))}
const MLBL=m=>{const x=slots().find(z=>z.id===m);return x?x.name:(m||'Meal')};
/* migrate fixed Breakfast/Lunch/Dinner/Snacks to Meal 1-4 */
function migrateMeals(d){if(d.mealSlots&&d.mealSlots.length)return false;const MAP={Breakfast:'m1',Lunch:'m2',Dinner:'m3',Snack:'m4'};let snack=false;
 Object.values(d.food||{}).forEach(day=>(day||[]).forEach(e=>{if(MAP[e.meal]){if(e.meal==='Snack')snack=true;e.meal=MAP[e.meal]}}));
 d.mealSlots=[{id:'m1',name:'Meal 1'},{id:'m2',name:'Meal 2'},{id:'m3',name:'Meal 3'}].concat(snack?[{id:'m4',name:'Meal 4'}]:[]);delete d.mealPlan;return true}
const SM=()=>D.savedMeals||[];
function vFoodLog(){const day=D.food[S.foodDate]||[],t=totals(day),g=goalFor(S.foodDate);
 return `<div class="card"><div class="row"><button class="icon-btn" data-act="fd" data-n="-1" aria-label="Previous day">‹</button><div class="grow" style="text-align:center;font-weight:650">${S.foodDate===iso(new Date())?'Today':prettyDate(S.foodDate)}</div><button class="icon-btn" data-act="fd" data-n="1" aria-label="Next day">›</button></div>
 <button class="goalbtn" data-act="goals" data-d="${S.foodDate}" aria-label="Edit daily goals"><span class="pencil">✎ Goals</span><div class="row" style="margin-top:12px">${ring(t.kcal,g.kcal,'kcal',96)}<div class="grow">${macroBars(t,g)}</div></div></button></div>
 ${MEALS.map(m=>{const items=day.map((e,i)=>({...e,i})).filter(e=>e.meal===m),mt=totals(items);return `<div class="card mealcard"><h2><button class="mealname" data-edit data-act="mealmenu" data-meal="${m}">${esc(MLBL(m))} <span class="muted">⋯</span></button> <small>${Math.round(mt.kcal)} kcal</small></h2><div class="list">${items.map(e=>{const f=food(e.fid);return `<div class="item"><div class="grow"><div class="t">${esc(f.name)}${amtTxt(e)}</div><div class="s">${Math.round(f.kcal*entryQ(f,e))} kcal · P${Math.round(f.p*entryQ(f,e))} C${Math.round(f.c*entryQ(f,e))} F${Math.round(f.f*entryQ(f,e))}</div></div><button class="icon-btn" data-edit data-act="rmfood" data-i="${e.i}" aria-label="Remove">✕</button></div>`}).join('')||'<div class="muted">Nothing logged</div>'}</div>
 <div class="mealbtns" data-edit><button class="btn addfood" data-act="addfood" data-meal="${m}">＋ Add food</button><button class="btn ghost scanmini" data-act="scan" data-meal="${m}" aria-label="Scan barcode for ${MLBL(m)}">▥</button></div>
 ${SM().length?`<div class="smchips" data-edit>${SM().map((x,j)=>`<button class="chip" data-act="logsaved" data-j="${j}" data-meal="${m}">⚡ ${esc(x.name)}</button>`).join('')}</div>`:''}${items.length?`<button class="linkbtn" data-edit data-act="savemeal" data-meal="${m}">Save as meal…</button>`:''}</div>`}).join('')}<button class="btn ghost block addmeal" data-edit data-act="addmeal">＋ Add meal</button>`}
const ARCH=()=>D.foods.filter(f=>f.custom);
function vArchive(){const q=(S.archQ||'').toLowerCase(),L=ARCH().filter(f=>f.name.toLowerCase().includes(q)||(f.barcode||'').includes(q));
 return `<div class="card"><h2>Food archive <small>${ARCH().length} foods</small></h2><p class="muted" style="margin-top:0">Your personal food list. Scan a barcode or add one manually, then log it in one tap.</p>
 <div class="grid2" data-edit><button class="btn" data-act="scan">▥ Scan to archive</button><button class="btn ghost" data-act="customfood">＋ Add manually</button></div>
 <input id="archq" type="search" placeholder="Search your archive" value="${esc(S.archQ||'')}" style="margin-top:10px" autocomplete="off"></div>
 <div class="card"><div class="list">${L.map(f=>`<div class="item"><div class="grow"><div class="t">${esc(f.name)}</div><div class="s">${(()=>{const n=normFood(f);return n.kind==='measured'?'per '+fmtNum(n.size)+' '+n.unit:'per item'})()} · ${Math.round(f.kcal)} kcal · P${r1(f.p)} C${r1(f.c)} F${r1(f.f)}${f.barcode?' · ▥ '+esc(f.barcode):''}</div></div><button class="btn sm" data-edit data-act="archlog" data-fid="${f.id}">＋ Log</button><button class="icon-btn" data-edit data-act="archedit" data-fid="${f.id}" aria-label="Edit">✎</button><button class="icon-btn" data-edit data-act="archdel" data-fid="${f.id}" aria-label="Delete">🗑</button></div>`).join('')||`<div class="emptystate"><div class="big">🗂️</div><b>${ARCH().length?'No matches':'Your archive is empty'}</b><p class="muted">${ARCH().length?'Try a different search.':'Scan a barcode or add a food manually to start your list.'}</p></div>`}</div></div>`}
function vSaved(){const L=SM();
 return `<div class="card"><h2>Saved meals <small>optional</small></h2><p class="muted" style="margin-top:0">Save foods you often eat together, then log them in one tap from any meal on Today.</p><button class="btn block" data-edit data-act="newsaved">＋ New saved meal</button></div>
 ${L.length?L.map((x,j)=>{const t=totals(x.items);return `<div class="card"><h2>${esc(x.name)} <small>${Math.round(t.kcal)} kcal · P${Math.round(t.p)}</small></h2><div class="list">${x.items.map((e,i)=>{const f=food(e.fid);return `<div class="item"><div class="grow"><div class="t">${esc(f.name)}${amtTxt(e)}</div><div class="s">${Math.round(f.kcal*entryQ(f,e))} kcal</div></div><button class="icon-btn" data-edit data-act="sqedit" data-j="${j}" data-i="${i}" aria-label="Edit amount">✎</button><button class="icon-btn" data-edit data-act="rmsaveditem" data-j="${j}" data-i="${i}" aria-label="Remove">✕</button></div>`}).join('')||'<div class="muted">No foods yet</div>'}</div>
 <div class="grid2" data-edit style="margin-top:8px"><button class="btn" data-act="logsaved" data-j="${j}">Log now</button><button class="btn ghost" data-act="addfood" data-meal="${MEALS[0]}" data-plan="s${j}">＋ Add food</button></div><div class="row" style="gap:16px"><button class="linkbtn" data-edit data-act="renamesaved" data-j="${j}">Rename</button><button class="linkbtn" data-edit data-act="delsaved" data-j="${j}">Delete meal</button></div></div>`}).join(''):'<div class="emptystate"><div class="big">🍱</div><b>No saved meals</b><p class="muted">Tip: log a meal on Today, then tap “Save as meal…”.</p></div>'}`}
function pantryStep(p){return p.unit==='g'?100:1}
function foodSheet(meal,plan){meal=meal&&MEALS.includes(meal)?meal:mealNow();
 const sv=!plan;sheet(`<h3>${plan?'Add to saved meal':'Add food'}</h3><div class="seg" id="msel" ${plan?'style="display:none"':''}>${MEALS.map(m=>`<button class="${m===meal?'on':''}" data-m="${m}">${MLBL(m)}</button>`).join('')}</div>
 ${sv?`<div class="seg ftabs" id="ftab"><button class="on" data-ft="foods">Foods</button><button data-ft="saved">Saved meals${SM().length?' ('+SM().length+')':''}</button></div>`:''}
 <div id="fpfoods"><div class="grid2" style="margin-bottom:10px"><button class="btn scanbtn" id="fscan">▥ Scan barcode</button><button class="btn ghost" id="fcust">＋ Add to archive</button></div>
 <input id="fq" placeholder="Search your archive and food database" autocomplete="off"><div class="list" id="fres" style="margin-top:6px"></div></div>
 ${sv?`<div id="fpsaved" style="display:none"><div class="list">${SM().map((x,j)=>{const t=totals(x.items);return `<div class="item"><div class="grow"><div class="t">${esc(x.name)}</div><div class="s">${x.items.length} food${x.items.length===1?'':'s'} · ${Math.round(t.kcal)} kcal · P${Math.round(t.p)}</div></div><button class="btn sm" data-slog="${j}">＋ Log</button></div>`}).join('')||'<div class="emptystate"><div class="big">🍱</div><b>No saved meals yet</b><p class="muted">Create one in Food › Saved meals, or log foods then tap “Save as meal…”.</p></div>'}</div><button class="btn ghost block sm" id="fnewsm" style="margin-top:10px">＋ New saved meal</button></div>`:''}
`,el=>{
  const ft=el.querySelector('#ftab');if(ft)ft.onclick=e=>{const b=e.target.closest('[data-ft]');if(!b)return;ft.querySelectorAll('button').forEach(x=>x.classList.toggle('on',x===b));el.querySelector('#fpfoods').style.display=b.dataset.ft==='foods'?'':'none';el.querySelector('#fpsaved').style.display=b.dataset.ft==='saved'?'':'none'};
  el.querySelectorAll('[data-slog]').forEach(b=>b.onclick=()=>{const x=SM()[+b.dataset.slog];if(!x.items.length)return toast('This saved meal is empty');save(d=>{const t=S.foodDate||iso(new Date());d.food[t]=d.food[t]||[];x.items.forEach(e=>d.food[t].push(Object.assign({},e,{meal})))},`Logged ${x.name} to ${MLBL(meal)}`);closeSheet()});
  const nb=el.querySelector('#fnewsm');if(nb)nb.onclick=()=>{closeSheet();S.foodSeg='plan';drawOV&&OV&&drawOV();document.querySelector('[data-act="newsaved"]')&&document.querySelector('[data-act="newsaved"]').click()};
  el.querySelector('#fscan').onclick=()=>{closeSheet();scanSheet(meal)};el.querySelector('#fcust').onclick=()=>{closeSheet();customFoodSheet({},plan?null:meal)};
  const draw=()=>{const q=el.querySelector('#fq').value.toLowerCase();el.querySelector('#fres').innerHTML=[...D.foods].sort((a,b)=>(b.custom?1:0)-(a.custom?1:0)).filter(f=>f.name.toLowerCase().includes(q)).map(f=>`<button class="item" style="background:none;border-left:0;border-right:0;border-bottom:0;width:100%;text-align:left;cursor:pointer" data-fid="${f.id}"><div class="grow"><div class="t">${esc(f.name)}</div><div class="s">${f.custom?'Archive · ':''}${f.serving?esc(f.serving)+' · ':''}${f.kcal} kcal · P${f.p} C${f.c} F${f.f}</div></div><span class="pill">＋</span></button>`).join('')||'<div class="empty">No match. Add a custom food below.</div>'};
  draw();el.querySelector('#fq').oninput=draw;
  el.querySelector('#msel').onclick=e=>{const b=e.target.closest('button');if(!b)return;meal=b.dataset.m;el.querySelectorAll('#msel button').forEach(x=>x.classList.toggle('on',x===b))};
  const add=fid=>{closeSheet();const toSaved=plan&&String(plan)[0]==='s';amountSheet(fid,{cta:toSaved?'Add to saved meal':'Log to '+MLBL(meal)},e=>save(d=>{if(toSaved){const sm=(d.savedMeals||[])[+String(plan).slice(1)];if(sm)sm.items.push(Object.assign({fid},e))}else{(d.food[S.foodDate]=d.food[S.foodDate]||[]).push(Object.assign({fid,meal},e))}},toSaved?'Added to saved meal':`Added to ${MLBL(meal)}`))};
  el.querySelector('#fres').onclick=e=>{const b=e.target.closest('[data-fid]');if(b)add(b.dataset.fid)};
 })}

/* ---------- PROGRESS ---------- */
function vProgress(){if(!(D.workouts.length||Object.values(D.food).some(a=>a&&a.length)||D.sleep.length||D.weight.length))return `<div class="card"><div class="emptystate"><div class="big">📈</div><b>No history yet</b><p class="muted">Your lifts, food, sleep and weight trends build up here as you log.</p><button class="btn block" data-go="train">Log a workout</button><button class="btn ghost block" style="margin-top:8px" data-go="food">Log food</button><button class="btn ghost block" style="margin-top:8px" data-go="recovery">Log sleep or weight</button></div></div>`;return `<div class="seg">${[['lifts','Lifts'],['sessions','Sessions'],['food','Food'],['body','Body'],['cal','Calendar']].map(([k,n])=>`<button class="${S.progSeg===k?'on':''}" data-seg="progSeg" data-v="${k}">${n}</button>`).join('')}</div>`+(S.progSeg==='lifts'?vLifts():S.progSeg==='sessions'?vSessions():S.progSeg==='food'?foodCharts():S.progSeg==='body'?vBody():vCal())}
function vSessions(){const L=[...D.workouts].sort((a,b)=>b.date.localeCompare(a.date));if(!L.length)return '<div class="card"><div class="emptystate"><div class="big">🏋️</div><b>No sessions yet</b><button class="btn block" data-go="train">Log a workout</button></div></div>';
 return `<div class="card"><h2>Sessions <small>${L.length}</small></h2><div class="list">${L.slice(0,S.sessAll?999:15).map(w=>{const en=w.exercises.filter(e=>e.note);return `<button class="item linkish" data-act="openw" data-id="${w.id}" style="width:100%;text-align:left;display:block"><div class="t">${esc(w.name)} <span class="muted" style="font-weight:400">· ${prettyDate(w.date)}</span></div><div class="s">${w.exercises.length} exercises · ${vol(w).toLocaleString()} ${U()}</div>${w.notes?`<div class="wnote">📝 ${esc(w.notes)}</div>`:''}${en.map(e=>`<div class="wnote sub">• ${esc(e.name)}: ${esc(e.note)}</div>`).join('')}</button>`}).join('')}</div>${L.length>15&&!S.sessAll?'<button class="btn ghost block sm" data-act="sessall">Show all</button>':''}</div>`}
const FCM=[['kcal','Calories','kcal'],['p','Protein','g'],['c','Carbs','g'],['f','Fat','g']];
function foodCharts(compact){const r=S.fcRange||'7',m=S.fcMetric||'kcal',[,mn,mu]=FCM.find(x=>x[0]===m),td=iso(new Date());
 const seg=`<div class="seg fcseg">${[['7','7 days'],['30','30 days'],['90','90 days'],['month','Month']].map(([k,n])=>`<button class="${r===k?'on':''}" data-act="fcr" data-v="${k}">${n}</button>`).join('')}</div><div class="seg fcseg">${FCM.map(([k,n])=>`<button class="${m===k?'on':''}" data-act="fcm" data-v="${k}">${n}</button>`).join('')}</div>`;
 const val=d=>{const l=D.food[d]||[];return l.length?totals(l)[m]:null};
 if(r==='month'){const now=new Date(),mo=new Date(now.getFullYear(),now.getMonth()+(S.fcMonth||0),1),first=(mo.getDay()+6)%7,dim=new Date(mo.getFullYear(),mo.getMonth()+1,0).getDate();let cells='',hit=0,logged=0,sum=0;
  for(let i=0;i<first;i++)cells+='<div></div>';for(let d=1;d<=dim;d++){const ds=iso(new Date(mo.getFullYear(),mo.getMonth(),d)),v=val(ds),g=goalFor(ds)[m];let cls='';if(v!=null){logged++;sum+=v;const q=v/g;cls=q<.9?'lo':q>1.1?'hi':'ok';if(cls==='ok')hit++}
   cells+=`<div class="fmc ${cls} ${ds===td?'today':''}" title="${ds}: ${v==null?'nothing logged':Math.round(v)+' / '+g+' '+mu}"><span>${d}</span><b>${v==null?'':Math.round(v)}</b></div>`}
  return `<div class="card">${compact?'':`<h2>Food history</h2>`}${seg}<div class="row" style="margin:8px 0"><button class="icon-btn" data-act="fcmo" data-n="-1" aria-label="Previous month">‹</button><div class="grow" style="text-align:center;font-weight:700">${mo.toLocaleDateString(undefined,{month:'long',year:'numeric'})}</div><button class="icon-btn" data-act="fcmo" data-n="1" aria-label="Next month" ${(S.fcMonth||0)>=0?'disabled':''}>›</button></div>
  <div class="fmgrid">${['M','T','W','T','F','S','S'].map(x=>`<div class="muted" style="text-align:center;font-size:11px">${x}</div>`).join('')}${cells}</div><div class="legend"><span><i class="fl ok"></i>On goal ±10%</span><span><i class="fl lo"></i>Under</span><span><i class="fl hi"></i>Over</span></div>
  <div class="grid2" style="margin-top:8px"><div class="stat"><b>${logged?Math.round(sum/logged):'—'} ${mu}</b><span>Avg ${mn.toLowerCase()} (logged days)</span></div><div class="stat"><b>${hit}/${logged}</b><span>Days on goal</span></div></div></div>`}
 const n=+r,pts=[];for(let i=n-1;i>=0;i--){const d=dayOff(-i),v=val(d);pts.push({x:n<=7?new Date(d+'T12:00').toLocaleDateString(undefined,{weekday:'narrow'}):(i%(n<=30?5:15)===0?d.slice(5):''),y:Math.round(v||0),g:goalFor(d)[m],d})}
 const lg=pts.filter(p=>D.food[p.d]&&D.food[p.d].length),avgV=lg.length?Math.round(lg.reduce((a,p)=>a+p.y,0)/lg.length):null,on=lg.filter(p=>Math.abs(p.y/p.g-1)<=.1).length;
 return `<div class="card">${compact?'':`<h2>Food history</h2>`}${seg}<div style="margin-top:8px">${barChart(pts,{h:compact?120:150})}</div><p class="muted" style="margin:4px 0 0;font-size:12px">Bars: ${mn.toLowerCase()} eaten · tick: that day’s goal</p>
 <div class="grid2" style="margin-top:8px"><div class="stat"><b>${avgV==null?'—':avgV+' '+mu}</b><span>Avg on logged days</span></div><div class="stat"><b>${on}/${lg.length}</b><span>Days within 10% of goal</span></div></div></div>`}
function vLifts(){const names=[...new Set(D.workouts.flatMap(w=>w.exercises.map(e=>e.name)))];if(!names.includes(S.liftEx))S.liftEx=names[0]||'';
 const hist=D.workouts.filter(w=>w.exercises.some(e=>e.name===S.liftEx)).sort((a,b)=>a.date.localeCompare(b.date)).map(w=>{const e=w.exercises.find(e=>e.name===S.liftEx);const best=e.sets.reduce((m,s)=>Math.max(m,epley(toDisp(+s.w||0),s.r)),0);const top=e.sets.reduce((m,s)=>Math.max(m,toDisp(+s.w||0)),0);return {x:w.date.slice(5),y:Math.round(best),top}});
 const pr=hist.reduce((m,h)=>Math.max(m,h.y),0),topW=hist.reduce((m,h)=>Math.max(m,h.top),0);
 const weeks=[];for(let i=5;i>=0;i--){const end=new Date();end.setDate(end.getDate()-i*7);const st=new Date(end);st.setDate(st.getDate()-7);weeks.push({x:'W-'+i,y:D.workouts.filter(w=>{const d=new Date(w.date+'T12:00');return d>st&&d<=end}).reduce((a,w)=>a+vol(w),0)})}weeks[5].x='Now';
 return `<div class="card"><h2>Exercise</h2><select id="liftsel" aria-label="Exercise">${names.map(n=>`<option ${n===S.liftEx?'selected':''}>${esc(n)}</option>`).join('')}</select>
 <div class="grid2" style="margin-top:10px"><div class="stat"><b>${pr} ${U()}</b><span>Best est. 1RM</span></div><div class="stat"><b>${topW} ${U()}</b><span>Heaviest set</span></div></div></div>
 <div class="card"><h2>Estimated 1RM <small>Epley</small></h2>${lineChart(hist)}</div>
 <div class="card"><h2>Weekly volume <small>${U()}</small></h2>${barChart(weeks)}</div>`}
function vBody(){const w=D.weight.slice(-14).map(x=>({x:x.date.slice(5),y:toDisp(x.kg)})),s=D.sleep.slice(-10).map(x=>({x:x.date.slice(8),y:x.hours}));
 const k=[];for(let i=-6;i<=0;i++){const d=dayOff(i);k.push({x:new Date(d+'T12:00').toLocaleDateString(undefined,{weekday:'narrow'}),y:Math.round(totals(D.food[d]||[]).kcal),g:goalFor(d).kcal})}
 const avgS=D.sleep.slice(-7).reduce((a,x)=>a+x.hours,0)/Math.max(1,D.sleep.slice(-7).length);
 return `<div class="card"><h2>Body weight <small>${U()}</small></h2>${lineChart(w,{color:'var(--accent2)'})}</div>
 <div class="card"><h2>Sleep <small>7-day avg ${avgS.toFixed(1)} h</small></h2>${barChart(s,{goal:P().sleepGoal})}</div>`}
function vCal(){const now=new Date();const m=new Date(now.getFullYear(),now.getMonth()+S.calMonth,1);const first=(m.getDay()+6)%7,dim=new Date(m.getFullYear(),m.getMonth()+1,0).getDate();
 const wd=new Set(D.workouts.map(w=>w.date));let cells='';for(let i=0;i<first;i++)cells+='<div class="x"></div>';
 for(let d=1;d<=dim;d++){const ds=iso(new Date(m.getFullYear(),m.getMonth(),d));cells+=`<div class="${wd.has(ds)?'w':''}">${d}</div>`}
 const count=D.workouts.filter(w=>w.date.startsWith(iso(m).slice(0,7))).length;
 return `<div class="card"><div class="row"><button class="icon-btn" data-act="cm" data-n="-1" aria-label="Previous month">‹</button><div class="grow" style="text-align:center;font-weight:650">${m.toLocaleDateString(undefined,{month:'long',year:'numeric'})}</div><button class="icon-btn" data-act="cm" data-n="1" aria-label="Next month">›</button></div>
 <div class="month" style="margin-top:12px">${['M','T','W','T','F','S','S'].map(x=>`<div class="x muted">${x}</div>`).join('')}${cells}</div><p class="muted">${count} workout${count===1?'':'s'} this month</p></div>`}

/* ---------- ME ---------- */
function accountCard(){const S_=window.SYNC?SYNC.state:{status:'signedout'},u=S_.user;
 const stx={signedout:'Not signed in · data stays on this device',syncing:'Syncing…',synced:'Synced'+(S_.at?' at '+new Date(S_.at).toLocaleTimeString([], {hour:'2-digit',minute:'2-digit'}):''),error:'Sync problem'}[S_.status]||'';
 if(u)return `<div class="card" id="acct"><h2>Account <small class="syncst ${S_.status}">● ${esc(stx)}</small></h2><div class="item"><div class="avatar" style="width:40px;height:40px;display:flex;align-items:center;justify-content:center">${esc((u.name||u.email||'?')[0].toUpperCase())}</div><div class="grow"><div class="t">${esc(u.name||u.email||'Signed in')}</div><div class="s">${esc(u.email||'')}</div></div></div>
  ${S_.err?`<p class="muted" style="color:#ff3b30">${esc(S_.err)}</p>`:''}<div class="grid2" style="margin-top:8px"><button class="btn ghost" data-act="ssync">Sync now</button><button class="btn ghost" data-act="sout">Sign out</button></div><p class="muted">Changes sync automatically across devices signed in to this account. The newest change to each item wins.</p></div>`;
 return `<div class="card" id="acct"><h2>Account <small class="syncst ${S_.status}">● ${esc(stx)}</small></h2><p class="muted" style="margin-top:0">Sign in to back up your data and sync it across devices. Anything already on this device is merged in.</p>
  <button class="btn block gbtn" data-act="sgoogle"><b>G</b> Continue with Google</button>
  <label class="f">Email</label><input id="semail" type="email" autocomplete="email" placeholder="you@example.com"><label class="f">Password</label><input id="spass" type="password" autocomplete="current-password" placeholder="At least 6 characters">
  <div class="grid2" style="margin-top:10px"><button class="btn" data-act="semail">Sign in</button><button class="btn ghost" data-act="screate">Create account</button></div><button class="linkbtn" data-act="sreset">Forgot password?</button>
  ${S_.err?`<p class="muted" style="color:#ff3b30">${esc(S_.err)}</p>`:''}</div>`}
function vMe(){const p=P(),u=DB.currentUser(),t=p.targets;
 return `<div class="verlbl">Preview ${PREVIEW_VER}</div><div class="card"><h2>Appearance</h2><div class="seg">${[['light','Light'],['dark','Dark'],['auto','Auto']].map(([k,n])=>`<button class="${TH.mode===k?'on':''}" data-act="thmode" data-v="${k}">${n}</button>`).join('')}</div>
 <label class="f">Colourway</label><div class="cwgrid">${CW_ORDER.map(k=>{const c=CW[k],dk=document.documentElement.dataset.theme==='dark',v=dk?c.Dk:c.L;return `<button class="cw ${TH.cw===k?'on':''}" data-act="cw" data-v="${k}" style="background:${v.bg};color:${v.fg};font-family:${c.fh}"><span class="sw"><i style="background:${v.a}"></i><i style="background:${v.a2}"></i><i style="background:${v.a3}"></i></span><b>${esc(c.n)}</b></button>`}).join('')}</div>
 <p class="muted">Saved on this device. Auto follows your iPhone's light/dark setting.</p></div>
 <div class="card"><h2>Home screen</h2><button class="btn ghost block" data-act="editmode">Edit widgets</button><button class="btn ghost block" style="margin-top:8px" data-act="resetlayout">Reset home screen to default</button></div>
 ${accountCard()}
 <div class="card"><h2>Profile</h2><label class="f">Name</label><input data-p="name" value="${esc(p.name)}" ${canEdit()?'':'disabled'}>
 <label class="f">Goal</label><select data-p="goal" ${canEdit()?'':'disabled'}>${['Build muscle','Lose fat','Get stronger','Stay healthy'].map(g=>`<option ${g===p.goal?'selected':''}>${g}</option>`).join('')}</select>
 <div class="grid2"><div><label class="f">Units</label><select data-p="units" ${canEdit()?'':'disabled'}><option value="kg" ${p.units==='kg'?'selected':''}>kg</option><option value="lb" ${p.units==='lb'?'selected':''}>lb</option></select></div>
  <div><label class="f">Workouts / week</label><input data-p="weekGoal" inputmode="numeric" value="${p.weekGoal}" ${canEdit()?'':'disabled'}></div><div><label class="f">Sleep goal (h)</label><input data-p="sleepGoal" inputmode="decimal" value="${p.sleepGoal}" ${canEdit()?'':'disabled'}></div></div></div>
 <div class="card"><h2>Daily goals <small>from today on</small></h2><div class="grid2">${[['kcal','Calories',''],['p','Protein','g'],['c','Carbs','g'],['f','Fat','g']].map(([k,n,u])=>`<div class="stat"><b>${t[k]}${u}</b><span>${n}</span></div>`).join('')}</div><button class="btn ghost block" style="margin-top:10px" data-edit data-act="goals">✎ Edit daily goals</button><p class="muted">Changing goals applies from today forward; past days keep the goals they had.</p></div>
 <div class="card"><h2>Data</h2><div class="grid2"><button class="btn ghost sm" data-act="export" data-k="all">Export all (JSON)</button><button class="btn ghost sm" data-act="export" data-k="mealplan">Export saved meals</button></div>
 <div data-edit><label class="btn ghost sm block" style="margin-top:8px">Import backup<input type="file" accept="application/json" id="imp" hidden></label></div>
 <p class="muted">${window.SYNC&&SYNC.state.user?'Synced to your account and saved on this device.':'Saved on this device. Sign in above to back up and sync across devices.'}</p></div>
 <div class="card"><button class="btn ghost block" data-act="tour">Replay tutorial</button><button class="btn danger block" data-act="reset">Erase all data on this device</button></div>
 <p class="muted" style="text-align:center">Logbook v2 preview · build 1</p>`}
function exportData(kind){const name=kind==='mealplan'?'logbook-mealplan.json':'logbook-export.json';
 const obj=kind==='mealplan'?{targets:P().targets,savedMeals:SM().map(x=>({name:x.name,items:x.items.map(e=>({...food(e.fid),amt:e.amt,unit:e.unit,q:e.q}))}))}:D;
 const a=document.createElement('a');a.href=URL.createObjectURL(new Blob([JSON.stringify(obj,null,2)],{type:'application/json'}));a.download=name;a.click();toast('Exported '+name)}

/* ---------- ONBOARDING ---------- */
const TOUR=[['📱','Home screen','Widgets summarise your day. Tap one to open that section, swipe left and right between sections, and press and hold to add, resize, rearrange or customise widgets.'],
 ['🏋️','Train','Start from a template. Previous weights are filled in, tap ✓ to finish a set and a rest timer starts. Sessions survive closing the app.'],
 ['🥗','Food','Log food as you go, meal by meal. Scan barcodes, build your food archive, and save meals you eat often.'],
 ['📈','Progress','Estimated 1RM per lift, weekly volume, body weight, sleep and a training calendar.'],
 ['☁️','Sync','Sign in under Settings with Google or email to back up and sync across your devices. Without signing in, everything stays on this device.']];
/* w12: first-launch welcome / account step (before onboarding) */
function waitSync(ms=12000){return new Promise(res=>{let done=false;const fin=v=>{if(!done){done=true;res(v)}};const chk=s=>{if(s.user&&(s.status==='synced'||s.status==='error'))fin(s.status)};SYNC.on(chk);chk(SYNC.state);setTimeout(()=>fin('timeout'),ms)})}
function welcome(resume){S.auth={mode:resume?'in':'home',busy:false,err:''};drawAuth();if(resume)S.authAfter()}
function drawAuth(){const a=S.auth;let el=$('#onb');if(!el){el=document.createElement('div');el.id='onb';el.className='onb';document.body.appendChild(el)}
 const up=a.mode==='up',inn=a.mode==='in';let body;
 if(a.mode==='home')body=`<div class="hero" style="margin-top:48px"><img class="applogo" src="icon-192.png?v=w12" alt="Logbook" style="width:104px;height:104px;border-radius:24px"></div><h2 style="text-align:center;margin-top:18px">Logbook</h2><p class="muted" style="text-align:center;font-size:17px">Train, eat and track your progress. All in one place.</p>
 <div style="margin-top:auto"></div>`;
 else body=`<div class="hero" style="margin:16px 0 4px"><img class="applogo" src="icon-192.png?v=w12" alt="" style="width:64px;height:64px;border-radius:16px;margin:0"></div><h2>${up?'Create your account':'Welcome back'}</h2><p class="muted">${up?'Back up your logs and sync them across your devices.':'Sign in to load your logs on this device.'}</p>
 <button class="btn ghost block" id="agoogle" style="margin-top:8px">Continue with Google</button><div class="muted" style="text-align:center;margin:14px 0;font-size:13px">or use email</div>
 <label class="f">Email</label><input id="aem" type="email" autocomplete="email" inputmode="email" value="${esc(a.em||'')}">
 <label class="f">Password</label><input id="apw" type="password" autocomplete="${up?'new-password':'current-password'}">
 ${up?'<label class="f">Confirm password</label><input id="apw2" type="password" autocomplete="new-password">':''}
 ${a.err?`<p id="aerr" style="color:var(--red,#e5484d);margin:12px 0 0;font-weight:600">${esc(a.err)}</p>`:''}
 <button class="btn block" id="ago" style="margin-top:16px">${a.busy?(up?'Creating account…':'Signing in…'):(up?'Sign up':'Sign in')}</button>
 ${inn?'<button class="btn ghost block sm" id="aforgot" style="margin-top:10px">Forgot password?</button>':''}
 <p class="muted" style="text-align:center;margin-top:14px">${up?'Already have an account? <a href="#" id="aswap" style="color:inherit;font-weight:700">Sign in</a>':'New here? <a href="#" id="aswap" style="color:inherit;font-weight:700">Create an account</a>'}</p>`;
 el.innerHTML=`<div style="flex:1;max-width:480px;width:100%;margin:0 auto;display:flex;flex-direction:column">${body}</div><div style="max-width:480px;width:100%;margin:0 auto">${a.mode==='home'?'<button class="btn block" id="aup">Sign up</button><button class="btn ghost block" id="ain" style="margin-top:10px">Sign in</button>':'<button class="btn ghost block" id="aback">Back</button>'}<button class="btn ghost block sm" id="askip" style="margin-top:10px;border:0">Continue without an account</button></div>`;
 const q=x=>el.querySelector(x),go=m=>{a.mode=m;a.err='';drawAuth()};
 q('#aup')&&(q('#aup').onclick=()=>go('up'));q('#ain')&&(q('#ain').onclick=()=>go('in'));q('#aback')&&(q('#aback').onclick=()=>go('home'));
 q('#aswap')&&(q('#aswap').onclick=e=>{e.preventDefault();a.em=q('#aem').value.trim();go(up?'in':'up')});
 q('#askip').onclick=()=>{S.auth=null;onboarding(false)};
 const fail=e=>{a.busy=false;a.err=typeof e==='string'?e:authErr(e);a.em=(q('#aem')||{}).value||a.em;drawAuth()};
 const after=S.authAfter=async()=>{a.busy=true;drawAuth();const r=await waitSync();D=DB.get();
  if(P().onboarded){el.remove();S.auth=null;render();toast('Welcome back'+(P().name?', '+P().name:'')+'. Your data is loaded.');return}
  S.auth=null;onboarding(false);const u=SYNC.state.user;if(u&&u.name&&!S.onb.name){S.onb.name=u.name.split(' ')[0];drawOnb()}
  if(r==='error')toast('Signed in, but sync is paused: '+(SYNC.state.err||'try again later'))};
 q('#agoogle')&&(q('#agoogle').onclick=()=>{if(a.busy)return;SYNC.google().then(after).catch(fail)});
 q('#ago')&&(q('#ago').onclick=()=>{if(a.busy)return;const em=q('#aem').value.trim(),pw=q('#apw').value;a.em=em;
  if(!/^\S+@\S+\.\S+$/.test(em))return fail('Enter a valid email address');if(!pw)return fail('Enter your password');
  if(up){if(pw.length<6)return fail('Password must be at least 6 characters');if(pw!==q('#apw2').value)return fail('Passwords don’t match')}
  a.busy=true;a.err='';drawAuth();SYNC.email(em,pw,up).then(after).catch(fail)});
 q('#aforgot')&&(q('#aforgot').onclick=()=>{const em=q('#aem').value.trim();a.em=em;if(!/^\S+@\S+\.\S+$/.test(em))return fail('Enter your email above, then tap Forgot password');
  SYNC.reset(em).then(()=>{a.err='';drawAuth();ui.alert({title:'Check your email',message:'If an account exists for '+em+', we’ve sent a link to reset your password.'})}).catch(e=>/user-not-found/.test(e&&e.code||'')?ui.alert({title:'Check your email',message:'If an account exists for '+em+', we’ve sent a link to reset your password.'}):fail(e))});
}
function onboarding(tourOnly){S.onb={step:tourOnly?5:0,split:['','',''],tourOnly,goal:P().goal,units:P().units,name:P().name||''};drawOnb()}
function drawOnb(){const o=S.onb;let el=$('#onb');if(!el){el=document.createElement('div');el.id='onb';el.className='onb';document.body.appendChild(el)}
 const steps=5+TOUR.length,st=o.step;let body='';
 if(st===0)body=`<div class="hero"><img class="applogo" src="icon-192.png?v=w12" alt="Logbook"></div><h2>Welcome to Logbook</h2><p class="muted">Training, food, sleep and progress in one place. Everything starts empty. Log as you go and your widgets fill in.</p><label class="f">What should we call you?</label><input id="oname" value="${esc(o.name)}" autocomplete="given-name">`;
 else if(st===1)body=`<div class="hero">🎯</div><h2>Your goal</h2><p class="muted">We’ll suggest targets from this. You can change them any time.</p><div class="chips">${['Build muscle','Lose fat','Get stronger','Stay healthy'].map(g=>`<button class="chip ${g===o.goal?'on':''}" data-g="${g}">${g}</button>`).join('')}</div>
 <label class="f" style="margin-top:20px">Units</label><div class="seg">${['kg','lb'].map(u=>`<button class="${u===o.units?'on':''}" data-u="${u}">${u}</button>`).join('')}</div>`;
 else if(st===2){const sug={'Build muscle':[2600,180,300,75],'Lose fat':[1900,170,170,60],'Get stronger':[2700,180,320,80],'Stay healthy':[2200,130,250,70]}[o.goal];o.t=o.t&&o.tg===o.goal?o.t:{kcal:sug[0],p:sug[1],c:sug[2],f:sug[3]};o.tg=o.goal;
  body=`<div class="hero">🍽️</div><h2>Daily targets</h2><p class="muted">Suggested for “${esc(o.goal)}”. Adjust if you like.</p><div class="grid2">${[['kcal','Calories'],['p','Protein g'],['c','Carbs g'],['f','Fat g']].map(([k,n])=>`<div><label class="f">${n}</label><input inputmode="numeric" data-ot="${k}" value="${o.t[k]}"></div>`).join('')}</div>`}
 else if(st===3)body=`<div class="hero">⚖️</div><h2>What's your weight?</h2><p class="muted">Starts your weight widget. You can add it later.</p><div class="grid2"><div><label class="f">Weight</label><input id="owt" inputmode="decimal" placeholder="e.g. 78.5" value="${o.wt||''}"></div><div><label class="f">Units</label><div class="seg">${['kg','lb'].map(u=>`<button class="${u===o.units?'on':''}" data-u="${u}">${u}</button>`).join('')}</div></div></div><button class="btn ghost block sm" style="margin-top:16px" id="olater">Add later</button>`;
 else if(st===4){body=`<div class="hero">🔁</div><h2>What's your split?</h2><p class="muted">Your split is a cycle of days that repeats in order, not tied to weekdays. Name each day, or leave it blank for rest. Or pick a template.</p><div class="chips">${[['ppl','Push/Pull/Legs'],['ul','Upper/Lower'],['fb','Full body'],['blank','Start blank']].map(([k,n])=>`<button class="chip" data-stpl="${k}">${n}</button>`).join('')}</div>
  <div class="row" style="gap:8px;align-items:center;margin-top:12px"><label class="f" style="margin:0">Days in cycle</label><select id="osn">${Array.from({length:14},(_,i)=>`<option ${o.split.length===i+1?'selected':''}>${i+1}</option>`).join('')}</select></div><div class="osplit">${o.split.map((x,i)=>`<label><span>Day ${i+1}</span><input data-osd="${i}" placeholder="Rest" value="${esc(x||'')}"></label>`).join('')}</div><button class="btn ghost block sm" style="margin-top:12px" id="olater">Add later</button>`}
 else{const [e,h,txt]=TOUR[st-5];body=`<div class="hero">${e}</div><span class="demo">Tour ${st-4}/${TOUR.length}</span><h2 style="margin-top:8px">${h}</h2><p class="muted" style="font-size:17px">${txt}</p>`}
 el.innerHTML=`<div style="flex:1;max-width:480px;width:100%;margin:0 auto">${body}</div><div style="max-width:480px;width:100%;margin:0 auto"><div class="dots">${Array.from({length:steps},(_,i)=>`<i class="${i===st?'on':''}"></i>`).join('')}</div>
 <div class="grid2">${st>(o.tourOnly?5:0)?'<button class="btn ghost" id="oback">Back</button>':'<button class="btn ghost" id="oskip">Skip</button>'}<button class="btn" id="onext">${st===steps-1?'Get started':'Continue'}</button></div></div>`;
 el.querySelectorAll('[data-g]').forEach(b=>b.onclick=()=>{o.goal=b.dataset.g;drawOnb()});
 el.querySelectorAll('[data-u]').forEach(b=>b.onclick=()=>{grab();o.units=b.dataset.u;drawOnb()});
 const SPT={ppl:['Push','Pull','Legs',''],ul:['Upper','Lower',''],fb:['Full body A','','Full body B',''],blank:['','','']};
 el.querySelector('#osn')&&(el.querySelector('#osn').onchange=e=>{grab();const n=+e.target.value;o.split=o.split.slice(0,n);while(o.split.length<n)o.split.push('');drawOnb()});
 el.querySelectorAll('[data-stpl]').forEach(b=>b.onclick=()=>{o.split=SPT[b.dataset.stpl].slice();drawOnb()});
 el.querySelector('#olater')&&(el.querySelector('#olater').onclick=()=>{if(st===3)o.wt='';else o.split=[''];o.split=st===3?o.split:[];o.step++;drawOnb()});
 const grab=()=>{const n=el.querySelector('#oname');if(n)o.name=n.value.trim();const w=el.querySelector('#owt');if(w)o.wt=w.value.trim();el.querySelectorAll('[data-osd]').forEach(i=>o.split[+i.dataset.osd]=i.value.trim());el.querySelectorAll('[data-ot]').forEach(i=>o.t[i.dataset.ot]=+i.value||0)};
 const finish=()=>{grab();if(!o.tourOnly&&canEdit())save(d=>{d.profile.name=o.name;d.profile.goal=o.goal;d.profile.units=o.units;if(o.t){d.profile.targets=o.t;d.profile.goalHist=[{from:'2000-01-01',t:Object.assign({},o.t)}]}d.profile.onboarded=true;
  const wv=parseFloat(o.wt);if(wv>0){const kg=+(o.units==='lb'?wv/2.20462:wv).toFixed(1);d.weight=[{date:iso(new Date()),kg}]}
  if(o.split.some(x=>x)){d.split=o.split.map(x=>x||'rest');const have=new Set(d.templates.map(t=>t.name));d.split.forEach(x=>{if(x!=='rest'&&!have.has(x)){have.add(x);d.templates.push({name:x,exercises:[]})}})}});else if(canEdit()&&!P().onboarded)save(d=>d.profile.onboarded=true);el.remove();S.onb=null;render();toast(P().name?`You’re all set, ${P().name}`:'You’re all set')};
 el.querySelector('#onext').onclick=()=>{grab();if(st===steps-1)finish();else{o.step++;drawOnb()}};
 el.querySelector('#oback')&&(el.querySelector('#oback').onclick=()=>{grab();o.step--;drawOnb()});
 el.querySelector('#oskip')&&(el.querySelector('#oskip').onclick=finish)}

/* ---------- RENDER ---------- */
/* ---------- SLEEP & BODY page ---------- */
function vRecovery(){const today=iso(new Date()),sl=D.sleep.find(s=>s.date===today),wt=D.weight.find(w=>w.date===today),supps=D.supplements.log[today]||[];
 const lastS=[...D.sleep].sort((a,b)=>a.date.localeCompare(b.date)).pop(),lastW=[...D.weight].sort((a,b)=>a.date.localeCompare(b.date)).pop();
 return `<div class="grid2"><div class="card" style="margin:0 0 12px"><h2>Sleep</h2><b style="font-size:26px">${sl?sl.hours+' h':lastS?lastS.hours+' h':'—'}</b><div class="muted">${sl?'Last night':lastS?prettyDate(lastS.date):'Not logged'}</div><button class="btn ghost sm block" style="margin-top:8px" data-edit data-act="sleep">${sl?'Edit':'Log'}</button></div>
 <div class="card" style="margin:0 0 12px"><h2>Weight</h2><b style="font-size:26px">${wt?toDisp(wt.kg):lastW?toDisp(lastW.kg):'—'} <small style="font-size:14px">${U()}</small></b><div class="muted">${wt?'Today':lastW?prettyDate(lastW.date):'Not logged'}</div><button class="btn ghost sm block" style="margin-top:8px" data-edit data-act="weight">${wt?'Edit':'Log'}</button></div></div>
 <div class="card"><h2>Supplements <small>${supps.length}/${D.supplements.list.length}</small></h2><div class="chips">${D.supplements.list.length?'':'<span class="muted">No supplements yet. Add the ones you take.</span>'}${D.supplements.list.map(s=>`<button class="chip ${supps.includes(s)?'on':''}" data-act="supp" data-s="${esc(s)}" ${canEdit()?'':'disabled'}>${supps.includes(s)?'✓ ':''}${esc(s)}</button>`).join('')}<button class="chip" data-edit data-act="addsupp">＋</button></div></div>
 ${vBody()}
 <div class="card"><h2>Coach</h2>${coachTips().map(x=>`<div class="tip">${esc(x)}</div>`).join('')||'<div class="muted">All on track. Nice.</div>'}</div>`}

/* ---------- WIDGETS ---------- */
const WSTATE={edit:false};
const lastN=(n,f)=>{const o=[];for(let i=-(n-1);i<=0;i++){const d=dayOff(i);o.push({d,y:f(d)})}return o};
function seriesOld(metric,days){const since=dayOff(-(days-1));
 if(metric==='weight')return D.weight.filter(w=>w.date>=since).sort((a,b)=>a.date.localeCompare(b.date)).map(w=>({d:w.date,y:toDisp(w.kg)}));
 if(metric==='sleep')return D.sleep.filter(w=>w.date>=since).sort((a,b)=>a.date.localeCompare(b.date)).map(w=>({d:w.date,y:w.hours}));
 if(metric==='kcal')return lastN(days,d=>Math.round(totals(D.food[d]||[]).kcal)).filter(p=>p.y>0);
 if(metric==='protein')return lastN(days,d=>Math.round(totals(D.food[d]||[]).p)).filter(p=>p.y>0);
 if(metric==='volume')return D.workouts.filter(w=>w.date>=since).sort((a,b)=>a.date.localeCompare(b.date)).map(w=>({d:w.date,y:vol(w)}));
 return []}
const METRIC={weight:['Weight',()=>U(),'line'],kcal:['Calories','kcal','bar'],protein:['Protein','g','bar'],sleep:['Sleep','h','bar'],volume:['Workout volume',()=>U(),'bar']};
function spark(pts,{w=300,h=90,kind='line',goal=null}={}){if(pts.length<2)return '<div class="muted" style="font-size:12px">Not enough data yet</div>';
 const ys=pts.map(p=>p.y),mx=Math.max(...ys,goal||-Infinity),mn=kind==='bar'?0:Math.min(...ys),rg=(mx-mn)||1,pad=4;
 const X=i=>pad+i*(w-2*pad)/(pts.length-1),Y=v=>h-pad-(v-mn)/rg*(h-2*pad);
 let g=goal!=null?`<line x1="0" x2="${w}" y1="${Y(goal)}" y2="${Y(goal)}" stroke="var(--muted)" stroke-dasharray="3 4" stroke-width="1"/>`:'';
 if(kind==='bar'){const bw=(w-2*pad)/pts.length;return `<svg class="spark" viewBox="0 0 ${w} ${h}" preserveAspectRatio="none">${g}${pts.map((p,i)=>{const bh=Math.max(2,(p.y-mn)/rg*(h-2*pad));return `<rect x="${pad+i*bw+bw*.15}" y="${h-pad-bh}" width="${bw*.7}" height="${bh}" rx="${Math.min(4,bw*.3)}" fill="var(--accent)" opacity="${i===pts.length-1?1:.55}"/>`}).join('')}</svg>`}
 const d=pts.map((p,i)=>(i?'L':'M')+X(i).toFixed(1)+' '+Y(p.y).toFixed(1)).join(' ');
 return `<svg class="spark" viewBox="0 0 ${w} ${h}" preserveAspectRatio="none">${g}<path d="${d} L${X(pts.length-1)} ${h} L${X(0)} ${h}Z" fill="var(--accent)" opacity=".15"/><path d="${d}" fill="none" stroke="var(--accent)" stroke-width="2.5" vector-effect="non-scaling-stroke" stroke-linejoin="round" stroke-linecap="round"/></svg>`}
function miniRing(val,goal,sz,col='var(--accent)',sw=null){sw=sw||sz/9;const r=sz/2-sw/2,c=2*Math.PI*r,p=Math.min(1,goal?val/goal:0);
 return `<svg width="${sz}" height="${sz}" viewBox="0 0 ${sz} ${sz}" class="mring"><circle cx="${sz/2}" cy="${sz/2}" r="${r}" stroke="var(--card2)" stroke-width="${sw}" fill="none"/><circle cx="${sz/2}" cy="${sz/2}" r="${r}" stroke="${col}" stroke-width="${sw}" fill="none" stroke-linecap="round" stroke-dasharray="${c*p} ${c}" transform="rotate(-90 ${sz/2} ${sz/2})"/></svg>`}
const todayT=()=>totals(D.food[iso(new Date())]||[]);
const wkCount=()=>D.workouts.filter(w=>(new Date()-new Date(w.date+'T12:00'))/864e5<7).length;

/* type: [name, icon, section, sizes, default opt, options {key:[label,[[val,label]...]]}, render(size,opt)] */
const FR=()=>document.body.getBoundingClientRect(),VW=()=>document.body.clientWidth||window.innerWidth,VH=()=>document.body.clientHeight||window.innerHeight;
/* ---- demo extras (derived, deterministic; demo only) ---- */
const hsh=s=>{let h=2166136261;for(const c of String(s)){h^=c.charCodeAt(0);h=Math.imul(h,16777619)}return ((h>>>0)%10000)/10000};
const hm=m=>{m=((Math.round(m)%1440)+1440)%1440;return String(Math.floor(m/60)).padStart(2,'0')+':'+String(m%60).padStart(2,'0')};
const WKEY='lb2w:water';const WATER=JSON.parse(localStorage.getItem(WKEY)||'{}');
const X={water:d=>WATER[d]??0,waterGoal:2500,
 steps:d=>0,hr:d=>0,
 bed:d=>1365+Math.round(hsh('b'+d)*80-20),bedGoal:1365,
 meas:[],journal:[],
 fibre:{f1:0,f2:6,f3:0,f4:1,f5:3,f6:0,f7:1,f8:0,f9:5,f10:4},fibreGoal:30,
 mealTime:new Proxy({},{get:(o,m)=>420+Math.max(0,MEALS.indexOf(m))*Math.round(780/Math.max(1,MEALS.length))})};
const fibreOf=list=>list.reduce((a,e)=>a+(X.fibre[e.fid]??2)*e.q,0);
const MUSCLE={'Bench Press':'Chest','Incline DB Press':'Chest','Overhead Press':'Shoulders','Tricep Pushdown':'Arms','Bicep Curl':'Arms','Barbell Row':'Back','Pull-up':'Back','Lat Pulldown':'Back','Squat':'Legs','Leg Press':'Legs','Romanian Deadlift':'Legs','Deadlift':'Back'};
const sortedW=()=>[...D.workouts].sort((a,b)=>a.date.localeCompare(b.date));
function prs(){const m={};D.workouts.forEach(w=>w.exercises.forEach(e=>e.sets.forEach(s=>{const v=epley(toDisp(+s.w||0),s.r);if(!m[e.name]||v>m[e.name].e1)m[e.name]={e1:Math.round(v),w:toDisp(+s.w||0),r:s.r,d:w.date}})));return Object.entries(m).filter(x=>x[1].e1>0).sort((a,b)=>b[1].e1-a[1].e1)}
function weekVols(n=8){const o=[];for(let i=n-1;i>=0;i--){const end=new Date();end.setDate(end.getDate()-i*7);const st=new Date(end);st.setDate(st.getDate()-7);const ws=D.workouts.filter(w=>{const d=new Date(w.date+'T12:00');return d>st&&d<=end});o.push({x:i?'W-'+i:'Now',y:ws.reduce((a,w)=>a+vol(w),0),n:ws.length,start:iso(new Date(st.getTime()+864e5))})}return o}
function muscleSets(days=7){const since=dayOff(-days),m={Chest:0,Back:0,Legs:0,Shoulders:0,Arms:0};D.workouts.filter(w=>w.date>since).forEach(w=>w.exercises.forEach(e=>{const g0=groupOf(e.name),g=['Quads','Hamstrings','Glutes','Calves'].includes(g0)?'Legs':['Biceps','Triceps','Forearms'].includes(g0)?'Arms':g0;if(g in m)m[g]+=e.sets.length}));return m}
function wkStreak(){let n=0;const wv=weekVols(12).reverse();for(const w of wv){if(w.n>=Math.min(P().weekGoal,3))n++;else if(w.x!=='Now')break}return n}
const avg=a=>a.length?a.reduce((x,y)=>x+y,0)/a.length:0;
const r1=v=>Math.round(v*10)/10;
function metricVals(m,from,to){const out=[];for(let i=from;i<=to;i++){const d=dayOff(i);let v=null;
 if(m==='kcal'){const t=D.food[d];if(t&&t.length)v=totals(t).kcal}else if(m==='protein'){const t=D.food[d];if(t&&t.length)v=totals(t).p}
 else if(m==='sleep'){const s=D.sleep.find(x=>x.date===d);if(s)v=s.hours}else if(m==='weight'){const s=D.weight.find(x=>x.date===d);if(s)v=toDisp(s.kg)}
 else if(m==='volume'){const ws=D.workouts.filter(w=>w.date===d);if(ws.length)v=ws.reduce((a,w)=>a+vol(w),0)}else if(m==='steps')v=X.steps(d);else if(m==='water')v=X.water(d)/1000;
 if(v!=null)out.push({d,y:Math.round(v*10)/10})}return out}
METRIC.steps=['Steps','steps','bar'];METRIC.water=['Water','L','bar'];
function series(m,days){return metricVals(m,-(days-1),0)}
const CATS={home:['Home','progress'],train:['Training','train'],food:['Food','food'],body:['Sleep & body','recovery'],hist:['History','progress']};
const big=(v,u,sz,cls='')=>`<b class="wn ${sz==='S'?'sm':''} ${cls}">${v}${u?`<em> ${u}</em>`:''}</b>`;
const L_=t=>`<small class="wl">${t}</small>`;
const chartW=(pts,sz,o={})=>`<div class="wchart">${spark(pts,o)}</div>`;
const listW=(rows,n)=>`<div class="wlist">${rows.slice(0,n).map(([a,b,c])=>`<div><span>${a}</span><em class="${c||''}">${b}</em></div>`).join('')||'<div>None</div>'}</div>`;
const nRows=sz=>sz==='L'?7:sz==='M'?2:1;
const DAYS=[['7','7 days'],['14','14 days'],['30','30 days']];
/* mini helpers */
const card=(t,b,sm='')=>`<div class="card"><h2>${t}${sm?` <small>${sm}</small>`:''}</h2>${b}</div>`;
const stats=a=>`<div class="grid2" style="margin-bottom:12px">${a.map(([v,l])=>`<div class="stat"><b>${v}</b><span>${l}</span></div>`).join('')}</div>`;
const rows=a=>`<div class="list">${a.map(([t,s,r])=>`<div class="item"><div class="grow"><div class="t">${t}</div>${s?`<div class="s">${s}</div>`:''}</div>${r!=null?`<b>${r}</b>`:''}</div>`).join('')||'<div class="empty">Nothing yet</div>'}</div>`;
const rng=(cur,list=['7','14','30','90'])=>`<div class="seg">${list.map(d=>`<button class="${String(cur)===d?'on':''}" data-mdays="${d}">${d} d</button>`).join('')}</div>`;
function metricMini(m,days){const [n,u,kind]=METRIC[m],unit=typeof u==='function'?u():u,pts=series(m,+days),ys=pts.map(p=>p.y);const goal=m==='kcal'?P().targets.kcal:m==='protein'?P().targets.p:m==='sleep'?P().sleepGoal:m==='water'?2.5:null;
 return rng(days)+card(n,(kind==='bar'?barChart:lineChart)(pts.map(p=>({x:p.d.slice(5),y:p.y})),kind==='bar'?{goal,h:170}:{h:190}),unit)+stats([[ys.length?ys[ys.length-1].toLocaleString():'—','Latest'],[ys.length?r1(avg(ys)).toLocaleString():'—',days+'-day average']])+card('Entries',rows([...pts].reverse().map(p=>[prettyDate(p.d),'',p.y.toLocaleString()+' '+unit])),pts.length)}
/* registry: [name, icon, cat, sizes, defaults, options, render(sz,o), mini(o,days)] */
const WT={
 /* FOOD */
 kcal:['Calories left','🔥','food',['S','M','L'],{},{},(sz)=>{const t=todayT(),g=P().targets,left=Math.round(g.kcal-t.kcal);if(sz==='S')return L_('Calories')+`<div class="wcenter">${miniRing(t.kcal,g.kcal,64)}</div>`+big(left,'left',sz);
  return L_('Calories')+`<div class="wrow">${miniRing(t.kcal,g.kcal,sz==='L'?100:66)}<div style="flex:1;min-width:0">${big(left,'kcal left',sz)}<small>${Math.round(t.kcal)} of ${g.kcal} eaten</small>${sz==='M'?macroMini(t):''}</div></div>`+(sz==='L'?macroMini(t)+chartW(series('kcal',7),sz,{kind:'bar',goal:g.kcal}):'')},
  ()=>{const t=todayT(),g=P().targets;return card('Today',`<div class="row">${ring(t.kcal,g.kcal,'of '+g.kcal+' kcal',120)}<div class="grow"><b style="font-size:30px">${Math.round(g.kcal-t.kcal)}</b><div class="muted">kcal left</div></div></div>`)+foodCharts(true)+`<button class="btn block" data-edit data-act="addfood">＋ Log food</button><button class="btn ghost block" style="margin-top:8px" data-edit data-act="goals">✎ Edit daily goals</button>`}],
 macros:['Macros','🥗','food',['M','L'],{},{},(sz)=>L_('Macros today')+macroMini(todayT()),()=>{const t=todayT();return card('Macros today',macroBars(t))+card('Protein, last 7 days',barChart(series('protein',7).map(p=>({x:p.d.slice(8),y:p.y})),{goal:P().targets.p}))}],
 protein:['Protein goal','🥩','food',['S','M'],{},{},(sz)=>{const t=todayT(),g=P().targets.p;return L_('Protein')+`<div class="wrow">${miniRing(t.p,g,sz==='M'?70:52,'var(--p)')}<div>${big(Math.round(t.p),'/'+g+'g',sz)}${sz==='M'?`<small>${Math.max(0,Math.round(g-t.p))} g to go</small>`:''}</div></div>`},(o,d)=>metricMini('protein',d||'14')],
 water:['Water','💧','food',['S','M'],{},{},(sz)=>{const w=X.water(iso(new Date()));return L_('Water')+big((w/1000).toFixed(1),'/ '+X.waterGoal/1000+' L',sz)+`<div class="glass"><i style="height:${Math.min(100,w/X.waterGoal*100)}%"></i></div>${sz==='M'?'<small>Tap to add a glass</small>':''}`},
  (o,d)=>`<div class="card"><h2>Today <small>${(X.water(iso(new Date()))/1000).toFixed(2)} L</small></h2><div class="grid3"><button class="btn" data-x="water" data-v="250">＋250 ml</button><button class="btn" data-x="water" data-v="500">＋500 ml</button><button class="btn ghost" data-x="water" data-v="-250">−250</button></div></div>`+metricMini('water',d||'7')],
 meals:['Today’s meals','🍽️','food',['M','L'],{},{},(sz)=>{const day=D.food[iso(new Date())]||[];if(!day.length)return L_('Meals today')+'<b class="wt">Nothing logged yet</b><small>Tap to log your first meal</small>';return L_('Meals today')+listW(MEALS.map(m=>{const t=totals(day.filter(e=>e.meal===m));return [m,t.kcal?Math.round(t.kcal)+' kcal':'—']}),sz==='L'?4:3)},
  ()=>{const day=D.food[iso(new Date())]||[];return MEALS.map(m=>card(MLBL(m),rows(day.filter(e=>e.meal===m).map(e=>{const f=food(e.fid);return [esc(f.name),`P${Math.round(f.p*entryQ(f,e))} C${Math.round(f.c*entryQ(f,e))} F${Math.round(f.f*entryQ(f,e))}`,Math.round(f.kcal*entryQ(f,e))]})))).join('')+`<button class="btn block" data-edit data-act="addfood">＋ Log food</button>`}],
 favs:['Quick log','⭐','food',['M','L'],{},{},(sz)=>{const f=favs().slice(0,sz==='L'?6:3);if(!f.length)return L_('Quick log')+'<b class="wt">No favourites yet</b><small>Foods you log often show up here</small>';return L_('Quick log')+`<div class="wchips">${f.map(x=>`<span>＋ ${esc(x.name.split(' (')[0])}</span>`).join('')}</div>`},
  ()=>!favs().length?`<div class="emptystate"><div class="big">⭐</div><b>No favourites yet</b><p class="muted">Log a few foods and your most-logged ones appear here.</p><button class="btn block" data-edit data-act="addfood">＋ Log food</button></div>`:card('Favourites',`<div class="list">${favs().map(f=>`<div class="item"><div class="grow"><div class="t">${esc(f.name)}</div><div class="s">${f.kcal} kcal · P${f.p}</div></div><button class="btn sm" data-edit data-x="qlog" data-v="${f.id}">＋ Log</button></div>`).join('')}</div>`,'most logged')],
 timing:['Meal timing','⏱️','food',['S','M'],{},{},(sz)=>{const day=D.food[iso(new Date())]||[],done=MEALS.filter(m=>day.some(e=>e.meal===m)),nx=MEALS.find(m=>!done.includes(m));return L_('Next meal')+big(nx?hm(X.mealTime[nx]):'Done','',sz)+`<small>${nx||'All meals logged'}</small>${sz==='M'?`<div class="wweek">${MEALS.map(m=>`<i class="${done.includes(m)?'on':''}"><span>${hm(X.mealTime[m])}</span></i>`).join('')}</div>`:''}`},
  ()=>{const day=D.food[iso(new Date())]||[];return card('Meal schedule',rows(MEALS.map(m=>{const t=totals(day.filter(e=>e.meal===m));return [MLBL(m),hm(X.mealTime[m]),t.kcal?Math.round(t.kcal)+' kcal':'—']})))+'<p class="muted">Times are your planned meal times (24-hour).</p>'}],
 fibre:['Fibre','🌾','food',['S','M'],{},{},(sz)=>{const f=fibreOf(D.food[iso(new Date())]||[]);return L_('Fibre')+`<div class="wrow">${miniRing(f,X.fibreGoal,sz==='M'?70:52,'var(--c)')}<div>${big(Math.round(f),'/'+X.fibreGoal+'g',sz)}</div></div>`},
  ()=>{const pts=lastN(7,d=>fibreOf(D.food[d]||[]));return card('Fibre, last 7 days',barChart(pts.map(p=>({x:p.d.slice(8),y:p.y})),{goal:X.fibreGoal}))+card('Top sources',rows(D.foods.filter(f=>X.fibre[f.id]).sort((a,b)=>X.fibre[b.id]-X.fibre[a.id]).map(f=>[esc(f.name),'',X.fibre[f.id]+' g'])))}],
 kcalavg:['Weekly calories','📊','food',['S','M','L'],{},{},(sz)=>{const p=series('kcal',7),a=Math.round(avg(p.map(x=>x.y)));return L_('7-day avg')+big(a.toLocaleString(),'kcal',sz)+(sz!=='S'?chartW(p,sz,{kind:'bar',goal:P().targets.kcal}):`<small>goal ${P().targets.kcal}</small>`)},(o,d)=>metricMini('kcal',d||'7')],
 /* TRAINING */
 split:['Workout split','📆','train',['M','L'],{},{},(sz)=>{const sp=splitOf();if(!sp)return L_('Workout split')+`<b class="wt">No split set</b><small>Tap to set up your cycle</small>`;const nx=splitNext(),N=sp.length,sh=sz==='M'?Math.min(N,7):N,st=N<=sh?0:Math.max(0,Math.min(nx-1,N-sh));
  return L_(`Split · ${N}-day cycle`)+(sz==='M'?`<div class="wsplit">${Array.from({length:sh},(_,k)=>st+k).map(i=>`<div class="${i===nx?'on':''} ${sp[i]==='rest'?'rest':''}"><span>D${i+1}</span><b>${sp[i]==='rest'?'–':esc(sp[i].split(/[ +]/)[0].slice(0,5))}</b></div>`).join('')}</div><small>Next: <b>Day ${nx+1} of ${N} · ${esc(dayName(nx))}</b></small>`
  :`<div class="wlist">${sp.map((x,i)=>`<div class="${i===nx?'hl':''}"><span>Day ${i+1}${i===nx?' · next':''}</span><em>${esc(dayName(i))}</em></div>`).join('')}</div>`)},
  ()=>{const sp=splitOf();if(!sp)return `<div class="emptystate"><div class="big">📆</div><b>No split set</b><p class="muted">Set up your split cycle in Training.</p><button class="btn block" data-go="train">Open Training</button></div>`;const nx=splitNext();
   return card(`${sp.length}-day cycle`,rows(sp.map((x,i)=>{const t=D.templates.find(y=>y.name===x);return [`Day ${i+1}${i===nx?' · <b>next</b>':''}`,t?esc(t.exercises.slice(0,3).join(' · '))+'…':'',esc(dayName(i))]})))+`<button class="btn ghost block" data-edit data-act="splitskip">Skip / mark rest (Day ${nx+1})</button>`}],
 easynext:['Easy next','✨','food',['M','L'],{},{},(sz)=>{const r=easyNext();if(!r)return L_('Easy next')+'<b class="wt">You’re on target</b><small>Nothing needed right now</small>';
  return L_('Easy next')+`<div class="wrow"><div style="flex:1;min-width:0"><b class="wt">${esc(r.label)}</b><small>${Math.round(r.kcal)} kcal · P${Math.round(r.p)} C${Math.round(r.c)} F${Math.round(r.f)}</small></div><button class="qlog" data-qlog="${r.f_.id}" data-q="${r.q}" aria-label="Log ${esc(r.label)}">＋</button></div><small class="why">${esc(r.why)}</small>${sz==='L'?listW(r.alts.map(a=>[esc(a.label),Math.round(a.kcal)+' kcal · P'+Math.round(a.p)]),3):''}`},
  ()=>{const r=easyNext(),t=todayT(),g=P().targets;if(!r)return card('On target','<p class="muted">Calories and protein are covered for today.</p>');
   return card('Best fit right now',`<b style="font-size:20px">${esc(r.label)}</b><p class="muted">${esc(r.why)}</p>`+stats([[Math.round(r.kcal),'kcal'],[Math.round(r.p)+' g','protein']])+`<button class="btn block" data-edit data-x="qlog" data-v="${r.f_.id}" data-q="${r.q}">＋ Log it</button>`)+card('Other good options',`<div class="list">${r.alts.map(a=>`<div class="item"><div class="grow"><div class="t">${esc(a.label)}</div><div class="s">${Math.round(a.kcal)} kcal · P${Math.round(a.p)} · ${esc(a.tag)}</div></div><button class="btn sm" data-edit data-x="qlog" data-v="${a.f_.id}" data-q="${a.q}">＋</button></div>`).join('')}</div>`)+`<p class="muted">Left today: ${Math.round(g.kcal-t.kcal)} kcal, ${Math.max(0,Math.round(g.p-t.p))} g protein.</p>`}],
 today:['Today','☀️','home',['M','L'],{},{},(sz)=>{const b=brief();return L_('Today')+`<div class="brief">${b.lines.slice(0,sz==='L'?5:3).map(([i,t])=>`<p><span>${i}</span>${t}</p>`).join('')}</div>${sz==='L'?`<small class="why">💡 ${esc(b.tip)}</small>`:''}`},
  ()=>{const b=brief();return card(new Date().toLocaleDateString('en-CA',{weekday:'long',month:'long',day:'numeric'}),`<div class="brief big">${b.lines.map(([i,t])=>`<p><span>${i}</span>${t}</p>`).join('')}</div>`)+card('Tip',`<p>${esc(b.tip)}</p>`)}],
 next:['Next workout','🏋️','train',['S','M','L'],{},{},(sz)=>{if(D.active)return L_('In progress')+`<b class="wt">● ${esc(D.active.name)}</b><small>Tap to resume</small>`;const n=nextTpl(),up=upcoming(1)[0];if(!n)return L_('Next workout')+'<b class="wt">No workouts yet</b><small>Open Training to create one</small>';return L_('Next'+(up?' · '+up.day:''))+`<b class="wt">${esc(n.name)}</b>${sz==='S'?`<small>${n.exercises.length} exercises</small>`:listW(n.exercises.map(e=>[esc(e),esc(lastFor(e).replace('Last: ','').split(',')[0])]),sz==='L'?6:2)}`},
  ()=>{const n=nextTpl();if(!n&&!D.active)return `<div class="emptystate"><div class="big">🏋️</div><b>No workouts yet</b><button class="btn block" data-go="train">Create workout</button></div>`;return card(D.active?'In progress':'Next up',`<b style="font-size:22px">${esc(D.active?D.active.name:n.name)}</b>`+rows((D.active?D.active.exercises.map(e=>e.name):n.exercises).map(e=>[esc(e),esc(lastFor(e))])))+(D.active?'':`<button class="btn block" data-edit data-act="start" data-t="${esc(n.name)}">Start ${esc(n.name)}</button>`)}],
 week:['This week','📅','train',['S','M'],{},{},(sz)=>{const wk=wkCount(),g=P().weekGoal;return L_('This week')+big(wk,'/'+g,sz)+`<div class="wdots">${Array.from({length:g},(_,i)=>`<i class="${i<wk?'on':''}"></i>`).join('')}</div>`+(sz==='M'?`<small>${Math.max(0,g-wk)} to go · last 7 days</small>`:'')},
  ()=>{const ws=sortedW().filter(w=>(new Date()-new Date(w.date+'T12:00'))/864e5<7);return stats([[wkCount()+'/'+P().weekGoal,'Sessions'],[ws.reduce((a,w)=>a+vol(w),0).toLocaleString()+' '+U(),'Volume']])+card('Sessions',rows(ws.map(w=>[esc(w.name),prettyDate(w.date),vol(w).toLocaleString()])))}],
 last:['Last workout','✅','train',['S','M','L'],{},{},(sz)=>{const w=sortedW().pop();if(!w)return L_('Last workout')+'<b class="wt">None yet</b>';return L_('Last workout')+`<b class="wt">${esc(w.name)}</b><small>${prettyDate(w.date)}${sz!=='S'?' · '+vol(w).toLocaleString()+' '+U():''}</small>${sz==='L'?listW(w.exercises.map(e=>[esc(e.name),e.sets.map(s=>toDisp(s.w)+'×'+s.r).join(' ')]),6):''}`},
  ()=>{const w=sortedW().pop();return w?card(esc(w.name),rows(w.exercises.map(e=>[esc(e.name),e.sets.map(s=>toDisp(s.w)+' × '+s.r).join(' · ')])),prettyDate(w.date))+stats([[vol(w).toLocaleString()+' '+U(),'Volume'],[w.exercises.reduce((a,e)=>a+e.sets.length,0),'Sets']]):''}],
 prs:['Personal records','🏆','train',['S','M','L'],{},{},(sz)=>{const p=prs();return L_('Best lifts')+(sz==='S'?big(p[0]?p[0][1].e1:'—',U(),sz)+`<small>${esc(p[0]?.[0]||'')} e1RM</small>`:listW(p.map(([n,v])=>[esc(n),v.e1+' '+U()]),nRows(sz)+1))},
  ()=>card('Estimated 1RM (Epley)',rows(prs().map(([n,v])=>[esc(n),`${v.w} ${U()} × ${v.r} · ${prettyDate(v.d)}`,v.e1+' '+U()])))],
 volume:['Volume trend','📈','train',['M','L'],{},{},(sz)=>{const w=weekVols(sz==='L'?8:6);return L_('Weekly volume')+big(w[w.length-1].y.toLocaleString(),U(),sz)+chartW(w,sz,{kind:'bar'})},()=>{const w=weekVols(8);return card('Weekly volume',barChart(w),U())+rows([...w].reverse().map(x=>['Week of '+prettyDate(x.start),x.n+' sessions',x.y.toLocaleString()]))}],
 streak:['Streak','⚡','train',['S','M'],{},{},(sz)=>{const s=wkStreak(),days=lastN(7,d=>D.workouts.some(w=>w.date===d));return L_('Streak')+big(s,s===1?'week':'weeks',sz)+`<div class="wweek">${days.map(x=>`<i class="${x.y?'on':''}"><span>${new Date(x.d+'T12:00').toLocaleDateString('en-CA',{weekday:'narrow'})}</span></i>`).join('')}</div>`},
  ()=>card('Weekly streak',`<b style="font-size:30px">${wkStreak()} weeks</b><p class="muted">Weeks in a row with at least ${Math.min(P().weekGoal,3)} sessions.</p>`)+card('Last 8 weeks',rows(weekVols(8).reverse().map(x=>['Week of '+prettyDate(x.start),'',x.n+' sessions'])))],
 muscles:['Muscle groups','💪','train',['M','L'],{},{},(sz)=>{const m=muscleSets(7),mx=Math.max(...Object.values(m),1);return L_('Sets, last 7 days')+`<div class="heat">${Object.entries(m).map(([k,v])=>`<div style="--o:${.12+.88*v/mx}"><b>${v}</b><span>${k}</span></div>`).join('')}</div>`},
  ()=>{const m=muscleSets(7),m2=muscleSets(28);return card('Sets per muscle group',rows(Object.keys(m).map(k=>[k,'28 days: '+m2[k]+' sets',m[k]+' this week'])))+'<p class="muted">Aim for roughly 10–20 hard sets per muscle group per week.</p>'}],
 rest:['Rest timer','⏲️','train',['S','M'],{},{},(sz)=>L_('Rest timer')+big('1:30','',sz)+`<small>${sz==='M'?'Open for 1:00 · 1:30 · 2:00 · 3:00':'Quick start'}</small>`,
  ()=>card('Start a rest timer',`<div class="grid2">${[60,90,120,180].map(s=>`<button class="btn" data-x="rest" data-v="${s}">${Math.floor(s/60)}:${String(s%60).padStart(2,'0')}</button>`).join('')}</div>`)+'<p class="muted">The countdown shows at the bottom of the screen and vibrates when done.</p>'],
 plan:['Upcoming plan','🗓️','train',['M','L'],{},{},(sz)=>L_('Coming up')+listW(upcoming(sz==='L'?6:3).map(x=>[x.day,esc(x.t.name)]),sz==='L'?6:3),()=>card('Next sessions',rows(upcoming(7).map(x=>[esc(x.t.name),x.day,x.t.exercises.length+' ex.'])))+'<p class="muted">Rotates through your templates on your usual training days.</p>'],
 /* SLEEP & BODY */
 sleeplast:['Last night','🌙','body',['S','M'],{},{},(sz)=>{const all=[...D.sleep].sort((a,b)=>a.date.localeCompare(b.date)),s=all.pop();if(!s)return L_('Sleep')+'<b class="wt">—</b>';const b=X.bed(s.date);return L_('Last night')+big(s.hours,'h',sz)+`<small class="stars">${'★'.repeat(s.quality)}${'☆'.repeat(5-s.quality)}</small><small>${hm(b)} → ${hm(b+s.hours*60)}</small>`+chartW(series('sleep',7),sz,{kind:'bar',goal:P().sleepGoal})},
  ()=>{const s=[...D.sleep].sort((a,b)=>a.date.localeCompare(b.date)).pop();return s?stats([[s.hours+' h','Slept'],['★'.repeat(s.quality),'Quality'],[hm(X.bed(s.date)),'Bedtime'],[hm(X.bed(s.date)+s.hours*60),'Wake']])+`<button class="btn block" data-edit data-act="sleep">Log tonight</button>`:''}],
 sleep7:['Sleep chart','📉','body',['M','L'],{days:'7'},{days:['Range',DAYS]},(sz,o)=>{const p=series('sleep',+o.days);return L_('Sleep · '+o.days+'d')+big(r1(avg(p.map(x=>x.y))),'h avg',sz)+chartW(p,sz,{kind:'bar',goal:P().sleepGoal})},(o,d)=>metricMini('sleep',d||o.days)],
 consist:['Sleep consistency','🎯','body',['S','M'],{},{},(sz)=>{const c=consistency();return L_('Consistency')+big(c.score,'%',sz)+`<small>bedtime ±${c.sd} min</small>`},()=>{const c=consistency();return stats([[c.score+'%','Score'],['±'+c.sd+' min','Bedtime spread']])+card('Bedtimes, last 7 nights',rows(c.list.map(x=>[prettyDate(x.d),'',hm(x.b)])))}],
 weight:['Weight','⚖️','body',['S','M'],{},{},(sz)=>{const p=series('weight',30),l=p[p.length-1],d=p.length>1?r1(l.y-p[0].y):0;return L_('Weight')+big(l?l.y:'—',U(),sz)+`<small class="${d<=0?'good':'bad'}">${d<0?'▼':d>0?'▲':'•'} ${Math.abs(d)} ${U()} · 30d</small>`+chartW(p,sz)},(o,d)=>metricMini('weight',d||'30')+`<button class="btn block" data-edit data-act="weight">Log weight</button>`],
 wtrend:['Weight trend','📉','body',['M','L'],{days:'30'},{days:['Range',DAYS]},(sz,o)=>{const p=series('weight',+o.days),dl=p.length>1?r1(p[p.length-1].y-p[0].y):0;return L_('Weight · '+o.days+'d')+big((dl>0?'+':'')+dl,U(),sz)+chartW(p,sz)},(o,d)=>metricMini('weight',d||o.days)],
 measure:['Measurements','📏','body',['S','M','L'],{},{},(sz)=>{const m=X.meas,l=m[m.length-1],f=m[0];return L_('Waist')+big(l.waist,'cm',sz)+`<small>${r1(l.waist-f.waist)} cm in 12 weeks</small>`+(sz!=='S'?listW([['Chest',l.chest+' cm'],['Arm',l.arm+' cm']],2):'')},
  ()=>card('Measurements',lineChart(X.meas.map(m=>({x:m.d.slice(5),y:m.waist})),{h:150}),'waist, cm')+card('History',rows([...X.meas].reverse().map(m=>[prettyDate(m.d),`Chest ${m.chest} · Arm ${m.arm}`,m.waist+' cm'])))+'<p class="muted">Demo measurements.</p>'],
 supps:['Supplements','💊','body',['S','M'],{},{},(sz)=>{const t=D.supplements.log[iso(new Date())]||[];return L_('Supplements')+big(t.length,'/'+D.supplements.list.length,sz)+(sz==='M'?`<div class="wchips">${D.supplements.list.map(s=>`<span class="${t.includes(s)?'on':''}">${t.includes(s)?'✓ ':''}${esc(s)}</span>`).join('')}</div>`:'<small>taken today</small>')},
  ()=>{const t=D.supplements.log[iso(new Date())]||[];return card('Today',`<div class="chips">${D.supplements.list.length?'':'<span class="muted">No supplements yet. Add the ones you take.</span>'}${D.supplements.list.map(s=>`<button class="chip ${t.includes(s)?'on':''}" data-act="supp" data-s="${esc(s)}">${t.includes(s)?'✓ ':''}${esc(s)}</button>`).join('')}</div>`)}],
 vitals:['Steps & resting HR','❤️','body',['S','M','L'],{show:'both'},{show:['Show',[['both','Both'],['steps','Steps'],['hr','Resting HR']]]},(sz,o)=>{const d=iso(new Date()),st=X.steps(d),hr=X.hr(d);
  if(sz==='S'||o.show!=='both')return o.show==='hr'?L_('Resting HR')+big(hr,'bpm',sz):L_('Steps')+big(st.toLocaleString(),'',sz)+chartW(series('steps',7),sz,{kind:'bar',goal:10000});return L_('Today')+`<div class="wrow"><div>${big(st.toLocaleString(),'steps',sz)}</div><div>${big(hr,'bpm',sz)}</div></div>`+chartW(series('steps',7),sz,{kind:'bar',goal:10000})},
  (o,d)=>stats([[X.steps(iso(new Date())).toLocaleString(),'Steps today'],[X.hr(iso(new Date()))+' bpm','Resting HR']])+metricMini('steps',d||'7')+'<p class="muted">Demo values. The real app could read these from Apple Health.</p>'],
 bedtime:['Bedtime target','🛏️','body',['S','M'],{},{},(sz)=>{const now=new Date(),m=now.getHours()*60+now.getMinutes(),left=(X.bedGoal-m+1440)%1440;return L_('Bedtime')+big(hm(X.bedGoal),'',sz)+`<small>in ${Math.floor(left/60)} h ${left%60} min</small>`+(sz==='M'?`<small>Wake ${hm(X.bedGoal+P().sleepGoal*60)} for ${P().sleepGoal} h</small>`:'')},
  ()=>stats([[hm(X.bedGoal),'Target bedtime'],[hm(X.bedGoal+P().sleepGoal*60),'Wake for '+P().sleepGoal+' h']])+card('Wind down',rows([['Screens off',hm(X.bedGoal-30)],['Last caffeine',hm(X.bedGoal-480)],['Last big meal',hm(X.bedGoal-180)]]))],
 /* HISTORY */
 graph:['Graph','📈','hist',['S','M','L'],{metric:'weight',days:'14'},{metric:['Graph',Object.entries(METRIC).map(([k,v])=>[k,v[0]])],days:['Range',DAYS]},(sz,o)=>{const [n,u,kind]=METRIC[o.metric]||METRIC.weight,unit=typeof u==='function'?u():u,p=series(o.metric,+o.days),l=p[p.length-1];return L_(n+' · '+o.days+'d')+big(l?l.y.toLocaleString():'—',unit,sz)+chartW(p,sz,{kind})},(o,d)=>metricMini(o.metric,d||o.days)],
 calheat:['Calendar heatmap','🟩','hist',['M','L'],{metric:'workouts'},{metric:['Shows',[['workouts','Workouts'],['kcal','Calories on target'],['sleep','Sleep goal hit']]]},(sz,o)=>L_({workouts:'Workouts',kcal:'Calories on target',sleep:'Sleep goal'}[o.metric]+' · 28d')+heat(o.metric,sz==='L'?35:28),(o)=>card('Last 35 days',heat(o.metric,35,true))],
 month:['Month summary','🗒️','hist',['M','L'],{},{},(sz)=>{const m=monthSum();return L_(m.name)+listW([['Workouts',m.w],['Avg calories',m.k],['Avg sleep',m.s+' h'],['Weight',m.wt],['Volume',m.v]],sz==='L'?5:3)},()=>{const m=monthSum();return stats([[m.w,'Workouts'],[m.k,'Avg kcal'],[m.s+' h','Avg sleep'],[m.wt,'Weight change']])+card('Volume',`<b>${m.v}</b>`)}],
 bestweek:['Best week','🥇','hist',['S','M'],{},{},(sz)=>{const b=weekVols(8).reduce((a,x)=>x.y>a.y?x:a);return L_('Best week')+big(b.y.toLocaleString(),U(),sz)+`<small>${prettyDate(b.start)} · ${b.n} sessions</small>`},()=>{const w=weekVols(8),b=w.reduce((a,x)=>x.y>a.y?x:a);return card('Top week',`<b style="font-size:26px">${b.y.toLocaleString()} ${U()}</b><div class="muted">Week of ${prettyDate(b.start)} · ${b.n} sessions</div>`)+card('Last 8 weeks',barChart(w))}],
 compare:['Compare','⚖︎','hist',['S','M'],{metric:'kcal'},{metric:['Metric',Object.entries(METRIC).map(([k,v])=>[k,v[0]])]},(sz,o)=>{const c=cmp(o.metric);return L_(METRIC[o.metric][0]+' vs prev')+big((c.pct>0?'+':'')+c.pct,'%',sz)+`<small>${c.a} vs ${c.b} avg</small>`+(sz==='M'?'<small>Last 14 days vs the 14 before</small>':'')},
  (o)=>{const c=cmp(o.metric);return stats([[c.a,'Last 14 days avg'],[c.b,'Previous 14 days avg']])+card('Change',`<b style="font-size:28px">${c.pct>0?'+':''}${c.pct}%</b>`)+'<p class="muted">Comparison uses 14-day windows because the demo data covers about a month.</p>'}],
 milestones:['Milestones','🎉','hist',['M','L'],{},{},(sz)=>L_('Milestones')+listW(milestones().map(m=>[m.t,m.d]),nRows(sz)+1),()=>card('Achievements',rows(milestones().map(m=>[m.t,m.s,m.d])))],
 journal:['Journal','📓','hist',['M','L'],{},{},(sz)=>L_('Journal')+`<div class="wtips">${X.journal.slice(0,sz==='L'?4:1).map(j=>`<p><b>${prettyDate(j.d)}</b> ${esc(j.t)}</p>`).join('')}</div>`,()=>card('Entries',rows(X.journal.map(j=>[esc(j.t),prettyDate(j.d)])))+'<p class="muted">Demo journal entries.</p>'],
 totals:['All-time totals','🧮','hist',['S','M'],{},{},(sz)=>{const t=allTotals();return L_('All time')+big(t.s,'sessions',sz)+(sz==='M'?`<small>${t.v} ${U()} lifted · ${t.m} meals · ${t.n} nights</small>`:'')},()=>{const t=allTotals();return stats([[t.s,'Sessions'],[t.v+' '+U(),'Volume'],[t.m,'Meals logged'],[t.n,'Nights logged']])}]
};
function easyNext(){const t=todayT(),g=P().targets,R=g.kcal-t.kcal,Rp=Math.max(0,g.p-t.p);if(R<120)return null;
 const fav=new Set(favs().slice(0,5).map(f=>f.id)),stock=new Set(D.foods.filter(f=>f.custom).map(f=>f.id)),out=new Set();
 const cand=[];D.foods.forEach(f=>{if(out.has(f.id))return;[1,2].forEach(q=>{const k=f.kcal*q,p=f.p*q;if(k>R+60||k<60)return;let sc=(Rp?Math.min(p,Rp)/Rp:0)*.65+Math.min(k,R*.5)/(R*.5)*.25+(p/Math.max(k,1))*.6;if(stock.has(f.id))sc+=.12;if(fav.has(f.id))sc+=.06;if(q===2)sc-=.05;
  cand.push({f_:f,q,kcal:k,p,c:f.c*q,f:f.f*q,sc,label:(q>1?'2× ':'')+f.name,tag:stock.has(f.id)?'in your food archive':fav.has(f.id)?'a favourite':'from your foods'})})});
 cand.sort((a,b)=>b.sc-a.sc);const best=cand[0];if(!best)return null;const seen=new Set([best.f_.id]);best.alts=cand.filter(c=>!seen.has(c.f_.id)&&seen.add(c.f_.id)).slice(0,3);
 best.why=`Covers ${Math.round(Math.min(best.p,Rp))} of your ${Math.round(Rp)} g protein gap and ${Math.round(best.kcal)} of ${Math.round(R)} kcal left · ${best.tag}.`;return best}
function brief(){const t=todayT(),g=P().targets,n=nextTpl(),done=D.workouts.find(w=>w.date===iso(new Date())),sp=splitOf(),nxi=sp?splitNext():-1,td=sp&&!(D.workouts.some(w=>w.date===iso(new Date())))?sp[nxi]:null;
 const s=[...D.sleep].sort((a,b)=>a.date.localeCompare(b.date)).pop(),w=series('weight',14),dl=w.length>1?r1(w[w.length-1].y-w[0].y):null,tips=coachTips();
 const lines=[['🏋️',done?`Done: <b>${esc(done.name)}</b>`:td==='rest'?`Rest day (Day ${nxi+1} of ${sp.length}). Recover well`:sp&&n?`Day ${nxi+1} of ${sp.length}: <b>${esc(n.name)}</b> · ${n.exercises.length} exercises`:n?`Workout: <b>${esc(n.name)}</b> · ${n.exercises.length} exercises`:'No workout planned'],
  ['🔥',`<b>${Math.round(g.kcal-t.kcal)}</b> kcal and <b>${Math.max(0,Math.round(g.p-t.p))} g</b> protein left`],
  ['🌙',s?`Slept <b>${s.hours} h</b> ${'★'.repeat(s.quality)}`:'Sleep not logged'],
  ['⚖️',dl==null?'Not enough weigh-ins yet':`Weight ${dl<0?'down':dl>0?'up':'steady'} <b>${Math.abs(dl)} ${U()}</b> over 14 days`],
  ['💧',`${(X.water(iso(new Date()))/1000).toFixed(1)} of ${X.waterGoal/1000} L water`]];
 return {lines,tip:tips[0]||'All on track. Nice.'}}
function macroMini(t){const g=P().targets;return `<div class="wmac">${[['P','p','var(--p)'],['C','c','var(--c)'],['F','f','var(--f)']].map(([n,k,col])=>`<div><span>${n}</span><div class="bar"><i style="width:${Math.min(100,t[k]/g[k]*100)}%;background:${col}"></i></div><em>${Math.round(t[k])}/${g[k]}</em></div>`).join('')}</div>`}
function favs(){const c={};Object.values(D.food).flat().forEach(e=>c[e.fid]=(c[e.fid]||0)+1);return D.foods.filter(f=>c[f.id]).sort((a,b)=>c[b.id]-c[a.id])}
function groceries(){return [];const o=D.pantry.filter(p=>pantryStatus(p)!=='ok').map(p=>({n:p.name,why:pantryStatus(p)==='out'?'Out':'Low'}));const have=new Set(D.pantry.map(p=>p.fid).filter(Boolean));
 return o}
function upcoming(n){{const o=[];for(let day=1;o.length<n&&day<60;day++){const ds=dayOff(day),p=plannedOn(ds),t=p&&D.templates.find(x=>x.name===p);if(t)o.push({day:new Date(ds+'T12:00').toLocaleDateString('en-CA',{weekday:'short',day:'numeric'}),t})}if(o.length||D.schedule)return o}if(!D.templates.length)return [];const o=[];let k=D.workouts.length,day=1;while(o.length<n){const d=new Date();d.setDate(d.getDate()+day);if(d.getDay()!==3&&d.getDay()!==0){o.push({day:d.toLocaleDateString('en-CA',{weekday:'short',day:'numeric'}),t:D.templates[k%D.templates.length]});k++}day++}return o}
function consistency(){const l=[...D.sleep].sort((a,b)=>a.date.localeCompare(b.date)).slice(-7).map(s=>({d:s.date,b:X.bed(s.date)})),a=avg(l.map(x=>x.b)),sd=Math.round(Math.sqrt(avg(l.map(x=>(x.b-a)**2))));return {sd,score:Math.max(0,Math.round(100-sd*1.5)),list:l.reverse()}}
function heat(m,n,big){const cells=[];for(let i=-(n-1);i<=0;i++){const d=dayOff(i);let v=0;
 if(m==='workouts')v=D.workouts.some(w=>w.date===d)?1:0;else if(m==='kcal'){const t=D.food[d];v=t&&t.length?Math.max(0,1-Math.abs(totals(t).kcal-goalFor(d).kcal)/goalFor(d).targets.kcal*3):0}else{const s=D.sleep.find(x=>x.date===d);v=s?Math.min(1,s.hours/P().sleepGoal)**3:0}
 cells.push(`<i style="--o:${.1+.9*v}" title="${d}">${big?new Date(d+'T12:00').getDate():''}</i>`)}return `<div class="calh ${big?'big':''}">${cells.join('')}</div>`}
function monthSum(){const now=new Date(),mk=iso(now).slice(0,7),ws=D.workouts.filter(w=>w.date.startsWith(mk)),ks=Object.entries(D.food).filter(([d,l])=>d.startsWith(mk)&&l.length).map(([d,l])=>totals(l).kcal),ss=D.sleep.filter(s=>s.date.startsWith(mk)).map(s=>s.hours),wt=D.weight.filter(s=>s.date.startsWith(mk)).sort((a,b)=>a.date.localeCompare(b.date));
 return {name:now.toLocaleDateString('en-CA',{month:'long'}),w:ws.length,k:Math.round(avg(ks)).toLocaleString(),s:r1(avg(ss)),wt:wt.length>1?(r1(toDisp(wt[wt.length-1].kg-wt[0].kg))>0?'+':'')+r1(toDisp(wt[wt.length-1].kg-wt[0].kg))+' '+U():'—',v:ws.reduce((a,w)=>a+vol(w),0).toLocaleString()+' '+U()}}
function cmp(m){const a=avg(metricVals(m,-13,0).map(x=>x.y)),b=avg(metricVals(m,-27,-14).map(x=>x.y));return {a:r1(a).toLocaleString(),b:b?r1(b).toLocaleString():'—',pct:b?Math.round((a-b)/b*100):0}}
function milestones(){const o=[],n=D.workouts.length;[5,10,25,50,100].forEach(k=>{if(n>=k){const w=sortedW()[k-1];o.push({t:k+' workouts logged',s:'Consistency',d:prettyDate(w.date)})}});
 prs().slice(0,3).forEach(([e,v])=>o.push({t:`${e} PR · ${v.e1} ${U()}`,s:'Estimated 1RM',d:prettyDate(v.d)}));const w=[...D.weight].sort((a,b)=>a.date.localeCompare(b.date));if(w.length>1&&w[0].kg-w[w.length-1].kg>=0.5)o.push({t:`Down ${r1(toDisp(w[0].kg-w[w.length-1].kg))} ${U()}`,s:'Body weight',d:prettyDate(w[w.length-1].date)});
 return o.sort((a,b)=>b.d.localeCompare(a.d))}
function allTotals(){return {s:D.workouts.length,v:D.workouts.reduce((a,w)=>a+vol(w),0).toLocaleString(),m:Object.values(D.food).flat().length,n:D.sleep.length}}
const SZN={S:'Small',M:'Medium',L:'Large'};

/* ---------- LAYOUT (section-scoped pages) ---------- */
const nw=(type,size,opt)=>({id:'w'+uid(),type,size,opt:Object.assign({},WT[type][4],opt||{})});
const PCAT={home:'Home',train:'Training',food:'Food',body:'Sleep & body',hist:'History',other:'Other'};
const mixed=c=>c==='home'||c==='other';
function defaultLayout(){const P_=(cat,w)=>({id:'p'+uid(),cat,name:PCAT[cat],w});return [
 P_('home',[nw('today','M'),nw('kcal','M'),nw('sleeplast','S'),nw('weight','S'),nw('split','M')]),
 P_('train',[nw('next','M'),nw('split','M'),nw('week','S'),nw('streak','S'),nw('plan','M')]),
 P_('food',[nw('easynext','M'),nw('macros','M'),nw('water','S'),nw('protein','S'),nw('meals','M')]),
 P_('body',[nw('sleeplast','S'),nw('weight','S'),nw('sleep7','M'),nw('vitals','M'),nw('supps','M')]),
 P_('hist',[nw('graph','L',{metric:'weight',days:'30'}),nw('calheat','M'),nw('month','M')]),
 P_('other',[nw('journal','M'),nw('rest','S'),nw('protein','S'),nw('compare','S'),nw('bestweek','S'),nw('milestones','M')])]}
function sanitize(l){const other=l.find(p=>p.cat==='other')||(l.push({id:'p'+uid(),cat:'other',name:'Other',w:[]}),l[l.length-1]);
 l.forEach(p=>{if(!PCAT[p.cat])p.cat='other';p.w=p.w.filter(x=>WT[x.type]);if(!mixed(p.cat)){const bad=p.w.filter(x=>WT[x.type][2]!==p.cat);if(bad.length){p.w=p.w.filter(x=>!bad.includes(x));other.w.push(...bad)}}});
 const oi=l.indexOf(other);l.splice(oi,1);l.push(other);return l}
let LAYOUT=(()=>{try{const l=JSON.parse(localStorage.getItem('lb2w:pages6'));if(Array.isArray(l)&&l.length)return sanitize(l)}catch(e){}return defaultLayout()})();
function saveLayout(){localStorage.setItem('lb2w:pages6',JSON.stringify(LAYOUT))}
const SB={cur:0,rows:4,W:390};
const probe=(()=>{const d=document.createElement('div');d.style.cssText='position:fixed;top:0;left:0;visibility:hidden;padding-top:env(safe-area-inset-top);padding-bottom:env(safe-area-inset-bottom)';document.documentElement.appendChild(d);return d})();
function metrics(){const cs=getComputedStyle(probe),sat=parseFloat(cs.paddingTop)||0,sab=parseFloat(cs.paddingBottom)||0,W=Math.min(VW(),560),H=VH();
 const head=H<700?50:58,bottom=(H<700?92:104)+Math.max(sab,8)+20,avail=H-sat-8-head-bottom,gap=14,cw=(W-32-gap)/2;
 const rows=(avail-3*gap)/4>=cw*.6?4:Math.max(2,Math.min(4,Math.floor((avail+gap)/(cw*.8+gap))));const rh=Math.floor(Math.min(cw*1.05,(avail-gap*(rows-1))/rows));Object.assign(SB,{rows,rh,W:VW(),avail});return SB}
function fits(occ,R,sz,r,c){const cells=sz==='S'?[[r,c]]:sz==='M'?(c?null:[[r,0],[r,1]]):(c||r+1>=R?null:[[r,0],[r,1],[r+1,0],[r+1,1]]);if(!cells||cells.some(([y,x])=>y>=R||occ[y][x]))return null;return cells}
function placeAll(items){const R=SB.rows,occ=Array.from({length:R},()=>[0,0]),placed=[],rest=[];
 for(const w of items){let ok=null;for(let r=0;r<R&&!ok;r++)for(let c=0;c<2&&!ok;c++){const cl=fits(occ,R,w.size,r,c);if(cl){cl.forEach(([y,x])=>occ[y][x]=1);ok={w,r,c}}}ok?placed.push(ok):rest.push(w)}return [placed,rest]}
const baseName=c=>PCAT[c];
function pack(){const out=[];for(const p of LAYOUT){let items=p.w,first=true;
  do{const [placed,rest]=placeAll(items);out.push({id:first?p.id:p.id+'x'+out.length,cat:p.cat,name:p.name,items:placed});items=rest;first=false}while(items.length)}
 const cnt={};out.forEach(p=>{cnt[p.cat]=(cnt[p.cat]||0)+1;p.name=cnt[p.cat]>1?baseName(p.cat)+' '+cnt[p.cat]:baseName(p.cat)});return out}
function commitPack(){LAYOUT=pack().map(p=>({id:p.id,cat:p.cat,name:p.name,w:p.items.map(x=>x.w)}));saveLayout()}
const anyFood=()=>Object.values(D.food).some(a=>a&&a.length),todayFood=()=>(D.food[iso(new Date())]||[]).length>0,anyW=()=>D.workouts.length>0;
function emptyOf(t,o){const F=['Nothing logged today','Log food','Your calories, macros and meals appear here once you log food.','food'],W=['No workouts yet','Log a workout','Log or start a workout and your training stats fill in.','train'],SL=['No sleep logged','Log sleep','Log last night’s sleep to see it here.','recovery'],WT_=['No weight logged','Log weight','Add a weigh-in to start your trend.','recovery'],H=['No history yet','Start logging','Log workouts, food, sleep or weight and your history builds up here.','train'];
 switch(t){case 'kcal':case 'macros':case 'protein':case 'meals':case 'timing':case 'fibre':return todayFood()?null:F;case 'kcalavg':return anyFood()?null:['No food logged yet','Log food','Weekly calories appear after you log some days.','food'];
 case 'water':return X.water(iso(new Date()))?null:['No water logged','Add water','Tap to add glasses of water.','food'];
 case 'week':case 'last':case 'prs':case 'volume':case 'streak':case 'muscles':return anyW()?null:W;case 'plan':return upcoming(1).length?null:['Nothing planned','Set up your split','Set a split or schedule a workout from the calendar.','train'];
 case 'sleeplast':case 'sleep7':case 'consist':case 'bedtime':return D.sleep.length?null:SL;case 'weight':case 'wtrend':return D.weight.length?null:WT_;
 case 'measure':return X.meas.length?null:['No measurements','Add measurements','Measurements will show here once added.','recovery'];
 case 'supps':return D.supplements.list.length?null:['No supplements','Add supplements','Add the supplements you take to tick them off daily.','recovery'];
 case 'vitals':return ['No steps or heart rate','Not connected','Steps and resting HR need Apple Health, which the preview can’t read yet.','recovery'];
 case 'journal':return ['No journal entries','Open History','Journal entries will appear here.','progress'];
 case 'graph':{try{return series(o.metric||'weight',+(o.days||14)).filter(p=>p&&p.y).length?null:H}catch(e){return H}}
 case 'calheat':case 'month':case 'bestweek':case 'compare':case 'milestones':case 'totals':return anyW()||anyFood()||D.sleep.length||D.weight.length?null:H}return null}
window.__lbt=()=>({WT,widgetHTML});
function widgetHTML(w,r,c){const T=WT[w.type];let inner;const em=emptyOf(w.type,w.opt||{});try{inner=em?`<small class="wl">${T[1]} ${esc(T[0])}</small><b class="wt wempty">${em[0]}</b><small class="wcta">${em[1]} ›</small>`:T[6](w.size,w.opt||{})}catch(e){console.warn(e);inner='<small class="wl">'+T[0]+'</small><small>Unavailable</small>'}
 return `<div class="w ${w.size}" data-type="${w.type}" data-c="${T[2]}" data-wid="${w.id}" style="grid-row:${r+1} / span ${w.size==='L'?2:1};grid-column:${w.size==='S'?c+1:'1 / span 2'}" role="button" tabindex="0" aria-label="${T[0]} widget"><div class="wi">${inner}</div>
 <button class="wx" data-wx aria-label="Remove widget">−</button><button class="wsz" data-wsz aria-label="Change size">${w.size}</button></div>`}
function dayChecks(ds){ds=ds||iso(new Date());const sl=D.supplements.list,tk=D.supplements.log[ds]||[];
 return [['sleep','🌙','Sleep',D.sleep.some(x=>x.date===ds),'recovery'],...(sl.length?[['supps','💊','Supps',sl.every(x=>tk.includes(x)),'recovery',`${tk.filter(x=>sl.includes(x)).length}/${sl.length}`]]:[]),['weight','⚖️','Weight',D.weight.some(x=>x.date===ds),'recovery'],['workout','🏋️','Workout',D.workouts.some(w=>w.date===ds),'train'],['food','🍽️','Food',(D.food[ds]||[]).length>0,'food']]}
function checksRow(){const c=dayChecks(),n=c.filter(x=>x[3]).length;return `<div class="checks" aria-label="Today's checklist: ${n} of ${c.length} done">${c.map(([k,ic,lb,ok,go,extra])=>`<button class="chk2 ${ok?'ok':''}" data-go="${go}" title="${lb}${extra?' '+extra:''}" aria-label="${lb} ${ok?'done':'not done'}"><span class="ci">${ic}</span>${ok?'<i class="tick">✓</i>':''}</button>`).join('')}<span class="cn ${n===c.length?'all':''}">${n}/${c.length}</span></div>`}
function pageTitle(p,i){return p.cat==='home'&&p.name==='Home'?`<div class="sub">${new Date().toLocaleDateString('en-CA',{weekday:'long',month:'long',day:'numeric'})}</div><div class="hrow"><h1>Hi${P().name?' '+esc(P().name):''}</h1>${checksRow()}</div>`:`<div class="sub">${mixed(p.cat)?'Any widgets':'Section'}</div><h1>${esc(p.name)}</h1>`}

/* ---------- APPS (dock) ---------- */
const APPS={train:['Training',vTrain,'linear-gradient(160deg,#ff9f43,#ee5a24)'],food:['Food',vFood,'linear-gradient(160deg,#7bed9f,#20bf6b)'],progress:['History',vProgress,'linear-gradient(160deg,#70a1ff,#1e6fd9)'],recovery:['Sleep & body',vRecovery,'linear-gradient(160deg,#a29bfe,#5f27cd)'],me:['Settings',vMe,'linear-gradient(160deg,#c8ccd2,#7d848e)']};
const GLYPH={train:ICON.train,food:ICON.food,progress:ICON.progress,recovery:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M20 14.5A8 8 0 0 1 9.5 4a8 8 0 1 0 10.5 10.5z"/></svg>',me:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M12 15.5a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7z"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>'};
const appIcon=k=>`<span class="aico" style="background:${APPS[k][2]}">${GLYPH[k]}</span>`;
let OV=null; // {kind:'app',k} | {kind:'mini',id,days}
function curWidget(){return LAYOUT.flatMap(p=>p.w).find(x=>x.id===OV.id)}
function miniHTML(){const it=curWidget();if(!it)return '<div class="empty">Widget removed</div>';{const em=emptyOf(it.type,it.opt||{});if(em&&!['water','supps','rest'].includes(it.type))return `<div class="emptystate"><div class="big">${WT[it.type][1]}</div><b>${em[0]}</b><p class="muted">${em[2]||''}</p><button class="btn block" data-go="${em[3]}">${em[1]}</button></div>`}const T=WT[it.type],[cn,app]=CATS[T[2]];let body;
 try{body=T[7](Object.assign({},T[4],it.opt),OV.days)}catch(e){console.warn(e);body='<div class="empty">Unavailable</div>'}
 if(T[2]==='home')return body;return body+`<button class="btn ghost block openfull" data-go="${app}">Open ${cn} ›</button>`}
function ovTitle(){if(OV.kind==='app')return APPS[OV.k][0];const it=curWidget();if(!it)return '';const o=it.opt||{};return it.type==='graph'?METRIC[o.metric||'weight'][0]:WT[it.type][0]}
function ovBody(){return OV.kind==='app'?APPS[OV.k][1]():miniHTML()}
function drawOV(){let el=$('#ov');if(!OV){el&&el.remove();return}const keep=el?el.querySelector('.ovb').scrollTop:0;
 if(!el){el=document.createElement('div');el.id='ov';el.className='ov';$('#app').appendChild(el)}
 el.innerHTML=`<div class="ovh"><button class="back" data-close aria-label="Back">‹ Home</button><b>${esc(ovTitle())}</b>${OV.kind==='app'&&(OV.k==='train'||OV.k==='food')?'<button class="hdrhist" data-hist>History ›</button>':'<span style="width:56px"></span>'}</div><div class="ovb"><div class="pin">${ovBody()}</div></div><div class="homebar" role="button" aria-label="Swipe up to go Home"><i></i></div>`;
 el.querySelector('.ovb').scrollTop=keep;if(!canEdit())el.querySelectorAll('input,select,textarea').forEach(i=>{if(i.id!=='liftsel')i.disabled=true});bindOV(el)}
function rectFT(r){const W=VW(),H=VH(),f=FR();return `translate(${r.left-f.left}px,${r.top-f.top}px) scale(${r.width/W},${r.height/H})`}
function openOV(state,rect){OV=state;OV.rect=rect;drawOV();const el=$('#ov');if(!rect)rect={left:VW()*.3,top:VH()*.35,width:VW()*.4,height:VH()*.3};
 el.style.transition='none';el.style.transform=rectFT(rect);el.style.borderRadius='60px';el.style.opacity='.4';el.offsetWidth;
 el.style.transition='transform .42s cubic-bezier(.2,.9,.25,1),border-radius .42s,opacity .2s';el.style.transform='none';el.style.borderRadius='0';el.style.opacity='1';document.body.classList.add('ovopen')}
function closeOV(){const el=$('#ov');if(!el){OV=null;return}let r=OV.rect;const src=OV.kind==='mini'?document.querySelector(`.sb [data-wid="${OV.id}"]`):document.querySelector(`.dock [data-app="${OV.k}"]`);if(src)r=src.getBoundingClientRect();
 if(!r)r={left:VW()*.3,top:VH()*.35,width:VW()*.4,height:VH()*.3};
 el.style.transition='transform .36s cubic-bezier(.3,.7,.3,1),border-radius .36s,opacity .36s';el.style.transform=rectFT(r);el.style.borderRadius='60px';el.style.opacity='0';
 OV=null;document.body.classList.remove('ovopen');setTimeout(()=>{if(!OV)el.remove()},380);render()}
function bindOV(el){let st=null;
 el.querySelector('[data-close]').onclick=e=>{e.stopPropagation();closeOV()};const hh=el.querySelector('[data-hist]');if(hh)hh.onclick=e=>{e.stopPropagation();goPage('progress')};
 el.querySelectorAll('[data-x]').forEach(b=>b.onclick=e=>{e.stopPropagation();const v=b.dataset.v;if(b.dataset.x==='rest'){restTimer(+v);return}if(!canEdit())return toast('Read-only account — editing is disabled');if(b.dataset.x==='water'){const d=iso(new Date());WATER[d]=Math.max(0,X.water(d)+ +v);localStorage.setItem(WKEY,JSON.stringify(WATER));window.__lbLocalChange&&__lbLocalChange();drawOV();render();toast('Water updated')}if(b.dataset.x==='qlog'){const meal=mealNow();save(d=>{(d.food[iso(new Date())]=d.food[iso(new Date())]||[]).push({fid:v,meal,q:+b.dataset.q||1})},'Logged to '+meal)}});
 el.querySelectorAll('[data-mdays]').forEach(b=>b.onclick=e=>{e.stopPropagation();OV.days=b.dataset.mdays;drawOV()});
 // iOS-style home gesture: only from the bottom home-bar zone (~34px); edge-swipe right still goes back
 el.addEventListener('pointerdown',e=>{if(e.target.closest('button,a,input,select,label,textarea'))return;const fr=FR(),y=e.clientY-fr.top,hb=!!e.target.closest('.homebar')||y>VH()-34,edge=e.clientX-fr.left<20&&!hb;if(!hb&&!edge)return;
  e.preventDefault();st={x:e.clientX,y:e.clientY,t:Date.now(),mode:hb?'home':'back',hist:[[e.clientY,Date.now()]],p:0};el.classList.add('dragging');try{el.setPointerCapture(e.pointerId)}catch(_){}});
 el.addEventListener('pointermove',e=>{if(!st)return;const dx=e.clientX-st.x,dy=e.clientY-st.y,W=VW(),H=VH();
  if(st.mode==='back'){const p=Math.max(0,dx)/W;st.p=p;el.style.transition='none';el.style.transform=`translateX(${Math.max(0,dx)}px) scale(${1-p*.3})`;el.style.borderRadius=Math.min(40,p*200)+'px';return}
  st.hist.push([e.clientY,Date.now()]);if(st.hist.length>6)st.hist.shift();
  const up=Math.max(0,-dy),p=up/H,s=Math.max(.35,1-p*1.1),tx=W*(1-s)/2+dx*.35*s,ty=H-up-H*s;st.p=p;
  el.style.transition='none';el.style.transform=`translate(${tx}px,${ty}px) scale(${s})`;el.style.borderRadius=Math.min(44,8+p*160)+'px'});
 const end=()=>{if(!st)return;const m=st.mode,p=st.p||0,h=st.hist||[],a=h[0],z=h[h.length-1];const vy=a&&z&&z[1]>a[1]?(a[0]-z[0])/(z[1]-a[1]):0;st=null;el.classList.remove('dragging');
  if(m==='home'?(p>0.18||(vy>0.6&&p>0.05)):(p>0.3))closeOV();
  else{el.style.transition='transform .38s cubic-bezier(.2,1.25,.4,1),border-radius .38s';el.style.transform='none';el.style.borderRadius='0'}};
 el.addEventListener('pointerup',end);el.addEventListener('pointercancel',end)}
function goPage(k){const [a,seg]=k.split(':');if(seg)S.foodSeg=seg;if(a==='today'){if(OV)closeOV();return}
 if(!APPS[a])return;if(OV){OV={kind:'app',k:a,rect:OV.rect};drawOV();$('#ov .ovb').scrollTop=0;return}
 const ic=document.querySelector(`.dock [data-app="${a}"]`);openOV({kind:'app',k:a},ic?ic.getBoundingClientRect():null)}

/* ---------- SPRINGBOARD RENDER ---------- */
function render(){D=DB.get();syncMeals();applyTheme();document.body.classList.toggle('readonly',!canEdit());document.body.classList.toggle('editing',WSTATE.edit);metrics();document.body.classList.toggle('compact',SB.rh<125);
 const pages=pack();SB.n=pages.length;SB.cur=Math.min(SB.cur,pages.length-1);
 const edit=WSTATE.edit?`<div class="etools"><button class="pillbtn" data-pdel ${pages.length<2?'disabled':''}>− Page</button><button class="pillbtn" data-padd>＋ Page</button><button class="pillbtn" data-wadd aria-label="Add widget">＋ Widget</button><button class="pillbtn on" data-wdone>Done</button></div>`:'';
 $('#app').innerHTML=`<div class="sb" id="sb"><div class="track" id="track" style="transform:translateX(${-SB.cur*SB.W}px)">${pages.map((p,i)=>`<section class="page" data-pi="${i}" data-cat="${p.cat}"><div class="pin2"><header class="top">${WSTATE.edit&&i===SB.cur?edit:`<div style="min-width:0">${pageTitle(p,i)}</div>`}</header>
 <div class="wgrid" style="grid-template-rows:repeat(${SB.rows},${SB.rh}px)">${p.items.map(x=>widgetHTML(x.w,x.r,x.c)).join('')}</div>${p.items.length?'':`<div class="emptypg">${WSTATE.edit?'Empty page. Tap ＋ Widget to add one, or − Page to remove it.':'Empty page'}</div>`}</div></section>`).join('')}</div></div>
 ${D.active&&!OV?`<button class="fab-live" data-go="train"><span>● ${esc(D.active.name)} in progress</span><span>Resume ›</span></button>`:''}
 <div class="dockwrap"><div class="pdots">${pages.map((p,i)=>`<button data-pg="${i}" aria-label="${esc(p.name)}" class="${i===SB.cur?'on':''}"><i></i></button>`).join('')}</div><nav class="dock" aria-label="Apps">${['train','food','progress','recovery','me'].map(k=>`<button data-app="${k}" aria-label="${APPS[k][0]}">${appIcon(k)}<span>${APPS[k][0].split(' ')[0]}</span></button>`).join('')}</nav></div>`;
 if(OV){const el=document.createElement('div');el.id='ov';el.className='ov';$('#app').appendChild(el);el.innerHTML='<div class="ovb"></div>';drawOV()}
 bindSB();tickElapsed()}
function setPage(i,anim=true){i=Math.max(0,Math.min(SB.n-1,i));SB.cur=i;const t=$('#track');t.style.transition=anim?'transform .45s cubic-bezier(.2,.9,.25,1)':'none';t.style.transform=`translateX(${-i*SB.W}px)`;
 document.querySelectorAll('.pdots button').forEach((d,j)=>d.classList.toggle('on',j===i));if(WSTATE.edit)setTimeout(render,460)}
addEventListener('resize',()=>{clearTimeout(SB.rz);SB.rz=setTimeout(render,120)});
document.addEventListener('keydown',e=>{if(OV||$('.sheet')||/INPUT|SELECT|TEXTAREA/.test(document.activeElement?.tagName||''))return;if(e.key==='ArrowRight'){setPage(SB.cur+1);e.preventDefault()}if(e.key==='ArrowLeft'){setPage(SB.cur-1);e.preventDefault()}if(e.key==='Escape'&&WSTATE.edit)setEdit(false)});
document.addEventListener('keydown',e=>{if(e.key==='Escape'&&OV&&!$('.sheet'))closeOV()});
function setEdit(on){if(on)commitPack();WSTATE.edit=on;render()}
function bindSB(){const sb=$('#sb'),track=$('#track');let st=null,lp=null,edgeT=null;
 document.querySelectorAll('.dock [data-app]').forEach(b=>b.onclick=()=>{if(WSTATE.edit)setEdit(false);openOV({kind:'app',k:b.dataset.app},b.querySelector('.aico').getBoundingClientRect())});
 const q=s=>sb.querySelector(s);q('[data-wdone]')&&(q('[data-wdone]').onclick=()=>setEdit(false));q('[data-wadd]')&&(q('[data-wadd]').onclick=gallery);
 q('[data-padd]')&&(q('[data-padd]').onclick=()=>{const c=LAYOUT[SB.cur].cat==='home'?'other':LAYOUT[SB.cur].cat;LAYOUT.splice(SB.cur+1,0,{id:'p'+uid(),cat:c,name:PCAT[c],w:[]});commitPack();saveLayout();SB.cur++;render();toast('Page added')});
 q('[data-pdel]')&&(q('[data-pdel]').onclick=async()=>{const p=LAYOUT[SB.cur];if(p.cat==='home'&&p.name==='Home')return toast('The Home page can’t be removed');if(p.w.length&&!(await ui.confirm({title:'Remove this page?',message:`Its ${p.w.length} widget${p.w.length>1?'s':''} will be removed too.`,action:'Remove'})))return;LAYOUT.splice(SB.cur,1);if(!LAYOUT.some(x=>x.cat==='other'))LAYOUT.push({id:'p'+uid(),cat:'other',name:'Other',w:[]});commitPack();SB.cur=Math.max(0,SB.cur-1);render();toast('Page removed')});
 sb.addEventListener('contextmenu',e=>e.preventDefault());sb.addEventListener('dragstart',e=>e.preventDefault());
 document.querySelectorAll('.pdots [data-pg]').forEach(b=>b.onclick=()=>setPage(+b.dataset.pg));
 let wacc=0,wT=null;sb.addEventListener('wheel',e=>{const dx=Math.abs(e.deltaX)>Math.abs(e.deltaY)?e.deltaX:(e.shiftKey?e.deltaY:0);if(!dx||WSTATE.edit&&st)return;e.preventDefault();wacc-=dx;
  let off=wacc;if((SB.cur===0&&off>0)||(SB.cur===SB.n-1&&off<0))off=off/(1+Math.abs(off)/(SB.W*.35))*.6;track.style.transition='none';track.style.transform=`translateX(${-SB.cur*SB.W+off}px)`;
  clearTimeout(wT);wT=setTimeout(()=>{const a=wacc;wacc=0;setPage(SB.cur+(a<-SB.W*.15?1:a>SB.W*.15?-1:0))},140)},{passive:false});
 sb.addEventListener('pointerdown',e=>{if(e.target.closest('.etools'))return;const w=e.target.closest('.w');st={x:e.clientX,y:e.clientY,t:Date.now(),w,btn:e.target.closest('[data-wx],[data-wsz]'),mode:null,pid:e.pointerId,hist:[[e.clientX,Date.now()]]};
  if(!WSTATE.edit)lp=setTimeout(()=>{if(st&&!st.mode){st.mode='lp';navigator.vibrate?.(15);setEdit(true)}},500)});
 sb.addEventListener('pointermove',e=>{if(!st||st.mode==='lp')return;const dx=e.clientX-st.x,dy=e.clientY-st.y;st.hist.push([e.clientX,Date.now()]);if(st.hist.length>6)st.hist.shift();
  if(!st.mode&&Math.hypot(dx,dy)>8){clearTimeout(lp);if(WSTATE.edit&&st.w&&!st.btn){st.mode='wdrag';st.w.classList.add('drag');st.ox=0;st.oy=0}else st.mode=Math.abs(dx)>Math.abs(dy)?'pager':'none';try{sb.setPointerCapture(st.pid)}catch(_){}}
  if(st.mode==='pager'){let off=dx;if((SB.cur===0&&dx>0)||(SB.cur===SB.n-1&&dx<0))off=dx/(1+Math.abs(dx)/(SB.W*.35))*.6;track.style.transition='none';track.style.transform=`translateX(${-SB.cur*SB.W+off}px)`}
  if(st.mode==='wdrag'){const w=st.w;w.style.transform=`translate(${dx-st.ox}px,${dy-st.oy}px) scale(1.06)`;w.style.pointerEvents='none';
   const fx=e.clientX-FR().left,edge=fx<22?-1:fx>VW()-22?1:0;
   if(edge&&!edgeT)edgeT=setTimeout(()=>{edgeT=null;if(!st||st.mode!=='wdrag')return;const id=w.dataset.wid,from=LAYOUT[SB.cur],it=from.w.find(x=>x.id===id),to=SB.cur+edge;if(to<0)return;
    if(!LAYOUT[to])return;if(!mixed(LAYOUT[to].cat)&&LAYOUT[to].cat!==WT[it.type][2]){toast(`${CATS[WT[it.type][2]][0]} widgets can’t go on ${LAYOUT[to].name}`);return}from.w=from.w.filter(x=>x!==it);LAYOUT[to].w.push(it);commitPack();st=null;SB.cur=to;render();toast('Moved to page '+(to+1))},550);
   if(!edge){clearTimeout(edgeT);edgeT=null}
   const over=document.elementFromPoint(e.clientX,e.clientY)?.closest('.w');if(over&&over!==w&&!over.getAnimations().some(a=>!(window.CSSAnimation&&a instanceof CSSAnimation))){const pg=LAYOUT[SB.cur],a=pg.w.findIndex(x=>x.id===w.dataset.wid),b=pg.w.findIndex(x=>x.id===over.dataset.wid);
    if(a>=0&&b>=0){const r0=w.getBoundingClientRect();const [it]=pg.w.splice(a,1);pg.w.splice(b,0,it);const before=new Map([...w.parentNode.children].map(el=>[el.dataset.wid,el.getBoundingClientRect()]));
     const p2=pack()[SB.cur];p2.items.forEach(x=>{const el=w.parentNode.querySelector(`[data-wid="${x.w.id}"]`);if(el){el.style.gridRow=`${x.r+1} / span ${x.w.size==='L'?2:1}`;el.style.gridColumn=x.w.size==='S'?String(x.c+1):'1 / span 2'}});
     [...w.parentNode.children].forEach(el=>{if(el===w)return;const A=before.get(el.dataset.wid),B=el.getBoundingClientRect();if(A&&(A.left!==B.left||A.top!==B.top))el.animate([{transform:`translate(${A.left-B.left}px,${A.top-B.top}px)`},{transform:'none'}],{duration:240,easing:'cubic-bezier(.2,.8,.2,1)'})});
     const r1=w.getBoundingClientRect();st.ox+=r1.left-r0.left;st.oy+=r1.top-r0.top;w.style.transform=`translate(${dx-st.ox}px,${dy-st.oy}px) scale(1.06)`}}}});
 const end=e=>{clearTimeout(lp);clearTimeout(edgeT);edgeT=null;if(!st)return;const s=st;st=null;
  if(s.mode==='pager'){const dx=e.clientX-s.x,h=s.hist,v=h.length>1?(h[h.length-1][0]-h[0][0])/Math.max(1,h[h.length-1][1]-h[0][1]):0;let i=SB.cur;
   if(dx<-SB.W/2||v<-0.35)i++;else if(dx>SB.W/2||v>0.35)i--;setPage(i);return}
  if(s.mode==='wdrag'){saveLayout();commitPack();render();return}
  if(s.mode||e.type!=='pointerup'||Date.now()-s.t>480)return;
  if(WSTATE.edit){if(s.btn&&s.btn.matches('[data-wx]')){const id=s.w.dataset.wid;LAYOUT.forEach(p=>p.w=p.w.filter(x=>x.id!==id));saveLayout();s.w.animate([{transform:'scale(1)',opacity:1},{transform:'scale(.3)',opacity:0}],{duration:180}).onfinish=()=>{commitPack();render()}}
   else if(s.btn){const it=LAYOUT.flatMap(p=>p.w).find(x=>x.id===s.w.dataset.wid),sz=WT[it.type][3];it.size=sz[(sz.indexOf(it.size)+1)%sz.length];commitPack();render()}
   else if(s.w)wsettings(s.w.dataset.wid);else if(!e.target.closest('.top'))setEdit(false);return}
  const ql=e.target.closest('[data-qlog]');if(ql){if(!canEdit())return toast('Read-only account — editing is disabled');const meal=mealNow();save(d=>{(d.food[iso(new Date())]=d.food[iso(new Date())]||[]).push({fid:ql.dataset.qlog,meal,q:+ql.dataset.q||1})},'Logged to '+meal);return}
  if(s.w)openOV({kind:'mini',id:s.w.dataset.wid},s.w.getBoundingClientRect())};
 sb.addEventListener('pointerup',end);sb.addEventListener('pointercancel',end);
 sb.addEventListener('keydown',e=>{const w=e.target.closest('.w');if(w&&(e.key==='Enter'||e.key===' ')){e.preventDefault();WSTATE.edit?wsettings(w.dataset.wid):openOV({kind:'mini',id:w.dataset.wid},w.getBoundingClientRect())}})}
function gallery(){const pg=LAYOUT[SB.cur],cats=mixed(pg.cat)?Object.keys(CATS):[pg.cat];
 const item=([k,T])=>`<div class="gitem"><div class="gh"><span class="gic">${T[1]}</span><b>${T[0]}</b></div><div class="gprev">${T[3].map(sz=>`<button class="gsz" data-add="${k}" data-sz="${sz}"><div class="w ${sz} mini"><div class="wi">${T[6](sz,T[4])}</div></div><span>${SZN[sz]}</span></button>`).join('')}</div></div>`;
 sheet(`<h3>Add a widget</h3><p class="muted">${mixed(pg.cat)?'Any widget can go on this page.':`Only ${CATS[pg.cat][0]} widgets can go on this page.`} If it doesn’t fit, a new ${esc(PCAT[pg.cat])} page is added.</p>
 <div class="gal">${cats.map(c=>`${cats.length>1?`<h4 class="gcat">${CATS[c][0]}</h4>`:''}${Object.entries(WT).filter(([k,T])=>T[2]===c).map(item).join('')}`).join('')}</div>`,el=>{
 el.addEventListener('click',e=>{const b=e.target.closest('[data-add]');if(!b)return;LAYOUT[SB.cur].w.unshift(nw(b.dataset.add,b.dataset.sz));commitPack();closeSheet();render();toast(WT[b.dataset.add][0]+' widget added')})})}
function wsettings(id){const it=LAYOUT.flatMap(p=>p.w).find(x=>x.id===id);if(!it)return;const T=WT[it.type];it.opt=Object.assign({},T[4],it.opt);
 const draw=el=>{el.querySelector('#wprev').innerHTML=`<div class="w ${it.size}"><div class="wi">${T[6](it.size,it.opt)}</div></div>`};
 sheet(`<h3>${T[1]} ${T[0]} widget</h3><div class="wprev" id="wprev"></div>
 <label class="f">Size</label><div class="seg" data-k="__size">${T[3].map(s=>`<button class="${it.size===s?'on':''}" data-v="${s}">${SZN[s]}</button>`).join('')}</div>
 ${Object.entries(T[5]).map(([k,[lab,opts]])=>`<label class="f">${lab}</label><div class="seg wrap" data-k="${k}">${opts.map(([v,n])=>`<button class="${it.opt[k]===v?'on':''}" data-v="${v}">${n}</button>`).join('')}</div>`).join('')}
 <div class="grid2"><button class="btn danger" id="wrm">Remove</button><button class="btn" id="wok">Done</button></div>`,el=>{draw(el);
  el.addEventListener('click',e=>{const b=e.target.closest('.seg [data-v]');if(b){const k=b.parentNode.dataset.k;if(k==='__size')it.size=b.dataset.v;else it.opt[k]=b.dataset.v;b.parentNode.querySelectorAll('button').forEach(x=>x.classList.toggle('on',x===b));commitPack();draw(el);render()}});
  el.querySelector('#wok').onclick=()=>{closeSheet();render()};el.querySelector('#wrm').onclick=()=>{LAYOUT.forEach(p=>p.w=p.w.filter(x=>x.id!==id));commitPack();closeSheet();render()}})}

function tickElapsed(){const e=$('#elapsed');if(e&&D.active){const s=Math.floor((Date.now()-D.active.start)/1000);e.textContent=`${Math.floor(s/60)}:${String(s%60).padStart(2,'0')}`}}
setInterval(tickElapsed,1000);

/* ---------- EVENTS ---------- */
document.addEventListener('click',e=>{if(e.target.closest('#sb'))return;const g=e.target.closest('[data-go]');if(g){goPage(g.dataset.go);return}
 const sg=e.target.closest('[data-seg]');if(sg){S[sg.dataset.seg]=sg.dataset.v;render();return}
 const b=e.target.closest('[data-act]');if(!b||!$('#app').contains(b))return;const a=b.dataset.act,ds=b.dataset;
 const viewOnly=['fcr','fcm','fcmo','sessall','td','tdtoday','fdtoday','calday','trm','histmore','supp_','tpl','exinfo','openw','fd','cm','signin','export','tour','thmode','cw','editmode','resetlayout'];if(!canEdit()&&!viewOnly.includes(a))return toast('Read-only account — editing is disabled');
 switch(a){
 case 'thmode':TH.mode=ds.v;saveTheme();render();break;
 case 'cw':TH.cw=ds.v;saveTheme();render();break;
 case 'editmode':closeOV();setTimeout(()=>setEdit(true),420);break;
 case 'resetlayout':ui.confirm({title:'Reset home screen?',message:'All pages and widgets go back to the default layout.',action:'Reset'}).then(ok=>{if(ok){LAYOUT=defaultLayout();saveLayout();render();toast('Home screen reset')}});break;
 case 'start':startSession(ds.t,S.trDate&&S.trDate!==iso(new Date())?S.trDate:undefined);break;
 case 'fcr':S.fcRange=ds.v;OV?drawOV():render();break;
 case 'fcm':S.fcMetric=ds.v;OV?drawOV():render();break;
 case 'fcmo':S.fcMonth=Math.min(0,(S.fcMonth||0)+ +ds.n);OV?drawOV():render();break;
 case 'sessall':S.sessAll=true;OV?drawOV():render();break;
 case 'td':{const td=iso(new Date());let v=iso(new Date(new Date((S.trDate||td)+'T12:00').getTime()+ds.n*864e5));if(v>td)v=td;S.trDate=v;render();break}
 case 'tdtoday':S.trDate=iso(new Date());render();break;
 case 'fdtoday':S.foodDate=iso(new Date());render();break;
 case 'addset':save(d=>{const s=d.active.exercises[ds.ei].sets;const l=s[s.length-1]||{w:'',r:8};s.push({w:l.w,r:l.r,done:false})});break;
 case 'done':save(d=>{const s=d.active.exercises[ds.ei].sets[ds.si];s.done=!s.done;if(s.done)restTimer(90)});break;
 case 'rmex':save(d=>d.active.exercises.splice(ds.ei,1));break;
 case 'pickex':pickExercise({title:'Add exercise',label:'Add'},n=>save(d=>d.active.exercises.push(newEx(n)),'Added '+n));break;
 case 'repl':{const ei=+ds.ei,old=D.active.exercises[ei].name;pickExercise({title:'Replace '+old,first:groupOf(old),label:'Use'},n=>save(d=>{d.active.exercises[ei]=newEx(n)},'Replaced with '+n));break}
 case 'tpl':tplSheet(+ds.i);break;
 case 'calday':daySheet(ds.d);break;
 case 'trm':S.trMonth=(S.trMonth||0)+ +ds.n;render();break;
 case 'histmore':S.histAll=!S.histAll;render();break;
 case 'scan':scanSheet(ds.meal);break;
 case 'customfood':customFoodSheet({},ds.meal);break;
 case 'exinfo':exDetail(ds.n);break;
 case 'exform':exForm();break;
 case 'splitskip':{const sp=splitOf();if(!sp)break;const i=splitNext();save(d=>{(d.splitMarks=d.splitMarks||[]).push({date:iso(new Date()),idx:i,ts:Date.now()})},`Day ${i+1} marked done`);break}
 case 'splitreset':{const sp=splitOf();if(!sp)break;save(d=>{(d.splitMarks=d.splitMarks||[]).push({date:iso(new Date()),idx:sp.length-1,ts:Date.now()})},'Next up: Day 1');break}
 case 'clearw':ui.confirm({title:'Clear all workouts?',message:'Removes every workout and your split. Logged sessions stay.',action:'Clear all'}).then(ok=>{if(ok)save(d=>{d.templates=[];d.split=[];d.splitMarks=[];d.active=null},'Workouts cleared')});break;
 case 'finish':{const a2=D.active;const kept=a2.exercises.map(e=>({...e,sets:e.sets.filter(s=>s.done&&s.w!=='')})).filter(e=>e.sets.length);if(!kept.length)return toast('Tick at least one set first');
  save(d=>{d.workouts.push({id:a2.id,date:a2.date,name:a2.name,notes:a2.notes||'',exercises:kept});d.active=null},'Workout saved 💪');clearInterval(restT);break}
 case 'discard':ui.confirm({title:'Discard this session?',message:'Sets you’ve entered in this session will be lost.',action:'Discard'}).then(ok=>{if(ok)save(d=>d.active=null,'Session discarded')});break;
 case 'openw':openWorkout(ds.id);break;
 case 'newtpl':ui.prompt({title:'New workout',placeholder:'e.g. Upper A',action:'Create'}).then(n=>{if(n&&n.trim()){if(D.templates.some(t=>t.name===n.trim()))return toast('That name exists');save(d=>d.templates.push({name:n.trim(),exercises:[]}),'Workout created');tplSheet(D.templates.length-1)}});break;
 case 'addfood':foodSheet(ds.meal,ds.plan);break;
 case 'rmfood':save(d=>d.food[S.foodDate].splice(+ds.i,1));break;
 case 'newsaved':ui.prompt({title:'New saved meal',placeholder:'e.g. Usual breakfast',action:'Create'}).then(n=>{if(n&&n.trim()){save(d=>{(d.savedMeals=d.savedMeals||[]).push({name:n.trim(),items:[]})},'Saved meal created');foodSheet(MEALS[0],'s'+(SM().length-1))}});break;
 case 'savemeal':{const m=ds.meal,items=(D.food[S.foodDate]||[]).filter(e=>e.meal===m);if(!items.length)break;ui.prompt({title:'Save as meal',message:`Saves the ${items.length} food${items.length>1?'s':''} in ${MLBL(m)} for one-tap logging.`,value:`My ${MLBL(m).toLowerCase()}`,action:'Save'}).then(n=>{if(n&&n.trim())save(d=>{(d.savedMeals=d.savedMeals||[]).push({name:n.trim(),items:items.map(e=>{const o=Object.assign({},e);delete o.meal;delete o.i;return o})})},'Saved “'+n.trim()+'”')});break}
 case 'goals':if(!canEdit())return toast('Read-only account — editing is disabled');goalsSheet(ds.d);break;
 case 'sgoogle':SYNC.google().catch(e=>toast(authErr(e)));break;
 case 'semail':case 'screate':{const em=($('#semail')||{}).value||'',pw=($('#spass')||{}).value||'';if(!em||!pw)return toast('Enter email and password');SYNC.email(em.trim(),pw,a==='screate').then(()=>toast(a==='screate'?'Account created':'Signed in')).catch(e=>toast(authErr(e)));break}
 case 'sreset':{const em=($('#semail')||{}).value||'';if(!em)return toast('Enter your email first');SYNC.reset(em.trim()).then(()=>ui.alert({title:'Check your email',message:'We sent a password reset link to '+em.trim()+'.'})).catch(e=>toast(authErr(e)));break}
 case 'ssync':SYNC.syncNow();break;
 case 'sout':ui.confirm({title:'Sign out?',message:'Your data stays on this device. Sign in again to resume syncing.',action:'Sign out',destructive:false}).then(ok=>{if(ok)SYNC.signOut().then(()=>toast('Signed out'))});break;
 case 'addmeal':save(d=>{const sl=(d.mealSlots&&d.mealSlots.length?d.mealSlots:slots()).slice();let n=1;while(sl.some(x=>x.id==='m'+n))n++;sl.push({id:'m'+n,name:'Meal '+(sl.length+1)});d.mealSlots=sl},'Meal added');break;
 case 'mealmenu':{const m=ds.meal,name=MLBL(m),cnt=Object.values(D.food).reduce((a,day)=>a+(day||[]).filter(e=>e.meal===m).length,0);
  ui.menu({title:name,actions:[{label:'Rename',value:'rename'}].concat(slots().length>1?[{label:'Remove meal',value:'remove',destructive:true}]:[])}).then(v=>{
   if(v==='rename')ui.prompt({title:'Rename meal',value:name,action:'Save'}).then(n=>{if(n&&n.trim())save(d=>{d.mealSlots=slots().map(x=>x.id===m?{...x,name:n.trim()}:x)},'Renamed')});
   if(v==='remove'){const to=MEALS.find(x=>x!==m);ui.confirm({title:'Remove “'+name+'”?',message:cnt?`${cnt} logged item${cnt>1?'s':''} in this slot will move to ${MLBL(to)}.`:'The slot is removed from every day.',action:'Remove'}).then(ok=>{if(ok)save(d=>{d.mealSlots=slots().filter(x=>x.id!==m);Object.values(d.food).forEach(day=>(day||[]).forEach(e=>{if(e.meal===m)e.meal=to}))},'Meal removed')})}});break}
 case 'archlog':logAsk(ds.fid,mealNow());break;
 case 'archedit':customFoodSheet(Object.assign({},food(ds.fid)));break;
 case 'archdel':ui.confirm({title:'Delete “'+food(ds.fid).name+'”?',message:'It will be removed from your food archive and any saved meals. Past logs keep their entries.',action:'Delete'}).then(ok=>{if(ok)save(d=>{d.foods=d.foods.filter(f=>f.id!==ds.fid);(d.savedMeals||[]).forEach(m=>m.items=m.items.filter(e=>e.fid!==ds.fid))},'Deleted from archive')});break;
 case 'logsaved':{const x=SM()[+ds.j];if(!x||!x.items.length){toast('Add foods to this meal first');break}const m=ds.meal||mealNow();save(d=>{const t=S.foodDate||iso(new Date());d.food[t]=d.food[t]||[];x.items.forEach(e=>{d.food[t].push(Object.assign({},e,{meal:m}));})},`Logged ${x.name} to ${MLBL(m)}`);break}
 case 'sqedit':{const e=SM()[+ds.j].items[+ds.i];amountSheet(e.fid,{init:e,cta:'Update amount'},ne=>save(d=>{d.savedMeals[+ds.j].items[+ds.i]=Object.assign({fid:e.fid},ne)},'Amount updated'));break}
 case 'sq':save(d=>{const e=d.savedMeals[+ds.j].items[+ds.i];e.q=Math.max(0.5,+(e.q+ +ds.n).toFixed(1))});break;
 case 'rmsaveditem':save(d=>d.savedMeals[+ds.j].items.splice(+ds.i,1));break;
 case 'renamesaved':{const x=SM()[+ds.j];ui.prompt({title:'Rename meal',value:x.name,action:'Save'}).then(n=>{if(n&&n.trim())save(d=>d.savedMeals[+ds.j].name=n.trim(),'Renamed')});break}
 case 'delsaved':ui.confirm({title:'Delete “'+SM()[+ds.j].name+'”?',message:'The saved meal is removed. Foods stay in your archive.',action:'Delete'}).then(ok=>{if(ok)save(d=>d.savedMeals.splice(+ds.j,1),'Deleted')});break;
 case 'fd':S.foodDate=iso(new Date(new Date(S.foodDate+'T12:00').getTime()+ds.n*864e5));render();break;
 case 'cm':S.calMonth+=+ds.n;render();break;
 case 'sleep':{const t=iso(new Date()),cur=D.sleep.find(s=>s.date===t)||{hours:7.5,quality:3};sheet(`<h3>Log sleep</h3><label class="f">Hours slept</label><input id="sh" inputmode="decimal" value="${cur.hours}"><label class="f">Quality</label><div class="seg" id="sq">${[1,2,3,4,5].map(q=>`<button class="${q===cur.quality?'on':''}" data-q="${q}">${q}★</button>`).join('')}</div><button class="btn block" id="ss">Save sleep</button>`,el=>{let q=cur.quality;el.querySelector('#sq').onclick=ev=>{const x=ev.target.closest('[data-q]');if(!x)return;q=+x.dataset.q;el.querySelectorAll('#sq button').forEach(y=>y.classList.toggle('on',y===x))};
  el.querySelector('#ss').onclick=()=>{const h=+el.querySelector('#sh').value;if(!(h>0&&h<24))return toast('Enter hours 0–24');save(d=>{d.sleep=d.sleep.filter(s=>s.date!==t);d.sleep.push({date:t,hours:h,quality:q})},'Sleep saved');closeSheet()}});break}
 case 'weight':{const t=iso(new Date()),cur=D.weight.find(s=>s.date===t);sheet(`<h3>Log body weight</h3><label class="f">Weight (${U()})</label><input id="wv" inputmode="decimal" value="${cur?toDisp(cur.kg):''}"><button class="btn block" style="margin-top:12px" id="ws">Save</button>`,el=>{el.querySelector('#ws').onclick=()=>{const v=+el.querySelector('#wv').value;if(!(v>0))return toast('Enter a weight');save(d=>{d.weight=d.weight.filter(s=>s.date!==t);d.weight.push({date:t,kg:fromDisp(v)})},'Weight saved');closeSheet()}});break}
 case 'supp':save(d=>{const t=iso(new Date()),l=d.supplements.log[t]=d.supplements.log[t]||[];const i=l.indexOf(ds.s);i<0?l.push(ds.s):l.splice(i,1)});break;
 case 'addsupp':ui.prompt({title:'Add supplement',placeholder:'e.g. Creatine',action:'Add'}).then(n=>{if(n&&n.trim())save(d=>d.supplements.list.push(n.trim()))});break;
 case 'signin':DB.signIn(ds.id);D=DB.get();closeOV();toast('Signed in as '+DB.currentUser().name);break;
 case 'export':exportData(ds.k);break;
 case 'tour':onboarding(true);break;
 case 'reset':ui.confirm({title:'Erase all data?',message:'Everything you’ve logged in this preview on this device will be deleted. This can’t be undone.',action:'Erase'}).then(ok=>{if(ok){D=DB.reset();render();welcome()}});break;
 }});
document.addEventListener('input',e=>{if(e.target.id==='archq'){S.archQ=e.target.value;if(OV){drawOV();const i=$('#archq');if(i){i.focus();i.setSelectionRange(i.value.length,i.value.length)}}return}if(e.target.id==='libq'){S.libQ=e.target.value;const a=$('#libacc');if(a)a.innerHTML=libAccordion(S.libQ)}});
document.addEventListener('toggle',e=>{const d=e.target;if(d.matches&&d.matches('#libacc details')&&!S.libQ){S.libOpen=S.libOpen||{};S.libOpen[d.dataset.g]=d.open}},true);
document.addEventListener('change',e=>{const t=e.target;if(t.dataset&&t.dataset.splitn!=null){const n=+t.value;save(d=>{const a=Array.isArray(d.split)?d.split.slice(0,n):[];while(a.length<n)a.push('rest');d.split=a},`Split is now ${n} days`);return}if(t.dataset&&t.dataset.split!=null){save(d=>{d.split=Array.isArray(d.split)?d.split:[];d.split[+t.dataset.split]=t.value},'Split updated');return}
 if(t.id==='liftsel'){S.liftEx=t.value;render();return}
 if(t.id==='imp'){const f=t.files[0];if(!f)return;f.text().then(s=>{try{const j=JSON.parse(s);if(!j.profile||!j.workouts)throw 0;DB.replace(j);render();toast('Backup imported')}catch(x){toast('That file is not a Logbook backup')}});return}
 if(t.dataset.p){const k=t.dataset.p,num=['weekGoal','sleepGoal'].includes(k);save(d=>d.profile[k]=num?(+t.value||0):t.value,'Saved');return}
 if(t.dataset.t){save(d=>d.profile.targets[t.dataset.t]=+t.value||0,'Target saved');return}
 if(t.dataset.f&&D.active){const v=t.value.trim();save(d=>{const s=d.active.exercises[t.dataset.ei].sets[t.dataset.si];s[t.dataset.f]=t.dataset.f==='w'?(v===''?'':fromDisp(+v)):(+v||0)})}
 if(t.id==='sdate'&&D.active){const v=t.value;if(!v||v>iso(new Date()))return toast('Pick today or a past date');save(d=>d.active.date=v,'Session date set');return}
 if(t.id==='snote'&&D.active){save(d=>d.active.notes=t.value.trim(),'Note saved');return}
 if(t.dataset&&t.dataset.exnote!=null&&D.active){save(d=>{d.active.exercises[+t.dataset.exnote].note=t.value.trim()},'Note saved');return}
 if(t.id==='sname'&&D.active)save(d=>d.active.name=t.value.trim()||'Workout')});

render();
if(!D.mealSlots&&canEdit()){DB.mutate(d=>migrateMeals(d));D=DB.get()}syncMeals();
if(D.foods.some(f=>!f.kind)&&canEdit()){DB.mutate(d=>{d.foods=d.foods.map(f=>f.kind?f:normFood(f))});D=DB.get()}
if(!P().goalHist&&canEdit()){DB.mutate(d=>{d.profile.goalHist=[{from:'2000-01-01',t:Object.assign({},d.profile.targets)}]});D=DB.get()}
if(!P().onboarded&&canEdit()){if(window.SYNC)welcome(!!localStorage.getItem('lb2w:signedin'));else onboarding(false)}
window.SYNC&&SYNC.on(()=>{const c=document.getElementById('acct');if(c){const em=(document.getElementById('semail')||{}).value;const t=document.createElement('div');t.innerHTML=accountCard();c.replaceWith(t.firstElementChild);const e2=document.getElementById('semail');if(e2&&em)e2.value=em}});

})();

/* preview update: own service worker (scope /preview-widget/) + version check */
(function(){if('serviceWorker'in navigator){navigator.serviceWorker.register('sw.js?v='+PREVIEW_VER,{scope:'./'}).then(r=>r.update()).catch(()=>{});
 let reloaded=false;navigator.serviceWorker.addEventListener('controllerchange',()=>{if(reloaded)return;reloaded=true;location.reload()})}
 const chk=()=>fetch('version.json?t='+Date.now(),{cache:'no-store'}).then(r=>r.json()).then(async j=>{if(!j.v||j.v===PREVIEW_VER||sessionStorage.getItem('lb2w:vr')===j.v)return;sessionStorage.setItem('lb2w:vr',j.v);
  try{const rs=await navigator.serviceWorker?.getRegistrations?.()||[];await Promise.all(rs.filter(r=>r.scope.includes('/preview-widget/')).map(r=>r.update()));const ks=await caches.keys();await Promise.all(ks.filter(k=>k.startsWith('lb2w-preview')).map(k=>caches.delete(k)))}catch(e){}
  location.replace(location.pathname+'?v='+j.v)}).catch(()=>{});
 chk();document.addEventListener('visibilitychange',()=>{if(document.visibilityState==='visible')chk()});window.addEventListener('pageshow',e=>{if(e.persisted)chk()})})();
