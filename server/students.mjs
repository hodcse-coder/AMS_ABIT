import {randomBytes} from 'node:crypto';
import {pool} from './db.mjs';
import {hashPassword} from './passwords.mjs';
import {studentFields,studentDefaults,studentSections,studentImportColumns} from '../shared/students.mjs';
import {courseSemesterCount} from '../shared/course-semesters.mjs';
import {attendanceWorkbook} from '../shared/attendance-export.mjs';
import {parseStudentImport} from './student-import.mjs';
const base='/api/admin/students';
const fail=message=>{throw Object.assign(new Error(message),{status:400});};
const positive=value=>Number.isSafeInteger(Number(value))&&Number(value)>0;
const today=()=>{const parts=new Intl.DateTimeFormat('en-CA',{timeZone:'Asia/Kolkata',year:'numeric',month:'2-digit',day:'2-digit'}).formatToParts(new Date());return ['year','month','day'].map(key=>parts.find(part=>part.type===key).value).join('-');};
const listQuery=`SELECT m.stu_master_id,m.stu_master_user_id,m.stu_master_course_id,m.stu_master_batch_id,m.stu_master_section_id,m.stu_master_stu_status_id,m.stu_master_category_id,m.semester_registered,m.deleted_at,
 i.stu_unique_id,i.stu_first_name,i.stu_middle_name,i.stu_last_name,u.username,u.is_active,c.course_name,c.course_code,b.batch_name,s.section_name,t.stu_status_name,t.allows_login,k.stu_category_name
 FROM stu_master m JOIN stu_info i ON i.stu_info_id=m.stu_master_stu_info_id JOIN users u ON u.user_id=m.stu_master_user_id
 JOIN courses c ON c.course_id=m.stu_master_course_id JOIN batches b ON b.batch_id=m.stu_master_batch_id JOIN section s ON s.s_id=m.stu_master_section_id
 JOIN stu_status t ON t.stu_status_id=m.stu_master_stu_status_id JOIN stu_category k ON k.stu_category_id=m.stu_master_category_id`;
function validate(input){
 if(!input||typeof input!=='object'||Array.isArray(input))fail('Provide the student details.');const defaults=studentDefaults(),values={};
 for(const field of studentFields){let value=input[field.key]??defaults[field.key]??'';if(typeof value!=='string'&&typeof value!=='number')fail('Enter a valid '+field.label+'.');value=String(value).trim();
  if(!value){if(field.required)fail(field.label+' is required.');values[field.key]=null;continue;}
  if(field.type==='reference'||field.type==='semester'){if(!positive(value))fail('Choose a valid '+field.label+'.');values[field.key]=Number(value);continue;}
  if(field.type==='number'){const number=Number(value);if(!Number.isFinite(number)||number<(field.min??0)||number>(field.maxValue??100000000))fail('Enter a valid '+field.label+'.');values[field.key]=number;continue;}
  if(value.length>field.max)fail(field.label+' is too long.');
  if(field.type==='email'&&!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value))fail('Enter a valid '+field.label+'.');
  if(field.type==='tel'&&!/^\+?[0-9 ()-]{7,25}$/.test(value))fail('Enter a valid '+field.label+'.');
  if(field.type==='date'&&(!/^\d{4}-\d{2}-\d{2}$/.test(value)||!Number.isFinite(Date.parse(value+'T00:00:00Z'))||new Date(value+'T00:00:00Z').toISOString().slice(0,10)!==value))fail('Enter a valid '+field.label+'.');
  if(field.type==='select'&&!field.options.some(([key])=>String(key)===value))fail('Choose a valid '+field.label+'.');
  values[field.key]=field.upper?value.toUpperCase():field.type==='email'?value.toLowerCase():value;
 }
 if(values.dob>=today())fail('Date of Birth must be before the current date.');
 if(values.aadhaar&&!/^\d{12}$/.test(values.aadhaar))fail('Aadhaar No. must contain 12 digits.');
 if(values.court_proceedings==='Y'&&!values.court_details)fail('Enter the court proceedings details.');
 if(values.chronic_ailments==='Y'&&!values.chronic_details)fail('Enter the chronic ailments details.');
 return values;
}
async function references(client,v){
 const course=(await client.query('SELECT course_duration FROM courses WHERE course_id=$1 FOR SHARE',[v.course_id])).rows[0];
 if(!course||v.semester>courseSemesterCount(course.course_duration))fail('Choose a Semester within the selected Course duration.');
 if(!(await client.query('SELECT batch_id FROM batches WHERE batch_id=$1 AND batch_course_id=$2 FOR SHARE',[v.batch_id,v.course_id])).rowCount)fail('Choose a Batch belonging to the Course.');
 if(!(await client.query('SELECT s_id FROM section WHERE s_id=$1 AND section_batch_id=$2 FOR SHARE',[v.section_id,v.batch_id])).rowCount)fail('Choose a Section belonging to the Batch.');
 if(!(await client.query('SELECT stu_category_id FROM stu_category WHERE stu_category_id=$1 FOR SHARE',[v.admission_category_id])).rowCount)fail('Select a saved Admission Category.');
 if(v.nationality_id&&!(await client.query('SELECT nationality_id FROM nationality WHERE nationality_id=$1 FOR SHARE',[v.nationality_id])).rowCount)fail('Select a saved Nationality.');
 for(const prefix of ['current','permanent']){
  const country=v[prefix+'_country_id'],state=v[prefix+'_state_id'],city=v[prefix+'_city_id'];
  if(country&&!(await client.query('SELECT country_id FROM country WHERE country_id=$1 FOR SHARE',[country])).rowCount)fail('Choose a saved Country.');
  if(state&&(!country||!(await client.query('SELECT state_id FROM state WHERE state_id=$1 AND state_country_id=$2 FOR SHARE',[state,country])).rowCount))fail('Choose a State belonging to the selected Country.');
  if(city&&(!state||!(await client.query('SELECT city_id FROM city WHERE city_id=$1 AND city_state_id=$2 AND city_country_id=$3 FOR SHARE',[city,state,country])).rowCount))fail('Choose a City belonging to the selected State and Country.');
 }
}
const pick=(v,keys)=>Object.fromEntries(keys.map(key=>[key,v[key]]));
async function saveStudent(client,input,actor,id){
 const v=validate(input);await references(client,v);let existing;
 if(id){existing=(await client.query('SELECT * FROM stu_master WHERE stu_master_id=$1 AND deleted_at IS NULL FOR UPDATE',[id])).rows[0];if(!existing)throw Object.assign(new Error('Student not found.'),{status:404});}
 const fullName=[v.first_name,v.middle_name,v.last_name].filter(Boolean).join(' ');if(fullName.length>150)fail('The combined student name must be at most 150 characters.');
 const password=existing?null:randomBytes(18).toString('base64url');let registration,userId,infoId;
 if(existing){userId=existing.stu_master_user_id;infoId=existing.stu_master_stu_info_id;registration=(await client.query('SELECT stu_unique_id FROM stu_info WHERE stu_info_id=$1',[infoId])).rows[0].stu_unique_id;}
 else{
  const sequence=(await client.query("SELECT nextval('student_registration_seq') AS number")).rows[0].number;
  const org=(await client.query('SELECT org_stu_prefix FROM organization ORDER BY org_id LIMIT 1')).rows[0];
  registration=(org?.org_stu_prefix||'ST').replace(/[^A-Za-z0-9]/g,'').slice(0,10).toUpperCase()+today().slice(2,4)+String(sequence).padStart(6,'0');
  const role=(await client.query("SELECT role_id FROM user_roles WHERE role_name='Student'")).rows[0].role_id;
  userId=(await client.query('INSERT INTO users(role_id,username,password_hash,full_name,email,mobile) VALUES($1,$2,$3,$4,$5,$6) RETURNING user_id',[role,registration,await hashPassword(password),fullName,v.domain_email||v.email,v.mobile])).rows[0].user_id;
  await client.query('INSERT INTO students(user_id,admission_number,semester) VALUES($1,$2,$3)',[userId,registration,v.semester]);
 }
 const details=pick(v,studentSections[0].fields.map(field=>field.key));
 const infoValues=[v.first_name,v.middle_name,v.last_name,v.dob,v.email,v.domain_email,v.mobile,JSON.stringify(details)];
 if(existing){await client.query('UPDATE stu_info SET stu_first_name=$1,stu_middle_name=$2,stu_last_name=$3,stu_dob=$4,stu_email_id=$5,stu_domain_email_id=$6,stu_mobile_no=$7,details=$8::jsonb WHERE stu_info_id=$9',[...infoValues,infoId]);await client.query('UPDATE users SET full_name=$1,email=$2,mobile=$3,updated_at=NOW() WHERE user_id=$4',[fullName,v.domain_email||v.email,v.mobile,userId]);await client.query('UPDATE students SET semester=$1 WHERE user_id=$2',[v.semester,userId]);}
 else infoId=(await client.query('INSERT INTO stu_info(stu_first_name,stu_middle_name,stu_last_name,stu_dob,stu_email_id,stu_domain_email_id,stu_mobile_no,details,stu_unique_id) VALUES($1,$2,$3,$4,$5,$6,$7,$8::jsonb,$9) RETURNING stu_info_id',[...infoValues,registration])).rows[0].stu_info_id;
 const group=title=>pick(v,studentSections.find(section=>section.title===title).fields.map(field=>field.key));
 const masterValues=[v.admission_category_id,v.nationality_id,v.course_id,v.batch_id,v.section_id,v.semester,Number(v.allotment_status),JSON.stringify(group('Academics Details')),JSON.stringify(group('Entrance Examination Details')),JSON.stringify(group('Other Paid Preference Details')),actor.user_id];
 let masterId;
 if(existing){masterId=existing.stu_master_id;await client.query('UPDATE stu_master SET stu_master_category_id=$1,stu_master_nationality_id=$2,stu_master_course_id=$3,stu_master_batch_id=$4,stu_master_section_id=$5,semester_registered=$6,allotment_status=$7,academic_details=$8::jsonb,entrance_details=$9::jsonb,paid_preferences=$10::jsonb,updated_by=$11,updated_at=NOW() WHERE stu_master_id=$12',[...masterValues,masterId]);}
 else{const active=(await client.query("SELECT stu_status_id FROM stu_status WHERE stu_status_name='Active'")).rows[0].stu_status_id;masterId=(await client.query('INSERT INTO stu_master(stu_master_category_id,stu_master_nationality_id,stu_master_course_id,stu_master_batch_id,stu_master_section_id,semester_registered,allotment_status,academic_details,entrance_details,paid_preferences,created_by,stu_master_stu_info_id,stu_master_user_id,stu_master_stu_status_id) VALUES($1,$2,$3,$4,$5,$6,$7,$8::jsonb,$9::jsonb,$10::jsonb,$11,$12,$13,$14) RETURNING stu_master_id',[...masterValues,infoId,userId,active])).rows[0].stu_master_id;}
 await client.query('INSERT INTO course_students(user_id,course_id,batch_id,section_id) VALUES($1,$2,$3,$4) ON CONFLICT(user_id) DO UPDATE SET course_id=EXCLUDED.course_id,batch_id=EXCLUDED.batch_id,section_id=EXCLUDED.section_id',[userId,v.course_id,v.batch_id,v.section_id]);
 for(const kind of ['current','permanent'])await client.query('INSERT INTO stu_address(student_id,address_type,address_text,country_id,state_id,city_id,pincode,house_no,phone_no) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9) ON CONFLICT(student_id,address_type) DO UPDATE SET address_text=EXCLUDED.address_text,country_id=EXCLUDED.country_id,state_id=EXCLUDED.state_id,city_id=EXCLUDED.city_id,pincode=EXCLUDED.pincode,house_no=EXCLUDED.house_no,phone_no=EXCLUDED.phone_no',[masterId,kind,v[kind+'_address'],v[kind+'_country_id'],v[kind+'_state_id'],v[kind+'_city_id'],v[kind+'_pincode'],v[kind+'_house_no'],v[kind+'_phone']]);
 for(const kind of ['father','mother'])await client.query('INSERT INTO stu_guardians(guardia_stu_master_id,guardian_relation,guardian_name,guardian_mobile_no,guardian_whatsapp_no,guardian_email,guardian_occupation,guardian_income) VALUES($1,$2,$3,$4,$5,$6,$7,$8) ON CONFLICT(guardia_stu_master_id,guardian_relation) DO UPDATE SET guardian_name=EXCLUDED.guardian_name,guardian_mobile_no=EXCLUDED.guardian_mobile_no,guardian_whatsapp_no=EXCLUDED.guardian_whatsapp_no,guardian_email=EXCLUDED.guardian_email,guardian_occupation=EXCLUDED.guardian_occupation,guardian_income=EXCLUDED.guardian_income',[masterId,kind,v[kind+'_name'],v[kind+'_mobile'],v[kind+'_whatsapp'],v[kind+'_email'],v[kind+'_occupation'],v[kind+'_income']]);
 if(existing)await client.query('DELETE FROM user_sessions WHERE user_id=$1',[userId]);
 return {id:masterId,registration_no:registration,...(!existing?{login_id:registration,temporary_password:password}:{})};
}
export async function handleStudents(req,res,path,actor,body,reply){
 if(path!==base&&!path.startsWith(base+'/'))return false;
 if(path===base+'/options'&&req.method==='GET'){
  const queries={courses:'SELECT course_id,course_name,course_code,course_duration FROM courses ORDER BY course_name',batches:'SELECT batch_id,batch_name,batch_course_id FROM batches ORDER BY batch_name',sections:'SELECT s_id,section_name,section_batch_id FROM section ORDER BY section_name',categories:'SELECT * FROM stu_category ORDER BY stu_category_name',statuses:'SELECT * FROM stu_status ORDER BY stu_status_id',nationalities:'SELECT nationality_id,nationality_name FROM nationality ORDER BY nationality_name',countries:'SELECT country_id,country_name FROM country ORDER BY country_name',states:'SELECT state_id,state_name,state_country_id FROM state ORDER BY state_name',cities:'SELECT city_id,city_name,city_state_id,city_country_id FROM city ORDER BY city_name'};
  const options={};await Promise.all(Object.entries(queries).map(async([key,sql])=>{options[key]=(await pool.query(sql)).rows;}));reply(res,200,options);return true;
 }
 if(path===base+'/import/template'&&req.method==='GET'){const bytes=Buffer.from(attendanceWorkbook([],studentImportColumns,'Students'));res.writeHead(200,{'Content-Type':'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','Content-Disposition':'attachment; filename="Student-Import-Template.xlsx"','Content-Length':bytes.length,'Cache-Control':'no-store'});res.end(bytes);return true;}
 const category=path.match(/^\/api\/admin\/students\/categories(?:\/(\d+))?$/);
 if(category){const id=category[1];
  if(req.method==='GET'&&!id){reply(res,200,{records:(await pool.query('SELECT * FROM stu_category ORDER BY stu_category_id DESC')).rows});return true;}
  if(req.method==='DELETE'&&id){const result=await pool.query('DELETE FROM stu_category WHERE stu_category_id=$1 RETURNING stu_category_id',[id]);reply(res,result.rowCount?200:404,result.rowCount?{ok:true}:{error:'Admission Category not found.'});return true;}
  if((req.method==='POST'&&!id)||(req.method==='PATCH'&&id)){const input=await body(req),name=typeof input?.name==='string'?input.name.trim().toUpperCase():'';if(!name||name.length>50)fail('Enter an Admission Category of up to 50 characters.');const result=id?await pool.query('UPDATE stu_category SET stu_category_name=$1,updated_at=NOW(),updated_by=$2 WHERE stu_category_id=$3 RETURNING stu_category_id',[name,actor.user_id,id]):await pool.query('INSERT INTO stu_category(stu_category_name,created_by) VALUES($1,$2) RETURNING stu_category_id',[name,actor.user_id]);reply(res,result.rowCount?(id?200:201):404,result.rowCount?{ok:true,id:result.rows[0].stu_category_id}:{error:'Admission Category not found.'});return true;}
  reply(res,405,{error:'Method not allowed.'});return true;
 }
 if((path===base||path===base+'/deleted')&&req.method==='GET'){reply(res,200,{records:(await pool.query(listQuery+' WHERE m.deleted_at IS '+(path.endsWith('/deleted')?'NOT ':'')+'NULL ORDER BY m.stu_master_id DESC')).rows});return true;}
 const match=path.match(/^\/api\/admin\/students\/(\d+)(?:\/(status|registration|login|password|restore))?$/);
 if(match&&req.method==='GET'&&!match[2]){
  const m=(await pool.query('SELECT m.*,i.details,i.stu_unique_id FROM stu_master m JOIN stu_info i ON i.stu_info_id=m.stu_master_stu_info_id WHERE m.stu_master_id=$1',[match[1]])).rows[0];if(!m){reply(res,404,{error:'Student not found.'});return true;}
  const form={...m.details,...m.academic_details,...m.entrance_details,...m.paid_preferences,course_id:m.stu_master_course_id,batch_id:m.stu_master_batch_id,section_id:m.stu_master_section_id,semester:m.semester_registered,admission_category_id:m.stu_master_category_id,nationality_id:m.stu_master_nationality_id,allotment_status:String(m.allotment_status)};
  for(const address of (await pool.query('SELECT * FROM stu_address WHERE student_id=$1',[m.stu_master_id])).rows){const k=address.address_type;Object.assign(form,{[k+'_address']:address.address_text,[k+'_country_id']:address.country_id,[k+'_state_id']:address.state_id,[k+'_city_id']:address.city_id,[k+'_pincode']:address.pincode,[k+'_house_no']:address.house_no,[k+'_phone']:address.phone_no});}
  for(const g of (await pool.query('SELECT * FROM stu_guardians WHERE guardia_stu_master_id=$1',[m.stu_master_id])).rows){const k=g.guardian_relation;Object.assign(form,{[k+'_name']:g.guardian_name,[k+'_mobile']:g.guardian_mobile_no,[k+'_whatsapp']:g.guardian_whatsapp_no,[k+'_email']:g.guardian_email,[k+'_occupation']:g.guardian_occupation,[k+'_income']:g.guardian_income});}
  reply(res,200,{id:m.stu_master_id,registration_no:m.stu_unique_id,form});return true;
 }
 if(path===base+'/import'&&req.method==='POST'){
  const input=await body(req),rows=parseStudentImport(input?.file_name||'',input?.file_base64,new Set(studentFields.map(field=>field.key)));
  const client=await pool.connect();try{await client.query('BEGIN');const credentials=[];for(const [index,row] of rows.entries()){try{const merged={...(input.defaults||{})};for(const [key,value] of Object.entries(row))if(value!=='')merged[key]=value;credentials.push(await saveStudent(client,merged,actor));}catch(error){throw Object.assign(new Error(`Row ${index+2}: ${error.code==='23505'?'Duplicate registration or account email.':error.status?error.message:'Unable to save this row.'} No students were imported.`),{status:400});}}await client.query('COMMIT');reply(res,201,{ok:true,count:credentials.length,credentials});}catch(error){await client.query('ROLLBACK');throw error;}finally{client.release();}return true;
 }
 if((path===base&&req.method==='POST')||(match&&!match[2]&&req.method==='PATCH')){const input=await body(req),client=await pool.connect();try{await client.query('BEGIN');const result=await saveStudent(client,input,actor,match?.[1]);await client.query('COMMIT');reply(res,match?200:201,{ok:true,...result});}catch(error){await client.query('ROLLBACK');throw error;}finally{client.release();}return true;}
 if(match&&((req.method==='DELETE'&&!match[2])||(req.method==='POST'&&match[2]))){
  const action=match[2]||'delete',input=req.method==='POST'?await body(req):{};let value,hash;
  if(action==='login'||action==='registration'){value=typeof input?.value==='string'?input.value.trim():'';if(action==='registration')value=value.toUpperCase();if(!value||value.length>(action==='login'?100:50)||!/^[A-Za-z0-9._@+\/-]+$/.test(value)||(action==='login'&&value.length<3))fail('Enter a valid '+(action==='login'?'Login ID':'Registration No.')+'.');}
  if(action==='password'){if(typeof input?.password!=='string'||input.password.length<8||input.password.length>1024)fail('Enter a password of 12–1024 characters.');hash=await hashPassword(input.password);}
  const client=await pool.connect();try{await client.query('BEGIN');const m=(await client.query('SELECT m.*,s.allows_login FROM stu_master m JOIN stu_status s ON s.stu_status_id=m.stu_master_stu_status_id WHERE m.stu_master_id=$1 FOR UPDATE OF m',[match[1]])).rows[0];
   if(!m||(action==='restore'?!m.deleted_at:!!m.deleted_at)){await client.query('ROLLBACK');reply(res,404,{error:'Student not found in this list.'});return true;}
   if(action==='status'){if(!positive(input?.status_id))fail('Choose a Student Status.');const status=(await client.query('SELECT * FROM stu_status WHERE stu_status_id=$1',[input.status_id])).rows[0];if(!status)fail('Choose a saved Student Status.');await client.query('UPDATE stu_master SET stu_master_stu_status_id=$2 WHERE stu_master_id=$1',[m.stu_master_id,status.stu_status_id]);await client.query('UPDATE users SET is_active=$1,updated_at=NOW() WHERE user_id=$2',[status.allows_login,m.stu_master_user_id]);}
   else if(action==='registration'){await client.query('UPDATE stu_info SET stu_unique_id=$1 WHERE stu_info_id=$2',[value,m.stu_master_stu_info_id]);await client.query('UPDATE students SET admission_number=$1 WHERE user_id=$2',[value,m.stu_master_user_id]);}
   else if(action==='login')await client.query('UPDATE users SET username=$1,updated_at=NOW() WHERE user_id=$2',[value,m.stu_master_user_id]);
   else if(action==='password')await client.query('UPDATE users SET password_hash=$1,updated_at=NOW() WHERE user_id=$2',[hash,m.stu_master_user_id]);
   else{const restore=action==='restore';await client.query('UPDATE stu_master SET deleted_at='+(restore?'NULL':'NOW()')+',deleted_by=$2 WHERE stu_master_id=$1',[m.stu_master_id,restore?null:actor.user_id]);await client.query('UPDATE users SET is_active=$1,updated_at=NOW() WHERE user_id=$2',[restore&&m.allows_login,m.stu_master_user_id]);}
   await client.query('UPDATE stu_master SET updated_at=NOW(),updated_by=$2 WHERE stu_master_id=$1',[m.stu_master_id,actor.user_id]);await client.query('DELETE FROM user_sessions WHERE user_id=$1',[m.stu_master_user_id]);await client.query('COMMIT');reply(res,200,{ok:true});
  }catch(error){await client.query('ROLLBACK');throw error;}finally{client.release();}return true;
 }
 reply(res,405,{error:'Method not allowed.'});return true;
}
