import {pool} from './db.mjs';
import {discussionTypes} from '../shared/mentoring.mjs';
const base='/api/mentoring';
const fail=message=>{throw Object.assign(new Error(message),{status:400});};
const positive=value=>Number.isSafeInteger(Number(value))&&Number(value)>0;
const text=(value,label,max,required=true)=>{const result=typeof value==='string'?value.trim():'';if(required&&!result||result.length>max)fail('Enter '+label+' (up to '+max+' characters).');return result||null;};
const money=value=>{if(value===''||value==null)return null;if(!/^\d{1,12}(\.\d{1,2})?$/.test(String(value))||Number(value)<0)fail('Enter a non-negative amount with up to two decimal places.');return String(value);};
function date(value){if(!value)return null;if(typeof value!=='string'||!/^\d{4}-\d{2}-\d{2}$/.test(value)||!Number.isFinite(Date.parse(value+'T00:00:00Z'))||new Date(value+'T00:00:00Z').toISOString().slice(0,10)!==value)fail('Enter a valid Transaction Date.');return value;}
const staffQuery=`SELECT e.emp_master_id,e.emp_master_user_id,u.full_name,d.emp_department_name FROM emp_master e JOIN users u ON u.user_id=e.emp_master_user_id JOIN user_roles r USING(role_id) JOIN emp_department d ON d.emp_department_id=e.emp_master_department_id WHERE e.deleted_at IS NULL AND u.is_active AND r.role_name IN('Faculty','Employee','Admin')`;
const studentQuery=`SELECT m.stu_master_id,m.stu_master_user_id,m.stu_master_course_id,m.stu_master_batch_id,m.stu_master_section_id,m.semester_registered,m.mentor_id,m.mentor_allotted_at,
 i.stu_unique_id,concat_ws(' ',i.stu_first_name,NULLIF(i.stu_middle_name,''),i.stu_last_name) AS student_name,c.course_name,b.batch_name,s.section_name,u.is_active,st.stu_status_name,
 mu.full_name AS mentor_name,(SELECT COUNT(*)::integer FROM studentcounselling sc WHERE sc.sc_student_master_id=m.stu_master_id) AS counselling_count
 FROM stu_master m JOIN stu_info i ON i.stu_info_id=m.stu_master_stu_info_id JOIN courses c ON c.course_id=m.stu_master_course_id JOIN batches b ON b.batch_id=m.stu_master_batch_id
 JOIN section s ON s.s_id=m.stu_master_section_id JOIN users u ON u.user_id=m.stu_master_user_id JOIN stu_status st ON st.stu_status_id=m.stu_master_stu_status_id
 LEFT JOIN emp_master me ON me.emp_master_id=m.mentor_id LEFT JOIN users mu ON mu.user_id=me.emp_master_user_id`;
const counsellingQuery=`SELECT sc.*,sc.fees_pay_tran_date::text AS fees_pay_tran_date,i.stu_unique_id,concat_ws(' ',i.stu_first_name,NULLIF(i.stu_middle_name,''),i.stu_last_name) AS student_name,
 c.course_name,b.batch_name,s.section_name,mu.full_name AS mentor_name,r1.full_name AS first_reviewer_name,r2.full_name AS second_reviewer_name,rc.full_name AS chief_reviewer_name,
 creator.full_name AS created_by_name,by1.full_name AS first_recorded_by,by2.full_name AS second_recorded_by,byc.full_name AS chief_recorded_by
 FROM studentcounselling sc JOIN stu_master m ON m.stu_master_id=sc.sc_student_master_id JOIN stu_info i ON i.stu_info_id=m.stu_master_stu_info_id
 JOIN courses c ON c.course_id=m.stu_master_course_id JOIN batches b ON b.batch_id=m.stu_master_batch_id JOIN section s ON s.s_id=m.stu_master_section_id
 JOIN users mu ON mu.user_id=sc.sc_emp_user_id JOIN emp_master e1 ON e1.emp_master_id=sc.reviewer_one JOIN users r1 ON r1.user_id=e1.emp_master_user_id
 JOIN emp_master e2 ON e2.emp_master_id=sc.reviewer_two JOIN users r2 ON r2.user_id=e2.emp_master_user_id
 JOIN emp_master ec ON ec.emp_master_id=sc.reviewer_chief JOIN users rc ON rc.user_id=ec.emp_master_user_id
 JOIN users creator ON creator.user_id=sc.created_by LEFT JOIN users by1 ON by1.user_id=sc.reviewerone_by LEFT JOIN users by2 ON by2.user_id=sc.reviewertwo_by LEFT JOIN users byc ON byc.user_id=sc.reviewerchief_by`;
const reviewerQuery=`SELECT r.*,m.full_name AS mentor_name,a.full_name AS first_reviewer_name,b.full_name AS second_reviewer_name,c.full_name AS chief_reviewer_name
 FROM mentorreviewer r JOIN emp_master me ON me.emp_master_id=r.r_mentor JOIN users m ON m.user_id=me.emp_master_user_id
 JOIN emp_master ae ON ae.emp_master_id=r.r_reviewerone JOIN users a ON a.user_id=ae.emp_master_user_id
 JOIN emp_master be ON be.emp_master_id=r.r_reviewertwo JOIN users b ON b.user_id=be.emp_master_user_id
 JOIN emp_master ce ON ce.emp_master_id=r.r_reviewerchief JOIN users c ON c.user_id=ce.emp_master_user_id`;
async function staff(client,id){if(!positive(id)||!(await client.query(staffQuery+' AND e.emp_master_id=$1 FOR SHARE OF e,u',[id])).rowCount)fail('Select an active employee for each Mentor and Reviewer.');}
function counsellingInput(input){
 if(!['S','P','B'].includes(input.discussed_with)||!discussionTypes.includes(input.discussion_type)||typeof input.urgent!=='boolean')fail('Choose Discussed With, Discussion Type and Urgent status.');
 return {discussed_with:input.discussed_with,discussion_type:input.discussion_type,dis_subject:text(input.dis_subject,'Discussion Subject',200),mentor_remarks:text(input.mentor_remarks,'Mentor Remarks',10000),urgent:input.urgent?1:0,
 fees_pay_tran_mode:text(input.fees_pay_tran_mode,'Transaction Mode',30,false),fees_pay_tran_date:date(input.fees_pay_tran_date),fees_pay_tran_amount:money(input.fees_pay_tran_amount),current_due:money(input.current_due)};
}
export async function handleMentoring(req,res,path,user,body,reply){
 if(path!==base&&!path.startsWith(base+'/'))return false;
 const admin=user.role_name==='Admin';if(!admin&&!['Faculty','Employee'].includes(user.role_name)){reply(res,403,{error:'Staff access required.'});return true;}
 const employee=(await pool.query('SELECT emp_master_id FROM emp_master WHERE emp_master_user_id=$1 AND deleted_at IS NULL',[user.user_id])).rows[0]?.emp_master_id||null;
 const scope=admin?'TRUE':'(sc.sc_emp_master_id=$1 OR sc.reviewer_one=$1 OR sc.reviewer_two=$1 OR sc.reviewer_chief=$1)',scopeValues=admin?[]:[employee];
 if(path===base+'/options'&&req.method==='GET'){
  const [staff,students,courses,batches,sections]=await Promise.all([
   pool.query(staffQuery+' ORDER BY u.full_name'),pool.query(studentQuery+' WHERE m.deleted_at IS NULL AND u.is_active'+(admin?'':' AND m.mentor_id=$1')+' ORDER BY student_name',scopeValues),
   pool.query('SELECT course_id,course_name FROM courses ORDER BY course_name'),pool.query('SELECT batch_id,batch_name,batch_course_id FROM batches ORDER BY batch_name'),pool.query('SELECT s_id,section_name,section_batch_id FROM section ORDER BY section_name')]);
  reply(res,200,{staff:staff.rows,students:students.rows,courses:courses.rows,batches:batches.rows,sections:sections.rows,employee_id:employee});return true;
 }
 if(path===base+'/students'&&req.method==='GET'){reply(res,200,{records:(await pool.query(studentQuery+' WHERE m.deleted_at IS NULL'+(admin?'':' AND m.mentor_id=$1')+' ORDER BY student_name',scopeValues)).rows});return true;}
 if(path===base+'/reviewers'&&req.method==='GET'){if(!admin){reply(res,403,{error:'Administrator access required.'});return true;}reply(res,200,{records:(await pool.query(reviewerQuery+' ORDER BY r.r_id DESC')).rows});return true;}
 const session=path.match(/^\/api\/mentoring\/counselling(?:\/(\d+)(?:\/review\/(one|two|chief))?)?$/);
 if(session&&req.method==='GET'&&!session[2]){
  const params=new URL(req.url||path,'http://localhost').searchParams,first=params.get('first')==='1';
  let where=' WHERE '+scope,values=[...scopeValues];if(session[1]){values.push(session[1]);where+=' AND sc.sc_id=$'+values.length;}
  if(first)where+=' AND sc.reviewerone_at IS NULL'+(admin?'':' AND sc.reviewer_one=$1');
  const rows=(await pool.query(counsellingQuery+where+' ORDER BY sc.created_at DESC,sc.sc_id DESC',values)).rows;
  reply(res,session[1]&&!rows.length?404:200,session[1]?(rows[0]?{record:rows[0]}:{error:'Counselling record not found.'}):{records:rows});return true;
 }
 const reviewer=path.match(/^\/api\/mentoring\/reviewers(?:\/(\d+))?$/);
 if((reviewer||path===base+'/allotments')&&!admin){reply(res,403,{error:'Administrator access required.'});return true;}
 if(!['POST','PATCH','DELETE'].includes(req.method)){reply(res,405,{error:'Method not allowed.'});return true;}
 const client=await pool.connect();try{
  await client.query('BEGIN');await client.query('SELECT pg_advisory_xact_lock(84102732)');
  const input=req.method==='DELETE'?{}:await body(req);if(!input||typeof input!=='object'||Array.isArray(input))fail('Provide the form details.');let result;
  if(path===base+'/allotments'&&req.method==='POST'){
   if(!Array.isArray(input.student_ids)||!input.student_ids.length||input.student_ids.length>500||input.student_ids.some(id=>!positive(id)))fail('Select between 1 and 500 students.');
   const ids=[...new Set(input.student_ids.map(String))];if(input.mentor_id!==null)await staff(client,input.mentor_id);
   const selected=(await client.query('SELECT m.stu_master_id,m.mentor_id FROM stu_master m JOIN users u ON u.user_id=m.stu_master_user_id WHERE m.stu_master_id=ANY($1::bigint[]) AND m.deleted_at IS NULL AND u.is_active FOR UPDATE OF m', [ids])).rows;
   if(selected.length!==ids.length)fail('Select active, existing students. No allotments were changed.');
   for(const row of selected){if(String(row.mentor_id)===String(input.mentor_id))continue;
    await client.query('INSERT INTO mentor_allotment_history(student_id,previous_mentor_id,mentor_id,created_by) VALUES($1,$2,$3,$4)',[row.stu_master_id,row.mentor_id,input.mentor_id,user.user_id]);
    await client.query('UPDATE stu_master SET mentor_id=$2,mentor_allotted_at=NOW(),mentor_allotted_by=$3,updated_at=NOW(),updated_by=$3 WHERE stu_master_id=$1',[row.stu_master_id,input.mentor_id,user.user_id]);
   }result={rowCount:1,rows:[{id:ids.length}]};
  }else if(reviewer&&((!reviewer[1]&&req.method==='POST')||(reviewer[1]&&['PATCH','DELETE'].includes(req.method)))){
   if(req.method==='DELETE')result=await client.query('DELETE FROM mentorreviewer WHERE r_id=$1 RETURNING r_id AS id',[reviewer[1]]);
   else{
    const ids=[input.r_mentor,input.r_reviewerone,input.r_reviewertwo,input.r_reviewerchief];if(new Set(ids.map(String)).size!==4)fail('Mentor and all three Reviewers must be different employees.');for(const id of ids)await staff(client,id);
    if(![0,1].includes(Number(input.is_status)))fail('Select the active status.');
    const values=[...ids,Number(input.is_status),user.user_id];
    result=reviewer[1]?await client.query('UPDATE mentorreviewer SET r_mentor=$1,r_reviewerone=$2,r_reviewertwo=$3,r_reviewerchief=$4,is_status=$5,updated_by=$6,updated_at=NOW() WHERE r_id=$7 RETURNING r_id AS id',[...values,reviewer[1]]):await client.query('INSERT INTO mentorreviewer(r_mentor,r_reviewerone,r_reviewertwo,r_reviewerchief,is_status,created_by) VALUES($1,$2,$3,$4,$5,$6) RETURNING r_id AS id',values);
   }
  }else if(session&&((!session[1]&&req.method==='POST')||(session[1]&&!session[2]&&['PATCH','DELETE'].includes(req.method))||(session[2]&&req.method==='POST'))){
   let old;if(session[1]){old=(await client.query('SELECT * FROM studentcounselling sc WHERE sc.sc_id=$1 AND '+(admin?'TRUE':'(sc.sc_emp_master_id=$2 OR sc.reviewer_one=$2 OR sc.reviewer_two=$2 OR sc.reviewer_chief=$2)')+' FOR UPDATE',admin?[session[1]]:[session[1],employee])).rows[0];if(!old){await client.query('ROLLBACK');reply(res,404,{error:'Counselling record not found.'});return true;}}
   if(session[2]){
    const stage=session[2],key='reviewer'+stage;if(!admin&&String(old['reviewer_'+stage])!==String(employee)){await client.query('ROLLBACK');reply(res,403,{error:'Only the assigned Reviewer may submit this review.'});return true;}
    if(old[key+'_at'])fail('This review has already been submitted.');if(stage==='two'&&!old.reviewerone_at||stage==='chief'&&!old.reviewertwo_at)fail('Complete the previous review first.');
    const remarks=text(input.remarks,'Reviewer Remarks',10000);let data={ [key+'_remarks']:remarks,[key+'_by']:user.user_id,is_status:stage==='chief'?2:1};
    if(stage==='one'){
     if(!['YES','NO'].includes(input.firstreviewer_verified)||!['EXCELLENT','GOOD','AVERAGE','NEEDS IMPROVEMENT'].includes(input.grading_to_mentor))fail('Choose Verification and Mentor Grading.');
     data={...data,firstreviewer_verified:input.firstreviewer_verified,grading_to_mentor:input.grading_to_mentor,suggestion_tomentor:text(input.suggestion_tomentor,'Suggestion to Mentor',10000,false)};
    }
    const keys=Object.keys(data),values=Object.values(data);result=await client.query('UPDATE studentcounselling SET '+keys.map((key,index)=>key+'=$'+(index+1)).join(',')+','+key+'_at=NOW() WHERE sc_id=$'+(values.length+1)+' RETURNING sc_id AS id',[...values,old.sc_id]);
   }else{
    if(old&&(!admin&&String(old.sc_emp_master_id)!==String(employee))){await client.query('ROLLBACK');reply(res,403,{error:'Only the Mentor may change this counselling record.'});return true;}
    if(old&&(old.reviewerone_at||old.reviewertwo_at||old.reviewerchief_at))fail('Reviewed counselling records are retained and cannot be edited or deleted.');
    if(req.method==='DELETE')result=await client.query('DELETE FROM studentcounselling WHERE sc_id=$1 RETURNING sc_id AS id',[old.sc_id]);
    else{
     const data=counsellingInput(input);
     if(!old){
      if(!positive(input.student_id))fail('Select an existing student.');
      const student=(await client.query('SELECT m.* FROM stu_master m JOIN users u ON u.user_id=m.stu_master_user_id WHERE m.stu_master_id=$1 AND m.deleted_at IS NULL AND u.is_active FOR SHARE OF m',[input.student_id])).rows[0];
      if(!student?.mentor_id)fail('Allot a Mentor to this active student first.');if(!admin&&String(student.mentor_id)!==String(employee)){await client.query('ROLLBACK');reply(res,403,{error:'This student is assigned to another Mentor.'});return true;}
      await staff(client,student.mentor_id);const reviewers=(await client.query('SELECT * FROM mentorreviewer WHERE r_mentor=$1 AND is_status=1 FOR SHARE',[student.mentor_id])).rows[0];if(!reviewers)fail('Complete active Reviewer Allotment for this Mentor first.');
      for(const id of [reviewers.r_reviewerone,reviewers.r_reviewertwo,reviewers.r_reviewerchief])await staff(client,id);
      const mentor=(await client.query('SELECT emp_master_user_id FROM emp_master WHERE emp_master_id=$1',[student.mentor_id])).rows[0];
      Object.assign(data,{sc_student_master_id:student.stu_master_id,sc_student_user_id:student.stu_master_user_id,sc_emp_master_id:student.mentor_id,sc_emp_user_id:mentor.emp_master_user_id,reviewer_one:reviewers.r_reviewerone,reviewer_two:reviewers.r_reviewertwo,reviewer_chief:reviewers.r_reviewerchief,created_by:user.user_id});
     }else{data.updated_by=user.user_id;}
     const keys=Object.keys(data),values=Object.values(data);
     result=old?await client.query('UPDATE studentcounselling SET '+keys.map((key,index)=>key+'=$'+(index+1)).join(',')+',updated_at=NOW() WHERE sc_id=$'+(values.length+1)+' RETURNING sc_id AS id',[...values,old.sc_id]):await client.query('INSERT INTO studentcounselling('+keys.join(',')+') VALUES('+keys.map((_,index)=>'$'+(index+1)).join(',')+') RETURNING sc_id AS id',values);
    }
   }
  }else{await client.query('ROLLBACK');reply(res,405,{error:'Method not allowed.'});return true;}
  await client.query('COMMIT');reply(res,result.rowCount?(req.method==='POST'?201:200):404,result.rowCount?{ok:true,id:result.rows[0].id}:{error:'Record not found.'});
 }catch(error){await client.query('ROLLBACK');throw error;}finally{client.release();}return true;
}
