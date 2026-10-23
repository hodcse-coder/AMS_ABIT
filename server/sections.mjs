import { pool } from './db.mjs';
import { handleSectionMasters } from './section-masters.mjs';
const fail=message=>{throw Object.assign(new Error(message),{status:400});};
function positive(value,label){if(!Number.isSafeInteger(Number(value))||Number(value)<=0||Number(value)>2147483647)fail(`Select a valid ${label}.`);return Number(value);}
export async function handleSectionAssignments(req,res,path,user,body,reply){
 const root='/api/admin/course-modules';
 if(await handleSectionMasters(req,res,path,user,body,reply))return true;
 const definitionMatch=path.match(/^\/api\/admin\/course-modules\/section-definitions(?:\/(\d+))?$/);
 if(definitionMatch){
  const id=definitionMatch[1];
  if(req.method==='GET'&&!id){const {rows}=await pool.query('SELECT d.*,m.section_master_name,a.course_name AS admission_course_name,c.course_name AS assigned_course_name,COALESCE(c.course_name,a.course_name) AS course_name,COALESCE(NULLIF(d.rel_coursefecth,0),d.rel_course) AS assignment_course_id FROM section_defined d LEFT JOIN section_master m ON m.section_master_id=d.section_master LEFT JOIN courses a ON a.course_id=d.rel_course LEFT JOIN courses c ON c.course_id=d.rel_coursefecth ORDER BY d.section_name,d.sid');reply(res,200,{definitions:rows});return true;}
  if((req.method==='POST'&&!id)||(req.method==='PATCH'&&id)||(req.method==='DELETE'&&id)){
   const input=req.method==='DELETE'?{}:await body(req);
   const name=typeof input.section_name==='string'?input.section_name.trim().toUpperCase():'';
   const masterId=input.section_master?positive(input.section_master,'Section Master'):0;
   const admissionId=input.rel_course?positive(input.rel_course,'Admission Form Course'):null;
   const courseId=input.rel_coursefecth?positive(input.rel_coursefecth,'Course'):0;
   if(req.method!=='DELETE'&&(!name||name.length>50))fail('Enter a Section Name of up to 50 characters.');
   const client=await pool.connect();
   try{
    await client.query('BEGIN');
    if(id){const found=await client.query('SELECT sid FROM section_defined WHERE sid=$1 FOR UPDATE',[id]);if(!found.rowCount){await client.query('ROLLBACK');reply(res,404,{error:'Section definition not found.'});return true;}}
    if(req.method==='DELETE'){
     if((await client.query('SELECT 1 FROM section WHERE section_id=$1 LIMIT 1',[id])).rowCount){await client.query('ROLLBACK');reply(res,409,{error:'This Section is assigned to a Batch. Remove its assignments before deleting it.'});return true;}
     await client.query('DELETE FROM section_defined WHERE sid=$1',[id]);await client.query('COMMIT');reply(res,200,{ok:true});return true;
    }
    if(masterId&&!(await client.query('SELECT 1 FROM section_master WHERE section_master_id=$1 FOR SHARE',[masterId])).rowCount)fail('Choose a saved Section Master.');
    for(const course of [admissionId,courseId].filter(Boolean))if(!(await client.query('SELECT 1 FROM courses WHERE course_id=$1',[course])).rowCount)fail('Choose a saved Course.');
    const actualCourse=courseId||admissionId;
    if(id&&actualCourse&&(await client.query('SELECT 1 FROM section s JOIN batches b ON b.batch_id=s.section_batch_id WHERE s.section_id=$1 AND b.batch_course_id<>$2 LIMIT 1',[id,actualCourse])).rowCount)fail('The Course conflicts with an existing Batch assignment.');
    const result=id?await client.query('UPDATE section_defined SET section_name=$1,section_master=$2,rel_course=$3,rel_coursefecth=$4 WHERE sid=$5 RETURNING sid',[name,masterId,admissionId,courseId,id]):await client.query('INSERT INTO section_defined(section_name,section_master,rel_course,rel_coursefecth) VALUES($1,$2,$3,$4) RETURNING sid',[name,masterId,admissionId,courseId]);
    if(id)await client.query('UPDATE section SET section_name=$1,updated_at=NOW(),updated_by=$2 WHERE section_id=$3',[name,user.user_id,id]);
    await client.query('COMMIT');reply(res,id?200:201,{ok:true,id:result.rows[0].sid});
   }catch(error){await client.query('ROLLBACK');throw error;}finally{client.release();}
   return true;
  }
  reply(res,405,{error:'Method not allowed.'});return true;
 }
 const match=path.match(/^\/api\/admin\/course-modules\/assignments(?:\/(\d+))?$/);
 if(!match)return false;
 const id=match[1];
 if(req.method==='GET'&&!id){const {rows}=await pool.query('SELECT s.s_id AS assignment_id,s.section_id AS definition_id,s.section_name,s.section_batch_id AS batch_id,s.intake,s.is_status,s.created_at,s.updated_at,b.batch_name,b.batch_course_id,c.course_name FROM section s JOIN batches b ON b.batch_id=s.section_batch_id JOIN courses c ON c.course_id=b.batch_course_id ORDER BY s.s_id');reply(res,200,{assignments:rows});return true;}
 if(req.method==='DELETE'&&id){const result=await pool.query('DELETE FROM section WHERE s_id=$1 RETURNING s_id',[id]);reply(res,result.rowCount?200:404,result.rowCount?{ok:true}:{error:'Section assignment not found.'});return true;}
 if((req.method==='POST'&&!id)||(req.method==='PATCH'&&id)){
  const input=await body(req),definitionId=positive(input.definition_id,'section'),batchId=positive(input.batch_id,'batch');
  const intake=input.intake===undefined||input.intake===null||input.intake===''?null:Number(input.intake);
  if(intake!==null&&(!Number.isInteger(intake)||intake<0||intake>2147483647))fail('Intake must be a non-negative whole number.');
  if(input.is_status!==undefined&&![0,1].includes(input.is_status))fail('Select a valid status.');
  const client=await pool.connect();
  try{
   await client.query('BEGIN');
   const definition=(await client.query('SELECT * FROM section_defined WHERE sid=$1 FOR SHARE',[definitionId])).rows[0];
   const batch=(await client.query('SELECT * FROM batches WHERE batch_id=$1 FOR SHARE',[batchId])).rows[0];
   if(!definition||!batch)fail('Select a saved Section and Batch.');
   if((definition.rel_coursefecth||definition.rel_course)&&String(definition.rel_coursefecth||definition.rel_course)!==String(batch.batch_course_id))fail('The selected Section belongs to a different course than this Batch.');
   const result=id?await client.query('UPDATE section SET section_id=$1,section_name=$2,section_batch_id=$3,intake=$4,is_status=COALESCE($5,is_status),updated_at=NOW(),updated_by=$6 WHERE s_id=$7 RETURNING s_id',[definitionId,definition.section_name,batchId,intake,input.is_status??null,user.user_id,id]):await client.query('INSERT INTO section(section_id,section_name,section_batch_id,intake,is_status,created_by) VALUES($1,$2,$3,$4,1,$5) RETURNING s_id',[definitionId,definition.section_name,batchId,intake,user.user_id]);
   await client.query('COMMIT');reply(res,result.rowCount?(id?200:201):404,result.rowCount?{ok:true,id:result.rows[0].s_id}:{error:'Section assignment not found.'});
  }catch(error){await client.query('ROLLBACK');throw error;}finally{client.release();}
  return true;
 }
 reply(res,405,{error:'Method not allowed.'});return true;
}