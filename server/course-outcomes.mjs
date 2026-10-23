import {pool} from './db.mjs';
const fail=message=>{throw Object.assign(new Error(message),{status:400});};
export async function handleCourseOutcomes(req,res,path,user,body,reply){
 const match=path.match(/^\/api\/admin\/academics\/course-outcome(?:\/(\d+))?$/);if(!match)return false;const id=match[1];
 if(req.method==='GET'&&!id){const {rows}=await pool.query('SELECT b.*,b.co_subject_id AS subject_id,s.subject_name,s.academic_year_id,s.branch_id,s.semester,y.academic_year,br.branch_name,u.full_name AS faculty_name FROM courseoutcome b LEFT JOIN subjects s ON s.subject_id=b.co_subject_id LEFT JOIN academic_years y ON y.academic_year_id=s.academic_year_id LEFT JOIN academic_branches br ON br.branch_id=s.branch_id LEFT JOIN users u ON u.user_id=b.created_by ORDER BY b.co_id DESC');reply(res,200,{records:rows});return true;}
 if(req.method==='DELETE'&&id){const result=await pool.query('DELETE FROM courseoutcome WHERE co_id=$1 RETURNING co_id',[id]);reply(res,result.rowCount?200:404,result.rowCount?{ok:true}:{error:'Course outcome not found.'});return true;}
 if((req.method==='POST'&&!id)||(req.method==='PATCH'&&id)){
  const input=await body(req),subjectId=Number(input.subject_id),codescription=typeof input.codescription==='string'?input.codescription.trim():'';
  if(!Number.isSafeInteger(subjectId)||subjectId<=0||!codescription||codescription.length>5000)fail('Select a Subject and enter a Course Outcome (up to 5000 characters).');
  if(!['CO-1','CO-2','CO-3','CO-4','CO-5'].includes(input.cotype))fail('Select a Course Outcome from CO-1 to CO-5.');
  const client=await pool.connect();try{await client.query('BEGIN');const subject=(await client.query('SELECT academic_year_id,branch_id,semester FROM subjects WHERE subject_id=$1 FOR SHARE',[subjectId])).rows[0];
   if(!subject||!subject.academic_year_id||!subject.branch_id||![1,2].includes(subject.semester)||String(subject.academic_year_id)!==String(input.academic_year_id)||String(subject.branch_id)!==String(input.branch_id)||String(subject.semester)!==String(input.semester))fail('Select a Subject matching the Academic Year, Branch and Semester.');
   const result=id?await client.query('UPDATE courseoutcome SET co_subject_id=$1,codescription=$2,updated_at=NOW(),updated_by=$3,cotype=$5 WHERE co_id=$4 RETURNING co_id',[subjectId,codescription,user.user_id,id,input.cotype]):await client.query('INSERT INTO courseoutcome(co_subject_id,codescription,cotype,created_at,created_by,is_status) VALUES($2,$3,$4,NOW(),$1,1) RETURNING co_id',[user.user_id,subjectId,codescription,input.cotype]);
   await client.query('COMMIT');reply(res,result.rowCount?(id?200:201):404,result.rowCount?{ok:true,id:result.rows[0].co_id}:{error:'Course outcome not found.'});
  }catch(error){await client.query('ROLLBACK');throw error;}finally{client.release();}return true;
 }
 reply(res,405,{error:'Method not allowed.'});return true;
}
