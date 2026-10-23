import assert from 'node:assert/strict';
import {randomBytes} from 'node:crypto';
import {pool} from '../server/db.mjs';
import {handleEmployees} from '../server/employees.mjs';
import {handleAcademicResources} from '../server/academic-resources.mjs';
import {verifyPassword} from '../server/passwords.mjs';
const suffix=randomBytes(5).toString('hex');
const actor=(await pool.query("SELECT u.user_id FROM users u JOIN user_roles r USING(role_id) WHERE r.role_name='Admin' LIMIT 1")).rows[0];
let department,designation,category,nonTeaching;const employeeIds=[],userIds=[],infoIds=[];
async function call(path='',method='GET',input){let result;assert.equal(await handleEmployees({method},{},'/api/admin/employees'+path,actor,async()=>input,(_res,status,data)=>{result={status,...data};}),true);return result;}
async function list(){return (await call()).records;}
async function account(id){return (await pool.query('SELECT u.*,r.role_name FROM users u JOIN user_roles r USING(role_id) WHERE u.user_id=$1',[id])).rows[0];}
try{
 for(const kind of ['department','designation','category']){
  const created=await call('/masters/'+kind,'POST',{name:'EMPTEST '+kind+' '+suffix,alias:(kind.slice(0,2)+suffix).slice(0,10),is_teaching:true});assert.equal(created.status,201);
  if(kind==='department')department=created.id;else if(kind==='designation')designation=created.id;else category=created.id;
 }
 nonTeaching=(await call('/masters/category','POST',{name:'NONTEACH '+suffix,alias:('N'+suffix).slice(0,10),is_teaching:false})).id;
 assert.ok((await call('/options')).department.some(row=>row.emp_department_id===department));
 await assert.rejects(call('/masters/department','POST',{name:'',alias:'BAD'}),error=>error.status===400);
 const number=Number((await call('/options')).next_employee_id);
 const input={employee_id:number,first_name:'Amiya',middle_name:'Kumar',last_name:'Rath',name_alias:'AKR',caste:'GENERAL',gender:'MALE',dob:'1985-05-20',joining_date:'2020-01-10',department_id:department,designation_id:designation,category_id:category,email:'employee'+suffix+'@example.com',mobile:'9876501234',experience_year:4,experience_month:6,marital_status:'MARRIED'};
 for(const invalid of [{...input,department_id:999999999},{...input,first_name:''},{...input,dob:'2026-02-30'},{...input,email:'bad'},{...input,mobile:'bad'},{...input,experience_month:12}])await assert.rejects(call('','POST',invalid),error=>error.status===400);
 let created=await call('','POST',input);assert.equal(created.status,201);employeeIds.push(created.id);assert.equal(created.account_type,'Faculty');
 let row=(await list()).find(row=>row.emp_master_id===created.id);userIds.push(row.emp_master_user_id);infoIds.push(row.emp_master_emp_info_id);
 assert.equal(row.emp_dob,'1985-05-20');assert.equal(row.emp_joining_date,'2020-01-10');assert.equal(row.emp_first_name,'AMIYA');assert.equal(row.emp_department_name,'EMPTEST DEPARTMENT '+suffix.toUpperCase());assert.equal(row.emp_experience_month,6);assert.equal(row.username,input.email);
 let user=await account(row.emp_master_user_id);assert.equal(await verifyPassword(created.temporary_password,user.password_hash),true);assert.equal(user.role_name,'Faculty');assert.equal(Object.hasOwn(row,'password_hash'),false);
 assert.equal((await pool.query('SELECT employee_code FROM faculty WHERE user_id=$1',[user.user_id])).rows[0].employee_code,'EMP-'+number);
 let facultyOptions;await handleAcademicResources({method:'GET'},{},'/api/admin/academics/lecture-notes/options',actor,null,(_r,_s,data)=>{facultyOptions=data;});assert.ok(facultyOptions.faculty.some(f=>f.user_id===user.user_id));
 await assert.rejects(call('/masters/department/'+department,'DELETE'),error=>error.code==='23503');
 await assert.rejects(call('/masters/category/'+category,'PATCH',{name:'EMPTEST CAT '+suffix,alias:('CT'+suffix).slice(0,10),is_teaching:false}),error=>error.status===400);
 const count=(await pool.query('SELECT COUNT(*)::int AS total FROM users')).rows[0].total;
 await assert.rejects(call('','POST',input),error=>error.code==='23505');assert.equal((await pool.query('SELECT COUNT(*)::int AS total FROM users')).rows[0].total,count);
 assert.equal((await call('/'+row.emp_master_id,'PATCH',{...input,first_name:'Updated'})).status,200);assert.equal((await account(user.user_id)).full_name,'UPDATED KUMAR RATH');
 const token=randomBytes(32).toString('hex');await pool.query("INSERT INTO user_sessions(token_hash,user_id,expires_at) VALUES($1,$2,NOW()+INTERVAL '1 hour')",[token,user.user_id]);
 const login='employee.'+suffix;assert.equal((await call('/'+row.emp_master_id+'/login','POST',{username:login})).status,200);assert.equal((await account(user.user_id)).username,login);assert.equal((await pool.query('SELECT COUNT(*)::int AS total FROM user_sessions WHERE user_id=$1',[user.user_id])).rows[0].total,0);
 await assert.rejects(call('/'+row.emp_master_id+'/password','POST',{password:'short'}),error=>error.status===400);
 const nextPassword=randomBytes(18).toString('hex');await call('/'+row.emp_master_id+'/password','POST',{password:nextPassword});assert.equal(await verifyPassword(nextPassword,(await account(user.user_id)).password_hash),true);assert.equal(await verifyPassword(created.temporary_password,(await account(user.user_id)).password_hash),false);
 await pool.query("INSERT INTO user_sessions(token_hash,user_id,expires_at) VALUES($1,$2,NOW()+INTERVAL '1 hour')",[token,user.user_id]);
 assert.equal((await call('/'+row.emp_master_id,'DELETE')).status,200);assert.equal((await account(user.user_id)).is_active,false);assert.equal((await list()).some(value=>value.emp_master_id===row.emp_master_id),false);assert.ok((await call('/deleted')).records.some(value=>value.emp_master_id===row.emp_master_id));assert.equal((await pool.query('SELECT COUNT(*)::int AS total FROM user_sessions WHERE user_id=$1',[user.user_id])).rows[0].total,0);
 assert.equal((await call('/'+row.emp_master_id+'/login','POST',{username:'deleted'+suffix})).status,404);
 assert.equal((await call('/'+row.emp_master_id+'/restore','POST',{})).status,200);assert.equal((await account(user.user_id)).is_active,true);assert.equal((await list()).find(value=>value.emp_master_id===row.emp_master_id).username,login);
 created=await call('','POST',{...input,employee_id:number+1,category_id:nonTeaching,email:'nonteach'+suffix+'@example.com',mobile:''});employeeIds.push(created.id);assert.equal(created.account_type,'Employee');row=(await list()).find(value=>value.emp_master_id===created.id);userIds.push(row.emp_master_user_id);infoIds.push(row.emp_master_emp_info_id);assert.equal((await account(row.emp_master_user_id)).role_name,'Employee');assert.equal((await pool.query('SELECT user_id FROM faculty WHERE user_id=$1',[row.emp_master_user_id])).rowCount,0);
 assert.equal((await call('/masters/department/'+department,'PATCH',{name:'RENAMED '+suffix,alias:('UP'+suffix).slice(0,10)})).status,200);assert.equal((await pool.query('SELECT department FROM faculty WHERE user_id=$1',[userIds[0]])).rows[0].department,'RENAMED '+suffix.toUpperCase());
 assert.equal((await call('/999999999','GET')).status,404);assert.equal((await call('','PUT')).status,405);
 console.log('PASS: employee master CRUD, validation and transaction rollback, create/edit, account hashing and Faculty integration, login/password reset, session invalidation, soft deletion/restoration and non-teaching logins.');
}finally{
 if(employeeIds.length)await pool.query('DELETE FROM emp_master WHERE emp_master_id=ANY($1::bigint[])',[employeeIds]);
 if(infoIds.length)await pool.query('DELETE FROM emp_info WHERE emp_info_id=ANY($1::bigint[])',[infoIds]);
 if(userIds.length)await pool.query('DELETE FROM users WHERE user_id=ANY($1::bigint[])',[userIds]);
 if(category)await pool.query('DELETE FROM emp_category WHERE emp_category_id=$1',[category]);
 if(nonTeaching)await pool.query('DELETE FROM emp_category WHERE emp_category_id=$1',[nonTeaching]);
 if(designation)await pool.query('DELETE FROM emp_designation WHERE emp_designation_id=$1',[designation]);
 if(department)await pool.query('DELETE FROM emp_department WHERE emp_department_id=$1',[department]);
 await pool.end();
}
