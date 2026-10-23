import assert from 'node:assert/strict';
import {randomBytes} from 'node:crypto';
import {pool} from '../server/db.mjs';
import {handleBranches} from '../server/branches.mjs';
const suffix=randomBytes(6).toString('hex');let courseId;
async function call(method,data,id=''){let result;assert.equal(await handleBranches({method},{},'/api/admin/course-modules/branches'+(id?'/'+id:''),{},async()=>data,(_res,status,payload)=>{result={status,...payload};}),true);return result;}
try{
 const user=(await pool.query('SELECT user_id FROM users LIMIT 1')).rows[0];assert.ok(user);
 courseId=(await pool.query('INSERT INTO courses(course_name,course_code,course_alias,course_duration,created_by) VALUES($1,$1,$1,4,$2) RETURNING course_id',['BRANCH_TEST_'+suffix,user.user_id])).rows[0].course_id;
 const input={course_id:courseId,branch_code:'cse',branch_alias:'cs',branch_name:'Computer science',is_active:true};
 const created=await call('POST',input);assert.equal(created.status,201);
 let row=(await call('GET')).branches.find(row=>row.branch_id===created.id);assert.equal(row.branch_code,'CSE');assert.equal(row.branch_name,'COMPUTER SCIENCE');assert.equal(row.branch_alias,'CS');
 await assert.rejects(call('POST',input),error=>error.code==='23505');
 await assert.rejects(call('POST',{...input,course_id:0}),error=>error.status===400);
 await assert.rejects(call('POST',{...input,is_active:'false'}),error=>error.status===400);
 assert.equal((await call('PATCH',{...input,branch_alias:'comp',is_active:false},created.id)).status,200);
 row=(await call('GET')).branches.find(row=>row.branch_id===created.id);assert.equal(row.is_active,false);assert.equal(row.branch_alias,'COMP');
 await assert.rejects(pool.query('DELETE FROM courses WHERE course_id=$1',[courseId]),error=>error.code==='23503');
 assert.equal((await call('PATCH',input,'9223372036854775807')).status,404);
 console.log('PASS: branch create/list/edit, uppercase saving, duplicate protection, validation, inactive status and course foreign key.');
}finally{if(courseId){await pool.query('DELETE FROM academic_branches WHERE course_id=$1',[courseId]);await pool.query('DELETE FROM courses WHERE course_id=$1',[courseId]);}await pool.end();}
