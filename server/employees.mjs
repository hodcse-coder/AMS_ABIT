import {randomBytes} from 'node:crypto';
import {pool} from './db.mjs';
import {hashPassword} from './passwords.mjs';
import {employeeMasters} from '../shared/employees.mjs';
const base='/api/admin/employees';
const fail=message=>{throw Object.assign(new Error(message),{status:400});};
const positive=value=>Number.isSafeInteger(Number(value))&&Number(value)>0;
const text=(value,label,max,required=false,upper=true)=>{const result=typeof value==='string'?value.trim():'';if((required&&!result)||result.length>max)fail(`Enter ${label} (up to ${max} characters).`);return result?(upper?result.toUpperCase():result):null;};
function date(value,label){if(!value)return null;if(typeof value!=='string'||!/^\d{4}-\d{2}-\d{2}$/.test(value)||!Number.isFinite(Date.parse(value+'T00:00:00Z'))||new Date(value+'T00:00:00Z').toISOString().slice(0,10)!==value)fail('Enter a valid '+label+'.');return value;}
const listQuery=`SELECT m.*,i.*,i.emp_dob::text AS emp_dob,i.emp_joining_date::text AS emp_joining_date,u.username,u.is_active,r.role_name,d.emp_department_name,g.emp_designation_name,c.emp_category_name,c.is_teaching,n.nationality_name
 FROM emp_master m JOIN emp_info i ON i.emp_info_id=m.emp_master_emp_info_id JOIN users u ON u.user_id=m.emp_master_user_id JOIN user_roles r USING(role_id)
 JOIN emp_department d ON d.emp_department_id=m.emp_master_department_id LEFT JOIN emp_designation g ON g.emp_designation_id=m.emp_master_designation_id
 JOIN emp_category c ON c.emp_category_id=m.emp_master_category_id LEFT JOIN nationality n ON n.nationality_id=m.emp_master_nationality_id`;

export async function handleEmployees(req,res,path,user,body,reply){
 if(path!==base&&!path.startsWith(base+'/'))return false;
 if(path===base+'/options'&&req.method==='GET'){
  const options={};await Promise.all(Object.entries(employeeMasters).map(async([key,spec])=>{options[key]=(await pool.query(`SELECT * FROM ${spec.table} ORDER BY ${spec.name}`)).rows;}));
  options.nationalities=(await pool.query('SELECT nationality_id,nationality_name FROM nationality ORDER BY nationality_name')).rows;
  options.next_employee_id=(await pool.query('SELECT COALESCE(MAX(emp_unique_id),0)+1 AS next FROM emp_info')).rows[0].next;
  reply(res,200,options);return true;
 }
 const master=path.match(/^\/api\/admin\/employees\/masters\/(department|designation|category)(?:\/(\d+))?$/);
 if(master){
  const [,kind,id]=master,spec=employeeMasters[kind];
  if(req.method==='GET'&&!id){reply(res,200,{records:(await pool.query(`SELECT * FROM ${spec.table} ORDER BY ${spec.id} DESC`)).rows});return true;}
  if(req.method==='DELETE'&&id){const result=await pool.query(`DELETE FROM ${spec.table} WHERE ${spec.id}=$1 RETURNING ${spec.id}`,[id]);reply(res,result.rowCount?200:404,result.rowCount?{ok:true}:{error:spec.label+' not found.'});return true;}
  if((req.method==='POST'&&!id)||(req.method==='PATCH'&&id)){
   const input=await body(req),name=text(input?.name,spec.label+' Name',spec.max,true),alias=text(input?.alias,spec.label+' Alias',10,true);
   if(kind==='category'&&typeof input.is_teaching!=='boolean')fail('Choose whether this is a teaching category.');
   const client=await pool.connect();try{await client.query('BEGIN');
    let previous;if(id){previous=(await client.query(`SELECT * FROM ${spec.table} WHERE ${spec.id}=$1 FOR UPDATE`,[id])).rows[0];if(!previous){await client.query('ROLLBACK');reply(res,404,{error:spec.label+' not found.'});return true;}}
    if(kind==='category'&&previous&&previous.is_teaching!==input.is_teaching&&(await client.query('SELECT emp_master_id FROM emp_master WHERE emp_master_category_id=$1',[id])).rowCount)fail('This category is assigned to employees. Change their categories before changing its teaching status.');
    const values=kind==='category'?[name,alias,user.user_id,input.is_teaching]:[name,alias,user.user_id];let result;
    if(id)result=await client.query(`UPDATE ${spec.table} SET ${spec.name}=$1,${spec.alias}=$2,updated_by=$3,updated_at=NOW()${kind==='category'?',is_teaching=$4':''} WHERE ${spec.id}=$${values.length+1} RETURNING ${spec.id}`,[...values,id]);
    else result=await client.query(`INSERT INTO ${spec.table}(${spec.name},${spec.alias},created_by${kind==='category'?',is_teaching':''}) VALUES(${values.map((_,index)=>'$'+(index+1)).join(',')}) RETURNING ${spec.id}`,values);
    if(kind==='department'&&id)await client.query('UPDATE faculty f SET department=$2 FROM emp_master m WHERE m.emp_master_user_id=f.user_id AND m.emp_master_department_id=$1',[id,name]);
    await client.query('COMMIT');reply(res,id?200:201,{ok:true,id:result.rows[0][spec.id]});
   }catch(error){await client.query('ROLLBACK');throw error;}finally{client.release();}return true;
  }
  reply(res,405,{error:'Method not allowed.'});return true;
 }
 if((path===base||path===base+'/deleted')&&req.method==='GET'){
  const {rows}=await pool.query(listQuery+` WHERE m.deleted_at IS ${path.endsWith('/deleted')?'NOT ':''}NULL ORDER BY m.emp_master_id DESC`);reply(res,200,{records:rows});return true;
 }
 const record=path.match(/^\/api\/admin\/employees\/(\d+)(?:\/(login|password|restore))?$/);
 if(record&&req.method==='GET'&&!record[2]){const row=(await pool.query(listQuery+' WHERE m.emp_master_id=$1',[record[1]])).rows[0];reply(res,row?200:404,row?{employee:row}:{error:'Employee not found.'});return true;}
 if(record&&(req.method==='DELETE'||(record[2]&&req.method==='POST'))){
  if(req.method==='DELETE'&&record[2]){reply(res,405,{error:'Method not allowed.'});return true;}
  const input=req.method==='POST'?await body(req):{};const action=record[2]||'delete';
  let username,passwordHash;
  if(action==='login'){username=text(input?.username,'User Login ID',100,true,false);if(username.length<3||!/^[A-Za-z0-9._@+-]+$/.test(username))fail('Enter a login ID of 3–100 letters, numbers or . _ @ + - characters.');}
  if(action==='password'){if(typeof input?.password!=='string'||input.password.length<8||input.password.length>1024)fail('Enter a password of 12–1024 characters.');passwordHash=await hashPassword(input.password);}
  const client=await pool.connect();try{await client.query('BEGIN');
   const row=(await client.query('SELECT * FROM emp_master WHERE emp_master_id=$1 FOR UPDATE',[record[1]])).rows[0];
   if(!row||(action==='restore'?!row.deleted_at:!!row.deleted_at)){await client.query('ROLLBACK');reply(res,404,{error:'Employee not found in this list.'});return true;}
   if(String(row.emp_master_user_id)===String(user.user_id))fail('Use your own account settings to change your account.');
   if(action==='login')await client.query('UPDATE users SET username=$1,updated_at=NOW() WHERE user_id=$2',[username,row.emp_master_user_id]);
   else if(action==='password')await client.query('UPDATE users SET password_hash=$1,updated_at=NOW() WHERE user_id=$2',[passwordHash,row.emp_master_user_id]);
   else if(action==='delete'||action==='restore'){
    const restore=action==='restore';await client.query('UPDATE emp_master SET deleted_at='+ (restore?'NULL':'NOW()')+',deleted_by=$2,is_status=$3 WHERE emp_master_id=$1',[row.emp_master_id,restore?null:user.user_id,restore?1:0]);await client.query('UPDATE users SET is_active=$1,updated_at=NOW() WHERE user_id=$2',[restore,row.emp_master_user_id]);
   }
   await client.query('UPDATE emp_master SET updated_at=NOW(),updated_by=$2 WHERE emp_master_id=$1',[row.emp_master_id,user.user_id]);await client.query('DELETE FROM user_sessions WHERE user_id=$1',[row.emp_master_user_id]);
   await client.query('COMMIT');reply(res,200,{ok:true});
  }catch(error){await client.query('ROLLBACK');throw error;}finally{client.release();}return true;
 }
 if((path===base&&req.method==='POST')||(record&&!record[2]&&req.method==='PATCH')){
  const id=record?.[1],input=await body(req);if(!input||!positive(input.employee_id)||!positive(input.department_id)||!positive(input.category_id))fail('Enter Employee ID, Department and Category.');
  const first=text(input.first_name,'First Name',35,true),middle=text(input.middle_name,'Middle Name',35),last=text(input.last_name,'Last Name',35,true),fullName=[first,middle,last].filter(Boolean).join(' ');
  const email=text(input.email,'Email ID',65,false,false)?.toLowerCase()||null,mobile=text(input.mobile,'Mobile No',20,false,false);
  if(email&&!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email))fail('Enter a valid Email ID.');if(mobile&&!/^\+?[0-9]{7,15}$/.test(mobile))fail('Enter a valid Mobile No.');
  const dob=date(input.dob,'Date of Birth'),joining=date(input.joining_date,'Joining Date');if(dob&&joining&&dob>joining)fail('Joining Date must be after Date of Birth.');
  const years=Number(input.experience_year??0),months=Number(input.experience_month??0);if(!Number.isInteger(years)||years<0||years>80||!Number.isInteger(months)||months<0||months>11)fail('Enter valid experience years and months.');
  const info={emp_unique_id:Number(input.employee_id),employee_code:'EMP-'+input.employee_id,emp_title:text(input.title,'Title',15),emp_first_name:first,emp_middle_name:middle,emp_last_name:last,emp_name_alias:text(input.name_alias,'Name Alias',10),emp_gender:text(input.gender,'Gender',20),emp_dob:dob,emp_joining_date:joining,emp_email_id:email,emp_mobile_no:mobile,emp_maritalstatus:text(input.marital_status,'Marital Status',35),emp_experience_year:years,emp_experience_month:months};
  const caste=text(input.caste,'Caste',35);const temporaryPassword=id?null:randomBytes(18).toString('base64url');const initialHash=temporaryPassword?await hashPassword(temporaryPassword):null;
  const client=await pool.connect();try{await client.query('BEGIN');let existing;
   if(id){existing=(await client.query('SELECT * FROM emp_master WHERE emp_master_id=$1 AND deleted_at IS NULL FOR UPDATE',[id])).rows[0];if(!existing){await client.query('ROLLBACK');reply(res,404,{error:'Employee not found.'});return true;}}
   const department=(await client.query('SELECT * FROM emp_department WHERE emp_department_id=$1 FOR SHARE',[input.department_id])).rows[0],category=(await client.query('SELECT * FROM emp_category WHERE emp_category_id=$1 FOR SHARE',[input.category_id])).rows[0];
   if(!department||!category)fail('Select a saved Department and Category.');
   if(input.designation_id&&!(await client.query('SELECT emp_designation_id FROM emp_designation WHERE emp_designation_id=$1 FOR SHARE',[input.designation_id])).rowCount)fail('Select a saved Designation.');
   if(input.nationality_id&&!(await client.query('SELECT nationality_id FROM nationality WHERE nationality_id=$1 FOR SHARE',[input.nationality_id])).rowCount)fail('Select a saved Nationality.');
   if(existing&&!category.is_teaching&&(await client.query('SELECT shst_id FROM section_house_subject_teacher WHERE shst_teacher_id=$1 UNION ALL SELECT subjectteacher_id FROM subjectteacher WHERE subjectteacher_employee_id=$1 LIMIT 1',[existing.emp_master_user_id])).rowCount)fail('Remove subject and class assignments before moving this employee to a non-teaching category.');
   const role=(await client.query('SELECT role_id FROM user_roles WHERE role_name=$1',[category.is_teaching?'Faculty':'Employee'])).rows[0].role_id;
   let userId,infoId,login;
   if(existing){userId=existing.emp_master_user_id;infoId=existing.emp_master_emp_info_id;const entries=Object.entries(info);await client.query(`UPDATE emp_info SET ${entries.map(([key],index)=>key+'=$'+(index+1)).join(',')} WHERE emp_info_id=$${entries.length+1}`,[...entries.map(([,value])=>value),infoId]);await client.query('UPDATE users SET full_name=$1,email=$2,mobile=$3,role_id=$4,updated_at=NOW() WHERE user_id=$5',[fullName,email,mobile,role,userId]);await client.query('DELETE FROM user_sessions WHERE user_id=$1',[userId]);}
   else{login=email||'EMP-'+input.employee_id;userId=(await client.query('INSERT INTO users(role_id,username,password_hash,full_name,email,mobile) VALUES($1,$2,$3,$4,$5,$6) RETURNING user_id',[role,login,initialHash,fullName,email,mobile])).rows[0].user_id;const entries=Object.entries(info);infoId=(await client.query(`INSERT INTO emp_info(${entries.map(([key])=>key).join(',')}) VALUES(${entries.map((_,index)=>'$'+(index+1)).join(',')}) RETURNING emp_info_id`,entries.map(([,value])=>value))).rows[0].emp_info_id;}
   if(category.is_teaching)await client.query('INSERT INTO faculty(user_id,employee_code,department) VALUES($1,$2,$3) ON CONFLICT(user_id) DO UPDATE SET employee_code=EXCLUDED.employee_code,department=EXCLUDED.department',[userId,info.employee_code,department.emp_department_name]);
   else await client.query('DELETE FROM faculty WHERE user_id=$1',[userId]);
   let result;if(existing)result=await client.query('UPDATE emp_master SET emp_master_department_id=$1,emp_master_designation_id=$2,emp_master_category_id=$3,emp_master_nationality_id=$4,emp_cast=$5,updated_at=NOW(),updated_by=$6 WHERE emp_master_id=$7 RETURNING emp_master_id',[input.department_id,input.designation_id||null,input.category_id,input.nationality_id||null,caste,user.user_id,id]);
   else result=await client.query('INSERT INTO emp_master(emp_master_emp_info_id,emp_master_user_id,emp_master_department_id,emp_master_designation_id,emp_master_category_id,emp_master_nationality_id,emp_cast,created_by) VALUES($1,$2,$3,$4,$5,$6,$7,$8) RETURNING emp_master_id',[infoId,userId,input.department_id,input.designation_id||null,input.category_id,input.nationality_id||null,caste,user.user_id]);
   await client.query('COMMIT');reply(res,id?200:201,{ok:true,id:result.rows[0].emp_master_id,...(!id?{login_id:login,temporary_password:temporaryPassword,account_type:category.is_teaching?'Faculty':'Employee'}:{})});
  }catch(error){await client.query('ROLLBACK');throw error;}finally{client.release();}return true;
 }
 reply(res,405,{error:'Method not allowed.'});return true;
}
