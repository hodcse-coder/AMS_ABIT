import assert from 'node:assert/strict';
import {randomBytes} from 'node:crypto';
import {pool} from '../server/db.mjs';
import {handleAcademicResources} from '../server/academic-resources.mjs';
const suffix=randomBytes(5).toString('hex');
const user=(await pool.query("SELECT u.user_id FROM users u JOIN user_roles r USING(role_id) WHERE r.role_name='Admin' LIMIT 1")).rows[0];
let course,batch,section,subject,teacher,assignment,topic,otherTopic;const students=[];
async function call(path,method='GET',input){let result;assert.equal(await handleAcademicResources({method},{},'/api/admin/academics/'+path,user,async()=>input,(_res,status,data)=>{result={status,...data};}),true);return result;}
async function account(role,name){return (await pool.query('INSERT INTO users(role_id,username,password_hash,full_name) SELECT role_id,$1,$2,$3 FROM user_roles WHERE role_name=$4 RETURNING user_id',[name+suffix,randomBytes(32).toString('hex'),name,role])).rows[0].user_id;}
try{
 course=(await pool.query('INSERT INTO courses(course_name,course_code,course_alias,course_duration,created_by) VALUES($1,$1,$1,4,$2) RETURNING course_id',['ATTEND'+suffix,user.user_id])).rows[0].course_id;
 batch=(await pool.query('INSERT INTO batches(batch_name,batch_alias,batch_course_id,created_by) VALUES($1,$1,$2,$3) RETURNING batch_id',['ATTEND'+suffix,course,user.user_id])).rows[0].batch_id;
 section=(await pool.query("INSERT INTO section(section_name,section_batch_id,created_by) VALUES('ATTENDANCE SECTION',$1,$2) RETURNING s_id",[batch,user.user_id])).rows[0].s_id;
 subject=(await pool.query("INSERT INTO subjects(subject_name,subject_code,subject_alias,subject_type,created_by) VALUES('ATTENDANCE SUBJECT',$1,'ATT','P',$2) RETURNING subject_id",[suffix,user.user_id])).rows[0].subject_id;
 teacher=await account('Faculty','ATTENDTEACHER');await pool.query('INSERT INTO faculty(user_id) VALUES($1)',[teacher]);
 assignment=(await call('lecture-notes/assignments','POST',{course_id:course,batch_id:batch,semester:5,section_type:'S',section_id:section,subject_id:subject,teacher_id:teacher,teacher_type:'M',student_group:'ALL'})).id;
 for(let index=0;index<3;index++){const student=await account('Student','ATTENDSTUDENT'+index);students.push(student);await pool.query('INSERT INTO students(user_id,admission_number,semester) VALUES($1,$2,$3)',[student,suffix+index,index===2?6:5]);await pool.query('INSERT INTO course_students(user_id,course_id,batch_id) VALUES($1,$2,$3)',[student,course,batch]);}
 topic=(await pool.query("INSERT INTO lessonplans(subjectteacher_id,subjectteacher_subject_id,module,topics,bookname,pagenumber,ppt_req,ppt,video_url,co,created_by) VALUES(0,$1,1,'Arrays','TEST',0,'0','','','CO-1',$2) RETURNING lessonplan_id",[subject,user.user_id])).rows[0].lessonplan_id;
 const root='take-attendance',detailPath=root+'/assignments/'+assignment;
 let detail=await call(detailPath);assert.equal(detail.eligible.length,2);assert.deepEqual(detail.roster,[]);assert.equal(detail.topics[0].lessonplan_id,topic);
 assert.ok((await call(root)).assignments.some(row=>row.shst_id===assignment));
 assert.equal((await call(root+'/assignments/999999999')).status,404);
 await assert.rejects(call(detailPath+'/roster','PUT',{students}),error=>error.status===400);
 await assert.rejects(call(detailPath+'/roster','PUT',{students:[students[0],students[0]]}),error=>error.status===400);
 assert.equal((await call(detailPath+'/roster','PUT',{students:students.slice(0,2)})).status,200);
 assert.equal((await call(detailPath)).roster.length,2);
 const input={assignment_id:assignment,topic_id:topic,date:'2026-10-22',start_time:'12:30',end_time:'13:30',students:students.slice(0,2).map((student_id,index)=>({student_id,present:index===0}))};
 for(const invalid of [{...input,end_time:'12:30'},{...input,date:'2026-02-30'},{...input,topic_id:999999999},{...input,students:[]},{...input,students:[input.students[0]]},{...input,students:[input.students[0],{student_id:students[2],present:true}]},{...input,students:[{student_id:students[0],present:'yes'},input.students[1]]}])await assert.rejects(call(root,'POST',invalid),error=>error.status===400);
 const saved=await call(root,'POST',input);assert.equal(saved.status,201);assert.equal(saved.count,2);
 const records=(await pool.query('SELECT * FROM student_attendance WHERE session_id=$1 ORDER BY student_attendance_student_id',[saved.id])).rows;
 assert.equal(records.length,2);assert.equal(records[0].student_attendance_present_absent,'1');assert.equal(records[1].student_attendance_present_absent,'0');
 for(const row of records){assert.equal(row.shst_subject_id,subject);assert.equal(row.shst_teacher_user_id,teacher);assert.equal(row.shst_batch_id,batch);assert.equal(row.shst_subject_type,'P');assert.equal(row.created_by,user.user_id);}
 await assert.rejects(call(root,'POST',input),error=>error.status===400);
 await assert.rejects(call(root,'POST',{...input,start_time:'13:00',end_time:'14:00'}),error=>error.status===400);
 assert.equal((await pool.query('SELECT COUNT(*)::int AS count FROM attendance_sessions WHERE assignment_id=$1',[assignment])).rows[0].count,1);
 assert.equal((await call(root,'POST',{...input,start_time:'13:30',end_time:'14:30'})).status,201);
 const report=await call('student-attendance');const summary=report.records.find(row=>row.session_id===saved.id);assert.equal(summary.strength,2);assert.equal(summary.present,1);assert.equal(summary.absent,1);assert.equal(summary.subject_type,'P');assert.equal(summary.topic_covered,'Arrays');assert.equal(summary.section_name,'ATTENDANCE SECTION');
 assert.equal((await call(root,'PATCH')).status,405);
 console.log('PASS: Attendance assignments, topics, explicit eligible roster, present/absent persistence, derived class/faculty details, validation, overlap protection, adjacent sessions and student attendance reporting.');
}finally{
 if(assignment){await pool.query('DELETE FROM student_attendance WHERE session_id IN(SELECT session_id FROM attendance_sessions WHERE assignment_id=$1)',[assignment]);await pool.query('DELETE FROM attendance_sessions WHERE assignment_id=$1',[assignment]);await pool.query('DELETE FROM attendance_roster WHERE assignment_id=$1',[assignment]);await pool.query('DELETE FROM section_house_subject_teacher WHERE shst_id=$1',[assignment]);}
 for(const student of students){await pool.query('DELETE FROM course_students WHERE user_id=$1',[student]);await pool.query('DELETE FROM users WHERE user_id=$1',[student]);}
 if(topic)await pool.query('DELETE FROM lessonplans WHERE lessonplan_id=$1',[topic]);
 if(teacher)await pool.query('DELETE FROM users WHERE user_id=$1',[teacher]);
 if(subject)await pool.query('DELETE FROM subjects WHERE subject_id=$1',[subject]);
 if(section)await pool.query('DELETE FROM section WHERE s_id=$1',[section]);
 if(batch)await pool.query('DELETE FROM batches WHERE batch_id=$1',[batch]);
 if(course)await pool.query('DELETE FROM courses WHERE course_id=$1',[course]);
 await pool.end();
}
