import assert from 'node:assert/strict';
import {randomBytes} from 'node:crypto';
import {pool} from '../server/db.mjs';
import {handleAcademicResources} from '../server/academic-resources.mjs';

const suffix=randomBytes(5).toString('hex');
const admin=(await pool.query("SELECT u.user_id FROM users u JOIN user_roles r USING(role_id) WHERE r.role_name='Admin' LIMIT 1")).rows[0];
let course,batch,section,subject,teacher,house;
const assignments=[];
async function call(path='',method='GET',data){
 let response;
 assert.equal(await handleAcademicResources({method},{},'/api/admin/academics/lecture-notes'+path,admin,async()=>data,(_res,status,payload)=>{response={status,...payload};}),true);
 return response;
}
async function report(method='GET'){
 let result;
 assert.equal(await handleAcademicResources({method},{},'/api/admin/academics/note-upload-report',admin,null,(_res,status,data)=>{result={status,...data};}),true);
 return result;
}
try{
 course=(await pool.query('INSERT INTO courses(course_name,course_code,course_alias,course_duration,created_by) VALUES($1,$1,$1,4,$2) RETURNING course_id',['NOTESTEST'+suffix,admin.user_id])).rows[0].course_id;
 batch=(await pool.query('INSERT INTO batches(batch_name,batch_alias,batch_course_id,created_by) VALUES($1,$1,$2,$3) RETURNING batch_id',['NOTES'+suffix,course,admin.user_id])).rows[0].batch_id;
 section=(await pool.query("INSERT INTO section(section_name,section_batch_id,created_by) VALUES('CSE',$1,$2) RETURNING s_id",[batch,admin.user_id])).rows[0].s_id;
 house=(await pool.query('INSERT INTO section_master(section_master_name,created_by) VALUES($1,$2) RETURNING section_master_id',['HOUSE'+suffix,admin.user_id])).rows[0].section_master_id;
 subject=(await pool.query("INSERT INTO subjects(subject_name,subject_code,subject_alias,created_by) VALUES('ARTIFICIAL INTELLIGENCE',$1,'AI',$2) RETURNING subject_id",[suffix,admin.user_id])).rows[0].subject_id;
 teacher=(await pool.query("INSERT INTO users(role_id,username,password_hash,full_name) SELECT role_id,$1,$2,'LECTURE TEST FACULTY' FROM user_roles WHERE role_name='Faculty' RETURNING user_id",['notes'+suffix,randomBytes(32).toString('hex')])).rows[0].user_id;
 await pool.query('INSERT INTO faculty(user_id) VALUES($1)',[teacher]);
 const options=await call('/options');assert.ok(options.faculty.some(row=>row.user_id===teacher));assert.ok(options.sections.some(row=>row.s_id===section));
 const mapping={course_id:course,batch_id:batch,semester:5,section_type:'S',section_id:section,subject_id:subject,teacher_id:teacher,teacher_type:'M',student_group:'ALL'};
 let created=await call('/assignments','POST',mapping);assert.equal(created.status,201);assignments.push(created.id);
 await assert.rejects(call('/assignments','POST',mapping),error=>error.status===400);
 for(const invalid of [{...mapping,teacher_id:admin.user_id},{...mapping,batch_id:999999999},{...mapping,section_id:999999999},{...mapping,semester:13},{...mapping,student_group:'TOOLONG'}])await assert.rejects(call('/assignments','POST',invalid),error=>error.status===400);
 created=await call('/assignments','POST',{...mapping,section_type:'H',section_id:house});assert.equal(created.status,201);assignments.push(created.id);
 let rows=(await call()).records;
 assert.equal(rows.find(row=>row.shst_id===assignments[0]).batch_name,'NOTES'+suffix.toUpperCase());
 assert.equal(rows.find(row=>row.shst_id===assignments[0]).section_name,'CSE');
 assert.equal(rows.find(row=>row.shst_id===assignments[1]).section_name,'HOUSE'+suffix.toUpperCase());
 assert.deepEqual(rows.find(row=>row.shst_id===assignments[0]).notes,[]);
 const bytes=Buffer.from('%PDF-1.7\nLecture notes fixture\n%%EOF');
 const upload={description:'AI',file_name:'AI notes.pdf',file_base64:bytes.toString('base64'),teacher:admin.user_id,subject:999999999,sem:1};
 for(const invalid of [{...upload,description:''},{...upload,file_name:'../note.pdf'},{...upload,file_name:'file.html'},{...upload,file_base64:'invalid'},{...upload,file_base64:Buffer.from('<html>bad</html>').toString('base64')},{...upload,file_base64:Buffer.alloc(10485761).toString('base64')}])await assert.rejects(call('/assignments/'+assignments[0],'POST',invalid),error=>error.status===400);
 assert.equal((await call('/assignments/999999999','POST',upload)).status,404);
 const note=await call('/assignments/'+assignments[0],'POST',upload);assert.equal(note.status,201);
 rows=(await call()).records;const noteRow=rows.find(row=>row.shst_id===assignments[0]).notes[0];
 assert.equal(noteRow.description,'AI');assert.equal(noteRow.downloadable,true);assert.equal(noteRow.teacher,teacher);assert.equal(noteRow.subject,subject);assert.equal(noteRow.sem,'5');
 assert.equal(rows.find(row=>row.shst_id===assignments[1]).notes.length,0);
 assert.equal(Object.hasOwn(noteRow,'file_data'),false);
 const reportRow=(await report()).records.find(row=>row.id===note.id);
 assert.equal(reportRow.faculty_name,'LECTURE TEST FACULTY');
 assert.equal(reportRow.subject_name,'ARTIFICIAL INTELLIGENCE');
 assert.equal(reportRow.sem,'5');assert.equal(reportRow.description,'AI');
 assert.equal(reportRow.file_name,'AI notes.pdf');assert.equal(reportRow.file_status,'Available');
 assert.equal(reportRow.downloadable,true);assert.equal(Object.hasOwn(reportRow,'file_data'),false);
 assert.equal((await report('POST')).status,405);
 assert.equal((await pool.query('SELECT created_by FROM lecture_notes WHERE id=$1',[note.id])).rows[0].created_by,admin.user_id);
 let headers,download;
 await handleAcademicResources({method:'GET'},{writeHead(status,value){assert.equal(status,200);headers=value;},end(value){download=value;}},'/api/admin/academics/lecture-notes/'+note.id+'/download',admin,null,()=>assert.fail('Expected a binary download.'));
 assert.deepEqual(download,bytes);assert.equal(headers['X-Content-Type-Options'],'nosniff');assert.match(headers['Content-Disposition'],/^attachment;/);
 assert.equal((await call('/999999999/download')).status,404);
 const legacy=(await pool.query("INSERT INTO lecture_notes(teacher,subject,sem,description,attachment,created_by) VALUES($1,$2,5,'Legacy','old.pdf',$3) RETURNING id",[teacher,subject,admin.user_id])).rows[0];
 assert.equal((await call('/'+legacy.id+'/download')).status,404);
 const missing=(await report()).records.find(row=>row.id===legacy.id);
 assert.equal(missing.file_status,'File Missing');assert.equal(missing.downloadable,false);assert.equal(missing.file_name,'old.pdf');
 await pool.query('UPDATE lecture_notes SET attachment=$2 WHERE id=$1',[legacy.id,'archive/notes/old.pdf']);
 assert.equal((await report()).records.find(row=>row.id===legacy.id).file_name,'old.pdf');
 assert.equal((await call()).records.find(row=>row.shst_id===assignments[0]).notes.find(row=>row.id===legacy.id).downloadable,false);
 await assert.rejects(pool.query('DELETE FROM section_house_subject_teacher WHERE shst_id=$1',[assignments[0]]),error=>error.code==='23503');
 assert.equal((await call('','POST',{})).status,405);
 console.log('PASS: Lecture Notes assignments, upload validation, binary download, legacy files and foreign keys; Upload Report joins, automatic availability, missing status, filenames and read-only API.');
}finally{
 if(subject)await pool.query('DELETE FROM lecture_notes WHERE subject=$1',[subject]);
 if(assignments.length)await pool.query('DELETE FROM section_house_subject_teacher WHERE shst_id=ANY($1::bigint[])',[assignments]);
 if(teacher)await pool.query('DELETE FROM users WHERE user_id=$1',[teacher]);
 if(subject)await pool.query('DELETE FROM subjects WHERE subject_id=$1',[subject]);
 if(section)await pool.query('DELETE FROM section WHERE s_id=$1',[section]);
 if(house)await pool.query('DELETE FROM section_master WHERE section_master_id=$1',[house]);
 if(batch)await pool.query('DELETE FROM batches WHERE batch_id=$1',[batch]);
 if(course)await pool.query('DELETE FROM courses WHERE course_id=$1',[course]);
 await pool.end();
}
