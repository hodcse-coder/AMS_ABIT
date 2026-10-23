import assert from 'node:assert/strict';
import {pool} from '../server/db.mjs';
import {academicResources} from '../shared/academic-resources.mjs';
import {handleAcademicResources} from '../server/academic-resources.mjs';
let inserted,subject;
async function request(key,method='GET'){let result;assert.equal(await handleAcademicResources({method},{},'/api/admin/academics/'+key,{},null,(_res,status,data)=>{result={status,...data};}),true);return result;}
try{
 for(const item of academicResources){const response=await request(item.key);assert.equal(response.status,200);assert.ok(Array.isArray(response.records));const columns=(await pool.query('SELECT column_name FROM information_schema.columns WHERE table_schema=\'public\' AND table_name=$1',[item.table])).rows.map(row=>row.column_name);assert.ok(columns.includes(item.id));}
 subject=(await pool.query("INSERT INTO subjects(subject_name,subject_code,subject_alias) VALUES('RESOURCE TEST','RESOURCE-'||gen_random_uuid()::text,'TEST') RETURNING subject_id")).rows[0].subject_id;
 inserted=(await pool.query("INSERT INTO videolecture(related_subject,brief_description,video_url,created_by) VALUES($1,'ACADEMICS CONNECTION TEST','https://example.com/test',0) RETURNING l_id",[subject])).rows[0].l_id;
 const records=(await request('video-lecture')).records;assert.equal(records.find(row=>row.l_id===inserted).brief_description,'ACADEMICS CONNECTION TEST');
 assert.equal((await request('unknown')).status,404);assert.equal((await request('video-lecture','PUT')).status,405);
 console.log('PASS: all eight Academics pages query their source tables, saved records are returned, and unknown modules/methods are rejected.');
}finally{if(inserted)await pool.query('DELETE FROM videolecture WHERE l_id=$1',[inserted]);if(subject)await pool.query('DELETE FROM subjects WHERE subject_id=$1',[subject]);await pool.end();}
