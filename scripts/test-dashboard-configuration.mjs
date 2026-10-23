import assert from 'node:assert/strict';
import {randomBytes} from 'node:crypto';
import {pool} from '../server/db.mjs';
import {handleDashboardConfiguration} from '../server/dashboard-configuration.mjs';
import {handleEmployees} from '../server/employees.mjs';
import {timetableToday} from '../shared/timetable.mjs';
const suffix=randomBytes(5).toString('hex'),admin=(await pool.query("SELECT u.user_id,r.role_name FROM users u JOIN user_roles r USING(role_id) WHERE r.role_name='Admin' LIMIT 1")).rows[0];
const messages=[],notices=[],employees=[],infos=[],users=[],departments=[];let category;
async function invoke(path,method='GET',input,actor=admin){let result;const res={writeHead(status,headers){result={status,headers};},end(bytes){result.bytes=bytes;}};assert.equal(await handleDashboardConfiguration({method,url:path},res,path,actor,async()=>input,(_r,status,data)=>{result={status,...data};}),true);return result;}
const call=(path,method='GET',input,actor=admin)=>invoke('/api/admin/dashboard-configuration/'+path,method,input,actor);
const feed=actor=>invoke('/api/dashboard-content','GET',null,actor);
async function employee(path='',method='GET',input){let result;assert.equal(await handleEmployees({method},{},'/api/admin/employees'+path,admin,async()=>input,(_r,status,data)=>{result={status,...data};}),true);return result;}
try{
 for(let i=0;i<2;i++)departments.push((await employee('/masters/department','POST',{name:'DASHBOARD '+i+' '+suffix,alias:(i+suffix).slice(0,10)})).id);
 category=(await employee('/masters/category','POST',{name:'DASHBOARD '+suffix,alias:suffix,is_teaching:true})).id;
 let next=Number((await employee('/options')).next_employee_id);
 for(let i=0;i<2;i++){
  const id=(await employee('','POST',{employee_id:next++,first_name:'Dashboard',last_name:'Test '+i,dob:'1980-01-01',joining_date:'2020-01-01',department_id:departments[i],category_id:category,email:'dash'+i+suffix+'@example.com',experience_year:0,experience_month:0})).id;employees.push(id);
  const row=(await employee()).records.find(row=>row.emp_master_id===id);infos.push(row.emp_master_emp_info_id);users.push(row.emp_master_user_id);
 }
 const faculty={user_id:users[0],role_name:'Faculty'},other={user_id:users[1],role_name:'Faculty'};
 const studentId=(await pool.query("INSERT INTO users(role_id,username,password_hash,full_name) SELECT role_id,$1,'unused','DASHBOARD STUDENT' FROM user_roles WHERE role_name='Student' RETURNING user_id",['dash'+suffix])).rows[0].user_id;users.push(studentId);const student={user_id:studentId,role_name:'Student'};
 assert.equal((await call('messages','GET',null,student)).status,403);
 const form={msg_details:'Dashboard '+suffix,msg_user_type:'0',is_status:1};
 for(const invalid of [{...form,msg_details:''},{...form,msg_details:'x'.repeat(101)},{...form,msg_user_type:'XYZ'},{...form,is_status:2}])await assert.rejects(call('messages','POST',invalid),e=>e.status===400);
 let created=await call('messages','POST',form);assert.equal(created.status,201);const all=created.id;messages.push(all);
 await assert.rejects(call('messages','POST',form),e=>e.code==='23505');
 assert.equal((await feed(admin)).message.msg_of_day_id,all);assert.equal((await feed(student)).message.msg_of_day_id,all);
 const targeted={...form,msg_details:'Students '+suffix,msg_user_type:'STU'};const targetedId=(await call('messages','POST',targeted)).id;messages.push(targetedId);
 assert.equal((await feed(student)).message.msg_of_day_id,targetedId);assert.equal((await feed(faculty)).message.msg_of_day_id,all);
 await call('messages/'+targetedId,'PATCH',{...targeted,is_status:0});assert.equal((await feed(student)).message.msg_of_day_id,all);
 const text='<script>example</script> '+suffix;await call('messages/'+all,'PATCH',{...form,msg_details:text});assert.equal((await feed(admin)).message.msg_details,text);
 const note={notice_title:'Notice '+suffix,notice_description:'Dashboard notice',notice_user_type:'0',notice_date:timetableToday(),is_status:1,department_ids:[]};
 for(const invalid of [{...note,notice_title:'x'.repeat(26)},{...note,notice_description:'x'.repeat(256)},{...note,notice_date:'2026-02-30'},{...note,department_ids:[999999999]},{...note,notice_user_type:'STU',department_ids:[departments[0]]},{...note,file_name:'bad.pdf',file_base64:Buffer.from('bad').toString('base64')}])await assert.rejects(call('notices','POST',invalid),e=>e.status===400);
 const pdf=Buffer.from('%PDF-1.4\nDashboard notice fixture\n%%EOF');const withFile={...note,file_name:'notice.pdf',file_base64:pdf.toString('base64')};const publicId=(await call('notices','POST',withFile)).id;notices.push(publicId);
 assert.ok((await feed(student)).notices.some(row=>row.notice_id===publicId));
 const downloaded=await invoke('/api/dashboard-content/notices/'+publicId+'/file','GET',null,student);assert.equal(downloaded.status,200);assert.deepEqual(downloaded.bytes,pdf);assert.equal(downloaded.headers['X-Content-Type-Options'],'nosniff');
 await call('notices/'+publicId,'PATCH',{...note,notice_description:'Edited'});assert.equal((await call('notices')).records.find(row=>row.notice_id===publicId).downloadable,true);
 await call('notices/'+publicId,'PATCH',{...note,remove_attachment:true});assert.equal((await call('notices')).records.find(row=>row.notice_id===publicId).downloadable,false);
 const departmentId=(await call('notices','POST',{...withFile,notice_user_type:'EMP',department_ids:[departments[0]]})).id;notices.push(departmentId);
 assert.ok((await feed(faculty)).notices.some(row=>row.notice_id===departmentId));assert.equal((await feed(other)).notices.some(row=>row.notice_id===departmentId),false);assert.equal((await feed(student)).notices.some(row=>row.notice_id===departmentId),false);
 assert.equal((await invoke('/api/dashboard-content/notices/'+departmentId+'/file','GET',null,other)).status,404);
 assert.equal((await invoke('/api/admin/dashboard-configuration/notices/'+departmentId+'/file')).status,200);
 const future=(await call('notices','POST',{...withFile,notice_date:'2099-01-01'})).id;notices.push(future);assert.equal((await feed(faculty)).notices.some(row=>row.notice_id===future),false);assert.equal((await invoke('/api/dashboard-content/notices/'+future+'/file','GET',null,faculty)).status,404);
 await call('notices/'+departmentId,'PATCH',{...note,notice_user_type:'EMP',department_ids:[departments[0]],is_status:0});assert.equal((await feed(faculty)).notices.some(row=>row.notice_id===departmentId),false);
 assert.equal((await invoke('/api/dashboard-content','POST',{},student)).status,405);
 assert.equal((await call('options')).departments.some(row=>row.emp_department_id===departments[0]),true);
 for(const id of notices)assert.equal((await call('notices/'+id,'DELETE')).status,200);
 for(const id of messages)assert.equal((await call('messages/'+id,'DELETE')).status,200);
 console.log('PASS: message/notice CRUD, audience-specific latest message, strict field/date validation, notice scheduling, department targeting, attachment preservation/removal, download authorization and plain-text rendering data.');
}finally{
 if(notices.length)await pool.query('DELETE FROM notice WHERE notice_id=ANY($1::bigint[])',[notices]);if(messages.length)await pool.query('DELETE FROM msg_of_day WHERE msg_of_day_id=ANY($1::bigint[])',[messages]);
 if(employees.length)await pool.query('DELETE FROM emp_master WHERE emp_master_id=ANY($1::bigint[])',[employees]);if(users.length)await pool.query('DELETE FROM users WHERE user_id=ANY($1::bigint[])',[users]);if(infos.length)await pool.query('DELETE FROM emp_info WHERE emp_info_id=ANY($1::bigint[])',[infos]);if(category)await pool.query('DELETE FROM emp_category WHERE emp_category_id=$1',[category]);if(departments.length)await pool.query('DELETE FROM emp_department WHERE emp_department_id=ANY($1::bigint[])',[departments]);await pool.end();
}
