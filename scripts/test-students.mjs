import assert from 'node:assert/strict';
import {randomBytes} from 'node:crypto';
import {pool} from '../server/db.mjs';
import {handleStudents} from '../server/students.mjs';
import {handleAcademicResources} from '../server/academic-resources.mjs';
import {verifyPassword} from '../server/passwords.mjs';
import {attendanceWorkbook} from '../shared/attendance-export.mjs';
import {studentImportColumns} from '../shared/students.mjs';
import {parseStudentImport} from '../server/student-import.mjs';
const suffix=randomBytes(5).toString('hex'),actor=(await pool.query("SELECT u.user_id FROM users u JOIN user_roles r USING(role_id) WHERE r.role_name='Admin' LIMIT 1")).rows[0];
let course,batch,section,otherSection,category,country,state,city,faculty,assignment;
async function call(path='',method='GET',input){let result;assert.equal(await handleStudents({method},{},'/api/admin/students'+path,actor,async()=>input,(_res,status,data)=>{result={status,...data};}),true);return result;}
async function academic(path,method='GET',input){let result;assert.equal(await handleAcademicResources({method},{},'/api/admin/academics/'+path,actor,async()=>input,(_res,status,data)=>{result={status,...data};}),true);return result;}
async function account(id){return (await pool.query('SELECT u.*,r.role_name FROM users u JOIN user_roles r USING(role_id) WHERE u.user_id=$1',[id])).rows[0];}
try{
 course=(await pool.query('INSERT INTO courses(course_name,course_code,course_alias,course_duration,created_by) VALUES($1,$1,$1,4,$2) RETURNING course_id',['STU'+suffix,actor.user_id])).rows[0].course_id;
 batch=(await pool.query('INSERT INTO batches(batch_name,batch_alias,batch_course_id,created_by) VALUES($1,$1,$2,$3) RETURNING batch_id',['STU'+suffix,course,actor.user_id])).rows[0].batch_id;
 for(const name of ['STUDENT SECTION','OTHER SECTION']){const id=(await pool.query('INSERT INTO section(section_name,section_batch_id,created_by) VALUES($1,$2,$3) RETURNING s_id',[name,batch,actor.user_id])).rows[0].s_id;if(!section)section=id;else otherSection=id;}
 category=(await call('/categories','POST',{name:'STUDENT CAT '+suffix})).id;
 assert.ok((await call('/categories')).records.some(row=>row.stu_category_id===category));await assert.rejects(call('/categories','POST',{name:''}),error=>error.status===400);
 country=(await pool.query('INSERT INTO country(country_name,created_by) VALUES($1,$2) RETURNING country_id',['COUNTRY'+suffix,actor.user_id])).rows[0].country_id;
 state=(await pool.query('INSERT INTO state(state_name,state_country_id,created_by) VALUES($1,$2,$3) RETURNING state_id',['STATE'+suffix,country,actor.user_id])).rows[0].state_id;
 city=(await pool.query('INSERT INTO city(city_name,city_country_id,city_state_id,created_by) VALUES($1,$2,$3,$4) RETURNING city_id',['CITY'+suffix,country,state,actor.user_id])).rows[0].city_id;
 const options=await call('/options'),active=options.statuses.find(row=>row.stu_status_name==='Active'),inactive=options.statuses.find(row=>row.stu_status_name==='Inactive');
 const defaults={course_id:course,batch_id:batch,section_id:section,admission_category_id:category,semester:1};
 const input={...defaults,first_name:'Student',middle_name:'Test',last_name:'Name',dob:'2005-03-15',email:'student'+suffix+'@example.com',mobile:'9876543210',aadhaar:'123456789012',father_name:'Father Name',father_mobile:'9876543211',father_income:100000,current_address:'Test Address',current_country_id:country,current_state_id:state,current_city_id:city,current_pincode:'751001',permanent_address:'Permanent Address',mark_10th:90,entrance_exam:'JEE',entrance_rank:1500,hostel:'Y',transport:'N',lunch:'Y',food_preference:'VEG'};
 for(const invalid of [{...input,first_name:''},{...input,dob:'2099-01-01'},{...input,dob:'2005-02-30'},{...input,batch_id:999999999},{...input,section_id:999999999},{...input,semester:9},{...input,email:'bad'},{...input,aadhaar:'bad'},{...input,current_country_id:999999999},{...input,court_proceedings:'Y',court_details:''}])await assert.rejects(call('','POST',invalid),error=>error.status===400);
 const created=await call('','POST',input);assert.equal(created.status,201);assert.ok(created.registration_no);assert.equal(created.login_id,created.registration_no);
 let row=(await call()).records.find(row=>row.stu_master_id===created.id),user=await account(row.stu_master_user_id);assert.equal(user.role_name,'Student');assert.equal(await verifyPassword(created.temporary_password,user.password_hash),true);assert.equal(Object.hasOwn(row,'password_hash'),false);assert.equal(row.stu_first_name,'STUDENT');
 let detail=await call('/'+created.id);assert.equal(detail.form.dob,'2005-03-15');assert.equal(detail.form.current_city_id,city);assert.equal(detail.form.father_name,'Father Name');assert.equal(Number(detail.form.father_income),100000);assert.equal(detail.form.mark_10th,90);assert.equal(detail.form.hostel,'Y');
 let enrollment=(await pool.query('SELECT * FROM course_students WHERE user_id=$1',[user.user_id])).rows[0];assert.equal(enrollment.course_id,course);assert.equal(enrollment.batch_id,batch);assert.equal(enrollment.section_id,section);
 const teacher=(await pool.query("INSERT INTO users(role_id,username,password_hash,full_name) SELECT role_id,$1,'unused','STUDENT TEST FACULTY' FROM user_roles WHERE role_name='Faculty' RETURNING user_id",['stufaculty'+suffix])).rows[0].user_id;faculty=teacher;await pool.query('INSERT INTO faculty(user_id) VALUES($1)',[teacher]);
 const subject=(await pool.query("INSERT INTO subjects(subject_name,subject_code,subject_alias,created_by) VALUES('STUDENT ROSTER SUBJECT',$1,'STU',$2) RETURNING subject_id",[suffix,actor.user_id])).rows[0].subject_id;
 assignment=(await academic('lecture-notes/assignments','POST',{course_id:course,batch_id:batch,section_type:'S',section_id:section,semester:1,subject_id:subject,teacher_id:teacher,teacher_type:'M',student_group:'ALL'})).id;
 assert.ok((await academic('take-attendance/assignments/'+assignment)).eligible.some(value=>value.user_id===user.user_id));
 await call('/'+created.id,'PATCH',{...input,first_name:'Updated',section_id:otherSection});assert.equal((await call('/'+created.id)).form.first_name,'UPDATED');assert.equal((await academic('take-attendance/assignments/'+assignment)).eligible.some(value=>value.user_id===user.user_id),false);
 await call('/'+created.id,'PATCH',input);
 await assert.rejects(call('/categories/'+category,'DELETE'),error=>error.code==='23503');
 const token=randomBytes(32).toString('hex');await pool.query("INSERT INTO user_sessions(token_hash,user_id,expires_at) VALUES($1,$2,NOW()+INTERVAL '1 hour')",[token,user.user_id]);
 await call('/'+created.id+'/registration','POST',{value:'REG'+suffix});assert.equal((await pool.query('SELECT admission_number FROM students WHERE user_id=$1',[user.user_id])).rows[0].admission_number,'REG'+suffix.toUpperCase());assert.equal((await account(user.user_id)).username,created.login_id);assert.equal((await pool.query('SELECT COUNT(*)::int AS count FROM user_sessions WHERE user_id=$1',[user.user_id])).rows[0].count,0);
 await call('/'+created.id+'/login','POST',{value:'student.'+suffix});assert.equal((await account(user.user_id)).username,'student.'+suffix);
 await assert.rejects(call('/'+created.id+'/password','POST',{password:'short'}),error=>error.status===400);const password=randomBytes(18).toString('hex');await call('/'+created.id+'/password','POST',{password});assert.equal(await verifyPassword(password,(await account(user.user_id)).password_hash),true);
 await call('/'+created.id+'/status','POST',{status_id:inactive.stu_status_id});assert.equal((await account(user.user_id)).is_active,false);assert.equal((await academic('take-attendance/assignments/'+assignment)).eligible.some(value=>value.user_id===user.user_id),false);
 await call('/'+created.id,'DELETE');assert.ok((await call('/deleted')).records.some(value=>value.stu_master_id===created.id));assert.equal((await call()).records.some(value=>value.stu_master_id===created.id),false);assert.equal((await call('/'+created.id+'/login','POST',{value:'bad'})).status,404);
 await call('/'+created.id+'/restore','POST',{});assert.equal((await account(user.user_id)).is_active,false);await call('/'+created.id+'/status','POST',{status_id:active.stu_status_id});assert.equal((await account(user.user_id)).is_active,true);
 const imported=await call('/import','POST',{file_name:'students.csv',file_base64:Buffer.from('first_name,last_name,dob\nImported,CSV,2006-02-03\n').toString('base64'),defaults});assert.equal(imported.count,1);assert.ok(imported.credentials[0].temporary_password);
 const count=(await pool.query('SELECT COUNT(*)::int AS count FROM stu_master')).rows[0].count;
 await assert.rejects(call('/import','POST',{file_name:'bad.csv',file_base64:Buffer.from('first_name,dob\nValid,2006-02-03\nInvalid,2099-01-01\n').toString('base64'),defaults}),error=>error.status===400&&/Row 3/.test(error.message));assert.equal((await pool.query('SELECT COUNT(*)::int AS count FROM stu_master')).rows[0].count,count);
 const xlsx=Buffer.from(attendanceWorkbook([{first_name:'Excel',dob:'2007-04-05'}],studentImportColumns,'Students'));const excel=await call('/import','POST',{file_name:'students.xlsx',file_base64:xlsx.toString('base64'),defaults});assert.equal(excel.count,1);
 await assert.rejects(call('/import','POST',{file_name:'bad.exe',file_base64:xlsx.toString('base64'),defaults}),error=>error.status===400);
 assert.throws(()=>parseStudentImport('bad.csv',Buffer.from('password\nsecret').toString('base64'),new Set(studentImportColumns.map(([key])=>key))),error=>error.status===400);
 let template;await handleStudents({method:'GET'},{writeHead(status){assert.equal(status,200);},end(bytes){template=bytes;}},'/api/admin/students/import/template',actor,null,()=>assert.fail());assert.equal(template.readUInt32LE(0),0x04034b50);
 await call('/categories/'+category,'PATCH',{name:'UPDATED CATEGORY '+suffix});assert.equal((await call()).records.find(value=>value.stu_master_id===created.id).stu_category_name,'UPDATED CATEGORY '+suffix.toUpperCase());
 assert.equal((await call('/999999999')).status,404);assert.equal((await call('','PUT')).status,405);
 console.log('PASS: Student profile/guardian/address/academic round trips, category CRUD, course/batch/section enrolment and roster integration, registration/login/password resets, status/session handling, deletion/restoration, CSV/XLSX import, all-or-nothing rollback and template download.');
 await pool.query('DELETE FROM section_house_subject_teacher WHERE shst_id=$1',[assignment]);assignment=null;await pool.query('DELETE FROM subjects WHERE subject_id=$1',[subject]);
}finally{
 if(assignment)await pool.query('DELETE FROM section_house_subject_teacher WHERE shst_id=$1',[assignment]);
 if(course){const records=(await pool.query('SELECT stu_master_id,stu_master_stu_info_id,stu_master_user_id FROM stu_master WHERE stu_master_course_id=$1',[course])).rows;for(const row of records){await pool.query('DELETE FROM stu_address WHERE student_id=$1',[row.stu_master_id]);await pool.query('DELETE FROM stu_guardians WHERE guardia_stu_master_id=$1',[row.stu_master_id]);await pool.query('DELETE FROM stu_master WHERE stu_master_id=$1',[row.stu_master_id]);await pool.query('DELETE FROM stu_info WHERE stu_info_id=$1',[row.stu_master_stu_info_id]);await pool.query('DELETE FROM course_students WHERE user_id=$1',[row.stu_master_user_id]);await pool.query('DELETE FROM users WHERE user_id=$1',[row.stu_master_user_id]);}}
 if(faculty)await pool.query('DELETE FROM users WHERE user_id=$1',[faculty]);
 if(category)await pool.query('DELETE FROM stu_category WHERE stu_category_id=$1',[category]);
 if(city)await pool.query('DELETE FROM city WHERE city_id=$1',[city]);if(state)await pool.query('DELETE FROM state WHERE state_id=$1',[state]);if(country)await pool.query('DELETE FROM country WHERE country_id=$1',[country]);
 if(otherSection)await pool.query('DELETE FROM section WHERE s_id=$1',[otherSection]);if(section)await pool.query('DELETE FROM section WHERE s_id=$1',[section]);if(batch)await pool.query('DELETE FROM batches WHERE batch_id=$1',[batch]);if(course)await pool.query('DELETE FROM courses WHERE course_id=$1',[course]);
 await pool.end();
}
