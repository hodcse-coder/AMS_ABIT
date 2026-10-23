import {inflateRawSync} from 'node:zlib';
const fail=message=>{throw Object.assign(new Error(message),{status:400});};
const decode=text=>text.replace(/&(#x[0-9a-f]+|#\d+|amp|lt|gt|quot|apos);/gi,(_,key)=>{if(key[0]==='#'){const number=key[1].toLowerCase()==='x'?parseInt(key.slice(2),16):Number(key.slice(1));return number<=0x10ffff&&number>0?String.fromCodePoint(number):'';}return {amp:'&',lt:'<',gt:'>',quot:'"',apos:"'"}[key.toLowerCase()];});
function texts(xml){return [...xml.matchAll(/<(?:\w+:)?t(?:\s[^>]*)?>([\s\S]*?)<\/(?:\w+:)?t>/g)].map(match=>decode(match[1])).join('');}
function csv(text){const rows=[];let row=[],cell='',quoted=false;for(let index=0;index<text.length;index++){const char=text[index];if(char==='"'){if(quoted&&text[index+1]==='"'){cell+='"';index++;}else quoted=!quoted;}else if(!quoted&&(char===','||char==='\n'||char==='\r')){row.push(cell);cell='';if(char!==','){if(char==='\r'&&text[index+1]==='\n')index++;rows.push(row);row=[];}}else cell+=char;}if(quoted)fail('CSV contains an unfinished quoted value.');if(cell||row.length){row.push(cell);rows.push(row);}return rows;}
function workbook(bytes){
 let end=-1;for(let index=bytes.length-22;index>=Math.max(0,bytes.length-65557);index--)if(bytes.readUInt32LE(index)===0x06054b50){end=index;break;}
 if(end<0)fail('Choose a valid XLSX workbook.');
 const entries=bytes.readUInt16LE(end+10),directory=bytes.readUInt32LE(end+16);if(entries>200||directory>=bytes.length)fail('Workbook is too large.');
 const files=new Map();let offset=directory,total=0;
 for(let index=0;index<entries;index++){
  if(offset+46>bytes.length||bytes.readUInt32LE(offset)!==0x02014b50)fail('Invalid workbook archive.');
  const flags=bytes.readUInt16LE(offset+8),method=bytes.readUInt16LE(offset+10),compressed=bytes.readUInt32LE(offset+20),size=bytes.readUInt32LE(offset+24),nameLength=bytes.readUInt16LE(offset+28),extra=bytes.readUInt16LE(offset+30),comment=bytes.readUInt16LE(offset+32),local=bytes.readUInt32LE(offset+42);
  const name=bytes.subarray(offset+46,offset+46+nameLength).toString('utf8');offset+=46+nameLength+extra+comment;
  if(flags&1||![0,8].includes(method)||size>8000000||offset>bytes.length)fail('Unsupported or oversized workbook.');
  total+=size;if(total>16000000)fail('Workbook is too large.');
  if(!['xl/sharedStrings.xml','xl/worksheets/sheet1.xml'].includes(name))continue;
  if(local+30>bytes.length||bytes.readUInt32LE(local)!==0x04034b50)fail('Invalid workbook entry.');
  const start=local+30+bytes.readUInt16LE(local+26)+bytes.readUInt16LE(local+28);if(start+compressed>bytes.length)fail('Invalid workbook data.');
  let output;try{output=method===8?inflateRawSync(bytes.subarray(start,start+compressed),{maxOutputLength:8000000}):bytes.subarray(start,start+compressed);}catch{fail('Unable to read the workbook.');}
  if(output.length!==size)fail('Invalid workbook entry size.');const xml=output.toString('utf8');if(/<!DOCTYPE|<!ENTITY/i.test(xml))fail('Unsupported XML content.');files.set(name,xml);
 }
 const sheet=files.get('xl/worksheets/sheet1.xml');if(!sheet)fail('The workbook must contain a first worksheet.');
 const shared=[...(files.get('xl/sharedStrings.xml')||'').matchAll(/<si(?:\s[^>]*)?>([\s\S]*?)<\/si>/g)].map(match=>texts(match[1]));
 return [...sheet.matchAll(/<row(?:\s[^>]*)?>([\s\S]*?)<\/row>/g)].map(match=>{const cells=[];let next=0;for(const cell of match[1].matchAll(/<c\b([^>]*?)(?:\/>|>([\s\S]*?)<\/c>)/g)){const attrs=cell[1],body=cell[2]||'',ref=attrs.match(/\br="([A-Z]+)\d+"/);let index=next;if(ref){index=0;for(const letter of ref[1])index=index*26+letter.charCodeAt(0)-64;index--;}if(index>200)fail('Workbook has too many columns.');const type=attrs.match(/\bt="([^"]+)"/)?.[1],value=body.match(/<v(?:\s[^>]*)?>([\s\S]*?)<\/v>/)?.[1]||'';if(/<f\b/.test(body))fail('Replace spreadsheet formulas with their values before importing.');cells[index]=type==='s'?shared[Number(value)]||'':type==='inlineStr'?texts(body):decode(value);next=index+1;}return cells;});
}
export function parseStudentImport(name,encoded,allowed){
 if(typeof encoded!=='string'||!encoded||encoded.length>5600000||encoded.length%4||!/^[A-Za-z0-9+/]+={0,2}$/.test(encoded))fail('Choose a CSV or XLSX file up to 4 MB.');
 const bytes=Buffer.from(encoded,'base64');if(bytes.length>4194304||bytes.toString('base64')!==encoded)fail('Choose a valid file up to 4 MB.');
 let rows;if(/\.xlsx$/i.test(name))rows=workbook(bytes);else if(/\.csv$/i.test(name))rows=csv(bytes.toString('utf8').replace(/^\uFEFF/,''));else fail('Choose a CSV or XLSX file.');
 rows=rows.filter(row=>row.some(value=>String(value??'').trim()));if(rows.length<2||rows.length>201)fail('Import between 1 and 200 students per file.');
 const headers=rows.shift().map(value=>String(value??'').trim().toLowerCase());if(new Set(headers).size!==headers.length||headers.some(value=>!allowed.has(value)))fail('Use the column names from the downloadable template.');
 return rows.map(row=>Object.fromEntries(headers.map((key,index)=>{let value=String(row[index]??'').trim();if(key==='dob'&&/^\d+(\.\d+)?$/.test(value)){const stamp=new Date(Date.UTC(1899,11,30)+Number(value)*86400000);if(Number.isFinite(stamp.getTime()))value=stamp.toISOString().slice(0,10);}return [key,value];})));
}
