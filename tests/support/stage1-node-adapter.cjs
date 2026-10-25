/* Synthetic-only durable disk adapter for Node tests. */
const fs=require('node:fs/promises'),path=require('node:path');
function createTempAdapter(directory,name='synthetic-stage1.json'){
 if(!/^synthetic-[a-zA-Z0-9._-]+[.]json$/.test(name))throw Error('Synthetic test filename required');
 const file=path.join(directory,name);
 return {async read(){try{return JSON.parse(await fs.readFile(file,'utf8'))}catch(e){if(e.code==='ENOENT')return null;throw e}},
 async write(value){const temp=path.join(directory,'synthetic-temp-'+process.pid+'-'+Date.now()+'-'+Math.random().toString(36).slice(2)+'.json');
 try{await fs.writeFile(temp,JSON.stringify(value),{flag:'wx',mode:0o600});await fs.rename(temp,file)}
 finally{await fs.rm(temp,{force:true})}}};
}
module.exports={createTempAdapter};
