import assert from 'node:assert/strict';
import {randomBytes} from 'node:crypto';
import {pool} from '../server/db.mjs';
import {handleAcademicResources} from '../server/academic-resources.mjs';

const suffix=randomBytes(5).toString('hex');
let course,branch,year,subject,otherSubject,book;
const user=(await pool.query('SELECT user_id FROM users LIMIT 1')).rows[0];
async function call(path,method='GET',data){
 let response;
 assert.equal(await handleAcademicResources({method},{},'/api/admin/academics/'+path,user,async()=>data,(_res,status,payload)=>{response={status,...payload};}),true);
 return response;
}
try{
 course=(await pool.query('INSERT INTO courses(course_name,course_code,course_alias,course_duration,created_by) VALUES($1,$1,$1,4,$2) RETURNING course_id',['LPLAN'+suffix,user.user_id])).rows[0].course_id;
 branch=(await pool.query("INSERT INTO academic_branches(course_id,branch_code,branch_name,branch_alias) VALUES($1,'TEST','TEST','TEST') RETURNING branch_id",[course])).rows[0].branch_id;
 const occupied=new Set((await pool.query('SELECT academic_year FROM academic_years')).rows.map(row=>row.academic_year));
 let start=2600,label;do{label=start+'-'+String((++start)%100).padStart(2,'0');}while(occupied.has(label));
 year=(await pool.query('INSERT INTO academic_years(academic_year,created_by) VALUES($1,$2) RETURNING academic_year_id',[label,user.user_id])).rows[0].academic_year_id;
 await pool.query('INSERT INTO academic_year_semesters VALUES($1,1),($1,2)',[year]);
 const createSubject=async code=>(await pool.query("INSERT INTO subjects(subject_name,subject_code,subject_alias,academic_year_id,branch_id,semester,created_by) VALUES('LESSON PLAN TEST',$1,'TEST',$2,$3,1,$4) RETURNING subject_id",[code,year,branch,user.user_id])).rows[0].subject_id;
 subject=await createSubject(suffix);otherSubject=await createSubject(suffix+'B');
 const path='lesson-plan/subjects/'+subject;
 assert.ok((await call('lesson-plan')).records.some(row=>row.subject_id===subject));
 let detail=await call(path);assert.equal(detail.subject.subject_id,subject);assert.deepEqual(detail.books,[]);assert.deepEqual(detail.topics,[]);
 assert.equal((await call('lesson-plan/subjects/999999999')).status,404);
 assert.equal((await call(path,'POST',{})).status,405);
 const topic={topics:'Explain arrays',co:'CO-1',book_id:999999999,pagenumber:12,ppt_req:'1',video_url:'https://example.com/lesson'};
 await assert.rejects(call(path,'PUT',{topics:[topic]}),error=>error.status===400&&/book name/.test(error.message));
 const mapping={academic_year_id:year,branch_id:branch,semester:1,subject_id:subject};
 const created=await call('preferred-books','POST',{...mapping,author:'Lesson Author',book_name:'Data Structures'});
 assert.equal(created.status,201);book=created.id;topic.book_id=book;
 detail=await call(path);assert.equal(detail.books[0].book_name,'DATA STRUCTURES');
 await call('course-outcome','POST',{...mapping,cotype:'CO-1',codescription:'Understand arrays'});
 assert.equal((await call(path)).outcomes[0].cotype,'CO-1');
 for(const invalid of [{...topic,topics:''},{...topic,co:'CO-6'},{...topic,co:[]},{...topic,co:['CO-1','CO-6']},{...topic,pagenumber:-1},{...topic,ppt_req:'maybe'},{...topic,video_url:'javascript:alert(1)'},{...topic,lessonplan_id:999999999}]){
  await assert.rejects(call(path,'PUT',{topics:[invalid]}),error=>error.status===400);
 }
 await assert.rejects(call('lesson-plan/subjects/'+otherSubject,'PUT',{topics:[topic]}),error=>error.status===400);
 assert.equal((await call(path,'PUT',{topics:[topic,{...topic,topics:'Explain linked lists',co:['CO-1','CO-3','CO-5'],ppt_req:'0',pagenumber:'',video_url:''}]})).status,200);
 detail=await call(path);assert.equal(detail.topics.length,2);const [first,second]=detail.topics;
 assert.equal(first.created_by,user.user_id);assert.equal(first.book_id,book);assert.equal(second.co,'CO-1, CO-3, CO-5');assert.equal(second.module,'2');assert.equal(second.pagenumber,'0');
 await assert.rejects(call(path,'PUT',{topics:[first,first]}),error=>error.status===400);
 await pool.query("UPDATE lessonplans SET ppt='https://example.com/slides' WHERE lessonplan_id=$1",[first.lessonplan_id]);
 assert.equal((await call(path,'PUT',{topics:[{...second,topics:'Updated topic'},first]})).status,200);
 detail=await call(path);assert.equal(detail.topics[0].lessonplan_id,second.lessonplan_id);assert.equal(detail.topics[0].topics,'Updated topic');assert.equal(detail.topics[0].updated_by,user.user_id);assert.equal(detail.topics[1].ppt,'https://example.com/slides');
 await assert.rejects(pool.query('DELETE FROM faculty_books WHERE book_id=$1',[book]),error=>error.code==='23503');
 await assert.rejects(pool.query('UPDATE faculty_books SET subject_id=$2 WHERE book_id=$1',[book,otherSubject]),error=>error.code==='23503');
 // Invalid updates roll back the whole batch.
 await assert.rejects(call(path,'PUT',{topics:[{...second,topics:'Must not persist'},{...first,book_id:999999999}]}),error=>error.status===400);
 assert.equal((await call(path)).topics[0].topics,'Updated topic');
 await call(path,'PUT',{topics:[first]});
 assert.equal((await call(path)).topics.length,1);
 assert.ok((await pool.query('SELECT deleted_at FROM lessonplans WHERE lessonplan_id=$1',[second.lessonplan_id])).rows[0].deleted_at);
 await call(path,'PUT',{topics:[]});assert.equal((await call(path)).topics.length,0);
 assert.equal((await call('lesson-plan')).records.find(row=>row.subject_id===subject).topic_count,0);
 console.log('PASS: Lesson Plan subject list/detail, no-book state, preferred-book names, COs, save/reorder/update, resource preservation, archive removal, validation, rollback and book-subject integrity.');
}finally{
 if(subject)await pool.query('DELETE FROM lessonplans WHERE subjectteacher_subject_id=$1',[subject]);
 if(subject)await pool.query('DELETE FROM courseoutcome WHERE co_subject_id=$1',[subject]);
 if(book)await pool.query('DELETE FROM faculty_books WHERE book_id=$1',[book]);
 if(otherSubject)await pool.query('DELETE FROM subjects WHERE subject_id=$1',[otherSubject]);
 if(subject)await pool.query('DELETE FROM subjects WHERE subject_id=$1',[subject]);
 if(year)await pool.query('DELETE FROM academic_years WHERE academic_year_id=$1',[year]);
 if(branch)await pool.query('DELETE FROM academic_branches WHERE branch_id=$1',[branch]);
 if(course)await pool.query('DELETE FROM courses WHERE course_id=$1',[course]);
 await pool.end();
}
