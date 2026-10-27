const {chromium}=require('playwright');const fs=require('fs');
(async()=>{const [mode,...ts]=process.argv.slice(2);
const b=await chromium.launch();const pg=await b.newPage({viewport:{width:1920,height:1080}});
pg.on('console',m=>console.log('console',m.text()));pg.on('pageerror',e=>console.log('ERR',e.message));
await pg.goto('file://'+__dirname+'/video.html');await pg.evaluate(()=>window.ready);
if(mode==='stills'){for(const t of ts){await pg.evaluate(t=>render(+t),t);await pg.screenshot({path:`still_${t}.png`});}}
else{fs.mkdirSync('frames',{recursive:true});const N=600;for(let i=0;i<N;i++){await pg.evaluate(t=>render(t),i/30);await pg.screenshot({path:`frames/f${String(i).padStart(4,'0')}.jpg`,type:'jpeg',quality:94});}}
await b.close();})();
