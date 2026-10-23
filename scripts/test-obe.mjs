import {handleEmployees} from '../server/employees.mjs';
import assert from 'node:assert/strict';
import {randomBytes} from 'node:crypto';
import {readFile} from 'node:fs/promises';
import {pool} from '../server/db.mjs';
import {handleObe} from '../server/obe.mjs';
const suffix=randomBytes(4).toString('hex'),admin=(await pool.query("SELECT u.user_id,r.role_name FROM users u JOIN user_roles r USING(role_id) WHERE r.role_name='Admin' LIMIT 1")).rows[0];
let department,programme,batch,course,co,po,erpDepartment,year,employeeCategory,employeeId,employeeUser,employeeInfo,facultyId;const base='/api/admin/obe';
async function call(path,method='GET',input,actor=admin){let result;const req={method,url:base+'/'+path};const res={writeHead(status){result={status};},end(){}};assert.equal(await handleObe(req,res,req.url.split('?')[0],actor,async()=>input,(_r,status,data)=>{result={status,data};}),true);return result;}
const check=(result,status)=>{assert.equal(result.status,status,JSON.stringify(result.data));return result.data;};
try{
 const client=await pool.connect();try{await client.query('BEGIN');const schema='obe_test_'+suffix;const sql=(await readFile(new URL('../database/obe.sql',import.meta.url),'utf8')).replaceAll('obe.',schema+'.').replace('CREATE SCHEMA IF NOT EXISTS obe;','CREATE SCHEMA IF NOT EXISTS '+schema+';');await client.query(sql);await client.query(sql);const compatibility=(await readFile(new URL('../database/obe-compatibility.sql',import.meta.url),'utf8')).replaceAll('obe.',schema+'.');await client.query(compatibility);assert.equal((await client.query('SELECT COUNT(*)::integer AS n FROM pg_tables WHERE schemaname=$1',[schema])).rows[0].n,39);assert.equal((await client.query('SELECT to_regclass($1) AS t',[schema+'.users'])).rows[0].t,null);await client.query('ROLLBACK');}finally{client.release();}
 assert.equal((await call('departments','GET',null,{user_id:admin.user_id,role_name:'Student'})).status,403);
 assert.equal((await call('login','POST',{})).status,404);assert.equal((await call('users')).status,404);assert.equal((await pool.query("SELECT to_regclass('obe.users') AS t")).rows[0].t,null);
 for(const path of ['departments','programmes','admission-batches','semesters','courses','course-outcomes','programme-outcomes','dashboard-content','students','erp-links','faculty-management'])check(await call(path),200);
 const form={department_name:'OBE TEST '+suffix,department_code:'OT'+suffix,institute_college:'ABIT',hod:'Test',email:'',phone:'',status:'Active'};
 check(await call('departments','POST',{}),400);department=check(await call('departments','POST',form),201).department_id;
 check(await call('departments/'+department,'PUT',{...form,department_name:'OBE UPDATED '+suffix}),200);
 const programmeForm={department_id:department,programme_name:'OBE PROGRAMME '+suffix,programme_code:'OP'+suffix,programme_type:'UG',duration_years:2,total_semesters:4,accreditation_status:'Accredited',status:'Active'};
 programme=check(await call('programmes','POST',programmeForm),201).programme_id;
 const yearStart=2900+parseInt(suffix.slice(0,3),16);year=yearStart+'-'+String((yearStart+1)%100).padStart(2,'0');
 const saved=check(await call('admission-batches','POST',{department_id:department,programme_id:programme,starting_academic_year:year,admission_year:yearStart,status:'Active'}),201);batch=saved.row.admission_batch_id;
 const semesters=check(await call('semesters'),200).filter(row=>row.admission_batch_id===batch);assert.equal(semesters.length,4);
 const cohort={department_id:department,programme_id:programme,semester_id:semesters[0].semester_id};
 const courseForm={...cohort,course_code:'OC'+suffix,course_name:'OBE TEST COURSE',course_type:'Theory',credits:4,lecture_hours:3,tutorial_hours:1,practical_hours:0,total_marks:100,status:'Active'};
 course=check(await call('courses','POST',courseForm),201).course_id;const context={...cohort,course_id:course,academic_year:year};
 co=check(await call('course-outcomes','POST',{...context,co_code:'CO1',co_statement:'Analyze programming problems',bloom_level:'Analyze',target_level:2.5,status:'Active'}),201).co_id;
 po=check(await call('programme-outcomes','POST',{department_id:department,programme_id:programme,outcome_type:'PO',outcome_code:'PO1',outcome_title:'Engineering Knowledge',outcome_statement:'Apply engineering knowledge',status:'Active'}),201).outcome_id;
 check(await call('co-po-mapping','POST',{mappings:[{co_id:co,po_id:po,mapping_level:3}]}),200);
 check(await call('co-po-mapping','POST',{mappings:[{co_id:co,po_id:po,mapping_level:7}]}),400);
 check(await call('internal-marks-upload','POST',{...context,branch:'CSE',rows:[{regd_no:'OT'+suffix,student_name:'OBE Student',attd:5,a1:10,a2:10,qt1:5,qt2:5,st1:10,st2:10,ct1:10,ct2:10,internal_mark:75}]}),201);
 const marks=check(await call('internal-marks-upload?course_id='+course+'&academic_year='+encodeURIComponent(year)),200);assert.equal(Number(marks[0].internal_mark),75);
 check(await call('internal-marks-upload','POST',{...context,branch:'CSE',rows:[{regd_no:'',student_name:'Invalid'}]}),400);assert.equal(check(await call('internal-marks-upload?course_id='+course+'&academic_year='+encodeURIComponent(year)),200).length,1);
 check(await call('external-marks-upload','POST',{...context,average_mark:80,target_average:60,attainment_value:100,rows:[{regd_no:'OT'+suffix,student_name:'OBE Student',grade:'E',percent_mark:80}]}),201);
 check(await call('mark-attainment','POST',{...context,rows:[{assessment_tool:'a1',tool_label:'Assignment 1',weightage:10,target_average:60,attainment_percent:80,level:'HL',level_point:3}]}),201);
 const calculation={rows:[{co_code:'CO1',values:{a1:3},results:{co_attainment:2.6}}]};
 check(await call('co-attainment-calculation','POST',{...context,batch:'TEST',internal_weight:80,external_weight:20,row_data:calculation}),201);
 check(await call('co-po-attainment','POST',{...context,row_data:{PO1:2.6}}),201);check(await call('co-pso-attainment','POST',{...context,row_data:{PSO1:2.4}}),201);
 assert.deepEqual((await pool.query('SELECT row_data FROM obe.co_attainment_calculation WHERE course_id=$1',[course])).rows[0].row_data,calculation);
 erpDepartment=(await pool.query('INSERT INTO public.emp_department(emp_department_name,emp_department_alias,created_by) VALUES($1,$2,$3) RETURNING emp_department_id',['OBE ERP '+suffix,suffix,admin.user_id])).rows[0].emp_department_id;
 check(await call('erp-links/departments/'+department,'PATCH',{erp_id:erpDepartment}),200);assert.equal((await pool.query('SELECT erp_id FROM obe.department WHERE department_id=$1',[department])).rows[0].erp_id,erpDepartment);
 await assert.rejects(pool.query('DELETE FROM public.emp_department WHERE emp_department_id=$1',[erpDepartment]),e=>e.code==='23503');
 await assert.rejects(call('erp-links/departments/'+department,'PATCH',{erp_id:999999999}),e=>e.status===400);
 check(await call('erp-links/departments/'+department,'PATCH',{erp_id:null}),200);
 employeeCategory=(await pool.query('INSERT INTO public.emp_category(emp_category_name,emp_category_alias,is_teaching,created_by) VALUES($1,$2,TRUE,$3) RETURNING emp_category_id',['OBE FACULTY '+suffix,suffix,admin.user_id])).rows[0].emp_category_id;
 let options;await handleEmployees({method:'GET'},{},'/api/admin/employees/options',admin,null,(_r,_s,data)=>{options=data;});
 let employee;await handleEmployees({method:'POST'},{},'/api/admin/employees',admin,async()=>({employee_id:Number(options.next_employee_id),first_name:'OBE',last_name:'Faculty',department_id:erpDepartment,category_id:employeeCategory,dob:'1980-01-01',joining_date:'2020-01-01',experience_year:1,experience_month:0,email:'obe-faculty'+suffix+'@example.com'}),(_r,status,data)=>{assert.equal(status,201);employee=data;});
 employeeId=employee.id;const master=(await pool.query('SELECT * FROM public.emp_master WHERE emp_master_id=$1',[employeeId])).rows[0];employeeUser=master.emp_master_user_id;employeeInfo=master.emp_master_emp_info_id;
 facultyId=check(await call('faculty-from-erp','POST',{employee_id:employeeId,department_id:department}),201).id;assert.ok(facultyId);
 assert.equal(check(await call('faculty-from-erp','POST',{employee_id:employeeId,department_id:department}),201).id,facultyId);
 assert.equal((await pool.query('SELECT erp_id FROM obe.faculty WHERE faculty_id=$1',[facultyId])).rows[0].erp_id,employeeId);
 assert.equal((await pool.query("SELECT to_regclass('obe.users') AS t")).rows[0].t,null);
 console.log('PASS: fresh/idempotent 39-table OBE schema, no standalone accounts/login, setup/outcomes/mapping CRUD, duration-based semesters, mark import rollback, attainment round trips and ERP foreign-key links.');
}finally{
 if(facultyId)await pool.query('DELETE FROM obe.faculty WHERE faculty_id=$1',[facultyId]);if(employeeId)await pool.query('DELETE FROM public.emp_master WHERE emp_master_id=$1',[employeeId]);if(employeeUser)await pool.query('DELETE FROM public.users WHERE user_id=$1',[employeeUser]);if(employeeInfo)await pool.query('DELETE FROM public.emp_info WHERE emp_info_id=$1',[employeeInfo]);if(employeeCategory)await pool.query('DELETE FROM public.emp_category WHERE emp_category_id=$1',[employeeCategory]);
 if(course){for(const table of ['internal_marks_upload','external_marks_upload','mark_attainment','co_attainment_calculation','co_po_attainment','co_pso_attainment','articulation_matrix','university_question_mapping'])await pool.query('DELETE FROM obe.'+table+' WHERE course_id=$1',[course]);}
 if(co)await pool.query('DELETE FROM obe.co_po_mapping WHERE co_id=$1',[co]);if(co)await pool.query('DELETE FROM obe.course_outcomes WHERE co_id=$1',[co]);if(po)await pool.query('DELETE FROM obe.programme_outcomes WHERE outcome_id=$1',[po]);if(course)await pool.query('DELETE FROM obe.courses WHERE course_id=$1',[course]);
 if(batch){await pool.query('DELETE FROM obe.semesters WHERE admission_batch_id=$1',[batch]);await pool.query('DELETE FROM obe.admission_batches WHERE admission_batch_id=$1',[batch]);}
 if(programme)await pool.query('DELETE FROM obe.programmes WHERE programme_id=$1',[programme]);if(department)await pool.query('DELETE FROM obe.department WHERE department_id=$1',[department]);if(erpDepartment)await pool.query('DELETE FROM public.emp_department WHERE emp_department_id=$1',[erpDepartment]);if(year)await pool.query('DELETE FROM obe.academic_years WHERE academic_year=$1',[year]);await pool.end();
}
