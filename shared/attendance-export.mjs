export const attendanceColumns=[['attendance_date','Date'],['start_time','Class Start Time'],['end_time','End Time'],['course_name','Course'],['batch_name','Batch'],['section_name','Section'],['semester','Semester'],['topic_covered','Topic Covered'],['subject_name','Subject'],['subject_type','Subject Type'],['student_group','Group'],['strength','Strength'],['present','Present'],['absent','Absent']];
const xml=value=>String(value??'').replace(/[\x00-\x08\x0b\x0c\x0e-\x1f]/g,'').replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;').replaceAll("'",'&apos;');
const column=index=>{let text='';for(index++;index;index=Math.floor((index-1)/26))text=String.fromCharCode(65+(index-1)%26)+text;return text;};
// Store UTF-8 OOXML files in a ZIP archive; no formulas or external references.
export function attendanceWorkbook(rows,columns=attendanceColumns,sheetName='Student Attendance'){
 const encoder=new TextEncoder();
 const values=[columns.map(([,label])=>label),...rows.map(row=>columns.map(([key])=>row[key]??''))];
 const sheet=`<?xml version="1.0" encoding="UTF-8"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>${values.map((row,r)=>`<row r="${r+1}">${row.map((value,c)=>`<c r="${column(c)}${r+1}" t="${r>0&&typeof value==='number'?'n':'inlineStr'}">${r>0&&typeof value==='number'?`<v>${Number(value)||0}</v>`:`<is><t xml:space="preserve">${xml(value)}</t></is>`}</c>`).join('')}</row>`).join('')}</sheetData></worksheet>`;
 const files={
  '[Content_Types].xml':'<?xml version="1.0"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/></Types>',
  '_rels/.rels':'<?xml version="1.0"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>',
  'xl/workbook.xml':'<?xml version="1.0"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="Student Attendance" sheetId="1" r:id="rId1"/></sheets></workbook>',
  'xl/_rels/workbook.xml.rels':'<?xml version="1.0"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/></Relationships>',
  'xl/worksheets/sheet1.xml':sheet
 };
 files['xl/workbook.xml']=files['xl/workbook.xml'].replace('Student Attendance',xml(sheetName));
 let offset=0;const chunks=[],directory=[];
 for(const [path,content] of Object.entries(files)){
  const name=encoder.encode(path),data=encoder.encode(content);let crc=0xffffffff;
  for(const byte of data){crc^=byte;for(let bit=0;bit<8;bit++)crc=(crc>>>1)^((crc&1)?0xedb88320:0);}crc=(crc^0xffffffff)>>>0;
  const header=new Uint8Array(30+name.length),view=new DataView(header.buffer);view.setUint32(0,0x04034b50,true);view.setUint16(4,20,true);view.setUint16(6,0x800,true);view.setUint16(12,33,true);view.setUint32(14,crc,true);view.setUint32(18,data.length,true);view.setUint32(22,data.length,true);view.setUint16(26,name.length,true);header.set(name,30);
  const central=new Uint8Array(46+name.length),cv=new DataView(central.buffer);cv.setUint32(0,0x02014b50,true);cv.setUint16(4,20,true);cv.setUint16(6,20,true);cv.setUint16(8,0x800,true);cv.setUint16(14,33,true);cv.setUint32(16,crc,true);cv.setUint32(20,data.length,true);cv.setUint32(24,data.length,true);cv.setUint16(28,name.length,true);cv.setUint32(42,offset,true);central.set(name,46);
  chunks.push(header,data);directory.push(central);offset+=header.length+data.length;
 }
 const size=directory.reduce((sum,item)=>sum+item.length,0),end=new Uint8Array(22),ev=new DataView(end.buffer);ev.setUint32(0,0x06054b50,true);ev.setUint16(8,directory.length,true);ev.setUint16(10,directory.length,true);ev.setUint32(12,size,true);ev.setUint32(16,offset,true);
 const output=new Uint8Array(offset+size+end.length);let position=0;for(const part of [...chunks,...directory,end]){output.set(part,position);position+=part.length;}return output;
}
