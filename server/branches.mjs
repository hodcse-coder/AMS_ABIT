import {pool} from './db.mjs';
const fail=message=>{throw Object.assign(new Error(message),{status:400});};
export async function handleBranches(req,res,path,user,body,reply){
 const match=path.match(/^\/api\/admin\/course-modules\/branches(?:\/(\d+))?$/);if(!match)return false;
 const id=match[1];
 if(req.method==='GET'&&!id){const {rows}=await pool.query('SELECT b.*,c.course_code,c.course_name FROM academic_branches b JOIN courses c USING(course_id) ORDER BY c.course_code,b.branch_name');reply(res,200,{branches:rows});return true;}
 if((req.method==='POST'&&!id)||(req.method==='PATCH'&&id)){
  const input=await body(req),course=Number(input.course_id);
  if(!Number.isSafeInteger(course)||course<=0)fail('Select a Course.');
  const values=['branch_code','branch_name','branch_alias'].map((key,index)=>{const value=typeof input[key]==='string'?input[key].trim().toUpperCase():'';if(!value||value.length>[30,200,50][index])fail('Enter a valid '+key.replaceAll('_',' ')+'.');return value;});
  if(typeof input.is_active!=='boolean')fail('Select Active or Inactive.');
  if(!(await pool.query('SELECT 1 FROM courses WHERE course_id=$1',[course])).rowCount)fail('Selected Course does not exist.');
  const params=[course,...values,input.is_active];
  const result=id?await pool.query('UPDATE academic_branches SET course_id=$1,branch_code=$2,branch_name=$3,branch_alias=$4,is_active=$5,updated_at=NOW() WHERE branch_id=$6 RETURNING branch_id',[...params,id]):await pool.query('INSERT INTO academic_branches(course_id,branch_code,branch_name,branch_alias,is_active) VALUES($1,$2,$3,$4,$5) RETURNING branch_id',params);
  reply(res,result.rowCount?(id?200:201):404,result.rowCount?{ok:true,id:result.rows[0].branch_id}:{error:'Branch not found.'});return true;
 }
 reply(res,405,{error:'Method not allowed.'});return true;
}
