import {pool} from './db.mjs';
const fail=message=>{throw Object.assign(new Error(message),{status:400});};
function text(input,key,max){const value=typeof input[key]==='string'?input[key].trim().toUpperCase():'';if(!value||value.length>max)fail(`Enter a valid ${key.replaceAll('_',' ')} (up to ${max} characters).`);return value;}
export async function handleAcademics(req,res,path,user,body,reply){
 const root='/api/admin/course-modules';
 const yearMatch=path.match(/^\/api\/admin\/course-modules\/academic-years(?:\/(\d+))?$/);
 if(yearMatch){
  const id=yearMatch[1];
  if(req.method==='GET'&&!id){const {rows}=await pool.query('SELECT y.*,ARRAY(SELECT s.semester FROM academic_year_semesters s WHERE s.academic_year_id=y.academic_year_id ORDER BY s.semester) AS semesters FROM academic_years y ORDER BY y.academic_year DESC');reply(res,200,{years:rows});return true;}
  if(req.method==='DELETE'&&id){const result=await pool.query('DELETE FROM academic_years WHERE academic_year_id=$1 RETURNING academic_year_id',[id]);reply(res,result.rowCount?200:404,result.rowCount?{ok:true}:{error:'Academic Year not found.'});return true;}
  if((req.method==='POST'&&!id)||(req.method==='PATCH'&&id)){
   const input=await body(req),label=typeof input.academic_year==='string'?input.academic_year.trim():'';
   if(!/^\d{4}-\d{2}$/.test(label)||Number(label.slice(-2))!==(Number(label.slice(0,4))+1)%100)fail('Use consecutive years in YYYY-YY format, for example 2026-27.');
   if(id){const result=await pool.query('UPDATE academic_years SET academic_year=$1,updated_at=NOW(),updated_by=$2 WHERE academic_year_id=$3 RETURNING academic_year_id',[label,user.user_id,id]);reply(res,result.rowCount?200:404,result.rowCount?{ok:true,id}:{error:'Academic Year not found.'});return true;}
   const client=await pool.connect();
   try{await client.query('BEGIN');const result=await client.query('INSERT INTO academic_years(academic_year,created_by) VALUES($1,$2) RETURNING academic_year_id',[label,user.user_id]);const yearId=result.rows[0].academic_year_id;await client.query('INSERT INTO academic_year_semesters(academic_year_id,semester) VALUES($1,1),($1,2)',[yearId]);await client.query('COMMIT');reply(res,201,{ok:true,id:yearId});}catch(error){await client.query('ROLLBACK');throw error;}finally{client.release();}return true;
  }
  reply(res,405,{error:'Method not allowed.'});return true;
 }
 const match=path.match(/^\/api\/admin\/course-modules\/subjects(?:\/(\d+))?$/);
 if(!match)return false;
 const id=match[1];
 if(req.method==='GET'&&!id){const {rows}=await pool.query('SELECT s.*,y.academic_year,b.branch_name,b.branch_code FROM subjects s LEFT JOIN academic_years y USING(academic_year_id) LEFT JOIN academic_branches b ON b.branch_id=s.branch_id ORDER BY y.academic_year DESC NULLS LAST,s.semester,s.subject_name');reply(res,200,{subjects:rows});return true;}
 if(req.method==='DELETE'&&id){const result=await pool.query('DELETE FROM subjects WHERE subject_id=$1 RETURNING subject_id',[id]);reply(res,result.rowCount?200:404,result.rowCount?{ok:true}:{error:'Subject not found.'});return true;}
 if((req.method==='POST'&&!id)||(req.method==='PATCH'&&id)){
  const input=await body(req),name=text(input,'subject_name',100),code=text(input,'subject_code',50),alias=text(input,'subject_alias',35);
  if(!['T','P'].includes(input.subject_type))fail('Select Theory or Practical.');
  const credit=input.credit===undefined||input.credit===null||input.credit===''?0:Number(input.credit);
  if(!Number.isInteger(credit)||credit<0||credit>2147483647)fail('Credit must be a non-negative whole number.');
  const yearId=Number(input.academic_year_id),semester=Number(input.semester),branchId=Number(input.branch_id);
  if(!Number.isSafeInteger(branchId)||branchId<=0)fail('Select a Branch Name.');
  if(!Number.isSafeInteger(yearId)||yearId<=0||![1,2].includes(semester))fail('Select an Academic Year and Semester 1 or 2.');
  const client=await pool.connect();
  try{await client.query('BEGIN');if(!(await client.query('SELECT 1 FROM academic_branches WHERE branch_id=$1 FOR SHARE',[branchId])).rowCount)fail('Selected Branch does not exist.');if(!(await client.query('SELECT 1 FROM academic_year_semesters WHERE academic_year_id=$1 AND semester=$2 FOR SHARE',[yearId,semester])).rowCount)fail('The selected semester is not mapped to this Academic Year.');
   const result=id?await client.query('UPDATE subjects SET academic_year_id=$1,semester=$2,subject_name=$3,subject_code=$4,subject_alias=$5,subject_type=$6,credit=$7,updated_at=NOW(),updated_by=$8,branch_id=$9 WHERE subject_id=$10 RETURNING subject_id',[yearId,semester,name,code,alias,input.subject_type,credit,user.user_id,branchId,id]):await client.query('INSERT INTO subjects(academic_year_id,semester,subject_name,subject_code,subject_alias,subject_type,credit,created_at,created_by,is_status,branch_id) VALUES($1,$2,$3,$4,$5,$6,$7,NOW(),$8,1,$9) RETURNING subject_id',[yearId,semester,name,code,alias,input.subject_type,credit,user.user_id,branchId]);
   await client.query('COMMIT');reply(res,result.rowCount?(id?200:201):404,result.rowCount?{ok:true,id:result.rows[0].subject_id}:{error:'Subject not found.'});
  }catch(error){await client.query('ROLLBACK');throw error;}finally{client.release();}return true;
 }
 reply(res,405,{error:'Method not allowed.'});return true;
}
