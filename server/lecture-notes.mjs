import {pool} from './db.mjs';
const base='/api/admin/academics/lecture-notes';
const fail=message=>{throw Object.assign(new Error(message),{status:400});};
const id=value=>Number.isSafeInteger(Number(value))&&Number(value)>0;
export const assignmentQuery=`SELECT a.*,c.course_name,c.course_code,b.batch_name,b.batch_id,
 CASE WHEN a.shst_section_house_type='H' THEN sm.section_master_name ELSE sec.section_name END AS section_name,
 s.subject_name,s.subject_code,s.subject_type,u.full_name AS faculty_name
 FROM section_house_subject_teacher a LEFT JOIN courses c ON c.course_id=a.shst_course_id
 LEFT JOIN LATERAL (SELECT batch_id,batch_name FROM batches WHERE batch_course_id=a.shst_course_id
  AND (batch_id::text=a.shst_batch_id OR batch_name=a.shst_batch_id) ORDER BY (batch_id::text=a.shst_batch_id) DESC LIMIT 1) b ON TRUE
 LEFT JOIN section sec ON sec.s_id=a.shst_section_house_id AND sec.section_batch_id=b.batch_id
 LEFT JOIN section_master sm ON sm.section_master_id=a.shst_section_house_id
 LEFT JOIN subjects s ON s.subject_id=a.shst_subject_id LEFT JOIN users u ON u.user_id=a.shst_teacher_id`;

function decodeFile(input){
 const name=typeof input.file_name==='string'?input.file_name.trim():'';
 const encoded=input.file_base64;
 if(!name||name.length>255||/[\x00-\x1f\x7f/\\]/.test(name))fail('Choose a valid file name of up to 255 characters.');
 if(typeof encoded!=='string'||!encoded||encoded.length>13981016||encoded.length%4!==0||!/^[A-Za-z0-9+/]+={0,2}$/.test(encoded))fail('Choose a document up to 10 MB.');
 const bytes=Buffer.from(encoded,'base64');
 if(!bytes.length||bytes.length>10485760||bytes.toString('base64')!==encoded)fail('Choose a document up to 10 MB.');
 const extension=name.split('.').pop().toLowerCase();
 const types={pdf:'application/pdf',doc:'application/msword',docx:'application/vnd.openxmlformats-officedocument.wordprocessingml.document',ppt:'application/vnd.ms-powerpoint',pptx:'application/vnd.openxmlformats-officedocument.presentationml.presentation'};
 if(!types[extension])fail('Choose a PDF, DOC, DOCX, PPT or PPTX file.');
 const valid=extension==='pdf'?bytes.subarray(0,5).toString()==='%PDF-':
  ['doc','ppt'].includes(extension)?bytes.subarray(0,8).equals(Buffer.from('d0cf11e0a1b11ae1','hex')):
  bytes.subarray(0,4).equals(Buffer.from('504b0304','hex'))&&bytes.includes(Buffer.from(extension==='docx'?'word/':'ppt/'));
 if(!valid)fail('The file contents do not match the selected document type.');
 return {name,bytes,type:types[extension]};
}

export async function handleLectureNotes(req,res,path,user,body,reply){
 if(path!==base&&!path.startsWith(base+'/'))return false;
 if(path===base&&req.method==='GET'){
  const rows=(await pool.query(assignmentQuery+' ORDER BY a.shst_id DESC')).rows;
  const notes=(await pool.query('SELECT id,assignment_id,teacher,subject,sem,description,file_name,file_type,file_size,(file_data IS NOT NULL) AS downloadable FROM lecture_notes ORDER BY id DESC')).rows;
  reply(res,200,{records:rows.map(row=>({...row,notes:notes.filter(note=>note.assignment_id?String(note.assignment_id)===String(row.shst_id):String(note.teacher)===String(row.shst_teacher_id)&&String(note.subject)===String(row.shst_subject_id)&&String(note.sem)===String(row.shst_semester))}))});return true;
 }
 if(path===base+'/options'&&req.method==='GET'){
  const [courses,batches,sections,houses,subjects,faculty]=await Promise.all([
   pool.query('SELECT course_id,course_name,course_code FROM courses ORDER BY course_name'),
   pool.query('SELECT batch_id,batch_course_id,batch_name FROM batches ORDER BY batch_name'),
   pool.query('SELECT s_id,section_name,section_batch_id FROM section ORDER BY section_name'),
   pool.query('SELECT section_master_id,section_master_name FROM section_master ORDER BY section_master_name'),
   pool.query('SELECT subject_id,subject_name,subject_code FROM subjects ORDER BY subject_name'),
   pool.query("SELECT u.user_id,u.full_name FROM users u JOIN user_roles r USING(role_id) WHERE r.role_name='Faculty' AND u.is_active=TRUE ORDER BY u.full_name")
  ]);
  reply(res,200,{courses:courses.rows,batches:batches.rows,sections:sections.rows,houses:houses.rows,subjects:subjects.rows,faculty:faculty.rows});return true;
 }
 if(path===base+'/assignments'&&req.method==='POST'){
  const input=await body(req);
  if(!input||!['course_id','batch_id','section_id','subject_id','teacher_id'].every(key=>id(input[key]))||!Number.isInteger(Number(input.semester))||Number(input.semester)<1||Number(input.semester)>12)fail('Select the course, batch, semester, section/house, subject and faculty.');
  const sectionType=input.section_type,teacherType=input.teacher_type,group=typeof input.student_group==='string'?input.student_group.trim().toUpperCase():'ALL';
  if(!['S','H'].includes(sectionType)||!['M','A'].includes(teacherType)||!group||!/^[A-Z0-9]{1,3}$/.test(group))fail('Choose a section/house and teacher type, and a student group of up to 3 letters or digits.');
  const client=await pool.connect();
  try{
   await client.query('BEGIN');
   const batch=(await client.query('SELECT batch_id FROM batches WHERE batch_id=$1 AND batch_course_id=$2 FOR SHARE',[input.batch_id,input.course_id])).rows[0];
   if(!batch)fail('Choose a Batch belonging to the Course.');
   const section=sectionType==='S'?(await client.query('SELECT s_id FROM section WHERE s_id=$1 AND section_batch_id=$2 FOR SHARE',[input.section_id,input.batch_id])).rows[0]:(await client.query('SELECT section_master_id FROM section_master WHERE section_master_id=$1 FOR SHARE',[input.section_id])).rows[0];
   if(!section)fail('Choose a valid section for the batch, or a saved house.');
   if(!(await client.query('SELECT subject_id FROM subjects WHERE subject_id=$1 FOR SHARE',[input.subject_id])).rowCount)fail('Subject not found.');
   if(!(await client.query("SELECT u.user_id FROM users u JOIN user_roles r USING(role_id) WHERE u.user_id=$1 AND r.role_name='Faculty' AND u.is_active=TRUE FOR SHARE OF u",[input.teacher_id])).rowCount)fail('Choose an active Faculty account.');
   // Serialize identical assignments without changing existing legacy mappings.
   const keys=[input.course_id,input.batch_id,input.semester,sectionType,input.section_id,input.subject_id,input.teacher_id,teacherType,group];
   await client.query('SELECT pg_advisory_xact_lock(hashtextextended($1,0))',[keys.join(':')]);
   const duplicate=await client.query(`SELECT shst_id FROM section_house_subject_teacher WHERE shst_course_id=$1 AND shst_batch_id=$2::text AND shst_semester=$3
    AND shst_section_house_type=$4 AND shst_section_house_id=$5 AND shst_subject_id=$6 AND shst_teacher_id=$7 AND teacher_type=$8 AND student_group=$9`,keys);
   if(duplicate.rowCount)fail('This teaching assignment already exists.');
   const result=await client.query(`INSERT INTO section_house_subject_teacher(shst_course_id,shst_batch_id,shst_semester,shst_section_house_type,shst_section_house_id,shst_subject_id,shst_teacher_id,teacher_type,student_group,shst_semester_master_id,created_at,created_by,is_status)
    VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,0,NOW(),$10,1) RETURNING shst_id`,[...keys,user.user_id]);
   await client.query('COMMIT');reply(res,201,{ok:true,id:result.rows[0].shst_id});
  }catch(error){await client.query('ROLLBACK');throw error;}finally{client.release();}return true;
 }
 const upload=path.match(/^\/api\/admin\/academics\/lecture-notes\/assignments\/(\d+)$/);
 if(upload&&req.method==='POST'){
  const input=await body(req),description=typeof input?.description==='string'?input.description.trim():'';
  if(!description||description.length>500)fail('Enter a note title of up to 500 characters.');
  const file=decodeFile(input),client=await pool.connect();
  try{
   await client.query('BEGIN');
   const assignment=(await client.query('SELECT * FROM section_house_subject_teacher WHERE shst_id=$1 FOR SHARE',[upload[1]])).rows[0];
   if(!assignment){await client.query('ROLLBACK');reply(res,404,{error:'Teaching assignment not found.'});return true;}
   const result=await client.query(`INSERT INTO lecture_notes(assignment_id,teacher,subject,sem,description,attachment,file_name,file_type,file_size,file_data,created_at,created_by,is_status)
    VALUES($1,$2,$3,$4,$5,$6::text,$6::text,$7,$8,$9,NOW(),$10,1) RETURNING id`,[assignment.shst_id,assignment.shst_teacher_id,assignment.shst_subject_id,assignment.shst_semester,description,file.name,file.type,file.bytes.length,file.bytes,user.user_id]);
   await client.query('COMMIT');reply(res,201,{ok:true,id:result.rows[0].id});
  }catch(error){await client.query('ROLLBACK');throw error;}finally{client.release();}return true;
 }
 const download=path.match(/^\/api\/admin\/academics\/lecture-notes\/(\d+)\/download$/);
 if(download&&req.method==='GET'){
  const file=(await pool.query('SELECT file_data,file_name FROM lecture_notes WHERE id=$1',[download[1]])).rows[0];
  if(!file?.file_data){reply(res,404,{error:'File not available. Upload the note again to restore its attachment.'});return true;}
  const ascii=file.file_name.replace(/[^a-zA-Z0-9._ -]/g,'_');
  res.writeHead(200,{'Content-Type':'application/octet-stream','Content-Length':file.file_data.length,'Content-Disposition':`attachment; filename="${ascii}"; filename*=UTF-8''${encodeURIComponent(file.file_name).replace(/['()*]/g,char=>'%'+char.charCodeAt(0).toString(16))}`,'X-Content-Type-Options':'nosniff','Cache-Control':'private, no-store'});
  res.end(file.file_data);return true;
 }
 reply(res,405,{error:'Method not allowed.'});return true;
}
