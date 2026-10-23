import {courseSemesterCount} from '../shared/course-semesters.mjs';
import {pool} from './db.mjs';
import {assignmentQuery} from './lecture-notes.mjs';
const base='/api/admin/subject-configuration';
const fail=message=>{throw Object.assign(new Error(message),{status:400});};
const positive=value=>Number.isSafeInteger(Number(value))&&Number(value)>0;
const bit=value=>[0,1,'0','1'].includes(value);
const tables={semesters:['semester_defined','id'],teachers:['subjectteacher','subjectteacher_id'],allotments:['section_house_subject_teacher','shst_id'],substitutes:['section_house_subject_teacher','shst_id']};

export async function handleSubjectConfiguration(req,res,path,user,body,reply){
 if(path!==base&&!path.startsWith(base+'/'))return false;
 if(path===base+'/options'&&req.method==='GET'){
  const queries={years:'SELECT academic_year_id,academic_year FROM academic_years ORDER BY academic_year DESC',academicSemesters:'SELECT academic_year_id,semester FROM academic_year_semesters ORDER BY academic_year_id,semester',courses:'SELECT course_id,course_name,course_code,course_duration FROM courses ORDER BY course_name',batches:'SELECT batch_id,batch_name,batch_course_id FROM batches ORDER BY batch_name',sections:'SELECT s_id,section_name,section_batch_id FROM section ORDER BY section_name',houses:'SELECT section_master_id,section_master_name FROM section_master ORDER BY section_master_name',branches:'SELECT branch_id,course_id,branch_name FROM academic_branches WHERE is_active=TRUE ORDER BY branch_name',subjects:'SELECT subject_id,subject_name,subject_code,branch_id,academic_year_id,semester FROM subjects ORDER BY subject_name',faculty:"SELECT u.user_id,u.full_name FROM users u JOIN user_roles r USING(role_id) WHERE r.role_name='Faculty' AND u.is_active=TRUE ORDER BY u.full_name",semesters:'SELECT * FROM semester_defined ORDER BY sem_course_master_id,sem_batch_master_id,semester',teachers:'SELECT subjectteacher_id,subjectteacher_subject_id,subjectteacher_employee_id FROM subjectteacher'};
  const options={};await Promise.all(Object.entries(queries).map(async([key,sql])=>{options[key]=(await pool.query(sql)).rows;}));reply(res,200,options);return true;
 }
 const match=path.match(/^\/api\/admin\/subject-configuration\/(semesters|teachers|allotments|substitutes)(?:\/(\d+))?$/);
 if(!match){reply(res,404,{error:'Subject Configuration page not found.'});return true;}
 const [,kind,id]=match,[table,pk]=tables[kind];
 if(req.method==='GET'&&!id){
  let sql;
  if(kind==='semesters')sql='SELECT d.*,c.course_name,b.batch_name FROM semester_defined d JOIN courses c ON c.course_id=d.sem_course_master_id JOIN batches b ON b.batch_id=d.sem_batch_master_id ORDER BY d.id DESC';
  else if(kind==='teachers')sql=`SELECT t.*,s.subject_name,s.subject_code,y.academic_year,br.branch_name,u.full_name AS faculty_name,
   (SELECT COUNT(*)::integer FROM lessonplans l WHERE l.subjectteacher_subject_id=t.subjectteacher_subject_id AND l.deleted_at IS NULL) AS lesson_count,
   (SELECT COUNT(*)::integer FROM lessonplans l WHERE l.subjectteacher_subject_id=t.subjectteacher_subject_id AND l.deleted_at IS NULL AND BTRIM(l.ppt)<>'') AS ppt_count
   FROM subjectteacher t LEFT JOIN subjects s ON s.subject_id=t.subjectteacher_subject_id LEFT JOIN users u ON u.user_id=t.subjectteacher_employee_id LEFT JOIN academic_years y ON y.academic_year_id=t.academic_year_id LEFT JOIN academic_branches br ON br.branch_id=t.branch_id ORDER BY t.subjectteacher_id DESC`;
  else sql=`SELECT a.*,br.branch_name,sd.is_active AS semester_active,
   (SELECT COUNT(*)::integer FROM attendance_roster r WHERE r.assignment_id=a.shst_id) AS student_count
   FROM (${assignmentQuery}) a LEFT JOIN academic_branches br ON br.branch_id=a.branch_id LEFT JOIN semester_defined sd ON sd.id=a.semester_definition_id
   WHERE a.allotment_kind='${kind==='substitutes'?'T':'P'}' ORDER BY a.shst_id DESC`;
  reply(res,200,{records:(await pool.query(sql)).rows});return true;
 }
 if(req.method==='DELETE'&&id){
  const client=await pool.connect();try{await client.query('BEGIN');
   if(kind==='teachers'&&(await client.query('SELECT a.shst_id FROM section_house_subject_teacher a JOIN subjectteacher t ON t.subjectteacher_subject_id=a.shst_subject_id AND t.subjectteacher_employee_id=a.shst_teacher_id WHERE t.subjectteacher_id=$1',[id])).rowCount)fail('Remove linked class allotments before deleting this subject-teacher assignment.');
   const result=await client.query(`DELETE FROM ${table} WHERE ${pk}=$1${['allotments','substitutes'].includes(kind)?` AND allotment_kind='${kind==='substitutes'?'T':'P'}'`:''} RETURNING ${pk}`,[id]);
   await client.query('COMMIT');reply(res,result.rowCount?200:404,result.rowCount?{ok:true}:{error:'Record not found.'});
  }catch(error){await client.query('ROLLBACK');throw error;}finally{client.release();}return true;
 }
 if((req.method==='POST'&&!id)||(req.method==='PATCH'&&id)){
  const input=await body(req);if(!input||typeof input!=='object')fail('Provide the form values.');
  const client=await pool.connect();try{await client.query('BEGIN');
   let existing;if(id){existing=(await client.query(`SELECT * FROM ${table} WHERE ${pk}=$1 FOR UPDATE`,[id])).rows[0];if(!existing||(['allotments','substitutes'].includes(kind)&&existing.allotment_kind!==(kind==='substitutes'?'T':'P'))){await client.query('ROLLBACK');reply(res,404,{error:'Record not found.'});return true;}}
   let data;
   if(kind==='semesters'){
    if(!positive(input.course_id)||!positive(input.batch_id)||!Number.isInteger(Number(input.semester))||Number(input.semester)<1||input.class_type!=='S'||!bit(input.is_active)||!bit(input.consider_for_accounts))fail('Choose Course, Batch, Semester, Class Type, active status and accounting status.');
    const course=(await client.query('SELECT course_duration FROM courses WHERE course_id=$1 FOR SHARE',[input.course_id])).rows[0];
    const limit=courseSemesterCount(course?.course_duration);
    if(!limit||Number(input.semester)>limit)fail('Select a Semester from 1 to '+limit+' for the selected Course duration.');
    if(!(await client.query('SELECT batch_id FROM batches WHERE batch_id=$1 AND batch_course_id=$2 FOR SHARE',[input.batch_id,input.course_id])).rowCount)fail('Select a Batch belonging to the Course.');
    if(id&&(await client.query('SELECT shst_id FROM section_house_subject_teacher WHERE semester_definition_id=$1 UNION ALL SELECT timetable_id FROM timetable_schedules WHERE batch_semester_id=$1',[id])).rowCount&&(String(existing.sem_course_master_id)!==String(input.course_id)||String(existing.sem_batch_master_id)!==String(input.batch_id)||String(existing.semester)!==String(input.semester)||existing.sem_section_house_type!==input.class_type))fail('This semester is used by class allotments. Only its active and accounting status can be changed.');
    data={sem_course_master_id:input.course_id,sem_batch_master_id:input.batch_id,semester:Number(input.semester),sem_section_house_type:input.class_type,is_active:Number(input.is_active),consider_for_accounts:Number(input.consider_for_accounts)};
   }else if(kind==='teachers'){
    if(!positive(input.subject_id)||!positive(input.teacher_id)||!bit(input.lessonplan_required)||!bit(input.study_note_required)||typeof input.library_submitted!=='boolean')fail('Choose Faculty, Subject and the required material settings.');
    if(!positive(input.academic_year_id)||!positive(input.branch_id)||!positive(input.semester))fail('Choose Academic Year, Branch and Semester.');
    const subject=(await client.query('SELECT subject_id,academic_year_id,branch_id,semester FROM subjects WHERE subject_id=$1 FOR SHARE',[input.subject_id])).rows[0];
    if(!subject||String(subject.academic_year_id)!==String(input.academic_year_id)||String(subject.branch_id)!==String(input.branch_id)||String(subject.semester)!==String(input.semester))fail('Select a Subject matching the Academic Year, Branch and Semester.');
    await validFaculty(client,input.teacher_id);
    if(id&&(String(existing.subjectteacher_subject_id)!==String(input.subject_id)||String(existing.subjectteacher_employee_id)!==String(input.teacher_id))&&(await client.query('SELECT shst_id FROM section_house_subject_teacher WHERE shst_subject_id=$1 AND shst_teacher_id=$2',[existing.subjectteacher_subject_id,existing.subjectteacher_employee_id])).rowCount)fail('Remove linked class allotments before changing this subject or faculty.');
    data={academic_year_id:input.academic_year_id,branch_id:input.branch_id,semester:Number(input.semester),subjectteacher_subject_id:input.subject_id,subjectteacher_employee_id:input.teacher_id,lessonplan_exempted:1-Number(input.lessonplan_required),study_material_exempted:1-Number(input.study_note_required),library_submitted:input.library_submitted,is_status:1};
   }else{
    if(!positive(input.semester_definition_id)||!positive(input.section_id)||!positive(input.subjectteacher_id)||!['M','A','C','S'].includes(input.teacher_type)||typeof input.student_group!=='string'||!/^[A-Z0-9]{1,3}$/.test(input.student_group))fail('Choose Batch/Semester, Section, Subject, Faculty, Student Group and Teacher Type.');
    const semester=(await client.query('SELECT * FROM semester_defined WHERE id=$1 FOR SHARE',[input.semester_definition_id])).rows[0];
    if(!semester||!semester.is_active||semester.sem_section_house_type!=='S')fail('Choose an active defined semester.');
    const eligible=(await client.query('SELECT t.*,s.branch_id FROM subjectteacher t JOIN subjects s ON s.subject_id=t.subjectteacher_subject_id WHERE t.subjectteacher_id=$1 FOR SHARE OF t,s',[input.subjectteacher_id])).rows[0];
    if(!eligible)fail('Assign the faculty to the subject first.');await validFaculty(client,eligible.subjectteacher_employee_id);
    const section=semester.sem_section_house_type==='S'?(await client.query('SELECT s_id FROM section WHERE s_id=$1 AND section_batch_id=$2 FOR SHARE',[input.section_id,semester.sem_batch_master_id])).rows[0]:(await client.query('SELECT section_master_id FROM section_master WHERE section_master_id=$1 FOR SHARE',[input.section_id])).rows[0];
    if(!section)fail('Choose a Section belonging to this Batch.');
    const branchId=input.branch_id||eligible.branch_id||null;
    if(kind==='substitutes'&&!positive(branchId))fail('Choose a Branch for the substitute allotment.');
    if(branchId&&(!(await client.query('SELECT branch_id FROM academic_branches WHERE branch_id=$1 AND course_id=$2 FOR SHARE',[branchId,semester.sem_course_master_id])).rowCount||(eligible.branch_id&&String(eligible.branch_id)!==String(branchId))))fail('Choose a Branch matching the Course and Subject.');
    const identity=[semester.id,input.section_id,eligible.subjectteacher_subject_id,eligible.subjectteacher_employee_id,input.student_group,input.teacher_type,kind];await client.query('SELECT pg_advisory_xact_lock(hashtextextended($1,0))',[identity.join(':')]);
    if((await client.query(`SELECT shst_id FROM section_house_subject_teacher WHERE shst_course_id=$1 AND shst_batch_id=$2::text AND shst_semester=$3 AND shst_section_house_type=$4 AND shst_section_house_id=$5 AND shst_subject_id=$6 AND shst_teacher_id=$7 AND student_group=$8 AND teacher_type=$9 AND allotment_kind=$10 AND ($11::bigint IS NULL OR shst_id<>$11)`,[semester.sem_course_master_id,semester.sem_batch_master_id,semester.semester,semester.sem_section_house_type,input.section_id,eligible.subjectteacher_subject_id,eligible.subjectteacher_employee_id,input.student_group,input.teacher_type,kind==='substitutes'?'T':'P',id||null])).rowCount)fail('This class/subject/teacher allotment already exists.');
    if(id&&(await client.query('SELECT session_id FROM attendance_sessions WHERE assignment_id=$1 UNION ALL SELECT id FROM lecture_notes WHERE assignment_id=$1 UNION ALL SELECT student_id FROM attendance_roster WHERE assignment_id=$1 UNION ALL SELECT cell_id FROM timetable_schedule_cells WHERE allotment_id=$1 LIMIT 1',[id])).rowCount)fail('This allotment has students, attendance, lecture notes or timetable periods. Create a new allotment to preserve its history.');
    data={shst_course_id:semester.sem_course_master_id,shst_batch_id:String(semester.sem_batch_master_id),shst_semester:semester.semester,shst_section_house_type:semester.sem_section_house_type,shst_section_house_id:input.section_id,shst_semester_master_id:semester.id,shst_subject_id:eligible.subjectteacher_subject_id,shst_teacher_id:eligible.subjectteacher_employee_id,teacher_type:input.teacher_type,student_group:input.student_group,semester_definition_id:semester.id,subjectteacher_id:eligible.subjectteacher_id,branch_id:branchId,allotment_kind:kind==='substitutes'?'T':'P',is_status:1};
   }
   const entries=Object.entries(data);let result;
   if(id){entries.push(['updated_by',user.user_id]);result=await client.query(`UPDATE ${table} SET ${entries.map(([key],index)=>key+'=$'+(index+1)).join(',')},updated_at=NOW() WHERE ${pk}=$${entries.length+1} RETURNING ${pk}`,[...entries.map(([,value])=>value),id]);}
   else{entries.push(['created_by',user.user_id]);result=await client.query(`INSERT INTO ${table}(${entries.map(([key])=>key).join(',')},created_at) VALUES(${entries.map((_,index)=>'$'+(index+1)).join(',')},NOW()) RETURNING ${pk}`,entries.map(([,value])=>value));}
   await client.query('COMMIT');reply(res,id?200:201,{ok:true,id:result.rows[0][pk]});
  }catch(error){await client.query('ROLLBACK');throw error;}finally{client.release();}return true;
 }
 reply(res,405,{error:'Method not allowed.'});return true;
}
async function validFaculty(client,id){if(!positive(id)||!(await client.query("SELECT u.user_id FROM users u JOIN user_roles r USING(role_id) WHERE u.user_id=$1 AND r.role_name='Faculty' AND u.is_active=TRUE FOR SHARE OF u",[id])).rowCount)fail('Choose an active Faculty account.');}
