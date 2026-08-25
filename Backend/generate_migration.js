const fs = require('fs');
const path = require('path');
const ROOT = __dirname;
const SEED = fs.readFileSync(path.join(ROOT, 'database.sql'), 'utf8');
const INV = JSON.parse(fs.readFileSync(path.join(ROOT, '_inventory.json'), 'utf8'));

const PK = { users:'user_id', authors:'author_id', categories:'category_id',
  packages:'package_id', books:'book_id', kyc_verifications:'kyc_id' };
const INTEREST = new Set(Object.keys(PK));

function splitTop(str){
  const out=[]; let cur='', ins=false;
  for(let i=0;i<str.length;i++){
    const ch=str[i];
    if(ch==="'"){
      if(ins && str[i+1]==="'"){ cur+="''"; i++; continue; }
      ins=!ins; cur+=ch;
    } else if(ch===',' && !ins){ out.push(cur.trim()); cur=''; }
    else cur+=ch;
  }
  out.push(cur.trim()); return out;
}
function unquote(c){ c=c.trim(); if(c[0]==="'"&&c[c.length-1]==="'") return c.slice(1,-1).replace(/''/g,"'"); return c; }
function isNull(v){ return v===null||v===undefined||String(v).trim().toUpperCase()==='NULL'; }
function eq(v){ return "'"+String(v).replace(/'/g,"''")+"'" ; }

// ---- parse seed INSERT blocks into seedMap[table|pk] -> {col: value} ----
const seedMap = {};
const insRe = /INSERT\s+INTO\s+`?([a-zA-Z_]+)`?\s*\(([^)]*)\)\s*VALUES\s*([\s\S]*?)\s*ON\s+DUPLICATE/gi;
let m;
while((m=insRe.exec(SEED))!==null){
  const table=m[1]; if(!INTEREST.has(table)) continue;
  const cols=m[2].split(',').map(x=>x.trim().replace(/`/g,''));
  const pkCol=PK[table]; if(cols.indexOf(pkCol)<0) continue;
  const rowRe=/\(\s*([\s\S]*?)\s*\)(?=\s*,\s*\(|$)/g;
  const body=m[3].replace(/^\s*--[^\n]*$/gm,''); // strip seed comment lines
  let r;
  while((r=rowRe.exec(body))!==null){
    const cells=splitTop(r[1]); const row={};
    cols.forEach((c,i)=>{ if(i<cells.length) row[c]=unquote(cells[i]); });
    const pk=row[pkCol];
    if(pk!==undefined && !isNull(pk)) seedMap[table+'|'+pk]=row;
  }
}
function seedValue(table, pk, col){ const row=seedMap[table+'|'+pk]; return (row && row[col]!==undefined) ? row[col] : undefined; }

// ---- classify broken cells ----
const items = (INV.clean||[]).concat(INV.lossy||[]);
const preview=[], updates=[], manual=[];
for(const it of items){
  const t=it.t, col=it.c, pk=it.pk, before=it.before;
  const target=seedValue(t, pk, col);
  if(target===undefined||isNull(target)){ manual.push({t,col,pk,why:'no seed literal'}); continue; }
  preview.push({t,col,pk,before});
  updates.push('UPDATE `'+t+'` SET `'+col+'` = '+eq(target)+
               '\n   WHERE `'+PK[t]+'` = '+pk+' AND `'+col+'` = '+eq(before)+';');
}

const now=new Date().toISOString().slice(0,10);
const L=[];
L.push('-- ============================================================');
L.push('-- Repair Lao mojibake (UTF-8 bytes stored as Windows-1252/cp1252).');
L.push('-- DRAFT - NOT yet executed.  Generated '+now+' by generate_migration.js');
L.push('-- Each UPDATE fires ONLY when the cell exactly equals the confirmed');
L.push('-- malformed mojibake string, so it is idempotent and never touches');
L.push('-- correct (already-Lao) or plain-English text.');
L.push('-- ============================================================');
L.push('SET NAMES utf8mb4;');
L.push('USE ebook_db;');
L.push('');
L.push('-- ---------- PREVIEW (rows about to be repaired) ----------');
for(const p of preview){
  L.push('SELECT '+eq(p.t+'.'+p.col)+' AS cell, `'+PK[p.t]+'` AS id, LEFT(`'+p.col+'`,80) AS value');
  L.push('  FROM `'+p.t+'` WHERE `'+PK[p.t]+'` = '+p.pk+';');
}
L.push('');
L.push('-- ---------- FIX ----------');
for(const u of updates) L.push(u);
L.push('');
L.push('-- ---------- VERIFY (remaining mojibake = 0 expected) ----------');
for(const p of preview){
  L.push('-- '+p.t+'.'+p.col+' pk='+p.pk);
  L.push('SELECT COUNT(*) AS still_broken FROM `'+p.t+'` WHERE `'+PK[p.t]+'` = '+p.pk+' AND `'+p.col+'` = '+eq(p.before)+';');
}
L.push('');
L.push('-- -------- Manual review needed (no authoritative seed) --------');
if(manual.length){ for(const x of manual) L.push('--   '+x.t+'.'+x.col+' pk='+x.pk+' ('+x.why+')'); }
else L.push('--   (none)');

const outPath=path.join(ROOT,'migrations','20260825_fix_lao_mojibake.sql');
fs.mkdirSync(path.dirname(outPath),{recursive:true});
fs.writeFileSync(outPath,L.join('\n'),'utf8');
console.log('Wrote: '+outPath);
console.log('auto-fix cells: '+updates.length+' | manual: '+manual.length);
// DEBUG
console.log('seedMap keys count: '+Object.keys(seedMap).length);
console.log('seed users|1: '+JSON.stringify(seedMap['users|1']||'MISSING'));
console.log('seed users|2: '+JSON.stringify(seedMap['users|2']? {fn:seedMap['users|2'].first_name} : 'MISSING'));
console.log('seedMap keys sample: '+Object.keys(seedMap).slice(0,8).join(','));
console.log('preview objects store before? '+(preview[0]?JSON.stringify(preview[0]).slice(0,80):'none'));