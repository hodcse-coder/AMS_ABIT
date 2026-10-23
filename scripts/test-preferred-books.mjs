import assert from 'node:assert/strict';import {randomBytes} from 'node:crypto';import {pool} from '../server/db.mjs';import {handlePreferredBooks} from '../server/preferred-books.mjs';
const suffix=randomBytes(5).toString('hex');let course,branch,year,subject,book;const user=(await pool.query('SELECT user_id FROM users LIMIT 1')).rows[0];
async function call(method,data,id=''){let result;assert.equal(await handlePreferredBooks({method},{},'/api/admin/academics/preferred-books'+(id?'/'+id:''),user,async()=>data,(_r,status,payload)=>result={status,...payload}),true);return result;}
try{
 course=(await pool.query('INSERT INTO courses(course_name,course_code,course_alias,course_duration,created_by) VALUES($1,$1,$1,4,$2) RETURNING course_id',['BOOKTEST'+suffix,user.user_id])).rows[0].course_id;
 branch=(await pool.query("INSERT INTO academic_branches(course_id,branch_code,branch_name,branch_alias) VALUES($1,'TEST','TEST','TEST') RETURNING branch_id",[course])).rows[0].branch_id;
 const occupied=new Set((await pool.query('SELECT academic_year FROM academic_years')).rows.map(r=>r.academic_year));let start=2500,label;do{label=start+'-'+String((++start)%100).padStart(2,'0');}while(occupied.has(label));
 year=(await pool.query('INSERT INTO academic_years(academic_year,created_by) VALUES($1,$2) RETURNING academic_year_id',[label,user.user_id])).rows[0].academic_year_id;await pool.query('INSERT INTO academic_year_semesters VALUES($1,1),($1,2)',[year]);
 subject=(await pool.query("INSERT INTO subjects(subject_name,subject_code,subject_alias,academic_year_id,branch_id,semester,created_by) VALUES('BOOK TEST',$1,'TEST',$2,$3,1,$4) RETURNING subject_id",[suffix,year,branch,user.user_id])).rows[0].subject_id;
 const input={academic_year_id:year,branch_id:branch,semester:1,subject_id:subject,author:'Test author'};
 const created=await call('POST',input);assert.equal(created.status,201);book=created.id;let row=(await call('GET')).records.find(r=>r.book_id===book);assert.equal(row.author,'TEST AUTHOR');assert.equal(row.branch_id,branch);assert.equal(row.faculty_id,user.user_id);
 await assert.rejects(call('POST',{...input,semester:2}),e=>e.status===400);await assert.rejects(call('POST',{...input,author:''}),e=>e.status===400);
 assert.equal((await call('PATCH',{...input,author:'Updated author'},book)).status,200);row=(await call('GET')).records.find(r=>r.book_id===book);assert.equal(row.author,'UPDATED AUTHOR');assert.equal(row.updated_by,user.user_id);
 await assert.rejects(pool.query('DELETE FROM subjects WHERE subject_id=$1',[subject]),e=>e.code==='23503');
 assert.equal((await call('DELETE',null,book)).status,200);assert.equal((await call('DELETE',null,book)).status,404);
 console.log('PASS: Preferred Books create/list/edit/delete, subject mapping validation, uppercase author, creator tracking, and subject foreign key.');
}finally{if(book)await pool.query('DELETE FROM faculty_books WHERE book_id=$1',[book]);if(subject)await pool.query('DELETE FROM subjects WHERE subject_id=$1',[subject]);if(year)await pool.query('DELETE FROM academic_years WHERE academic_year_id=$1',[year]);if(branch)await pool.query('DELETE FROM academic_branches WHERE branch_id=$1',[branch]);if(course)await pool.query('DELETE FROM courses WHERE course_id=$1',[course]);await pool.end();}
