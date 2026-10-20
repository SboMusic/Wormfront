// Copyright (c) 2026 SboMusic
// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';
import crypto from 'node:crypto';
const root=path.resolve(process.argv[2] || '.');
const markers=(process.env.PRIVATE_MARKERS || '').split('|').filter(Boolean);
const excluded=new Set(['.git','.godot','.local','dist','build']);
const findings=[]; let count=0;
function inspect(text,file,legal=false) {
 if (/(?:[a-z]:\\Users\\[^\\\s]+|\/Users\/[^/\s]+|\/home\/[^/\s]+)/i.test(text)) findings.push([file,'percorso personale']);
 if (/(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|sk-proj-[A-Za-z0-9_-]{30,})/.test(text)) findings.push([file,'possibile credenziale']);
 if(!legal && markers.some(m=>text.toLowerCase().includes(m.toLowerCase()))) findings.push([file,'marcatore privato']);
}
function walk(dir) {
 for(const entry of fs.readdirSync(dir,{withFileTypes:true})) {
  if(excluded.has(entry.name)) continue;
  const full=path.join(dir,entry.name), rel=path.relative(root,full);
  inspect(rel,rel);
  if(entry.isDirectory()) {walk(full);continue;}
  if(!entry.isFile()) continue;
  count++; const bytes=fs.readFileSync(full), legal=rel.split(path.sep).includes('licenses');
  // Unmodified official Godot 4.5.1 Windows release template; vendor build paths
  // and third-party author names are not personal data of the game publisher.
  if(entry.name==='Crateri.exe' && crypto.createHash('sha256').update(bytes).digest('hex')==='78ccc576e8f8bffd7ef6ad6f36ebd72a41e609a1052225a55b3407c96ea84065') continue;
  inspect(bytes.toString('utf8'),rel,legal); inspect(bytes.toString('utf16le'),rel,legal);
  if(entry.name.endsWith('.png')) {
   for(let offset=8;offset+12<=bytes.length;) {
    const size=bytes.readUInt32BE(offset), type=bytes.toString('ascii',offset+4,offset+8);
    const data=bytes.subarray(offset+8,offset+8+size);
    if(type==='tEXt'||type==='iTXt') inspect(data.toString('utf8'),rel);
    if(type==='zTXt') {const zero=data.indexOf(0);try{inspect(zlib.inflateSync(data.subarray(zero+2)).toString('utf8'),rel);}catch{findings.push([rel,'metadati compressi non leggibili']);}}
    offset+=size+12;
   }
  }
 }
}
walk(root);
console.log(JSON.stringify({files:count,findings},null,2));
process.exitCode=findings.length?1:0;
