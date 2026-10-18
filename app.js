(function(){
'use strict';
const $=s=>document.querySelector(s);
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const {iso,dayOff}=DB;
let D=DB.init();
const S={tab:D.active?'train':'today',foodSeg:'log',progSeg:'lifts',foodDate:iso(new Date()),liftEx:'Bench Press',calMonth:0,onb:null};
const ICON={
 today:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/></svg>',
 train:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><path d="M6.5 6.5v11M17.5 6.5v11M3 9v6M21 9v6M6.5 12h11"/></svg>',
 food:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><path d="M4 11h16a8 8 0 0 1-16 0zM8 7c0-2 2-2 2-4M12 7c0-2 2-2 2-4"/></svg>',
 progress:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><path d="M3 20h18M6 16l4-5 3 3 5-7"/></svg>',
 me:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><circle cx="12" cy="8" r="4"/><path d="M4 21c1.5-4 4.5-6 8-6s6.5 2 8 6"/></svg>'};
const TABS=[['today','Today'],['train','Train'],['food','Food'],['progress','Progress'],['me','Me']];

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
function applyTheme(){const t=P().theme;const dark=t==='dark'||(t==='system'&&matchMedia('(prefers-color-scheme: dark)').matches);document.documentElement.dataset.theme=dark?'dark':'light'}
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
 save(d=>{d.active={id:'w'+uid(),date:iso(new Date()),start:Date.now(),name:t?t.name:'Workout',exercises:(t?t.exercises:[]).map(n=>newEx(n))}},'Session started');S.tab='train';render()}
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
 return `<div class="card"><h2>Account <span class="demo">Demo login</span></h2><div class="list">${D.accounts.map(a=>`<div class="item"><div class="avatar" style="width:40px;height:40px;display:flex;align-items:center;justify-content:center">${esc(a.name[0])}</div><div class="grow"><div class="t">${esc(a.name)}</div><div class="s">${a.role==='owner'?'Owner · can edit':'Viewer · read-only'}${a.note?' · '+esc(a.note):''}</div></div>${a.id===u.id?'<span class="pill ok">Signed in</span>':`<button class="btn ghost sm" data-act="signin" data-id="${a.id}">Sign in</button>`}</div>`).join('')}</div>
 <p class="muted">Mock sign-in for the preview. In the real app each person signs in with their own account and the owner grants read-only access.</p></div>
 <div class="card"><h2>Profile</h2><label class="f">Name</label><input data-p="name" value="${esc(p.name)}" ${canEdit()?'':'disabled'}>
 <label class="f">Goal</label><select data-p="goal" ${canEdit()?'':'disabled'}>${['Build muscle','Lose fat','Get stronger','Stay healthy'].map(g=>`<option ${g===p.goal?'selected':''}>${g}</option>`).join('')}</select>
 <div class="grid2"><div><label class="f">Units</label><select data-p="units" ${canEdit()?'':'disabled'}><option value="kg" ${p.units==='kg'?'selected':''}>kg</option><option value="lb" ${p.units==='lb'?'selected':''}>lb</option></select></div>
 <div><label class="f">Appearance</label><select data-p="theme" ${canEdit()?'':'disabled'}>${['system','light','dark'].map(x=>`<option ${x===p.theme?'selected':''}>${x}</option>`).join('')}</select></div>
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
const TOUR=[['☀️','Today','Your daily dashboard: calories and macros left, today’s workout, sleep, weight, supplements and coach tips.'],
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
function render(){D=DB.get();applyTheme();const u=DB.currentUser(),ro=!canEdit();document.body.classList.toggle('readonly',ro);
 const titles={today:new Date().toLocaleDateString(undefined,{weekday:'long'}),train:'Train',food:'Food',progress:'Progress',me:'Settings'};
 const sub={today:`Hi ${esc(P().name)} · ${new Date().toLocaleDateString(undefined,{month:'long',day:'numeric'})}`,train:D.active?'Session in progress':'Workouts & history',food:'Log, plan & pantry',progress:'Trends over time',me:'Profile, targets & sharing'};
 const view={today:vToday,train:vTrain,food:vFood,progress:vProgress,me:vMe}[S.tab]();
 $('#app').innerHTML=`<header class="top"><div style="min-width:0"><div class="sub">${sub[S.tab]}</div><h1>${titles[S.tab]}</h1></div><button class="avatar" data-go="me" aria-label="Account">${esc((ro?u.name:P().name)[0])}</button></header>
 <div class="banner"><span class="demo">Preview</span><span>${ro?`Signed in as <b>${esc(u.name)}</b> · read-only`:'Demo data, saved on this device only'}</span></div>
 <main>${view}</main>
 ${D.active&&S.tab!=='train'?`<button class="fab-live" data-go="train"><span>● ${esc(D.active.name)} in progress</span><span>Resume ›</span></button>`:''}
 <nav class="tabbar"><div class="in">${TABS.map(([k,n])=>`<button class="${S.tab===k?'on':''}" data-go="${k}" aria-label="${n}">${ICON[k]}<span>${n}</span></button>`).join('')}</div></nav>`;
 if(ro)$('#app').querySelectorAll('main input,main select,main textarea').forEach(i=>{if(i.id!=='liftsel')i.disabled=true});
 tickElapsed()}
function tickElapsed(){const e=$('#elapsed');if(e&&D.active){const s=Math.floor((Date.now()-D.active.start)/1000);e.textContent=`${Math.floor(s/60)}:${String(s%60).padStart(2,'0')}`}}
setInterval(tickElapsed,1000);

/* ---------- EVENTS ---------- */
document.addEventListener('click',e=>{const g=e.target.closest('[data-go]');if(g){S.tab=g.dataset.go;render();scrollTo(0,0);return}
 const sg=e.target.closest('[data-seg]');if(sg){S[sg.dataset.seg]=sg.dataset.v;render();return}
 const b=e.target.closest('[data-act]');if(!b||!$('#app').contains(b))return;const a=b.dataset.act,ds=b.dataset;
 const viewOnly=['openw','fd','cm','signin','export','tour'];if(!canEdit()&&!viewOnly.includes(a))return toast('Read-only account — editing is disabled');
 switch(a){
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
 case 'signin':DB.signIn(ds.id);D=DB.get();S.tab='today';render();toast('Signed in as '+DB.currentUser().name);break;
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
if('serviceWorker' in navigator&&location.protocol!=='file:')navigator.serviceWorker.register('sw.js?v=1').catch(()=>{});
})();
