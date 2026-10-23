import assert from 'node:assert/strict';
import {randomBytes} from 'node:crypto';
import {pool} from '../server/db.mjs';
import {handleAcademicResources} from '../server/academic-resources.mjs';
const base='/api/admin/academics/video-lecture';
const user=(await pool.query("SELECT u.user_id FROM users u JOIN user_roles r USING(role_id) WHERE r.role_name='Admin' LIMIT 1")).rows[0];
let subject;
async function call(method,data,path=''){
 let result;assert.equal(await handleAcademicResources({method},{},base+path,user,async()=>data,(_res,status,payload)=>{result={status,...payload};}),true);return result;
}
async function media(id,range){
 let result={};const res={writeHead(status,headers){result={status,headers};},end(bytes){result.bytes=bytes;}};
 await handleAcademicResources({method:'GET',headers:range?{range}:{}},res,base+'/'+id+'/media',user,null,(_res,status,payload)=>{result={status,...payload};});return result;
}
try{
 const suffix=randomBytes(5).toString('hex');
 subject=(await pool.query("INSERT INTO subjects(subject_name,subject_code,subject_alias,created_by) VALUES('VIDEO TEST',$1,'TEST',$2) RETURNING subject_id",[suffix,user.user_id])).rows[0].subject_id;
 const input={related_subject:subject,brief_description:'Array lecture',video_url:'https://example.com/lecture'};
 for(const invalid of [{...input,related_subject:999999999},{...input,brief_description:''},{...input,video_url:'javascript:alert(1)'},{...input,video_url:'https://user:password@example.com/video'},{...input,video_url:''}])await assert.rejects(call('POST',invalid),error=>error.status===400);
 const linked=await call('POST',input);assert.equal(linked.status,201);
 let row=(await call('GET')).records.find(row=>row.l_id===linked.id);assert.equal(row.video_url,input.video_url);assert.equal(row.uploaded,false);assert.equal(row.created_by,user.user_id);assert.equal(row.subject_name,'VIDEO TEST');
 assert.equal((await media(linked.id)).status,404);
 const bytes=Buffer.concat([Buffer.from('000000186674797069736f6d','hex'),Buffer.alloc(30)]);
 const upload={related_subject:subject,brief_description:'Uploaded lecture',file_name:'arrays.mp4',file_base64:bytes.toString('base64')};
 for(const invalid of [{...upload,video_url:input.video_url},{...upload,file_name:'../video.mp4'},{...upload,file_name:'video.html'},{...upload,file_base64:Buffer.from('not a video').toString('base64')},{...upload,file_base64:'A'.repeat(34952540)}])await assert.rejects(call('POST',invalid),error=>error.status===400);
 const created=await call('POST',upload);assert.equal(created.status,201);
 row=(await call('GET')).records.find(row=>row.l_id===created.id);assert.equal(row.uploaded,true);assert.equal(row.file_type,'video/mp4');assert.equal(row.file_size,String(bytes.length));assert.equal(Object.hasOwn(row,'file_data'),false);
 const full=await media(created.id);assert.equal(full.status,200);assert.deepEqual(full.bytes,bytes);assert.equal(full.headers['Accept-Ranges'],'bytes');assert.equal(full.headers['X-Content-Type-Options'],'nosniff');
 const range=await media(created.id,'bytes=4-7');assert.equal(range.status,206);assert.equal(range.bytes.toString(),'ftyp');assert.equal(range.headers['Content-Range'],`bytes 4-7/${bytes.length}`);
 assert.deepEqual((await media(created.id,'bytes=-4')).bytes,bytes.subarray(bytes.length-4));
 assert.deepEqual((await media(created.id,'bytes=8-')).bytes,bytes.subarray(8));
 for(const invalid of ['bytes=999-','bytes=8-4','bytes=-0','bytes=','bytes=0-1,4-7'])assert.equal((await media(created.id,invalid)).status,416);
 for(const [file_name,signature] of [['arrays.webm','1a45dfa3'],['arrays.ogv','4f676753']]){
  const result=await call('POST',{...upload,file_name,file_base64:Buffer.from(signature,'hex').toString('base64')});assert.equal(result.status,201);
 }
 assert.equal((await call('DELETE',null,'/'+created.id)).status,200);assert.equal((await call('DELETE',null,'/'+created.id)).status,404);assert.equal((await media(created.id)).status,404);
 assert.equal((await call('PUT')).status,405);
 console.log('PASS: Video Lecture URL/file creation, subject and uploader mapping, source/file validation, 25 MB limit, list metadata, authenticated media handler, full/range playback, deletion and unsupported methods.');
}finally{if(subject){await pool.query('DELETE FROM videolecture WHERE related_subject=$1',[subject]);await pool.query('DELETE FROM subjects WHERE subject_id=$1',[subject]);}await pool.end();}
