/* Deterministic synthetic-only copy. Never writes preview-widget or production assets. */
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const root=path.resolve(__dirname,'..'),out=path.join(__dirname,'dev','generated');fs.mkdirSync(out,{recursive:true});
let source=fs.readFileSync(path.join(root,'preview-widget/app.js'),'utf8');
function replaceOnce(before,after){if(source.split(before).length!==2)throw Error('Legacy integration marker changed: '+before);source=source.replace(before,after)}
const boundary='/* preview update: own service worker (scope /preview-widget/) + version check */';
if(source.split(boundary).length!==2)throw Error('Service worker boundary changed');source=source.split(boundary)[0];
replaceOnce("(function(){\n'use strict';\nconst $=", "(async function(){\n'use strict';\nconst $=");
replaceOnce('function save(fn,msg){try{DB.mutate(fn);','async function save(fn,msg){try{await DB.mutate(fn);');
replaceOnce("catch(e){toast('Read-only account — editing is disabled')}}","catch(e){toast('Not saved: '+e.message)}}");
source=source.replaceAll('{DB.mutate(','{await DB.mutate(');
replaceOnce("if(t.id==='imp'){", "if(t.id==='imp'){toast('Imports are disabled in this synthetic development build');return;");
replaceOnce("case 'reset':", "case 'reset':toast('Reset is disabled in this synthetic build');break;case '__disabled_reset':");
source=source.replaceAll('localStorage.','Stage1Storage.').replaceAll('sessionStorage.','Stage1SessionStorage.');
if(/navigator\.serviceWorker|localStorage\.|sessionStorage\./.test(source))throw Error('Unexpected live storage or service worker reference');
fs.writeFileSync(path.join(out,'legacy-app.js'),source);
// Build the fixture from the actual legacy seed with an in-memory storage stub.
const memory=new Map(),context={window:{},localStorage:{getItem:k=>memory.get(k)||null,setItem:(k,v)=>memory.set(k,v)},Date};
vm.createContext(context);vm.runInContext(fs.readFileSync(path.join(root,'preview-widget/lib.js'),'utf8'),context);vm.runInContext(fs.readFileSync(path.join(root,'preview-widget/data.js'),'utf8'),context);
const fixture=context.window.DB.init();fixture.profile.name='Synthetic Developer';fixture.profile.onboarded=true;fixture.profile.goalHist=[{from:'2000-01-01',t:{...fixture.profile.targets}}];fixture.templates=[{id:'synthetic-template-1',name:'Fictional Push',exercises:['Bench Press']}];fixture.split=['Fictional Push'];fixture.foods=[];
fs.writeFileSync(path.join(out,'fixture.json'),JSON.stringify(fixture,null,2)+'\n');
console.log('Built isolated legacy copy and actual-schema synthetic fixture; production files untouched.');
