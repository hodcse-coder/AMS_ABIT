import {handleBranches} from './branches.mjs';
import { pool } from './db.mjs';
import { handleAcademics } from './academics.mjs';
import { handleSectionAssignments } from './sections.mjs';
const courseQuery=`SELECT c.*, (SELECT COUNT(*)::int FROM batches b WHERE b.batch_course_id=c.course_id) AS batch_count,(SELECT COUNT(*)::int FROM course_students s WHERE s.course_id=c.course_id) AS student_count FROM courses c ORDER BY c.course_id`;
const invalid=message=>{throw Object.assign(new Error(message),{status:400});};
function text(input,key,max,required=true){const value=typeof input[key]==='string'?input[key].trim().toUpperCase():'';if((required&&!value)||value.length>max)invalid(`Enter a valid ${key.replaceAll('_',' ')} (up to ${max} characters).`);return value||null;}
function integer(value,label,min=0){if(value===null||value===undefined||value===''||!Number.isInteger(Number(value))||Number(value)<min||Number(value)>2147483647)invalid(`Enter a valid ${label}.`);return Number(value);}
function date(value,label){if(typeof value!=='string'||!/^\d{4}-\d{2}-\d{2}$/.test(value)||!Number.isFinite(Date.parse(value+'T00:00:00Z'))||new Date(value+'T00:00:00Z').toISOString().slice(0,10)!==value)invalid(`Enter a valid ${label}.`);return value;}
function batchValues(input){const name=text(input,'batch_name',120),alias=text(input,'batch_alias',35),start=date(input.start_date,'start date'),end=date(input.end_date,'end date');if(end<start)invalid('End Date must be on or after Start Date.');return {name,alias,start,end};}
async function insertBatch(client,input,courseId,userId){const b=batchValues(input);const result=await client.query('INSERT INTO batches(batch_name,batch_alias,batch_course_id,start_date,end_date,created_by,is_status) VALUES($1,$2,$3,$4,$5,$6,1) RETURNING batch_id',[b.name,b.alias,courseId,b.start,b.end,userId]);return result.rows[0].batch_id;}
export async function handleCourses(req,res,path,user,body,reply){
 if(!path.startsWith('/api/admin/course-modules'))return false;
 if(await handleBranches(req,res,path,user,body,reply))return true;
 if(await handleAcademics(req,res,path,user,body,reply))return true;
 if(await handleSectionAssignments(req,res,path,user,body,reply))return true;
 const base='/api/admin/course-modules';
 if(path===base&&req.method==='GET'){
  const courses=(await pool.query(courseQuery)).rows;
  const batches=(await pool.query('SELECT b.*,b.batch_course_id AS course_id,b.start_date::text AS start_date,b.end_date::text AS end_date,c.course_name FROM batches b JOIN courses c ON c.course_id=b.batch_course_id ORDER BY b.batch_id')).rows;
  const sections=(await pool.query('SELECT s.*,s.s_id AS section_id,s.section_batch_id AS batch_id,b.batch_name,c.course_name FROM section s JOIN batches b ON b.batch_id=s.section_batch_id JOIN courses c ON c.course_id=b.batch_course_id ORDER BY s.s_id')).rows;
  reply(res,200,{courses,batches,sections});return true;
 }
 const studentMatch=path.match(/^\/api\/admin\/course-modules\/courses\/(\d+)\/students$/);
 if(studentMatch&&req.method==='GET'){const {rows}=await pool.query('SELECT u.user_id,u.full_name,u.username,b.batch_name FROM course_students cs JOIN users u USING(user_id) LEFT JOIN batches b USING(batch_id) WHERE cs.course_id=$1 ORDER BY u.full_name',[studentMatch[1]]);reply(res,200,{students:rows});return true;}
 const settings=path.match(/^\/api\/admin\/course-modules\/batches\/(\d+)\/settings$/);
 if(settings&&req.method==='PATCH'){
  const input=await body(req),allowed=['is_status','is_eligible_alumnisurvey','is_eligible_exitsurvey'];
  const names=Object.keys(input);
  if(!names.length||names.some(name=>!allowed.includes(name)||![0,1].includes(input[name])))invalid('Select a valid status or survey eligibility.');
  const values=names.map(name=>input[name]);values.push(user.user_id,settings[1]);
  const result=await pool.query(`UPDATE batches SET ${names.map((name,index)=>`${name}=$${index+1}`).join(',')},updated_at=NOW(),updated_by=$${values.length-1} WHERE batch_id=$${values.length} RETURNING batch_id`,values);
  reply(res,result.rowCount?200:404,result.rowCount?{ok:true}:{error:'Batch not found.'});return true;
 }
 const match=path.match(/^\/api\/admin\/course-modules\/(courses|batches|sections)(?:\/(\d+))?$/);
 if(!match){reply(res,404,{error:'Course module not found.'});return true;}
 const [,resource,id]=match;
 if(resource==='batches'&&id&&req.method==='DELETE'){const result=await pool.query('DELETE FROM batches WHERE batch_id=$1 RETURNING batch_id',[id]);reply(res,result.rowCount?200:404,result.rowCount?{ok:true}:{error:'Batch not found.'});return true;}
 if(resource==='batches'&&id&&req.method==='PATCH'){
  const input=await body(req),b=batchValues(input),courseId=integer(input.batch_course_id??input.course_id,'course',1);
  if(input.is_status!==undefined&&![0,1].includes(input.is_status))invalid('Select a valid batch status.');
  const result=await pool.query('UPDATE batches SET batch_name=$1,batch_alias=$2,batch_course_id=$3,start_date=$4,end_date=$5,is_status=COALESCE($6,is_status),updated_at=NOW(),updated_by=$7 WHERE batch_id=$8 RETURNING batch_id',[b.name,b.alias,courseId,b.start,b.end,input.is_status??null,user.user_id,id]);
  reply(res,result.rowCount?200:404,result.rowCount?{ok:true,id}:{error:'Batch not found.'});return true;
 }
 if(resource==='courses'&&id&&req.method==='DELETE'){const result=await pool.query('DELETE FROM courses WHERE course_id=$1 RETURNING course_id',[id]);reply(res,result.rowCount?200:404,result.rowCount?{ok:true}:{error:'Course not found.'});return true;}
 if((req.method==='POST'&&!id)||(req.method==='PATCH'&&id&&resource==='courses')){
  const input=await body(req);
  if(resource==='courses'){
   const name=text(input,'course_name',100),code=text(input,'course_code',50),alias=text(input,'course_alias',35),duration=integer(input.course_duration,'duration in years',1);
   if(input.is_active!==undefined&&typeof input.is_active!=='boolean')invalid('Select a valid course status.');
   if(id){const result=await pool.query('UPDATE courses SET course_name=$1,course_code=$2,course_alias=$3,course_duration=$4,is_active=$5,is_status=$6,updated_at=NOW(),updated_by=$7 WHERE course_id=$8 RETURNING course_id',[name,code,alias,duration,input.is_active??true,input.is_active===false?0:1,user.user_id,id]);reply(res,result.rowCount?200:404,result.rowCount?{ok:true,id}:{error:'Course not found.'});return true;}
   batchValues(input);
   const sectionName=text(input,'section_name',50,false);
   const intake=input.intake!==undefined&&input.intake!==''?integer(input.intake,'intake'):null;
   if(intake!==null&&!sectionName)invalid('Enter Section Name when specifying Intake.');
   const client=await pool.connect();
   try{
    await client.query('BEGIN');
    const course=await client.query('INSERT INTO courses(course_name,course_code,course_alias,course_duration,is_active,is_status,created_by) VALUES($1,$2,$3,$4,$5,$6,$7) RETURNING course_id',[name,code,alias,duration,input.is_active??true,input.is_active===false?0:1,user.user_id]);
    const courseId=course.rows[0].course_id,batchId=await insertBatch(client,input,courseId,user.user_id);
    let sectionId=null;
    if(sectionName){const section=await client.query('INSERT INTO section(section_name,section_batch_id,intake,created_by,is_status) VALUES($1,$2,$3,$4,1) RETURNING s_id',[sectionName,batchId,intake,user.user_id]);sectionId=section.rows[0].s_id;}
    await client.query('COMMIT');reply(res,201,{ok:true,id:courseId,batch_id:batchId,section_id:sectionId});
   }catch(error){await client.query('ROLLBACK');throw error;}finally{client.release();}
   return true;
  }
  if(resource==='batches'){const courseId=integer(input.batch_course_id??input.course_id,'course',1);const batchId=await insertBatch(pool,input,courseId,user.user_id);reply(res,201,{ok:true,id:batchId});return true;}
  const batchId=integer(input.section_batch_id??input.batch_id,'batch',1),name=text(input,'section_name',50),intake=input.intake!==undefined&&input.intake!==''?integer(input.intake,'intake'):null;
  await pool.query('INSERT INTO section(section_name,section_batch_id,intake,created_by,is_status) VALUES($1,$2,$3,$4,1)',[name,batchId,intake,user.user_id]);reply(res,201,{ok:true});return true;
 }
 reply(res,405,{error:'Method not allowed.'});return true;
}
