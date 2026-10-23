import assert from 'node:assert/strict';
import {randomBytes} from 'node:crypto';
import {pool} from '../server/db.mjs';
import {handleEmployees} from '../server/employees.mjs';
import {handleStudents} from '../server/students.mjs';
import {handleMentoring} from '../server/mentoring.mjs';
const suffix=randomBytes(5).toString('hex');
const admin=(await pool.query("SELECT u.user_id,r.role_name FROM users u JOIN user_roles r USING(role_id) WHERE r.role_name='Admin' LIMIT 1")).rows[0];
const employees=[],accounts=[],infos=[],sessions=[];let department,employeeCategory,studentCategory,course,batch,section,student,studentInfo,studentUser,reviewerAllotment;
async function invoke(handler,path,method='GET',input,actor=admin){let result;assert.equal(await handler({method,url:path},{},path.split('?')[0],actor,async()=>input,(_r,status,data)=>{result={status,...data};}),true);return result;}
const employee=(path='',method='GET',input)=>invoke(handleEmployees,'/api/admin/employees'+path,method,input);
const students=(path='',method='GET',input)=>invoke(handleStudents,'/api/admin/students'+path,method,input);
const call=(path,method='GET',input,actor=admin)=>invoke(handleMentoring,'/api/mentoring/'+path,method,input,actor);
try{
 department=(await employee('/masters/department','POST',{name:'MENTOR '+suffix,alias:suffix.slice(0,10)})).id;
 employeeCategory=(await employee('/masters/category','POST',{name:'MENTOR '+suffix,alias:suffix.slice(0,10),is_teaching:true})).id;
 let next=Number((await employee('/options')).next_employee_id);
 for(const name of ['Mentor','First','Second','Chief','Unrelated']){
  const created=await employee('','POST',{employee_id:next++,first_name:name,last_name:'Test',dob:'1980-01-01',joining_date:'2020-01-01',department_id:department,category_id:employeeCategory,email:name.toLowerCase()+suffix+'@example.com',experience_year:1,experience_month:0});
  employees.push(created.id);const row=(await employee()).records.find(row=>row.emp_master_id===created.id);accounts.push({user_id:row.emp_master_user_id,role_name:'Faculty'});infos.push(row.emp_master_emp_info_id);
 }
 course=(await pool.query('INSERT INTO courses(course_name,course_code,course_alias,course_duration,created_by) VALUES($1,$1,$1,4,$2) RETURNING course_id',['MENTOR'+suffix,admin.user_id])).rows[0].course_id;
 batch=(await pool.query('INSERT INTO batches(batch_name,batch_alias,batch_course_id,created_by) VALUES($1,$1,$2,$3) RETURNING batch_id',['MENTOR'+suffix,course,admin.user_id])).rows[0].batch_id;
 section=(await pool.query("INSERT INTO section(section_name,section_batch_id,created_by) VALUES('MENTOR TEST',$1,$2) RETURNING s_id",[batch,admin.user_id])).rows[0].s_id;
 studentCategory=(await students('/categories','POST',{name:'MENTOR '+suffix})).id;
 student=(await students('','POST',{first_name:'Mentored',last_name:'Student',dob:'2005-01-01',course_id:course,batch_id:batch,section_id:section,admission_category_id:studentCategory,semester:1})).id;
 const row=(await pool.query('SELECT * FROM stu_master WHERE stu_master_id=$1',[student])).rows[0];studentUser=row.stu_master_user_id;studentInfo=row.stu_master_stu_info_id;
 const [mentor,first,second,chief,other]=employees;
 assert.equal((await call('options','GET',null,{user_id:studentUser,role_name:'Student'})).status,403);
 assert.equal((await call('reviewers','GET',null,accounts[0])).status,403);
 assert.equal((await call('allotments','POST',{student_ids:[student],mentor_id:mentor},accounts[0])).status,403);
 await assert.rejects(call('allotments','POST',{student_ids:[student,999999999],mentor_id:mentor}),e=>e.status===400);
 assert.equal((await pool.query('SELECT mentor_id FROM stu_master WHERE stu_master_id=$1',[student])).rows[0].mentor_id,null);
 await call('allotments','POST',{student_ids:[student],mentor_id:mentor});
 assert.ok((await call('students','GET',null,accounts[0])).records.some(row=>row.stu_master_id===student));
 assert.equal((await call('students','GET',null,accounts[4])).records.length,0);
 const form={student_id:student,discussed_with:'S',discussion_type:'Academic',dis_subject:'Study progress',mentor_remarks:'Discussed study plan',urgent:false,current_due:'100.50',fees_pay_tran_amount:'50.25',fees_pay_tran_date:'2026-10-22',fees_pay_tran_mode:'UPI'};
 await assert.rejects(call('counselling','POST',form,accounts[0]),e=>e.status===400&&e.message.includes('Reviewer Allotment'));
 const config={r_mentor:mentor,r_reviewerone:first,r_reviewertwo:second,r_reviewerchief:chief,is_status:1};
 await assert.rejects(call('reviewers','POST',{...config,r_reviewerone:mentor}),e=>e.status===400);
 reviewerAllotment=(await call('reviewers','POST',config)).id;
 await assert.rejects(call('reviewers','POST',config),e=>e.code==='23505');
 assert.equal((await call('counselling','POST',form,accounts[4])).status,403);
 for(const invalid of [{...form,dis_subject:''},{...form,current_due:'-1'},{...form,fees_pay_tran_date:'2026-02-30'},{...form,urgent:1}])await assert.rejects(call('counselling','POST',invalid,accounts[0]),e=>e.status===400);
 let created=await call('counselling','POST',form,accounts[0]);assert.equal(created.status,201);const id=created.id;sessions.push(id);
 assert.equal((await call('counselling/'+id,'GET',null,accounts[4])).status,404);
 assert.equal((await call('counselling','GET',null,accounts[4])).records.length,0);
 assert.ok((await call('counselling?first=1','GET',null,accounts[1])).records.some(row=>row.sc_id===id));
 assert.equal((await call('counselling?first=1','GET',null,accounts[2])).records.some(row=>row.sc_id===id),false);
 assert.equal((await call('counselling/'+id,'PATCH',{...form,mentor_remarks:'Updated plan'},accounts[0])).status,200);
 assert.equal((await call('counselling/'+id,'PATCH',form,accounts[1])).status,403);
 await assert.rejects(call('counselling/'+id+'/review/two','POST',{remarks:'Too soon'},accounts[2]),e=>e.status===400);
 assert.equal((await call('counselling/'+id+'/review/one','POST',{remarks:'Unauthorized'},accounts[2])).status,403);
 const review={remarks:'Verified and recommended follow-up',firstreviewer_verified:'YES',grading_to_mentor:'GOOD',suggestion_tomentor:'Meet next month'};
 assert.equal((await call('counselling/'+id+'/review/one','POST',review,accounts[1])).status,201);
 await assert.rejects(call('counselling/'+id+'/review/one','POST',review,accounts[1]),e=>e.status===400);
 await assert.rejects(call('counselling/'+id,'PATCH',form,accounts[0]),e=>e.status===400);
 await assert.rejects(call('counselling/'+id,'DELETE',null,admin),e=>e.status===400);
 assert.equal((await call('counselling/'+id+'/review/two','POST',{remarks:'Second review complete'},accounts[2])).status,201);
 assert.equal((await call('counselling/'+id+'/review/chief','POST',{remarks:'Final review complete'},accounts[3])).status,201);
 let detail=(await call('counselling/'+id)).record;assert.equal(detail.is_status,2);assert.equal(detail.reviewerone_by,accounts[1].user_id);assert.equal(detail.fees_pay_tran_date,'2026-10-22');assert.equal(detail.current_due,'100.50');assert.equal(detail.mentor_remarks,'Updated plan');
 // Changing current allotments does not rewrite historical mentors or reviewers.
 await call('allotments','POST',{student_ids:[student],mentor_id:other});
 assert.equal((await call('students')).records.find(row=>row.stu_master_id===student).mentor_id,other);
 await call('reviewers/'+reviewerAllotment,'PATCH',{...config,r_reviewerone:other});
 detail=(await call('counselling/'+id)).record;assert.equal(detail.sc_emp_master_id,mentor);assert.equal(detail.reviewer_one,first);
 assert.ok((await call('counselling','GET',null,accounts[1])).records.some(row=>row.sc_id===id));
 await call('allotments','POST',{student_ids:[student],mentor_id:null});
 assert.equal((await pool.query('SELECT COUNT(*)::integer AS n FROM mentor_allotment_history WHERE student_id=$1',[student])).rows[0].n,3);
 await call('reviewers/'+reviewerAllotment,'DELETE');reviewerAllotment=null;
 assert.equal((await call('counselling/'+id)).record.is_status,2);
 // Soft-deleted students remain in the review history but leave allotment/report lists.
 await students('/'+student,'DELETE');assert.equal((await call('students')).records.some(row=>row.stu_master_id===student),false);assert.equal((await call('counselling/'+id)).status,200);
 console.log('PASS: mentor/reviewer allotments, atomic validation, scoped student/counselling access, counselling CRUD, sequential reviews, financial fields, audit history and reassignment/deletion history preservation.');
}finally{
 if(student){await pool.query('DELETE FROM studentcounselling WHERE sc_student_master_id=$1',[student]);await pool.query('DELETE FROM mentor_allotment_history WHERE student_id=$1',[student]);await pool.query('DELETE FROM stu_address WHERE student_id=$1',[student]);await pool.query('DELETE FROM stu_guardians WHERE guardia_stu_master_id=$1',[student]);await pool.query('DELETE FROM stu_master WHERE stu_master_id=$1',[student]);}
 if(studentUser){await pool.query('DELETE FROM course_students WHERE user_id=$1',[studentUser]);await pool.query('DELETE FROM users WHERE user_id=$1',[studentUser]);}
 if(studentInfo)await pool.query('DELETE FROM stu_info WHERE stu_info_id=$1',[studentInfo]);
 if(studentCategory)await pool.query('DELETE FROM stu_category WHERE stu_category_id=$1',[studentCategory]);
 if(employees.length)await pool.query('DELETE FROM mentorreviewer WHERE r_mentor=ANY($1::bigint[])',[employees]);
 if(employees.length)await pool.query('DELETE FROM emp_master WHERE emp_master_id=ANY($1::bigint[])',[employees]);
 if(accounts.length)await pool.query('DELETE FROM users WHERE user_id=ANY($1::bigint[])',[accounts.map(row=>row.user_id)]);
 if(infos.length)await pool.query('DELETE FROM emp_info WHERE emp_info_id=ANY($1::bigint[])',[infos]);
 if(employeeCategory)await pool.query('DELETE FROM emp_category WHERE emp_category_id=$1',[employeeCategory]);
 if(department)await pool.query('DELETE FROM emp_department WHERE emp_department_id=$1',[department]);
 if(section)await pool.query('DELETE FROM section WHERE s_id=$1',[section]);if(batch)await pool.query('DELETE FROM batches WHERE batch_id=$1',[batch]);if(course)await pool.query('DELETE FROM courses WHERE course_id=$1',[course]);
 await pool.end();
}
