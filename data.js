/* Data layer. Everything the UI touches goes through `DB`.
   Swap LocalBackend for a FirebaseBackend implementing the same methods later. */
(function(){
const iso=d=>{const x=new Date(d);x.setMinutes(x.getMinutes()-x.getTimezoneOffset());return x.toISOString().slice(0,10)};
const dayOff=n=>{const d=new Date();d.setDate(d.getDate()+n);return iso(d)};
function seed(){ // DEMO DATA ONLY — no real personal information
  const ex=['Bench Press','Squat','Deadlift','Overhead Press','Barbell Row','Pull-up','Romanian Deadlift','Lat Pulldown','Incline DB Press','Leg Press','Bicep Curl','Tricep Pushdown'];
  const workouts=[]; // workouts start blank (no auto-seeded sessions)
  const sleep=[],weight=[];
  for(let i=-20;i<0;i++){sleep.push({date:dayOff(i),hours:+(6.4+((i*7)%10)/7).toFixed(1),quality:3+((i*3)%3+3)%3});
    if(i%2===0)weight.push({date:dayOff(i),kg:+(78.6-(i+20)*0.04).toFixed(1)})}
  const foods=[
    {id:'f1',name:'Greek yogurt (1 cup)',kcal:150,p:20,c:9,f:4},{id:'f2',name:'Oats (60 g)',kcal:228,p:8,c:40,f:4},
    {id:'f3',name:'Chicken breast (150 g)',kcal:248,p:46,c:0,f:5},{id:'f4',name:'Rice, cooked (1 cup)',kcal:205,p:4,c:45,f:0},
    {id:'f5',name:'Banana',kcal:105,p:1,c:27,f:0},{id:'f6',name:'Eggs (2)',kcal:144,p:12,c:1,f:10},
    {id:'f7',name:'Protein shake',kcal:160,p:30,c:4,f:2},{id:'f8',name:'Salmon (150 g)',kcal:310,p:34,c:0,f:19},
    {id:'f9',name:'Broccoli (1 cup)',kcal:55,p:4,c:11,f:1},{id:'f10',name:'Almonds (28 g)',kcal:164,p:6,c:6,f:14}];
  const food={};
  // food log starts empty (no demo meals logged)
  return {
    version:1,demo:true,
    profile:{name:'Alex',goal:'Build muscle',units:'kg',theme:'system',targets:{kcal:2400,p:170,c:250,f:75},sleepGoal:8,weekGoal:4,onboarded:false},
    lib:(window.EXLIB||[]).map((e,i)=>({id:'x'+i,...e,builtin:true})),exerciseLib:(window.EXLIB||[]).map(e=>e.name),templates:JSON.parse(JSON.stringify(window.IMPORTED_TEMPLATES||[])),split:(window.IMPORTED_SPLIT||[]).slice(),
    workouts,active:null,sleep,weight,
    supplements:{list:['Creatine','Vitamin D'],log:{}},
    foods,food,
    mealPlan:{Breakfast:[],Lunch:[],Snack:[],Dinner:[]},schedule:{},
    pantry:[{id:'p1',name:'Eggs',qty:4,unit:'pcs',min:6,fid:'f6'},{id:'p2',name:'Chicken breast',qty:900,unit:'g',min:600,fid:'f3'},
      {id:'p3',name:'Greek yogurt',qty:0,unit:'cups',min:2,fid:'f1'},{id:'p4',name:'Oats',qty:1200,unit:'g',min:300,fid:'f2'},
      {id:'p5',name:'Bananas',qty:5,unit:'pcs',min:3,fid:'f5'},{id:'p6',name:'Rice',qty:250,unit:'g',min:500}],
    accounts:[{id:'owner',name:'Alex (you)',role:'owner'},{id:'sally',name:'Sally',role:'viewer',note:'Meal-plan helper'},{id:'atlas',name:'Atlas',role:'viewer',note:'Optimization bot'}]
  };
}
const LocalBackend={
  KEY:'lb2w:data6',SESSION:'lb2w:session',
  load(){try{const s=localStorage.getItem(this.KEY);if(s)return JSON.parse(s)}catch(e){}const d=seed();this.save(d);return d},
  save(d){localStorage.setItem(this.KEY,JSON.stringify(d))},
  reset(){localStorage.removeItem(this.KEY);return this.load()},
  getSession(){return localStorage.getItem(this.SESSION)||'owner'},
  setSession(id){localStorage.setItem(this.SESSION,id)}
};
let backend=LocalBackend,data=null,listeners=[];
window.DB={
  iso,dayOff,
  init(){data=backend.load();return data},
  get(){return data},
  currentUser(){const id=backend.getSession();return data.accounts.find(a=>a.id===id)||data.accounts[0]},
  canEdit(){return this.currentUser().role==='owner'},
  signIn(id){backend.setSession(id)},
  /* All writes go through mutate(); viewers are rejected here as well as in the UI. */
  mutate(fn){if(!this.canEdit()){throw new Error('read-only')}fn(data);backend.save(data);listeners.forEach(l=>l(data))},
  replace(d){if(!this.canEdit())throw new Error('read-only');data=d;backend.save(d)},
  reset(){data=backend.reset();backend.setSession('owner');return data},
  onChange(l){listeners.push(l)}
};
})();
