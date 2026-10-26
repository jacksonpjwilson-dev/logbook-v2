const test=require('node:test'),assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm'),path=require('node:path'),T=require('../stage2/training-core.js'),registry=require('../stage2/builtin-ids.js');
function library(){const context={window:{}};vm.createContext(context);vm.runInContext(fs.readFileSync(path.join(__dirname,'../preview-widget/lib.js'),'utf8'),context);return JSON.parse(JSON.stringify(context.window.EXLIB))}
test('built-in exercise identities remain permanent when the source library is reordered',()=>{
 const original=T.seedBuiltins(T.empty(),library(),registry),reordered=T.seedBuiltins(T.empty(),library().reverse(),registry);assert.deepEqual(Object.fromEntries(Object.values(original.catalog).map(e=>[e.name,e.id])),Object.fromEntries(Object.values(reordered.catalog).map(e=>[e.name,e.id])));assert.equal(original.catalog.x2.name,'Flat barbell bench press');
});
test('unknown built-ins require an explicit registry update and reseeding never replaces user renames',()=>{
 const original=T.seedBuiltins(T.empty(),library(),registry);assert.throws(()=>T.seedBuiltins(original,[{name:'Unregistered new exercise'}],registry),/registry/);const renamed=T.putExercise(original,{id:'x2',name:'My renamed press'}),reseeded=T.seedBuiltins(renamed,library(),registry);assert.equal(reseeded.catalog.x2.name,'My renamed press');assert.equal(reseeded.catalog.x2.equip,'Barbell');
});
