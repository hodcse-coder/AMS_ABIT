import {handleTimetable} from '../server/timetable.mjs';
import {courseSemesterOptions} from '../shared/course-semesters.mjs';
import assert from 'node:assert/strict';
import {randomBytes} from 'node:crypto';
import {pool} from '../server/db.mjs';
import {handleSubjectConfiguration} from '../server/subject-configuration.mjs';
import {handleAcademicResources} from '../server/academic-resources.mjs';
import {attendanceWorkbook} from '../shared/attendance-export.mjs';
const suffix=randomBytes(5).toString('hex');
const user=(await pool.query("SELECT u.user_id,r.role_name FROM users u JOIN user_roles r USING(role_id) WHERE r.role_name='Admin' LIMIT 1")).rows[0];
let plan,second,room,viewer;let course,batch,section,branch,subject,teacher,semester,eligibility,permanent,temporary,year;
async function call(path,method='GET',input){let result;assert.equal(await handleSubjectConfiguration({method},{},'/api/admin/subject-configuration/'+path,user,async()=>input,(_res,status,data)=>{result={status,...data};}),true);return result;}
async function academic(path){let result;assert.equal(await handleAcademicResources({method:'GET'},{},'/api/admin/academics/'+path,user,null,(_res,status,data)=>{result={status,...data};}),true);return result;}
try{
 assert.deepEqual(courseSemesterOptions(2),[[1,'1ST'],[2,'2ND'],[3,'3RD'],[4,'4TH']]);assert.equal(courseSemesterOptions(4).length,8);assert.equal(courseSemesterOptions(4)[7][1],'8TH');assert.deepEqual(courseSemesterOptions(undefined),[]);
 course=(await pool.query('INSERT INTO courses(course_name,course_code,course_alias,course_duration,created_by) VALUES($1,$1,$1,4,$2) RETURNING course_id',['SC'+suffix,user.user_id])).rows[0].course_id;
 batch=(await pool.query('INSERT INTO batches(batch_name,batch_alias,batch_course_id,created_by) VALUES($1,$1,$2,$3) RETURNING batch_id',['SC'+suffix,course,user.user_id])).rows[0].batch_id;
 section=(await pool.query("INSERT INTO section(section_name,section_batch_id,created_by) VALUES('SC SECTION',$1,$2) RETURNING s_id",[batch,user.user_id])).rows[0].s_id;
 branch=(await pool.query("INSERT INTO academic_branches(course_id,branch_code,branch_name,branch_alias) VALUES($1,'SC','SC BRANCH','SC') RETURNING branch_id",[course])).rows[0].branch_id;
 const occupied=new Set((await pool.query('SELECT academic_year FROM academic_years')).rows.map(row=>row.academic_year));let yearStart=2700,yearLabel;do{yearLabel=yearStart+'-'+String((++yearStart)%100).padStart(2,'0');}while(occupied.has(yearLabel));
 year=(await pool.query('INSERT INTO academic_years(academic_year,created_by) VALUES($1,$2) RETURNING academic_year_id',[yearLabel,user.user_id])).rows[0].academic_year_id;await pool.query('INSERT INTO academic_year_semesters VALUES($1,1),($1,2)',[year]);
 subject=(await pool.query("INSERT INTO subjects(subject_name,subject_code,subject_alias,branch_id,created_by,academic_year_id,semester) VALUES('SC SUBJECT',$1,'SC',$2,$3,$4,1) RETURNING subject_id",[suffix,branch,user.user_id,year])).rows[0].subject_id;
 teacher=(await pool.query("INSERT INTO users(role_id,username,password_hash,full_name) SELECT role_id,$1,$2,'SC FACULTY' FROM user_roles WHERE role_name='Faculty' RETURNING user_id",['sc'+suffix,randomBytes(32).toString('hex')])).rows[0].user_id;
 await pool.query('INSERT INTO faculty(user_id) VALUES($1)',[teacher]);

 async function tt(path,method='GET',input,actor=user){let result;const url=path.startsWith('/api/')?path:'/api/admin/timetable/'+path;assert.equal(await handleTimetable({method,url},{},url.split('?')[0],actor,async()=>input,(_res,status,data)=>{result={status,...data};}),true);return result;}
 semester=(await call('semesters','POST',{course_id:course,batch_id:batch,semester:1,class_type:'S',is_active:1,consider_for_accounts:1})).id;
 eligibility=(await call('teachers','POST',{academic_year_id:year,branch_id:branch,semester:1,subject_id:subject,teacher_id:teacher,lessonplan_required:1,study_note_required:1,library_submitted:false})).id;
 permanent=(await call('allotments','POST',{semester_definition_id:semester,section_id:section,subjectteacher_id:eligibility,student_group:'ALL',teacher_type:'M'})).id;
 const classroom={room_no:'TT'+suffix,building:'Test Building',floor_name:'1',capacity:60,room_type:'CLASSROOM',manager_id:teacher,is_active:true};
 room=(await tt('rooms','POST',classroom)).id;assert.ok(room);
 const draft={batch_semester_id:semester,section_id:section,timetable_name:'TT'+suffix,effective_from:'2098-01-01',effective_to:'2098-12-31',is_published:false};
 plan=(await tt('schedules','POST',draft)).id;assert.ok(plan);
 await assert.rejects(tt('schedules/'+plan,'PATCH',{...draft,is_published:true}),e=>e.status===400);
 const cell={day_of_week:1,period_number:1,start_time:'09:00',end_time:'10:00',allotment_id:permanent,room_id:room,notes:'Test topic'};
 await assert.rejects(tt('schedules/'+plan+'/cells','PUT',{cells:[cell,{...cell,period_number:2,start_time:'09:30'}]}),e=>e.status===400);
 assert.equal((await tt('schedules/'+plan+'/cells','PUT',{cells:[cell]})).status,200);
 assert.equal((await tt('schedules/'+plan)).cells.length,1);
 assert.equal((await tt('view?date=2098-01-01')).periods.some(r=>r.timetable_id===plan),false);
 assert.equal((await tt('schedules/'+plan,'PATCH',{...draft,is_published:true})).status,200);
 const facultyActor={user_id:teacher,role_name:'Faculty'};
 assert.equal((await tt('options','GET',null,facultyActor)).status,403);
 assert.ok((await tt('/api/timetable/mine?date=2098-01-01','GET',null,facultyActor)).periods.some(r=>r.timetable_id===plan));
 assert.ok((await tt('/api/timetable/floor?date=2098-01-01','GET',null,facultyActor)).rooms.some(r=>r.room_id===room));
 assert.equal((await tt('/api/timetable/mine?date=2097-01-01','GET',null,facultyActor)).periods.some(r=>r.timetable_id===plan),false);
 await assert.rejects(tt('rooms/'+room,'PATCH',{...classroom,is_active:false}),e=>e.status===400);
 await assert.rejects(tt('rooms/'+room,'DELETE'),e=>e.code==='23503');
 second=(await tt('schedules','POST',{...draft,timetable_name:'Conflict'})).id;
 await tt('schedules/'+second+'/cells','PUT',{cells:[cell]});
 await assert.rejects(tt('schedules/'+second,'PATCH',{...draft,is_published:true}),e=>e.status===400&&e.message.includes('clashes'));
 assert.equal((await tt('schedules/'+second)).schedule.is_published,false);
 await assert.rejects(call('allotments/'+permanent,'PATCH',{}),e=>e.status===400);
 viewer=(await pool.query("INSERT INTO users(role_id,username,password_hash,full_name) SELECT role_id,$1,'unused','TT VIEWER' FROM user_roles WHERE role_name='Employee' RETURNING user_id",['tt'+suffix])).rows[0].user_id;
 const employee={user_id:viewer,role_name:'Employee'};
 assert.equal((await tt('/api/timetable/mine?date=2098-01-01','GET',null,employee)).periods.length,0);
 const grant=await tt('access','POST',{type:'course',user_id:viewer,batch_semester_id:semester,section_id:section});
 assert.ok((await tt('/api/timetable/mine?date=2098-01-01','GET',null,employee)).periods.some(r=>r.timetable_id===plan));
 await tt('access/course/'+grant.id,'DELETE');
 assert.equal((await tt('/api/timetable/mine?date=2098-01-01','GET',null,employee)).periods.length,0);
 const facultyGrant=await tt('access','POST',{type:'faculty',user_id:viewer,employee_id:teacher});
 assert.ok((await tt('/api/timetable/mine?date=2098-01-01','GET',null,employee)).periods.some(r=>r.timetable_id===plan));
 await tt('access/faculty/'+facultyGrant.id,'DELETE');
 assert.ok((await tt('options')).allotments.some(r=>r.shst_id===permanent));
 assert.ok((await tt('view?date=2098-01-01')).faculty.some(r=>r.user_id===teacher));
 console.log('PASS: Timetable rooms, draft/period CRUD, publication, overlap/clash rejection, effective dates, faculty/floor views, authorization and viewer grants/revocation.');
 }finally{
 if(plan)await pool.query('DELETE FROM timetable_schedules WHERE timetable_id=ANY($1::bigint[])',[[plan,second].filter(Boolean)]);
 if(room)await pool.query('DELETE FROM timetable_rooms WHERE room_id=$1',[room]);
 if(viewer){await pool.query('DELETE FROM timetable_course_access WHERE user_id=$1',[viewer]);await pool.query('DELETE FROM timetable_faculty_access WHERE user_id=$1',[viewer]);await pool.query('DELETE FROM users WHERE user_id=$1',[viewer]);}

 if(subject)await pool.query('DELETE FROM lecture_notes WHERE subject=$1',[subject]);
 if(subject)await pool.query('DELETE FROM section_house_subject_teacher WHERE shst_subject_id=$1',[subject]);
 if(eligibility)await pool.query('DELETE FROM subjectteacher WHERE subjectteacher_id=$1',[eligibility]);
 if(semester)await pool.query('DELETE FROM semester_defined WHERE id=$1',[semester]);
 if(teacher)await pool.query('DELETE FROM users WHERE user_id=$1',[teacher]);
 if(subject)await pool.query('DELETE FROM subjects WHERE subject_id=$1',[subject]);
 if(year)await pool.query('DELETE FROM academic_years WHERE academic_year_id=$1',[year]);
 if(section)await pool.query('DELETE FROM section WHERE s_id=$1',[section]);
 if(branch)await pool.query('DELETE FROM academic_branches WHERE branch_id=$1',[branch]);
 if(batch)await pool.query('DELETE FROM batches WHERE batch_id=$1',[batch]);
 if(course)await pool.query('DELETE FROM courses WHERE course_id=$1',[course]);
 await pool.end();
}
