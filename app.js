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
delete CW[0];
const CW_ORDER=['teal',1,2,3,4,5,6,7,8,9,10].map(String);
const TH_KEY='lb2w:theme',LY_KEY='lb2w:layout';
const TH=Object.assign({cw:'teal',mode:'auto'},JSON.parse(localStorage.getItem(TH_KEY)||'{}'));
const PAGES=[['today','Home'],['train','Training'],['food','Food'],['recovery','Sleep & body'],['progress','History'],['me','Settings']];

/* ---------- helpers ---------- */
const P=()=>D.profile, U=()=>P().units;
const toDisp=kg=>U()==='lb'?Math.round(kg*2.20462*10)/10:kg;
const fromDisp=v=>U()==='lb'?Math.round(v/2.20462*100)/100:+v;
const uid=()=>Math.random().toString(36).slice(2,9);
const food=id=>D.foods.find(f=>f.id===id)||{name:'(deleted)',kcal:0,p:0,c:0,f:0};
const totals=list=>list.reduce((t,e)=>{const f=food(e.fid);t.kcal+=f.kcal*e.q;t.p+=f.p*e.q;t.c+=f.c*e.q;t.f+=f.f*e.q;return t},{kcal:0,p:0,c:0,f:0});
const prettyDate=d=>new Date(d+'T12:00').toLocaleDateString(undefined,{weekday:'short',month:'short',day:'numeric'});
const epley=(w,r)=>r>0?w*(1+r/30):0;
const canEdit=()=>DB.canEdit();
function toast(m){const t=$('#toast');t.textContent=m;t.classList.add('on');clearTimeout(t._h);t._h=setTimeout(()=>t.classList.remove('on'),1800)}
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
function macroBars(t){const g=P().targets;return [['Protein','p','var(--p)'],['Carbs','c','var(--c)'],['Fat','f','var(--f)']].map(([n,k,col])=>`<div class="macro"><span>${n}</span><div class="bar"><i style="width:${Math.min(100,t[k]/g[k]*100)}%;background:${col}"></i></div><span class="muted">${Math.round(t[k])}/${g[k]}g</span></div>`).join('')}
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
 const W=340,mx=Math.max(...pts.map(p=>p.y),goal||0)||1,bw=(W-8)/pts.length;
 return `<svg class="chart" viewBox="0 0 ${W} ${h}">${goal?`<line x1="0" x2="${W}" y1="${h-16-goal/mx*(h-26)}" y2="${h-16-goal/mx*(h-26)}" stroke="var(--accent2)" stroke-dasharray="4 4"/>`:''}
 ${pts.map((p,i)=>{const bh=p.y/mx*(h-26);return `<rect x="${4+i*bw+bw*.18}" y="${h-16-bh}" width="${bw*.64}" height="${Math.max(bh,1)}" rx="4" fill="var(--accent)"/><text x="${4+i*bw+bw/2}" y="${h-3}" font-size="9" text-anchor="middle" fill="var(--muted)">${esc(p.x)}</text>`}).join('')}</svg>`}

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
 const low=D.pantry.filter(p=>pantryStatus(p)!=='ok');if(low.length)tips.push(`${low.length} pantry item${low.length>1?'s':''} low or out: ${low.map(p=>p.name).join(', ')}.`);
 return tips}
function vToday(){const today=iso(new Date()),t=totals(D.food[today]||[]),g=P().targets;
 const sl=D.sleep.find(s=>s.date===today),wt=D.weight.find(w=>w.date===today);
 const supps=D.supplements.log[today]||[];const done=D.workouts.find(w=>w.date===today);
 const nextT=D.templates[D.workouts.length%D.templates.length];
 return `<div class="card"><h2>Fuel <small>${Math.round(g.kcal-t.kcal)} kcal left</small></h2><div class="row">${ring(t.kcal,g.kcal,'of '+g.kcal+' kcal')}<div class="grow">${macroBars(t)}</div></div>
 <button class="btn ghost block sm" style="margin-top:10px" data-edit data-act="addfood">＋ Log food</button></div>
 <div class="card"><h2>Training <small>${done?'Done ✓':''}</small></h2>${D.active?`<p class="muted">Session in progress: <b>${esc(D.active.name)}</b></p><button class="btn block" data-go="train">Resume session</button>`:done?`<p class="muted">${esc(done.name)} · ${done.exercises.length} exercise${done.exercises.length===1?"":"s"} · ${vol(done)} ${U()} volume</p>`:`<p class="muted">Suggested next: <b>${esc(nextT.name)}</b> (${nextT.exercises.join(', ')})</p><button class="btn block" data-edit data-act="start" data-t="${esc(nextT.name)}">Start ${esc(nextT.name)}</button>`}</div>
 <div class="grid2"><div class="card" style="margin:0 0 12px"><h2>Sleep</h2><b style="font-size:26px">${sl?sl.hours+' h':'—'}</b><div class="muted">${sl?'★'.repeat(sl.quality)+'☆'.repeat(5-sl.quality):'Not logged'}</div><button class="btn ghost sm block" style="margin-top:8px" data-edit data-act="sleep">${sl?'Edit':'Log'}</button></div>
 <div class="card" style="margin:0 0 12px"><h2>Weight</h2><b style="font-size:26px">${wt?toDisp(wt.kg)+' '+U():'—'}</b><div class="muted">${wt?'Today':'Not logged'}</div><button class="btn ghost sm block" style="margin-top:8px" data-edit data-act="weight">${wt?'Edit':'Log'}</button></div></div>
 <div class="card"><h2>Supplements <small>${supps.length}/${D.supplements.list.length}</small></h2><div class="chips">${D.supplements.list.map(s=>`<button class="chip ${supps.includes(s)?'on':''}" data-act="supp" data-s="${esc(s)}" ${canEdit()?'':'disabled'}>${supps.includes(s)?'✓ ':''}${esc(s)}</button>`).join('')}<button class="chip" data-edit data-act="addsupp">＋</button></div></div>
 <div class="card"><h2>Coach</h2>${coachTips().map(x=>`<div class="tip">${esc(x)}</div>`).join('')||'<div class="muted">All on track. Nice.</div>'}</div>`}
const vol=w=>Math.round(w.exercises.reduce((a,e)=>a+e.sets.reduce((b,s)=>b+(s.done?toDisp(s.w)*s.r:0),0),0));

/* ---------- TRAIN ---------- */
function vTrain(){const a=D.active;
 if(a){return `<div class="card"><h2>${esc(a.name)} <small id="elapsed"></small></h2><input data-edit id="sname" value="${esc(a.name)}" aria-label="Session name"></div>
 ${a.exercises.map((e,ei)=>`<div class="card"><h2>${esc(e.name)} <button class="icon-btn" data-edit data-act="rmex" data-ei="${ei}" aria-label="Remove exercise">✕</button></h2>
 <div class="muted" style="margin-bottom:4px">${lastFor(e.name)}</div>
 <div class="set muted" style="font-size:12px"><span class="n">Set</span><span class="n">${U()}</span><span class="n">Reps</span><span></span></div>
 ${e.sets.map((s,si)=>`<div class="set"><span class="n">${si+1}</span><input inputmode="decimal" data-f="w" data-ei="${ei}" data-si="${si}" value="${s.w===''?'':toDisp(s.w)}" aria-label="Weight"><input inputmode="numeric" data-f="r" data-ei="${ei}" data-si="${si}" value="${s.r}" aria-label="Reps"><button class="chk ${s.done?'on':''}" data-act="done" data-ei="${ei}" data-si="${si}" aria-label="Mark set done">✓</button></div>`).join('')}
 <button class="btn ghost sm block" data-act="addset" data-ei="${ei}">＋ Add set</button></div>`).join('')}
 <button class="btn ghost block" data-act="pickex">＋ Add exercise</button>
 <div class="grid2" style="margin-top:12px"><button class="btn danger" data-act="discard">Discard</button><button class="btn" data-act="finish">Finish workout</button></div>`}
 const recent=[...D.workouts].sort((a,b)=>b.date.localeCompare(a.date)).slice(0,12);
 return `<div class="card"><h2>Start a session</h2><div class="list">${D.templates.map(t=>`<div class="item"><div class="grow"><div class="t">${esc(t.name)}</div><div class="s">${esc(t.exercises.join(' · '))}</div></div><button class="btn sm" data-edit data-act="start" data-t="${esc(t.name)}">Start</button></div>`).join('')}</div>
 <div class="grid2" data-edit style="margin-top:8px"><button class="btn ghost sm" data-act="start" data-t="">Empty session</button><button class="btn ghost sm" data-act="newtpl">New template</button></div></div>
 <div class="card"><h2>History <small>${D.workouts.length} sessions</small></h2><div class="list">${recent.map(w=>`<button class="item" style="background:none;border-left:0;border-right:0;border-bottom:0;width:100%;text-align:left;cursor:pointer" data-act="openw" data-id="${w.id}"><div class="grow"><div class="t">${esc(w.name)}</div><div class="s">${prettyDate(w.date)} · ${w.exercises.length} exercise${w.exercises.length===1?"":"s"}</div></div><span class="pill">${vol(w).toLocaleString()} ${U()}</span></button>`).join('')||'<div class="empty">No workouts yet</div>'}</div></div>
 <div class="card"><h2>Exercise library <small>${D.exerciseLib.length}</small></h2><div class="chips">${D.exerciseLib.map(e=>`<span class="chip" style="cursor:default">${esc(e)}</span>`).join('')}</div>
 <div class="row" data-edit style="margin-top:10px"><input id="newex" placeholder="New exercise name"><button class="btn sm" data-act="libadd">Add</button></div></div>`}
function lastFor(name){const w=[...D.workouts].reverse().find(w=>w.exercises.some(e=>e.name===name));if(!w)return 'First time — set a baseline';
 const e=w.exercises.find(e=>e.name===name);return 'Last: '+e.sets.map(s=>toDisp(s.w)+'×'+s.r).join(', ')}
function startSession(tname){const t=D.templates.find(x=>x.name===tname);
 save(d=>{d.active={id:'w'+uid(),date:iso(new Date()),start:Date.now(),name:t?t.name:'Workout',exercises:(t?t.exercises:[]).map(n=>newEx(n))}},'Session started');goPage('train')}
function newEx(n){const w=[...D.workouts].reverse().find(w=>w.exercises.some(e=>e.name===n));const prev=w&&w.exercises.find(e=>e.name===n);
 return {name:n,sets:prev?prev.sets.map(s=>({w:s.w,r:s.r,done:false})):[{w:'',r:8,done:false},{w:'',r:8,done:false},{w:'',r:8,done:false}]}}
let restT=null;
function restTimer(sec=90){clearInterval(restT);let left=sec;const tick=()=>{toast(left>0?`Rest ${Math.floor(left/60)}:${String(left%60).padStart(2,'0')}`:'Rest over — next set');if(left--<=0){clearInterval(restT);navigator.vibrate?.(200)}};tick();restT=setInterval(tick,1000)}

/* ---------- FOOD ---------- */
function vFood(){return `<div class="seg">${[['log','Log'],['plan','Meal plan'],['pantry','Pantry']].map(([k,n])=>`<button class="${S.foodSeg===k?'on':''}" data-seg="foodSeg" data-v="${k}">${n}</button>`).join('')}</div>`+
 (S.foodSeg==='log'?vFoodLog():S.foodSeg==='plan'?vPlan():vPantry())}
const MEALS=['Breakfast','Lunch','Snack','Dinner'];
function vFoodLog(){const day=D.food[S.foodDate]||[],t=totals(day),g=P().targets;
 return `<div class="card"><div class="row"><button class="icon-btn" data-act="fd" data-n="-1" aria-label="Previous day">‹</button><div class="grow" style="text-align:center;font-weight:650">${S.foodDate===iso(new Date())?'Today':prettyDate(S.foodDate)}</div><button class="icon-btn" data-act="fd" data-n="1" aria-label="Next day">›</button></div>
 <div class="row" style="margin-top:12px">${ring(t.kcal,g.kcal,'kcal',96)}<div class="grow">${macroBars(t)}</div></div></div>
 ${MEALS.map(m=>{const items=day.map((e,i)=>({...e,i})).filter(e=>e.meal===m),mt=totals(items);return `<div class="card"><h2>${m} <small>${Math.round(mt.kcal)} kcal</small></h2><div class="list">${items.map(e=>{const f=food(e.fid);return `<div class="item"><div class="grow"><div class="t">${esc(f.name)}${e.q!==1?' ×'+e.q:''}</div><div class="s">${Math.round(f.kcal*e.q)} kcal · P${Math.round(f.p*e.q)} C${Math.round(f.c*e.q)} F${Math.round(f.f*e.q)}</div></div><button class="icon-btn" data-edit data-act="rmfood" data-i="${e.i}" aria-label="Remove">✕</button></div>`}).join('')||'<div class="muted">Nothing logged</div>'}</div>
 <button class="btn ghost sm block" style="margin-top:8px" data-edit data-act="addfood" data-meal="${m}">＋ Add to ${m.toLowerCase()}</button></div>`}).join('')}`}
function vPlan(){const g=P().targets,all=MEALS.flatMap(m=>D.mealPlan[m]||[]),t=totals(all);
 return `<div class="card"><h2>Daily plan vs targets</h2><div class="grid2">${[['kcal','Calories',''],['p','Protein','g'],['c','Carbs','g'],['f','Fat','g']].map(([k,n,u])=>`<div class="stat"><b>${Math.round(t[k])}${u}</b><span>${n} · target ${g[k]}${u}</span><div class="bar" style="margin-top:6px"><i style="width:${Math.min(100,t[k]/g[k]*100)}%"></i></div></div>`).join('')}</div>
 <button class="btn block" style="margin-top:12px" data-edit data-act="logplan">Log whole plan to today</button></div>
 ${MEALS.map(m=>`<div class="card"><h2>${m} <small>${Math.round(totals(D.mealPlan[m]||[]).kcal)} kcal</small></h2><div class="list">${(D.mealPlan[m]||[]).map((e,i)=>{const f=food(e.fid);return `<div class="item"><div class="grow"><div class="t">${esc(f.name)}${e.q!==1?' ×'+e.q:''}</div><div class="s">${Math.round(f.kcal*e.q)} kcal · P${Math.round(f.p*e.q)}</div></div><button class="icon-btn" data-edit data-act="rmplan" data-m="${m}" data-i="${i}" aria-label="Remove">✕</button></div>`}).join('')||'<div class="muted">Empty</div>'}</div><button class="btn ghost sm block" style="margin-top:8px" data-edit data-act="addfood" data-meal="${m}" data-plan="1">＋ Add to plan</button></div>`).join('')}`}
function vPantry(){const low=D.pantry.filter(p=>pantryStatus(p)!=='ok');
 const days=D.pantry.map(p=>{const f=p.fid;if(!f)return null;let use=0;MEALS.forEach(m=>(D.mealPlan[m]||[]).forEach(e=>{if(e.fid===f)use+=e.q}));return use?{p,use}:null}).filter(Boolean);
 return `${low.length?`<div class="card"><h2>Shopping list <small>${low.length} items</small></h2><div class="list">${low.map(p=>`<div class="item"><div class="grow"><div class="t">${esc(p.name)}</div><div class="s">Have ${p.qty} ${esc(p.unit)} · keep at least ${p.min}</div></div><span class="pill ${pantryStatus(p)}">${pantryStatus(p)==='out'?'Out':'Low'}</span></div>`).join('')}</div></div>`:''}
 <div class="card"><h2>On hand <small>${D.pantry.length} items</small></h2><div class="list">${D.pantry.map(p=>{const st=pantryStatus(p);return `<div class="item"><div class="grow"><div class="t">${esc(p.name)}</div><div class="s">${p.qty} ${esc(p.unit)} · min ${p.min}</div></div><span class="pill ${st}">${st==='ok'?'OK':st==='low'?'Low':'Out'}</span><button class="icon-btn" data-edit data-act="pq" data-id="${p.id}" data-n="-1" aria-label="Decrease">−</button><button class="icon-btn" data-edit data-act="pq" data-id="${p.id}" data-n="1" aria-label="Increase">＋</button></div>`}).join('')}</div>
 <button class="btn ghost block" style="margin-top:8px" data-edit data-act="addpantry">＋ Add pantry item</button></div>
 ${days.length?`<div class="card"><h2>Plan usage per day</h2>${days.map(({p,use})=>`<div class="item"><div class="grow"><div class="t">${esc(p.name)}</div><div class="s">Meal plan uses ${use} serving${use>1?'s':''}/day</div></div></div>`).join('')}<div class="muted">Logging a food linked to a pantry item takes it out of stock automatically.</div></div>`:''}`}
function pantryStep(p){return p.unit==='g'?100:1}
function foodSheet(meal,plan){meal=meal||'Breakfast';
 sheet(`<h3>Add food</h3><div class="seg" id="msel">${MEALS.map(m=>`<button class="${m===meal?'on':''}" data-m="${m}">${m}</button>`).join('')}</div>
 <input id="fq" placeholder="Search foods" autocomplete="off"><div class="list" id="fres" style="margin-top:6px"></div>
 <details style="margin-top:12px"><summary class="muted" style="min-height:44px;display:flex;align-items:center">Custom food or barcode</summary>
 <label class="f">Name</label><input id="cn"><div class="grid2"><div><label class="f">kcal</label><input id="ck" inputmode="decimal"></div><div><label class="f">Protein g</label><input id="cp" inputmode="decimal"></div><div><label class="f">Carbs g</label><input id="cc" inputmode="decimal"></div><div><label class="f">Fat g</label><input id="cf" inputmode="decimal"></div></div>
 <button class="btn block" style="margin-top:10px" id="cadd">Save & add</button>
 <label class="f">Barcode lookup (Open Food Facts)</label><div class="row"><input id="bc" inputmode="numeric" placeholder="e.g. 737628064502"><button class="btn sm" id="bcgo">Look up</button></div></details>`,el=>{
  const draw=()=>{const q=el.querySelector('#fq').value.toLowerCase();el.querySelector('#fres').innerHTML=D.foods.filter(f=>f.name.toLowerCase().includes(q)).map(f=>`<button class="item" style="background:none;border-left:0;border-right:0;border-bottom:0;width:100%;text-align:left;cursor:pointer" data-fid="${f.id}"><div class="grow"><div class="t">${esc(f.name)}</div><div class="s">${f.kcal} kcal · P${f.p} C${f.c} F${f.f}</div></div><span class="pill">＋</span></button>`).join('')||'<div class="empty">No match. Add a custom food below.</div>'};
  draw();el.querySelector('#fq').oninput=draw;
  el.querySelector('#msel').onclick=e=>{const b=e.target.closest('button');if(!b)return;meal=b.dataset.m;el.querySelectorAll('#msel button').forEach(x=>x.classList.toggle('on',x===b))};
  const add=fid=>{save(d=>{if(plan){(d.mealPlan[meal]=d.mealPlan[meal]||[]).push({fid,q:1})}else{(d.food[S.foodDate]=d.food[S.foodDate]||[]).push({fid,meal,q:1});
    const pi=d.pantry.find(p=>p.fid===fid);if(pi)pi.qty=Math.max(0,pi.qty-pantryStep(pi))}},`Added to ${meal}`);closeSheet()};
  el.querySelector('#fres').onclick=e=>{const b=e.target.closest('[data-fid]');if(b)add(b.dataset.fid)};
  el.querySelector('#cadd').onclick=()=>{const n=el.querySelector('#cn').value.trim();if(!n)return toast('Name required');const id='f'+uid();const num=s=>+el.querySelector(s).value||0;
   save(d=>d.foods.push({id,name:n,kcal:num('#ck'),p:num('#cp'),c:num('#cc'),f:num('#cf')}));add(id)};
  el.querySelector('#bcgo').onclick=async()=>{const code=el.querySelector('#bc').value.trim();if(!/^\d{6,14}$/.test(code))return toast('Enter a valid barcode');
   try{const r=await fetch(`https://world.openfoodfacts.org/api/v2/product/${code}.json?fields=product_name,nutriments,serving_size`);const j=await r.json();if(!j.product)throw 0;const n=j.product.nutriments||{};
    el.querySelector('#cn').value=j.product.product_name||'Scanned item';el.querySelector('#ck').value=Math.round(n['energy-kcal_serving']??n['energy-kcal_100g']??0);
    el.querySelector('#cp').value=Math.round(n.proteins_serving??n.proteins_100g??0);el.querySelector('#cc').value=Math.round(n.carbohydrates_serving??n.carbohydrates_100g??0);el.querySelector('#cf').value=Math.round(n.fat_serving??n.fat_100g??0);toast('Found — check and save')}catch(e){toast('Not found (or offline)')}};
 })}

/* ---------- PROGRESS ---------- */
function vProgress(){return `<div class="seg">${[['lifts','Lifts'],['body','Body & food'],['cal','Calendar']].map(([k,n])=>`<button class="${S.progSeg===k?'on':''}" data-seg="progSeg" data-v="${k}">${n}</button>`).join('')}</div>`+(S.progSeg==='lifts'?vLifts():S.progSeg==='body'?vBody():vCal())}
function vLifts(){const names=[...new Set(D.workouts.flatMap(w=>w.exercises.map(e=>e.name)))];if(!names.includes(S.liftEx))S.liftEx=names[0]||'';
 const hist=D.workouts.filter(w=>w.exercises.some(e=>e.name===S.liftEx)).sort((a,b)=>a.date.localeCompare(b.date)).map(w=>{const e=w.exercises.find(e=>e.name===S.liftEx);const best=e.sets.reduce((m,s)=>Math.max(m,epley(toDisp(+s.w||0),s.r)),0);const top=e.sets.reduce((m,s)=>Math.max(m,toDisp(+s.w||0)),0);return {x:w.date.slice(5),y:Math.round(best),top}});
 const pr=hist.reduce((m,h)=>Math.max(m,h.y),0),topW=hist.reduce((m,h)=>Math.max(m,h.top),0);
 const weeks=[];for(let i=5;i>=0;i--){const end=new Date();end.setDate(end.getDate()-i*7);const st=new Date(end);st.setDate(st.getDate()-7);weeks.push({x:'W-'+i,y:D.workouts.filter(w=>{const d=new Date(w.date+'T12:00');return d>st&&d<=end}).reduce((a,w)=>a+vol(w),0)})}weeks[5].x='Now';
 return `<div class="card"><h2>Exercise</h2><select id="liftsel" aria-label="Exercise">${names.map(n=>`<option ${n===S.liftEx?'selected':''}>${esc(n)}</option>`).join('')}</select>
 <div class="grid2" style="margin-top:10px"><div class="stat"><b>${pr} ${U()}</b><span>Best est. 1RM</span></div><div class="stat"><b>${topW} ${U()}</b><span>Heaviest set</span></div></div></div>
 <div class="card"><h2>Estimated 1RM <small>Epley</small></h2>${lineChart(hist)}</div>
 <div class="card"><h2>Weekly volume <small>${U()}</small></h2>${barChart(weeks)}</div>`}
function vBody(){const w=D.weight.slice(-14).map(x=>({x:x.date.slice(5),y:toDisp(x.kg)})),s=D.sleep.slice(-10).map(x=>({x:x.date.slice(8),y:x.hours}));
 const k=[];for(let i=-6;i<=0;i++){const d=dayOff(i);k.push({x:new Date(d+'T12:00').toLocaleDateString(undefined,{weekday:'narrow'}),y:Math.round(totals(D.food[d]||[]).kcal)})}
 const avgS=D.sleep.slice(-7).reduce((a,x)=>a+x.hours,0)/Math.max(1,D.sleep.slice(-7).length);
 return `<div class="card"><h2>Body weight <small>${U()}</small></h2>${lineChart(w,{color:'var(--accent2)'})}</div>
 <div class="card"><h2>Sleep <small>7-day avg ${avgS.toFixed(1)} h</small></h2>${barChart(s,{goal:P().sleepGoal})}</div>
 <div class="card"><h2>Calories, last 7 days <small>goal ${P().targets.kcal}</small></h2>${barChart(k,{goal:P().targets.kcal})}</div>`}
function vCal(){const now=new Date();const m=new Date(now.getFullYear(),now.getMonth()+S.calMonth,1);const first=(m.getDay()+6)%7,dim=new Date(m.getFullYear(),m.getMonth()+1,0).getDate();
 const wd=new Set(D.workouts.map(w=>w.date));let cells='';for(let i=0;i<first;i++)cells+='<div class="x"></div>';
 for(let d=1;d<=dim;d++){const ds=iso(new Date(m.getFullYear(),m.getMonth(),d));cells+=`<div class="${wd.has(ds)?'w':''}">${d}</div>`}
 const count=D.workouts.filter(w=>w.date.startsWith(iso(m).slice(0,7))).length;
 return `<div class="card"><div class="row"><button class="icon-btn" data-act="cm" data-n="-1" aria-label="Previous month">‹</button><div class="grow" style="text-align:center;font-weight:650">${m.toLocaleDateString(undefined,{month:'long',year:'numeric'})}</div><button class="icon-btn" data-act="cm" data-n="1" aria-label="Next month">›</button></div>
 <div class="month" style="margin-top:12px">${['M','T','W','T','F','S','S'].map(x=>`<div class="x muted">${x}</div>`).join('')}${cells}</div><p class="muted">${count} workout${count===1?'':'s'} this month</p></div>`}

/* ---------- ME ---------- */
function vMe(){const p=P(),u=DB.currentUser(),t=p.targets;
 return `<div class="card"><h2>Appearance</h2><div class="seg">${[['light','Light'],['dark','Dark'],['auto','Auto']].map(([k,n])=>`<button class="${TH.mode===k?'on':''}" data-act="thmode" data-v="${k}">${n}</button>`).join('')}</div>
 <label class="f">Colourway</label><div class="cwgrid">${CW_ORDER.map(k=>{const c=CW[k],dk=document.documentElement.dataset.theme==='dark',v=dk?c.Dk:c.L;return `<button class="cw ${TH.cw===k?'on':''}" data-act="cw" data-v="${k}" style="background:${v.bg};color:${v.fg};font-family:${c.fh}"><span class="sw"><i style="background:${v.a}"></i><i style="background:${v.a2}"></i><i style="background:${v.a3}"></i></span><b>${esc(c.n)}</b></button>`}).join('')}</div>
 <p class="muted">Saved on this device. Auto follows your iPhone's light/dark setting.</p></div>
 <div class="card"><h2>Home screen</h2><button class="btn ghost block" data-act="editmode">Edit widgets</button><button class="btn ghost block" style="margin-top:8px" data-act="resetlayout">Reset home screen to default</button></div>
 <div class="card"><h2>Account <span class="demo">Demo login</span></h2><div class="list">${D.accounts.map(a=>`<div class="item"><div class="avatar" style="width:40px;height:40px;display:flex;align-items:center;justify-content:center">${esc(a.name[0])}</div><div class="grow"><div class="t">${esc(a.name)}</div><div class="s">${a.role==='owner'?'Owner · can edit':'Viewer · read-only'}${a.note?' · '+esc(a.note):''}</div></div>${a.id===u.id?'<span class="pill ok">Signed in</span>':`<button class="btn ghost sm" data-act="signin" data-id="${a.id}">Sign in</button>`}</div>`).join('')}</div>
 <p class="muted">Mock sign-in for the preview. In the real app each person signs in with their own account and the owner grants read-only access.</p></div>
 <div class="card"><h2>Profile</h2><label class="f">Name</label><input data-p="name" value="${esc(p.name)}" ${canEdit()?'':'disabled'}>
 <label class="f">Goal</label><select data-p="goal" ${canEdit()?'':'disabled'}>${['Build muscle','Lose fat','Get stronger','Stay healthy'].map(g=>`<option ${g===p.goal?'selected':''}>${g}</option>`).join('')}</select>
 <div class="grid2"><div><label class="f">Units</label><select data-p="units" ${canEdit()?'':'disabled'}><option value="kg" ${p.units==='kg'?'selected':''}>kg</option><option value="lb" ${p.units==='lb'?'selected':''}>lb</option></select></div>
  <div><label class="f">Workouts / week</label><input data-p="weekGoal" inputmode="numeric" value="${p.weekGoal}" ${canEdit()?'':'disabled'}></div><div><label class="f">Sleep goal (h)</label><input data-p="sleepGoal" inputmode="decimal" value="${p.sleepGoal}" ${canEdit()?'':'disabled'}></div></div></div>
 <div class="card"><h2>Daily targets</h2><div class="grid2">${[['kcal','Calories'],['p','Protein (g)'],['c','Carbs (g)'],['f','Fat (g)']].map(([k,n])=>`<div><label class="f">${n}</label><input data-t="${k}" inputmode="numeric" value="${t[k]}" ${canEdit()?'':'disabled'}></div>`).join('')}</div></div>
 <div class="card"><h2>Data</h2><div class="grid2"><button class="btn ghost sm" data-act="export" data-k="all">Export all (JSON)</button><button class="btn ghost sm" data-act="export" data-k="mealplan">Export meal plan</button></div>
 <div data-edit><label class="btn ghost sm block" style="margin-top:8px">Import backup<input type="file" accept="application/json" id="imp" hidden></label></div>
 <p class="muted">Data lives only in this browser. Everything here is demo data.</p></div>
 <div class="card"><button class="btn ghost block" data-act="tour">Replay tutorial</button><button class="btn danger block" data-act="reset">Reset demo data</button></div>
 <p class="muted" style="text-align:center">Logbook v2 preview · build 1</p>`}
function exportData(kind){const name=kind==='mealplan'?'logbook-mealplan.json':'logbook-export.json';
 const obj=kind==='mealplan'?{targets:P().targets,meals:Object.fromEntries(MEALS.map(m=>[m,(D.mealPlan[m]||[]).map(e=>({...food(e.fid),q:e.q}))])),pantry:D.pantry}:D;
 const a=document.createElement('a');a.href=URL.createObjectURL(new Blob([JSON.stringify(obj,null,2)],{type:'application/json'}));a.download=name;a.click();toast('Exported '+name)}

/* ---------- ONBOARDING ---------- */
const TOUR=[['📱','Home screen','Widgets summarise your day. Tap one to open that section, swipe left and right between sections, and press and hold to add, resize, rearrange or customise widgets.'],
 ['🏋️','Train','Start from a template. Previous weights are filled in, tap ✓ to finish a set and a rest timer starts. Sessions survive closing the app.'],
 ['🥗','Food','Log meals, build a meal plan against your targets, and track pantry stock. Low items land on a shopping list.'],
 ['📈','Progress','Estimated 1RM per lift, weekly volume, body weight, sleep and a training calendar.'],
 ['👥','Sharing','Viewers like Sally or Atlas can sign in read-only. Switch accounts under Me.']];
function onboarding(tourOnly){S.onb={step:tourOnly?3:0,tourOnly,goal:P().goal,units:P().units,name:P().name};drawOnb()}
function drawOnb(){const o=S.onb;let el=$('#onb');if(!el){el=document.createElement('div');el.id='onb';el.className='onb';document.body.appendChild(el)}
 const steps=3+TOUR.length,st=o.step;let body='';
 if(st===0)body=`<div class="hero">📓</div><h2>Welcome to Logbook</h2><p class="muted">Training, food, sleep and pantry in one place. This is a preview filled with <b>demo data</b>, so feel free to poke around.</p><label class="f">What should we call you?</label><input id="oname" value="${esc(o.name)}" autocomplete="given-name">`;
 else if(st===1)body=`<div class="hero">🎯</div><h2>Your goal</h2><p class="muted">We’ll suggest targets from this. You can change them any time.</p><div class="chips">${['Build muscle','Lose fat','Get stronger','Stay healthy'].map(g=>`<button class="chip ${g===o.goal?'on':''}" data-g="${g}">${g}</button>`).join('')}</div>
 <label class="f" style="margin-top:20px">Units</label><div class="seg">${['kg','lb'].map(u=>`<button class="${u===o.units?'on':''}" data-u="${u}">${u}</button>`).join('')}</div>`;
 else if(st===2){const sug={'Build muscle':[2600,180,300,75],'Lose fat':[1900,170,170,60],'Get stronger':[2700,180,320,80],'Stay healthy':[2200,130,250,70]}[o.goal];o.t=o.t&&o.tg===o.goal?o.t:{kcal:sug[0],p:sug[1],c:sug[2],f:sug[3]};o.tg=o.goal;
  body=`<div class="hero">🍽️</div><h2>Daily targets</h2><p class="muted">Suggested for “${esc(o.goal)}”. Adjust if you like.</p><div class="grid2">${[['kcal','Calories'],['p','Protein g'],['c','Carbs g'],['f','Fat g']].map(([k,n])=>`<div><label class="f">${n}</label><input inputmode="numeric" data-ot="${k}" value="${o.t[k]}"></div>`).join('')}</div>`}
 else{const [e,h,txt]=TOUR[st-3];body=`<div class="hero">${e}</div><span class="demo">Tour ${st-2}/${TOUR.length}</span><h2 style="margin-top:8px">${h}</h2><p class="muted" style="font-size:17px">${txt}</p>`}
 el.innerHTML=`<div style="flex:1;max-width:480px;width:100%;margin:0 auto">${body}</div><div style="max-width:480px;width:100%;margin:0 auto"><div class="dots">${Array.from({length:steps},(_,i)=>`<i class="${i===st?'on':''}"></i>`).join('')}</div>
 <div class="grid2">${st>(o.tourOnly?3:0)?'<button class="btn ghost" id="oback">Back</button>':'<button class="btn ghost" id="oskip">Skip</button>'}<button class="btn" id="onext">${st===steps-1?'Get started':'Continue'}</button></div></div>`;
 el.querySelectorAll('[data-g]').forEach(b=>b.onclick=()=>{o.goal=b.dataset.g;drawOnb()});
 el.querySelectorAll('[data-u]').forEach(b=>b.onclick=()=>{o.units=b.dataset.u;drawOnb()});
 const grab=()=>{const n=el.querySelector('#oname');if(n)o.name=n.value.trim()||'Friend';el.querySelectorAll('[data-ot]').forEach(i=>o.t[i.dataset.ot]=+i.value||0)};
 const finish=()=>{grab();if(!o.tourOnly&&canEdit())save(d=>{d.profile.name=o.name;d.profile.goal=o.goal;d.profile.units=o.units;if(o.t)d.profile.targets=o.t;d.profile.onboarded=true});else if(canEdit()&&!P().onboarded)save(d=>d.profile.onboarded=true);el.remove();S.onb=null;render();toast(`You’re all set, ${P().name}`)};
 el.querySelector('#onext').onclick=()=>{grab();if(st===steps-1)finish();else{o.step++;drawOnb()}};
 el.querySelector('#oback')&&(el.querySelector('#oback').onclick=()=>{grab();o.step--;drawOnb()});
 el.querySelector('#oskip')&&(el.querySelector('#oskip').onclick=finish)}

/* ---------- RENDER ---------- */
/* ---------- SLEEP & BODY page ---------- */
function vRecovery(){const today=iso(new Date()),sl=D.sleep.find(s=>s.date===today),wt=D.weight.find(w=>w.date===today),supps=D.supplements.log[today]||[];
 const lastS=[...D.sleep].sort((a,b)=>a.date.localeCompare(b.date)).pop(),lastW=[...D.weight].sort((a,b)=>a.date.localeCompare(b.date)).pop();
 return `<div class="grid2"><div class="card" style="margin:0 0 12px"><h2>Sleep</h2><b style="font-size:26px">${sl?sl.hours+' h':lastS?lastS.hours+' h':'—'}</b><div class="muted">${sl?'Last night':lastS?prettyDate(lastS.date):'Not logged'}</div><button class="btn ghost sm block" style="margin-top:8px" data-edit data-act="sleep">${sl?'Edit':'Log'}</button></div>
 <div class="card" style="margin:0 0 12px"><h2>Weight</h2><b style="font-size:26px">${wt?toDisp(wt.kg):lastW?toDisp(lastW.kg):'—'} <small style="font-size:14px">${U()}</small></b><div class="muted">${wt?'Today':lastW?prettyDate(lastW.date):'Not logged'}</div><button class="btn ghost sm block" style="margin-top:8px" data-edit data-act="weight">${wt?'Edit':'Log'}</button></div></div>
 <div class="card"><h2>Supplements <small>${supps.length}/${D.supplements.list.length}</small></h2><div class="chips">${D.supplements.list.map(s=>`<button class="chip ${supps.includes(s)?'on':''}" data-act="supp" data-s="${esc(s)}" ${canEdit()?'':'disabled'}>${supps.includes(s)?'✓ ':''}${esc(s)}</button>`).join('')}<button class="chip" data-edit data-act="addsupp">＋</button></div></div>
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
const nextTpl=()=>D.templates[D.workouts.length%D.templates.length];
/* type: [name, icon, section, sizes, default opt, options {key:[label,[[val,label]...]]}, render(size,opt)] */
const FR=()=>document.body.getBoundingClientRect(),VW=()=>document.body.clientWidth||window.innerWidth,VH=()=>document.body.clientHeight||window.innerHeight;
/* ---- demo extras (derived, deterministic; demo only) ---- */
const hsh=s=>{let h=2166136261;for(const c of String(s)){h^=c.charCodeAt(0);h=Math.imul(h,16777619)}return ((h>>>0)%10000)/10000};
const hm=m=>{m=((Math.round(m)%1440)+1440)%1440;return String(Math.floor(m/60)).padStart(2,'0')+':'+String(m%60).padStart(2,'0')};
const WKEY='lb2w:water';const WATER=JSON.parse(localStorage.getItem(WKEY)||'{}');
const X={water:d=>d===iso(new Date())?(WATER[d]??1000):(WATER[d]??Math.round(1600+hsh('w'+d)*1200)),waterGoal:2500,
 steps:d=>Math.round(5200+hsh('s'+d)*7000),hr:d=>Math.round(53+hsh('h'+d)*8),
 bed:d=>1365+Math.round(hsh('b'+d)*80-20),bedGoal:1365,
 meas:[[-84,86,104,36.5],[-56,85.2,104.5,36.8],[-28,84.6,105,37],[-1,84,105.4,37.3]].map(([o,w,c,a])=>({d:dayOff(o),waist:w,chest:c,arm:a})),
 journal:[[-1,'Felt strong on squats. Sleep is helping.'],[-3,'Skipped snack, low energy at the gym.'],[-6,'New bench PR. Deload next week?'],[-10,'Meal prep Sunday made the week easy.'],[-15,'Travel day, kept protein up.']].map(([o,t])=>({d:dayOff(o),t})),
 fibre:{f1:0,f2:6,f3:0,f4:1,f5:3,f6:0,f7:1,f8:0,f9:5,f10:4},fibreGoal:30,
 mealTime:{Breakfast:450,Lunch:750,Snack:930,Dinner:1140}};
const fibreOf=list=>list.reduce((a,e)=>a+(X.fibre[e.fid]??2)*e.q,0);
const MUSCLE={'Bench Press':'Chest','Incline DB Press':'Chest','Overhead Press':'Shoulders','Tricep Pushdown':'Arms','Bicep Curl':'Arms','Barbell Row':'Back','Pull-up':'Back','Lat Pulldown':'Back','Squat':'Legs','Leg Press':'Legs','Romanian Deadlift':'Legs','Deadlift':'Back'};
const sortedW=()=>[...D.workouts].sort((a,b)=>a.date.localeCompare(b.date));
function prs(){const m={};D.workouts.forEach(w=>w.exercises.forEach(e=>e.sets.forEach(s=>{const v=epley(toDisp(+s.w||0),s.r);if(!m[e.name]||v>m[e.name].e1)m[e.name]={e1:Math.round(v),w:toDisp(+s.w||0),r:s.r,d:w.date}})));return Object.entries(m).filter(x=>x[1].e1>0).sort((a,b)=>b[1].e1-a[1].e1)}
function weekVols(n=8){const o=[];for(let i=n-1;i>=0;i--){const end=new Date();end.setDate(end.getDate()-i*7);const st=new Date(end);st.setDate(st.getDate()-7);const ws=D.workouts.filter(w=>{const d=new Date(w.date+'T12:00');return d>st&&d<=end});o.push({x:i?'W-'+i:'Now',y:ws.reduce((a,w)=>a+vol(w),0),n:ws.length,start:iso(new Date(st.getTime()+864e5))})}return o}
function muscleSets(days=7){const since=dayOff(-days),m={Chest:0,Back:0,Legs:0,Shoulders:0,Arms:0};D.workouts.filter(w=>w.date>since).forEach(w=>w.exercises.forEach(e=>{const g=MUSCLE[e.name]||'Arms';m[g]+=e.sets.length}));return m}
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
const CATS={train:['Training','train'],food:['Food','food'],body:['Sleep & body','recovery'],hist:['History','progress']};
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
  ()=>{const t=todayT(),g=P().targets;return card('Today',`<div class="row">${ring(t.kcal,g.kcal,'of '+g.kcal+' kcal',120)}<div class="grow"><b style="font-size:30px">${Math.round(g.kcal-t.kcal)}</b><div class="muted">kcal left</div></div></div>`)+card('Last 7 days',barChart(series('kcal',7).map(p=>({x:p.d.slice(8),y:p.y})),{goal:g.kcal}))+`<button class="btn block" data-edit data-act="addfood">＋ Log food</button>`}],
 macros:['Macros','🥗','food',['M','L'],{},{},(sz)=>L_('Macros today')+macroMini(todayT()),()=>{const t=todayT();return card('Macros today',macroBars(t))+card('Protein, last 7 days',barChart(series('protein',7).map(p=>({x:p.d.slice(8),y:p.y})),{goal:P().targets.p}))}],
 protein:['Protein goal','🥩','food',['S','M'],{},{},(sz)=>{const t=todayT(),g=P().targets.p;return L_('Protein')+`<div class="wrow">${miniRing(t.p,g,sz==='M'?70:52,'var(--p)')}<div>${big(Math.round(t.p),'/'+g+'g',sz)}${sz==='M'?`<small>${Math.max(0,Math.round(g-t.p))} g to go</small>`:''}</div></div>`},(o,d)=>metricMini('protein',d||'14')],
 water:['Water','💧','food',['S','M'],{},{},(sz)=>{const w=X.water(iso(new Date()));return L_('Water')+big((w/1000).toFixed(1),'/ '+X.waterGoal/1000+' L',sz)+`<div class="glass"><i style="height:${Math.min(100,w/X.waterGoal*100)}%"></i></div>${sz==='M'?'<small>Tap to add a glass</small>':''}`},
  (o,d)=>`<div class="card"><h2>Today <small>${(X.water(iso(new Date()))/1000).toFixed(2)} L</small></h2><div class="grid3"><button class="btn" data-x="water" data-v="250">＋250 ml</button><button class="btn" data-x="water" data-v="500">＋500 ml</button><button class="btn ghost" data-x="water" data-v="-250">−250</button></div></div>`+metricMini('water',d||'7')],
 meals:['Today’s meals','🍽️','food',['M','L'],{},{},(sz)=>{const day=D.food[iso(new Date())]||[];return L_('Meals today')+listW(MEALS.map(m=>{const t=totals(day.filter(e=>e.meal===m));return [m,t.kcal?Math.round(t.kcal)+' kcal':'—']}),sz==='L'?4:3)},
  ()=>{const day=D.food[iso(new Date())]||[];return MEALS.map(m=>card(m,rows(day.filter(e=>e.meal===m).map(e=>{const f=food(e.fid);return [esc(f.name),`P${Math.round(f.p*e.q)} C${Math.round(f.c*e.q)} F${Math.round(f.f*e.q)}`,Math.round(f.kcal*e.q)]})))).join('')+`<button class="btn block" data-edit data-act="addfood">＋ Log food</button>`}],
 favs:['Quick log','⭐','food',['M','L'],{},{},(sz)=>{const f=favs().slice(0,sz==='L'?6:3);return L_('Quick log')+`<div class="wchips">${f.map(x=>`<span>＋ ${esc(x.name.split(' (')[0])}</span>`).join('')}</div>`},
  ()=>card('Favourites',`<div class="list">${favs().map(f=>`<div class="item"><div class="grow"><div class="t">${esc(f.name)}</div><div class="s">${f.kcal} kcal · P${f.p}</div></div><button class="btn sm" data-edit data-x="qlog" data-v="${f.id}">＋ Log</button></div>`).join('')}</div>`,'most logged')],
 pantry:['Pantry low stock','🧺','food',['S','M','L'],{},{},(sz)=>{const low=D.pantry.filter(p=>pantryStatus(p)!=='ok');return L_('Pantry')+big(low.length,'low',sz)+(sz==='S'?`<small>${esc(low[0]?.name||'All stocked')}</small>`:listW(low.map(p=>[esc(p.name),pantryStatus(p)==='out'?'Out':'Low',pantryStatus(p)]),nRows(sz)+1))},
  ()=>card('Pantry',rows(D.pantry.map(p=>[esc(p.name),`${p.qty} ${esc(p.unit)} · min ${p.min}`,pantryStatus(p)==='ok'?'OK':pantryStatus(p)==='low'?'Low':'Out'])))],
 timing:['Meal timing','⏱️','food',['S','M'],{},{},(sz)=>{const day=D.food[iso(new Date())]||[],done=MEALS.filter(m=>day.some(e=>e.meal===m)),nx=MEALS.find(m=>!done.includes(m));return L_('Next meal')+big(nx?hm(X.mealTime[nx]):'Done','',sz)+`<small>${nx||'All meals logged'}</small>${sz==='M'?`<div class="wweek">${MEALS.map(m=>`<i class="${done.includes(m)?'on':''}"><span>${hm(X.mealTime[m])}</span></i>`).join('')}</div>`:''}`},
  ()=>{const day=D.food[iso(new Date())]||[];return card('Meal schedule',rows(MEALS.map(m=>{const t=totals(day.filter(e=>e.meal===m));return [m,hm(X.mealTime[m]),t.kcal?Math.round(t.kcal)+' kcal':'—']})))+'<p class="muted">Times are your planned meal times (24-hour).</p>'}],
 fibre:['Fibre','🌾','food',['S','M'],{},{},(sz)=>{const f=fibreOf(D.food[iso(new Date())]||[]);return L_('Fibre')+`<div class="wrow">${miniRing(f,X.fibreGoal,sz==='M'?70:52,'var(--c)')}<div>${big(Math.round(f),'/'+X.fibreGoal+'g',sz)}</div></div>`},
  ()=>{const pts=lastN(7,d=>fibreOf(D.food[d]||[]));return card('Fibre, last 7 days',barChart(pts.map(p=>({x:p.d.slice(8),y:p.y})),{goal:X.fibreGoal}))+card('Top sources',rows(D.foods.filter(f=>X.fibre[f.id]).sort((a,b)=>X.fibre[b.id]-X.fibre[a.id]).map(f=>[esc(f.name),'',X.fibre[f.id]+' g'])))}],
 kcalavg:['Weekly calories','📊','food',['S','M','L'],{},{},(sz)=>{const p=series('kcal',7),a=Math.round(avg(p.map(x=>x.y)));return L_('7-day avg')+big(a.toLocaleString(),'kcal',sz)+(sz!=='S'?chartW(p,sz,{kind:'bar',goal:P().targets.kcal}):`<small>goal ${P().targets.kcal}</small>`)},(o,d)=>metricMini('kcal',d||'7')],
 grocery:['Grocery list','🛒','food',['S','M','L'],{},{},(sz)=>{const g=groceries();return L_('Grocery list')+big(g.length,'items',sz)+(sz==='S'?'':listW(g.map(x=>[esc(x.n),x.why]),nRows(sz)+1))},()=>card('To buy',rows(groceries().map(x=>[esc(x.n),x.why])))+'<p class="muted">Built from low pantry stock and meal-plan foods you don’t have.</p>'],
 /* TRAINING */
 next:['Next workout','🏋️','train',['S','M','L'],{},{},(sz)=>{if(D.active)return L_('In progress')+`<b class="wt">● ${esc(D.active.name)}</b><small>Tap to resume</small>`;const n=nextTpl(),up=upcoming(1)[0];return L_('Next · '+up.day)+`<b class="wt">${esc(n.name)}</b>${sz==='S'?`<small>${n.exercises.length} exercises</small>`:listW(n.exercises.map(e=>[esc(e),esc(lastFor(e).replace('Last: ','').split(',')[0])]),sz==='L'?6:2)}`},
  ()=>{const n=nextTpl();return card(D.active?'In progress':'Next up',`<b style="font-size:22px">${esc(D.active?D.active.name:n.name)}</b>`+rows((D.active?D.active.exercises.map(e=>e.name):n.exercises).map(e=>[esc(e),esc(lastFor(e))])))+(D.active?'':`<button class="btn block" data-edit data-act="start" data-t="${esc(n.name)}">Start ${esc(n.name)}</button>`)}],
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
  ()=>{const t=D.supplements.log[iso(new Date())]||[];return card('Today',`<div class="chips">${D.supplements.list.map(s=>`<button class="chip ${t.includes(s)?'on':''}" data-act="supp" data-s="${esc(s)}">${t.includes(s)?'✓ ':''}${esc(s)}</button>`).join('')}</div>`)}],
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
function macroMini(t){const g=P().targets;return `<div class="wmac">${[['P','p','var(--p)'],['C','c','var(--c)'],['F','f','var(--f)']].map(([n,k,col])=>`<div><span>${n}</span><div class="bar"><i style="width:${Math.min(100,t[k]/g[k]*100)}%;background:${col}"></i></div><em>${Math.round(t[k])}/${g[k]}</em></div>`).join('')}</div>`}
function favs(){const c={};Object.values(D.food).flat().forEach(e=>c[e.fid]=(c[e.fid]||0)+1);return D.foods.filter(f=>c[f.id]).sort((a,b)=>c[b.id]-c[a.id])}
function groceries(){const o=D.pantry.filter(p=>pantryStatus(p)!=='ok').map(p=>({n:p.name,why:pantryStatus(p)==='out'?'Out':'Low'}));const have=new Set(D.pantry.map(p=>p.fid).filter(Boolean));
 MEALS.forEach(m=>(D.mealPlan[m]||[]).forEach(e=>{if(!have.has(e.fid)){have.add(e.fid);o.push({n:food(e.fid).name,why:'Meal plan'})}}));return o}
function upcoming(n){const o=[];let k=D.workouts.length,day=1;while(o.length<n){const d=new Date();d.setDate(d.getDate()+day);if(d.getDay()!==3&&d.getDay()!==0){o.push({day:d.toLocaleDateString('en-CA',{weekday:'short',day:'numeric'}),t:D.templates[k%D.templates.length]});k++}day++}return o}
function consistency(){const l=[...D.sleep].sort((a,b)=>a.date.localeCompare(b.date)).slice(-7).map(s=>({d:s.date,b:X.bed(s.date)})),a=avg(l.map(x=>x.b)),sd=Math.round(Math.sqrt(avg(l.map(x=>(x.b-a)**2))));return {sd,score:Math.max(0,Math.round(100-sd*1.5)),list:l.reverse()}}
function heat(m,n,big){const cells=[];for(let i=-(n-1);i<=0;i++){const d=dayOff(i);let v=0;
 if(m==='workouts')v=D.workouts.some(w=>w.date===d)?1:0;else if(m==='kcal'){const t=D.food[d];v=t&&t.length?Math.max(0,1-Math.abs(totals(t).kcal-P().targets.kcal)/P().targets.kcal*3):0}else{const s=D.sleep.find(x=>x.date===d);v=s?Math.min(1,s.hours/P().sleepGoal)**3:0}
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
 P_('home',[nw('kcal','M'),nw('sleeplast','S'),nw('weight','S'),nw('next','M'),nw('water','S'),nw('vitals','S',{show:'steps'})]),
 P_('train',[nw('next','M'),nw('week','S'),nw('streak','S'),nw('volume','M'),nw('prs','M')]),
 P_('food',[nw('macros','M'),nw('water','S'),nw('protein','S'),nw('meals','M'),nw('favs','M')]),
 P_('body',[nw('sleeplast','S'),nw('weight','S'),nw('sleep7','M'),nw('vitals','M'),nw('supps','M')]),
 P_('hist',[nw('graph','L',{metric:'weight',days:'30'}),nw('calheat','M'),nw('month','M')]),
 P_('other',[nw('journal','M'),nw('rest','S'),nw('protein','S'),nw('compare','S'),nw('bestweek','S'),nw('milestones','M')])]}
function sanitize(l){const other=l.find(p=>p.cat==='other')||(l.push({id:'p'+uid(),cat:'other',name:'Other',w:[]}),l[l.length-1]);
 l.forEach(p=>{if(!PCAT[p.cat])p.cat='other';p.w=p.w.filter(x=>WT[x.type]);if(!mixed(p.cat)){const bad=p.w.filter(x=>WT[x.type][2]!==p.cat);if(bad.length){p.w=p.w.filter(x=>!bad.includes(x));other.w.push(...bad)}}});
 const oi=l.indexOf(other);l.splice(oi,1);l.push(other);return l}
let LAYOUT=(()=>{try{const l=JSON.parse(localStorage.getItem('lb2w:pages4'));if(Array.isArray(l)&&l.length)return sanitize(l)}catch(e){}return defaultLayout()})();
function saveLayout(){localStorage.setItem('lb2w:pages4',JSON.stringify(LAYOUT))}
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
function widgetHTML(w,r,c){const T=WT[w.type];let inner;try{inner=T[6](w.size,w.opt||{})}catch(e){console.warn(e);inner='<small class="wl">'+T[0]+'</small><small>Unavailable</small>'}
 return `<div class="w ${w.size}" data-type="${w.type}" data-c="${T[2]}" data-wid="${w.id}" style="grid-row:${r+1} / span ${w.size==='L'?2:1};grid-column:${w.size==='S'?c+1:'1 / span 2'}" role="button" tabindex="0" aria-label="${T[0]} widget"><div class="wi">${inner}</div>
 <button class="wx" data-wx aria-label="Remove widget">−</button><button class="wsz" data-wsz aria-label="Change size">${w.size}</button></div>`}
function pageTitle(p,i){return p.cat==='home'&&p.name==='Home'?`<div class="sub">${new Date().toLocaleDateString('en-CA',{weekday:'long',month:'long',day:'numeric'})}</div><h1>Hi ${esc(P().name)}</h1>`:`<div class="sub">${mixed(p.cat)?'Any widgets':'Section'}</div><h1>${esc(p.name)}</h1>`}

/* ---------- APPS (dock) ---------- */
const APPS={train:['Training',vTrain,'linear-gradient(160deg,#ff9f43,#ee5a24)'],food:['Food',vFood,'linear-gradient(160deg,#7bed9f,#20bf6b)'],progress:['History',vProgress,'linear-gradient(160deg,#70a1ff,#1e6fd9)'],recovery:['Sleep & body',vRecovery,'linear-gradient(160deg,#a29bfe,#5f27cd)'],me:['Settings',vMe,'linear-gradient(160deg,#c8ccd2,#7d848e)']};
const GLYPH={train:ICON.train,food:ICON.food,progress:ICON.progress,recovery:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M20 14.5A8 8 0 0 1 9.5 4a8 8 0 1 0 10.5 10.5z"/></svg>',me:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><circle cx="12" cy="12" r="3.2"/><path d="M12 2.5v3M12 18.5v3M2.5 12h3M18.5 12h3M5.3 5.3l2.1 2.1M16.6 16.6l2.1 2.1M5.3 18.7l2.1-2.1M16.6 7.4l2.1-2.1"/></svg>'};
const appIcon=k=>`<span class="aico" style="background:${APPS[k][2]}">${GLYPH[k]}</span>`;
let OV=null; // {kind:'app',k} | {kind:'mini',id,days}
function curWidget(){return LAYOUT.flatMap(p=>p.w).find(x=>x.id===OV.id)}
function miniHTML(){const it=curWidget();if(!it)return '<div class="empty">Widget removed</div>';const T=WT[it.type],[cn,app]=CATS[T[2]];let body;
 try{body=T[7](Object.assign({},T[4],it.opt),OV.days)}catch(e){console.warn(e);body='<div class="empty">Unavailable</div>'}
 return body+`<button class="btn ghost block openfull" data-go="${it.type==='pantry'||it.type==='grocery'?'food:pantry':app}">Open ${cn} ›</button>`}
function ovTitle(){if(OV.kind==='app')return APPS[OV.k][0];const it=curWidget();if(!it)return '';const o=it.opt||{};return it.type==='graph'?METRIC[o.metric||'weight'][0]:WT[it.type][0]}
function ovBody(){return OV.kind==='app'?APPS[OV.k][1]():miniHTML()}
function drawOV(){let el=$('#ov');if(!OV){el&&el.remove();return}const keep=el?el.querySelector('.ovb').scrollTop:0;
 if(!el){el=document.createElement('div');el.id='ov';el.className='ov';$('#app').appendChild(el)}
 el.innerHTML=`<div class="ovh"><button class="back" data-close aria-label="Back">‹ Home</button><b>${esc(ovTitle())}</b><span style="width:70px"></span></div><div class="ovb"><div class="pin">${ovBody()}</div></div><div class="homebar" aria-label="Swipe to close"><i></i></div>`;
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
 el.querySelector('[data-close]').onclick=e=>{e.stopPropagation();closeOV()};
 el.querySelectorAll('[data-x]').forEach(b=>b.onclick=e=>{e.stopPropagation();const v=b.dataset.v;if(b.dataset.x==='rest'){restTimer(+v);return}if(!canEdit())return toast('Read-only account — editing is disabled');if(b.dataset.x==='water'){const d=iso(new Date());WATER[d]=Math.max(0,X.water(d)+ +v);localStorage.setItem(WKEY,JSON.stringify(WATER));drawOV();render();toast('Water updated')}if(b.dataset.x==='qlog'){const h=new Date().getHours(),meal=h<11?'Breakfast':h<15?'Lunch':h<17?'Snack':'Dinner';save(d=>{(d.food[iso(new Date())]=d.food[iso(new Date())]||[]).push({fid:v,meal,q:1})},'Logged to '+meal)}});
 el.querySelectorAll('[data-mdays]').forEach(b=>b.onclick=e=>{e.stopPropagation();OV.days=b.dataset.mdays;drawOV()});
 el.addEventListener('pointerdown',e=>{if(e.target.closest('button,a,input,select,label'))return;const hb=e.target.closest('.homebar,.ovh'),edge=e.clientX<28;if(!hb&&!edge)return;st={x:e.clientX,y:e.clientY,t:Date.now(),mode:edge&&!hb?'back':'down',hb:!!e.target.closest('.homebar')};el.setPointerCapture(e.pointerId)});
 el.addEventListener('pointermove',e=>{if(!st)return;const dx=e.clientX-st.x,dy=e.clientY-st.y;
  const p=st.mode==='back'?Math.max(0,dx)/VW():Math.abs(st.hb?Math.min(0,dy)*1.4||Math.max(0,dy):Math.max(0,dy))/VH();st.p=p;
  if(p>0.01){el.style.transition='none';const s=1-p*.45;el.style.transform=st.mode==='back'?`translateX(${dx}px) scale(${s})`:`translateY(${st.hb?dy*.5:dy}px) scale(${s})`;el.style.borderRadius=Math.min(40,p*200)+'px'}});
 const up=()=>{if(!st)return;const p=st.p||0,v=p/Math.max(1,Date.now()-st.t)*1000;st=null;if(p>0.22||v>1.2)closeOV();else{el.style.transition='transform .3s cubic-bezier(.2,.9,.25,1),border-radius .3s';el.style.transform='none';el.style.borderRadius='0'}};
 el.addEventListener('pointerup',up);el.addEventListener('pointercancel',up)}
function goPage(k){const [a,seg]=k.split(':');if(seg)S.foodSeg=seg;if(a==='today'){if(OV)closeOV();return}
 if(!APPS[a])return;if(OV){OV={kind:'app',k:a,rect:OV.rect};drawOV();$('#ov .ovb').scrollTop=0;return}
 const ic=document.querySelector(`.dock [data-app="${a}"]`);openOV({kind:'app',k:a},ic?ic.getBoundingClientRect():null)}

/* ---------- SPRINGBOARD RENDER ---------- */
function render(){D=DB.get();applyTheme();document.body.classList.toggle('readonly',!canEdit());document.body.classList.toggle('editing',WSTATE.edit);metrics();document.body.classList.toggle('compact',SB.rh<125);
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
 q('[data-pdel]')&&(q('[data-pdel]').onclick=()=>{const p=LAYOUT[SB.cur];if(p.cat==='home'&&p.name==='Home')return toast('The Home page can’t be removed');if(p.w.length&&!confirm(`Remove this page and its ${p.w.length} widget${p.w.length>1?'s':''}?`))return;LAYOUT.splice(SB.cur,1);if(!LAYOUT.some(x=>x.cat==='other'))LAYOUT.push({id:'p'+uid(),cat:'other',name:'Other',w:[]});commitPack();SB.cur=Math.max(0,SB.cur-1);render();toast('Page removed')});
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
 const viewOnly=['supp_','openw','fd','cm','signin','export','tour','thmode','cw','editmode','resetlayout'];if(!canEdit()&&!viewOnly.includes(a))return toast('Read-only account — editing is disabled');
 switch(a){
 case 'thmode':TH.mode=ds.v;saveTheme();render();break;
 case 'cw':TH.cw=ds.v;saveTheme();render();break;
 case 'editmode':closeOV();setTimeout(()=>setEdit(true),420);break;
 case 'resetlayout':if(confirm('Reset home screen widgets?')){LAYOUT=defaultLayout();saveLayout();render();toast('Home screen reset')}break;
 case 'start':startSession(ds.t);break;
 case 'addset':save(d=>{const s=d.active.exercises[ds.ei].sets;const l=s[s.length-1]||{w:'',r:8};s.push({w:l.w,r:l.r,done:false})});break;
 case 'done':save(d=>{const s=d.active.exercises[ds.ei].sets[ds.si];s.done=!s.done;if(s.done)restTimer(90)});break;
 case 'rmex':save(d=>d.active.exercises.splice(ds.ei,1));break;
 case 'pickex':sheet(`<h3>Add exercise</h3><input id="exq" placeholder="Search or type a new one"><div class="list" id="exl"></div>`,el=>{const draw=()=>{const q=el.querySelector('#exq').value.trim();const m=D.exerciseLib.filter(x=>x.toLowerCase().includes(q.toLowerCase()));el.querySelector('#exl').innerHTML=m.map(x=>`<button class="btn ghost block" style="margin-top:6px;justify-content:flex-start" data-x="${esc(x)}">${esc(x)}</button>`).join('')+(q&&!m.some(x=>x.toLowerCase()===q.toLowerCase())?`<button class="btn block" style="margin-top:6px" data-x="${esc(q)}" data-new="1">＋ Create “${esc(q)}”</button>`:'')};draw();el.querySelector('#exq').oninput=draw;
  el.querySelector('#exl').onclick=ev=>{const x=ev.target.closest('[data-x]');if(!x)return;save(d=>{if(x.dataset.new)d.exerciseLib.push(x.dataset.x);d.active.exercises.push(newEx(x.dataset.x))});closeSheet()}});break;
 case 'finish':{const a2=D.active;const kept=a2.exercises.map(e=>({...e,sets:e.sets.filter(s=>s.done&&s.w!=='')})).filter(e=>e.sets.length);if(!kept.length)return toast('Tick at least one set first');
  save(d=>{d.workouts.push({id:a2.id,date:a2.date,name:a2.name,notes:'',exercises:kept});d.active=null},'Workout saved 💪');clearInterval(restT);break}
 case 'discard':if(confirm('Discard this session?'))save(d=>d.active=null,'Session discarded');break;
 case 'openw':{const w=D.workouts.find(x=>x.id===ds.id);sheet(`<h3>${esc(w.name)}</h3><p class="muted">${prettyDate(w.date)} · ${vol(w).toLocaleString()} ${U()} volume</p>${w.exercises.map(e=>`<div class="card"><h2>${esc(e.name)}</h2><div class="muted">${e.sets.map(s=>toDisp(s.w)+' × '+s.r).join(' · ')}</div></div>`).join('')}<div class="grid2" data-edit><button class="btn danger" id="delw">Delete</button><button class="btn ghost" id="cl">Close</button></div>${canEdit()?'':'<button class="btn ghost block" id="cl2">Close</button>'}`,el=>{el.querySelector('#cl')&&(el.querySelector('#cl').onclick=closeSheet);el.querySelector('#cl2')&&(el.querySelector('#cl2').onclick=closeSheet);el.querySelector('#delw').onclick=()=>{if(confirm('Delete this workout?')){save(d=>d.workouts=d.workouts.filter(x=>x.id!==w.id),'Deleted');closeSheet()}}});break}
 case 'newtpl':sheet(`<h3>New template</h3><label class="f">Name</label><input id="tn" placeholder="e.g. Upper"><label class="f">Exercises</label><div class="chips" id="tx">${D.exerciseLib.map(x=>`<button class="chip" data-x="${esc(x)}">${esc(x)}</button>`).join('')}</div><button class="btn block" style="margin-top:14px" id="ts">Save template</button>`,el=>{const sel=[];el.querySelector('#tx').onclick=ev=>{const c=ev.target.closest('[data-x]');if(!c)return;const i=sel.indexOf(c.dataset.x);i<0?sel.push(c.dataset.x):sel.splice(i,1);c.classList.toggle('on')};
  el.querySelector('#ts').onclick=()=>{const n=el.querySelector('#tn').value.trim();if(!n||!sel.length)return toast('Name and at least one exercise');save(d=>d.templates.push({name:n,exercises:sel}),'Template saved');closeSheet()}});break;
 case 'libadd':{const v=$('#newex').value.trim();if(v)save(d=>{if(!d.exerciseLib.includes(v))d.exerciseLib.push(v)},'Added');break}
 case 'addfood':foodSheet(ds.meal,ds.plan);break;
 case 'rmfood':save(d=>d.food[S.foodDate].splice(+ds.i,1));break;
 case 'rmplan':save(d=>d.mealPlan[ds.m].splice(+ds.i,1));break;
 case 'logplan':save(d=>{const t=iso(new Date());d.food[t]=d.food[t]||[];MEALS.forEach(m=>(d.mealPlan[m]||[]).forEach(e=>{d.food[t].push({fid:e.fid,meal:m,q:e.q});const pi=d.pantry.find(p=>p.fid===e.fid);if(pi)pi.qty=Math.max(0,pi.qty-pantryStep(pi)*e.q)}))},'Meal plan logged to today');break;
 case 'fd':S.foodDate=iso(new Date(new Date(S.foodDate+'T12:00').getTime()+ds.n*864e5));render();break;
 case 'cm':S.calMonth+=+ds.n;render();break;
 case 'pq':save(d=>{const p=d.pantry.find(x=>x.id===ds.id);p.qty=Math.max(0,p.qty+ds.n*pantryStep(p))});break;
 case 'addpantry':sheet(`<h3>Add pantry item</h3><label class="f">Item</label><input id="pn"><div class="grid3"><div><label class="f">Qty</label><input id="pqv" inputmode="decimal" value="1"></div><div><label class="f">Unit</label><select id="pu"><option>pcs</option><option>g</option><option>cups</option><option>cans</option></select></div><div><label class="f">Low at</label><input id="pm" inputmode="decimal" value="1"></div></div>
  <label class="f">Link to food (auto-deduct when logged)</label><select id="pf"><option value="">None</option>${D.foods.map(f=>`<option value="${f.id}">${esc(f.name)}</option>`).join('')}</select><button class="btn block" style="margin-top:14px" id="ps">Add to pantry</button>`,el=>{el.querySelector('#ps').onclick=()=>{const n=el.querySelector('#pn').value.trim();if(!n)return toast('Name required');save(d=>d.pantry.push({id:'p'+uid(),name:n,qty:+el.querySelector('#pqv').value||0,unit:el.querySelector('#pu').value,min:+el.querySelector('#pm').value||0,fid:el.querySelector('#pf').value||undefined}),'Added to pantry');closeSheet()}});break;
 case 'sleep':{const t=iso(new Date()),cur=D.sleep.find(s=>s.date===t)||{hours:7.5,quality:3};sheet(`<h3>Log sleep</h3><label class="f">Hours slept</label><input id="sh" inputmode="decimal" value="${cur.hours}"><label class="f">Quality</label><div class="seg" id="sq">${[1,2,3,4,5].map(q=>`<button class="${q===cur.quality?'on':''}" data-q="${q}">${q}★</button>`).join('')}</div><button class="btn block" id="ss">Save sleep</button>`,el=>{let q=cur.quality;el.querySelector('#sq').onclick=ev=>{const x=ev.target.closest('[data-q]');if(!x)return;q=+x.dataset.q;el.querySelectorAll('#sq button').forEach(y=>y.classList.toggle('on',y===x))};
  el.querySelector('#ss').onclick=()=>{const h=+el.querySelector('#sh').value;if(!(h>0&&h<24))return toast('Enter hours 0–24');save(d=>{d.sleep=d.sleep.filter(s=>s.date!==t);d.sleep.push({date:t,hours:h,quality:q})},'Sleep saved');closeSheet()}});break}
 case 'weight':{const t=iso(new Date()),cur=D.weight.find(s=>s.date===t);sheet(`<h3>Log body weight</h3><label class="f">Weight (${U()})</label><input id="wv" inputmode="decimal" value="${cur?toDisp(cur.kg):''}"><button class="btn block" style="margin-top:12px" id="ws">Save</button>`,el=>{el.querySelector('#ws').onclick=()=>{const v=+el.querySelector('#wv').value;if(!(v>0))return toast('Enter a weight');save(d=>{d.weight=d.weight.filter(s=>s.date!==t);d.weight.push({date:t,kg:fromDisp(v)})},'Weight saved');closeSheet()}});break}
 case 'supp':save(d=>{const t=iso(new Date()),l=d.supplements.log[t]=d.supplements.log[t]||[];const i=l.indexOf(ds.s);i<0?l.push(ds.s):l.splice(i,1)});break;
 case 'addsupp':{const n=prompt('Supplement name');if(n&&n.trim())save(d=>d.supplements.list.push(n.trim()));break}
 case 'signin':DB.signIn(ds.id);D=DB.get();closeOV();toast('Signed in as '+DB.currentUser().name);break;
 case 'export':exportData(ds.k);break;
 case 'tour':onboarding(true);break;
 case 'reset':if(confirm('Reset all demo data?')){D=DB.reset();render();onboarding(false)}break;
 }});
document.addEventListener('change',e=>{const t=e.target;
 if(t.id==='liftsel'){S.liftEx=t.value;render();return}
 if(t.id==='imp'){const f=t.files[0];if(!f)return;f.text().then(s=>{try{const j=JSON.parse(s);if(!j.profile||!j.workouts)throw 0;DB.replace(j);render();toast('Backup imported')}catch(x){toast('That file is not a Logbook backup')}});return}
 if(t.dataset.p){const k=t.dataset.p,num=['weekGoal','sleepGoal'].includes(k);save(d=>d.profile[k]=num?(+t.value||0):t.value,'Saved');return}
 if(t.dataset.t){save(d=>d.profile.targets[t.dataset.t]=+t.value||0,'Target saved');return}
 if(t.dataset.f&&D.active){const v=t.value.trim();save(d=>{const s=d.active.exercises[t.dataset.ei].sets[t.dataset.si];s[t.dataset.f]=t.dataset.f==='w'?(v===''?'':fromDisp(+v)):(+v||0)})}
 if(t.id==='sname'&&D.active)save(d=>d.active.name=t.value.trim()||'Workout')});

render();
if(!P().onboarded&&canEdit())onboarding(false);

})();
