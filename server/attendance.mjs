import {randomUUID} from 'node:crypto';
import {pool} from './db.mjs';
import {assignmentQuery} from './lecture-notes.mjs';
const base='/api/admin/academics/take-attendance';
const fail=message=>{throw Object.assign(new Error(message),{status:400});};
const positive=value=>Number.isSafeInteger(Number(value))&&Number(value)>0;
const eligibleQuery=`SELECT u.user_id,u.full_name,st.admission_number FROM course_students cs JOIN students st USING(user_id) JOIN users u USING(user_id)
 WHERE cs.course_id=$1 AND cs.batch_id=$2 AND (st.semester IS NULL OR st.semester=$3) AND ($4::bigint IS NULL OR cs.section_id IS NULL OR cs.section_id=$4) AND u.is_active=TRUE ORDER BY u.full_name,u.user_id`;
async function assignment(client,id,lock=false){return (await client.query(assignmentQuery+' WHERE a.shst_id=$1'+(lock?' FOR UPDATE OF a':''),[id])).rows[0];}
export async function handleAttendance(req,res,path,user,body,reply){
 if(path!==base&&!path.startsWith(base+'/'))return false;
 if(path===base&&req.method==='GET'){
  const {rows}=await pool.query(assignmentQuery+' ORDER BY c.course_name,b.batch_name,a.shst_semester,s.subject_name');
  reply(res,200,{records:rows,assignments:rows});return true;
 }
 const match=path.match(/^\/api\/admin\/academics\/take-attendance\/assignments\/(\d+)(\/roster)?$/);
 if(match&&req.method==='GET'&&!match[2]){
  const a=await assignment(pool,match[1]);if(!a){reply(res,404,{error:'Teaching assignment not found.'});return true;}
  const eligible=(await pool.query(eligibleQuery,[a.shst_course_id,a.batch_id,a.shst_semester,a.shst_section_house_type==='S'?a.shst_section_house_id:null])).rows;
  const roster=(await pool.query('SELECT student_id FROM attendance_roster WHERE assignment_id=$1',[a.shst_id])).rows.map(row=>row.student_id);
  const topics=(await pool.query('SELECT lessonplan_id,module,topics FROM lessonplans WHERE subjectteacher_subject_id=$1 AND deleted_at IS NULL ORDER BY module,lessonplan_id',[a.shst_subject_id])).rows;
  reply(res,200,{assignment:a,eligible,roster,topics});return true;
 }
 if(match&&req.method==='PUT'&&match[2]){
  const input=await body(req);if(!Array.isArray(input?.students)||input.students.length>1000||input.students.some(value=>!positive(value))||new Set(input.students.map(String)).size!==input.students.length)fail('Choose a valid student roster.');
  const client=await pool.connect();try{await client.query('BEGIN');const a=await assignment(client,match[1],true);
   if(!a){await client.query('ROLLBACK');reply(res,404,{error:'Teaching assignment not found.'});return true;}
   const eligible=new Set((await client.query(eligibleQuery,[a.shst_course_id,a.batch_id,a.shst_semester,a.shst_section_house_type==='S'?a.shst_section_house_id:null])).rows.map(row=>String(row.user_id)));
   if(input.students.some(value=>!eligible.has(String(value))))fail('Choose students enrolled in this course, batch and semester.');
   await client.query('DELETE FROM attendance_roster WHERE assignment_id=$1',[a.shst_id]);
   if(input.students.length)await client.query('INSERT INTO attendance_roster(assignment_id,student_id) SELECT $1,unnest($2::bigint[])',[a.shst_id,input.students]);
   await client.query('COMMIT');reply(res,200,{ok:true});
  }catch(error){await client.query('ROLLBACK');throw error;}finally{client.release();}return true;
 }
 if(path===base&&req.method==='POST'){
  const input=await body(req);
  if(!positive(input?.assignment_id)||!positive(input?.topic_id))fail('Choose a class and the topic covered.');
  const date=input.date,start=input.start_time,end=input.end_time;
  if(typeof date!=='string'||!/^\d{4}-\d{2}-\d{2}$/.test(date)||!Number.isFinite(Date.parse(date+'T00:00:00Z'))||new Date(date+'T00:00:00Z').toISOString().slice(0,10)!==date)fail('Enter a valid attendance date.');
  if(![start,end].every(value=>typeof value==='string'&&/^([01]\d|2[0-3]):[0-5]\d$/.test(value))||end<=start)fail('End Time must be after Class Start Time.');
  if(!Array.isArray(input.students)||!input.students.length||input.students.length>1000||input.students.some(row=>!positive(row?.student_id)||typeof row.present!=='boolean')||new Set(input.students.map(row=>String(row.student_id))).size!==input.students.length)fail('Mark each student Present or Absent.');
  const client=await pool.connect();try{await client.query('BEGIN');const a=await assignment(client,input.assignment_id,true);
   if(!a||!a.batch_id||!a.subject_name||!a.faculty_name)fail('Select a fully mapped teaching assignment.');
   const topic=(await client.query('SELECT lessonplan_id FROM lessonplans WHERE lessonplan_id=$1 AND subjectteacher_subject_id=$2 AND deleted_at IS NULL FOR SHARE',[input.topic_id,a.shst_subject_id])).rows[0];
   if(!topic)fail('Choose a topic belonging to this class subject.');
   const roster=(await client.query(`SELECT r.student_id FROM attendance_roster r JOIN course_students cs ON cs.user_id=r.student_id JOIN students st ON st.user_id=r.student_id JOIN users u ON u.user_id=r.student_id
    WHERE r.assignment_id=$1 AND cs.course_id=$2 AND cs.batch_id=$3 AND (st.semester IS NULL OR st.semester=$4) AND ($5::bigint IS NULL OR cs.section_id IS NULL OR cs.section_id=$5) AND u.is_active=TRUE FOR SHARE OF r,cs,st,u`,[a.shst_id,a.shst_course_id,a.batch_id,a.shst_semester,a.shst_section_house_type==='S'?a.shst_section_house_id:null])).rows;
   const ids=new Set(roster.map(row=>String(row.student_id)));
   if(!ids.size||input.students.length!==ids.size||input.students.some(row=>!ids.has(String(row.student_id))))fail('The student roster has changed. Reload the class and mark every roster student.');
   if((await client.query('SELECT session_id FROM attendance_sessions WHERE assignment_id=$1 AND attendance_date=$2 AND start_time<$4::time AND end_time>$3::time',[a.shst_id,date,start,end])).rowCount)fail('Attendance has already been recorded for an overlapping class time.');
   const session=(await client.query('INSERT INTO attendance_sessions(assignment_id,topic_id,attendance_date,start_time,end_time,created_by) VALUES($1,$2,$3,$4,$5,$6) RETURNING session_id',[a.shst_id,topic.lessonplan_id,date,start,end,user.user_id])).rows[0].session_id;
   for(const row of input.students)await client.query(`INSERT INTO student_attendance(session_id,student_attendance_date,student_attendance_classstarttime,student_attendance_classendtime,
    student_attendance_lessonplan_id,student_attendance_student_id,student_attendance_present_absent,student_attendance_master_id,student_attendance_user_id,
    shst_master_id,shst_course_id,shst_batch_id,shst_semester,shst_section_house_type,shst_section_house_id,shst_subject_id,shst_subject_type,
    shst_teacher_emp_info_id,shst_teacher_emp_master_id,shst_teacher_user_id,student_group,created_at,created_by,is_status,rand_str)
    VALUES($1,$2,$3,$4,$5,$6,$7,$1,$8,$9,$10,$11,$12,$13,$14,$15,$19,0,0,$16,$17,NOW(),$8,1,$18)`,[session,date,start,end,topic.lessonplan_id,row.student_id,row.present?1:0,user.user_id,a.shst_id,a.shst_course_id,a.batch_id,a.shst_semester,a.shst_section_house_type,a.shst_section_house_id,a.shst_subject_id,a.shst_teacher_id,a.student_group,randomUUID(),a.subject_type]);
   await client.query('COMMIT');reply(res,201,{ok:true,id:session,count:input.students.length});
  }catch(error){await client.query('ROLLBACK');throw error;}finally{client.release();}return true;
 }
 reply(res,405,{error:'Method not allowed.'});return true;
}
