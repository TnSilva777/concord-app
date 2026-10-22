const fs = require('node:fs');
const path = require('node:path');
const sharp = require('sharp');
const toIcoModule = require('png-to-ico');
const toIco = toIcoModule.default || toIcoModule;
(async()=>{
 const dir=path.join(__dirname,'assets');
 const svg=fs.readFileSync(path.join(dir,'concord.svg'));
 const sizes=[16,32,48,64,128,256];
 const pngs=await Promise.all(sizes.map(size=>sharp(svg).resize(size,size).png().toBuffer()));
 fs.writeFileSync(path.join(dir,'concord.png'),pngs[5]);
 fs.writeFileSync(path.join(dir,'concord.ico'),await toIco(pngs));
 console.log('Ícones do CONCORD gerados: PNG e ICO');
})().catch(err=>{console.error(err);process.exitCode=1});
