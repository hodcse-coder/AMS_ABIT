import {pool} from './db.mjs';
import {assignmentQuery} from './lecture-notes.mjs';
import {timetableToday} from '../shared/timetable.mjs';
const base='/api/admin/timetable';
const fail=message=>{throw Object.assign(new Error(message),{status:400});};
const positive=value=>Number.isSafeInteger(Number(value))&&Number(value)>0;
const text=(value,label,max)=>{const result=typeof value==='string'?value.trim():'';if(!result||result.length>max)fail('Enter '+label+' (up to '+max+' characters).');return result;};
function date(value,label,optional=false){if(optional&&!value)return null;if(typeof value!=='string'||!/^\d{4}-\d{2}-\d{2}$/.test(value)||!Number.isFinite(Date.parse(value+'T00:00:00Z'))||new Date(value+'T00:00:00Z').toISOString().slice(0,10)!==value)fail('Enter a valid '+label+'.');return value;}
const periodQuery=`SELECT c.cell_id,c.timetable_id,c.day_of_week,c.period_number,c.start_time::text,c.end_time::text,c.allotment_id,c.room_id,c.notes,
 t.timetable_name,t.batch_semester_id,t.section_id,t.effective_from::text,t.effective_to::text,t.is_published,
 a.shst_teacher_id AS faculty_id,a.shst_subject_id AS subject_id,a.shst_course_id AS course_id,a.shst_semester AS semester,a.student_group,
 u.full_name AS faculty_name,s.subject_name,s.subject_code,co.course_name,b.batch_name,sec.section_name,r.room_no,r.building,r.floor_name,r.manager_id
 FROM timetable_schedule_cells c JOIN timetable_schedules t USING(timetable_id) JOIN section_house_subject_teacher a ON a.shst_id=c.allotment_id
 JOIN users u ON u.user_id=a.shst_teacher_id JOIN subjects s ON s.subject_id=a.shst_subject_id JOIN courses co ON co.course_id=a.shst_course_id
 JOIN semester_defined sd ON sd.id=t.batch_semester_id JOIN batches b ON b.batch_id=sd.sem_batch_master_id JOIN section sec ON sec.s_id=t.section_id
 JOIN timetable_rooms r ON r.room_id=c.room_id`;
const scheduleQuery=`SELECT t.*,t.effective_from::text AS effective_from,t.effective_to::text AS effective_to,c.course_name,b.batch_name,sd.semester,sec.section_name,
 (SELECT COUNT(*)::integer FROM timetable_schedule_cells cell WHERE cell.timetable_id=t.timetable_id) AS period_count
 FROM timetable_schedules t JOIN semester_defined sd ON sd.id=t.batch_semester_id JOIN courses c ON c.course_id=sd.sem_course_master_id
 JOIN batches b ON b.batch_id=sd.sem_batch_master_id JOIN section sec ON sec.s_id=t.section_id`;
async function cohort(client,semesterId,sectionId){
 if(!positive(semesterId)||!positive(sectionId))fail('Select Batch/Semester and Section.');
 const semester=(await client.query('SELECT d.*,b.batch_name FROM semester_defined d JOIN batches b ON b.batch_id=d.sem_batch_master_id WHERE d.id=$1 AND is_active=1 AND sem_section_house_type=\'S\' FOR SHARE',[semesterId])).rows[0];
 if(!semester||!(await client.query('SELECT s_id FROM section WHERE s_id=$1 AND section_batch_id=$2 FOR SHARE',[sectionId,semester.sem_batch_master_id])).rowCount)fail('Choose an active semester and a Section belonging to its Batch.');return semester;
}
async function checkedCells(client,plan,input){
 if(!Array.isArray(input)||input.length>140)fail('Provide up to 140 periods.');
 const semester=await cohort(client,plan.batch_semester_id,plan.section_id),periods=[];
 for(const row of input){
  if(!row||!Number.isInteger(Number(row.day_of_week))||Number(row.day_of_week)<1||Number(row.day_of_week)>7||!Number.isInteger(Number(row.period_number))||Number(row.period_number)<1||Number(row.period_number)>20||!positive(row.allotment_id)||!positive(row.room_id))fail('Select a valid Day, Period, Subject/Teacher and Room for each period.');
  const start=String(row.start_time||'').slice(0,5),end=String(row.end_time||'').slice(0,5);if(![start,end].every(time=>/^([01]\d|2[0-3]):[0-5]\d$/.test(time))||end<=start)fail('Each period End Time must be after Start Time.');
  const a=(await client.query('SELECT a.*,u.is_active FROM section_house_subject_teacher a JOIN users u ON u.user_id=a.shst_teacher_id WHERE shst_id=$1 FOR SHARE OF a,u',[row.allotment_id])).rows[0];
  if(!a||!a.is_active||String(a.shst_course_id)!==String(semester.sem_course_master_id)||![String(semester.sem_batch_master_id),semester.batch_name].includes(String(a.shst_batch_id))||String(a.shst_semester)!==String(semester.semester)||a.shst_section_house_type!=='S'||String(a.shst_section_house_id)!==String(plan.section_id))fail('Choose a Subject/Teacher allotted to this Batch, Semester and Section.');
  const room=(await client.query('SELECT * FROM timetable_rooms WHERE room_id=$1 AND is_active=TRUE FOR SHARE',[row.room_id])).rows[0];if(!room)fail('Select an active classroom.');
  const notes=typeof row.notes==='string'?row.notes.trim():'';if(notes.length>500)fail('Period notes must be at most 500 characters.');
  periods.push({day:Number(row.day_of_week),number:Number(row.period_number),start,end,allotment_id:a.shst_id,faculty_id:a.shst_teacher_id,room_id:room.room_id,room_no:room.room_no,notes});
 }
 for(const [index,a] of periods.entries())for(const b of periods.slice(index+1))if(a.day===b.day&&(a.number===b.number||a.start<b.end&&a.end>b.start))fail('Periods in this class cannot duplicate or overlap on the same day.');
 return periods;
}
async function conflicts(client,plan,periods){
 for(const row of periods){const collision=(await client.query(`SELECT t.timetable_name FROM timetable_schedule_cells c JOIN timetable_schedules t USING(timetable_id)
  JOIN section_house_subject_teacher a ON a.shst_id=c.allotment_id WHERE t.is_published=TRUE AND t.timetable_id<>$1 AND c.day_of_week=$2
  AND c.start_time<$4::time AND c.end_time>$3::time AND t.effective_from<=COALESCE($6::date,'infinity'::date) AND COALESCE(t.effective_to,'infinity'::date)>=$5::date
  AND (a.shst_teacher_id=$7 OR c.room_id=$8 OR (t.batch_semester_id=$9 AND t.section_id=$10)) LIMIT 1`,[plan.timetable_id||0,row.day,row.start,row.end,plan.effective_from,plan.effective_to,row.faculty_id,row.room_id,plan.batch_semester_id,plan.section_id])).rows[0];if(collision)fail('Teacher, classroom or class time clashes with published timetable: '+collision.timetable_name+'.');}
}
export async function handleTimetable(req,res,path,user,body,reply){
 const mine=path==='/api/timetable/mine',managed=path==='/api/timetable/floor';
 if(!mine&&!managed&&path!==base&&!path.startsWith(base+'/'))return false;
 if(!mine&&!managed&&user.role_name!=='Admin'&&user.authorized_module!=='timetable'){reply(res,403,{error:'Administrator access required.'});return true;}
 if((mine||managed||path===base+'/view')&&req.method==='GET'){
  const params=new URL(req.url||path,'http://localhost').searchParams,day=date(params.get('date')||timetableToday(),'view date');
  let where=' WHERE t.is_published=TRUE AND t.effective_from<=$1::date AND (t.effective_to IS NULL OR t.effective_to>=$1::date)',values=[day];
  if(mine){where+=` AND (a.shst_teacher_id=$2 OR EXISTS(SELECT 1 FROM timetable_faculty_access f WHERE f.user_id=$2 AND f.employee_id=a.shst_teacher_id AND f.is_active)
   OR EXISTS(SELECT 1 FROM timetable_course_access ac WHERE ac.user_id=$2 AND ac.batch_semester_id=t.batch_semester_id AND ac.section_id=t.section_id AND ac.is_active)
   OR EXISTS(SELECT 1 FROM course_students cs JOIN students st USING(user_id) WHERE cs.user_id=$2 AND cs.course_id=a.shst_course_id AND cs.batch_id=sd.sem_batch_master_id AND cs.section_id=t.section_id AND st.semester=a.shst_semester))`;values.push(user.user_id);}
  if(managed){where+=' AND r.manager_id=$2';values.push(user.user_id);}
  const periods=(await pool.query(periodQuery+where+' ORDER BY c.day_of_week,c.start_time,c.period_number',values)).rows;
  const faculty=mine||managed?[]:(await pool.query("SELECT u.user_id,u.full_name FROM users u JOIN user_roles r USING(role_id) WHERE r.role_name='Faculty' AND u.is_active=TRUE ORDER BY full_name")).rows;
  const rooms=(await pool.query('SELECT r.*,u.full_name AS manager_name FROM timetable_rooms r LEFT JOIN users u ON u.user_id=r.manager_id'+(managed?' WHERE r.manager_id=$1':' WHERE r.is_active=TRUE')+' ORDER BY r.building,r.floor_name,r.room_no',managed?[user.user_id]:[])).rows;
  reply(res,200,{periods,faculty,rooms:mine?rooms.filter(room=>periods.some(period=>String(period.room_id)===String(room.room_id))):rooms,date:day});return true;
 }
 if(path===base+'/options'&&req.method==='GET'){
  const result={};const queries={semesters:'SELECT d.*,c.course_name,b.batch_name FROM semester_defined d JOIN courses c ON c.course_id=d.sem_course_master_id JOIN batches b ON b.batch_id=d.sem_batch_master_id WHERE d.is_active=1 AND d.sem_section_house_type=\'S\' ORDER BY c.course_name,b.batch_name,d.semester',sections:'SELECT s_id,section_name,section_batch_id FROM section ORDER BY section_name',rooms:'SELECT * FROM timetable_rooms ORDER BY room_no',allotments:assignmentQuery+' ORDER BY s.subject_name,u.full_name',users:'SELECT u.user_id,u.full_name,r.role_name FROM users u JOIN user_roles r USING(role_id) WHERE u.is_active=TRUE ORDER BY u.full_name'};
  await Promise.all(Object.entries(queries).map(async([key,sql])=>{result[key]=(await pool.query(sql)).rows;}));reply(res,200,result);return true;
 }
 if(path===base+'/schedules'&&req.method==='GET'){reply(res,200,{records:(await pool.query(scheduleQuery+' ORDER BY t.timetable_id DESC')).rows});return true;}
 if(path===base+'/rooms'&&req.method==='GET'){reply(res,200,{records:(await pool.query('SELECT r.*,u.full_name AS manager_name FROM timetable_rooms r LEFT JOIN users u ON u.user_id=r.manager_id ORDER BY room_no')).rows});return true;}
 const schedule=path.match(/^\/api\/admin\/timetable\/schedules\/(\d+)(\/cells)?$/);
 if(schedule&&req.method==='GET'){
  const plan=(await pool.query(scheduleQuery+' WHERE t.timetable_id=$1',[schedule[1]])).rows[0];if(!plan){reply(res,404,{error:'Timetable not found.'});return true;}
  reply(res,200,{schedule:plan,cells:(await pool.query(periodQuery+' WHERE t.timetable_id=$1 ORDER BY c.day_of_week,c.period_number',[plan.timetable_id])).rows});return true;
 }
 if(path===base+'/access'&&req.method==='GET'){
  const faculty=(await pool.query('SELECT a.*,u.full_name AS viewer,f.full_name AS faculty_name FROM timetable_faculty_access a JOIN users u ON u.user_id=a.user_id JOIN users f ON f.user_id=a.employee_id WHERE a.is_active')).rows;
  const courses=(await pool.query('SELECT a.*,u.full_name AS viewer,c.course_name,b.batch_name,d.semester,s.section_name FROM timetable_course_access a JOIN users u ON u.user_id=a.user_id JOIN semester_defined d ON d.id=a.batch_semester_id JOIN courses c ON c.course_id=d.sem_course_master_id JOIN batches b ON b.batch_id=d.sem_batch_master_id JOIN section s ON s.s_id=a.section_id WHERE a.is_active')).rows;
  reply(res,200,{faculty,courses});return true;
 }
 if(!['POST','PATCH','PUT','DELETE'].includes(req.method)){reply(res,405,{error:'Method not allowed.'});return true;}
 const client=await pool.connect();try{await client.query('BEGIN');await client.query('SELECT pg_advisory_xact_lock(84102731)');
  const input=req.method==='DELETE'?{}:await body(req);let result;
  const room=path.match(/^\/api\/admin\/timetable\/rooms(?:\/(\d+))?$/),access=path.match(/^\/api\/admin\/timetable\/access(?:\/(faculty|course)\/(\d+))?$/);
  if(room&&((!room[1]&&req.method==='POST')||(room[1]&&['PATCH','DELETE'].includes(req.method)))){
   if(req.method==='DELETE'){result=await client.query('DELETE FROM timetable_rooms WHERE room_id=$1 RETURNING room_id',[room[1]]);}
   else{
    const number=text(input.room_no,'Room No.',50).toUpperCase(),building=text(input.building,'Building',100),floor=text(input.floor_name,'Floor',30),capacity=Number(input.capacity);
    if(!Number.isInteger(capacity)||capacity<1||capacity>1000||!['CLASSROOM','LAB','SEMINAR'].includes(input.room_type)||typeof input.is_active!=='boolean')fail('Choose Room Type, Capacity (1–1000) and active status.');
    if(input.manager_id&&!(await client.query("SELECT u.user_id FROM users u JOIN user_roles r USING(role_id) WHERE u.user_id=$1 AND u.is_active AND r.role_name IN('Admin','Faculty','Employee')",[input.manager_id])).rowCount)fail('Select an active employee as Floor Manager.');
    if(room[1]&&!input.is_active&&(await client.query('SELECT c.cell_id FROM timetable_schedule_cells c JOIN timetable_schedules t USING(timetable_id) WHERE c.room_id=$1 AND t.is_published AND (t.effective_to IS NULL OR t.effective_to>=$2::date) LIMIT 1',[room[1],timetableToday()])).rowCount)fail('Remove this room from current published timetables before deactivating it.');
    const values=[number,building,floor,capacity,input.room_type,input.manager_id||null,input.is_active,user.user_id];
    result=room[1]?await client.query('UPDATE timetable_rooms SET room_no=$1,building=$2,floor_name=$3,capacity=$4,room_type=$5,manager_id=$6,is_active=$7,updated_by=$8,updated_at=NOW() WHERE room_id=$9 RETURNING room_id',[...values,room[1]]):await client.query('INSERT INTO timetable_rooms(room_no,building,floor_name,capacity,room_type,manager_id,is_active,created_by) VALUES($1,$2,$3,$4,$5,$6,$7,$8) RETURNING room_id',values);
   }
  }else if((path===base+'/schedules'&&req.method==='POST')||(schedule&&!schedule[2]&&['PATCH','DELETE'].includes(req.method))){
   if(req.method==='DELETE')result=await client.query('DELETE FROM timetable_schedules WHERE timetable_id=$1 RETURNING timetable_id',[schedule[1]]);
   else{
    const name=text(input.timetable_name,'Timetable Name',150),from=date(input.effective_from,'Effective From'),to=date(input.effective_to,'Effective To',true);if(to&&to<from)fail('Effective To cannot be before Effective From.');if(typeof input.is_published!=='boolean')fail('Select the publication status.');
    await cohort(client,input.batch_semester_id,input.section_id);
    let old;if(schedule){old=(await client.query('SELECT * FROM timetable_schedules WHERE timetable_id=$1 FOR UPDATE',[schedule[1]])).rows[0];if(!old){await client.query('ROLLBACK');reply(res,404,{error:'Timetable not found.'});return true;}}
    const cells=old?(await client.query('SELECT * FROM timetable_schedule_cells WHERE timetable_id=$1',[old.timetable_id])).rows:[];
    if(cells.length&&(String(old.batch_semester_id)!==String(input.batch_semester_id)||String(old.section_id)!==String(input.section_id)))fail('Clear existing periods before changing the Batch/Semester or Section.');
    const plan={timetable_id:old?.timetable_id,batch_semester_id:input.batch_semester_id,section_id:input.section_id,effective_from:from,effective_to:to};
    if(input.is_published){if(!cells.length)fail('Add periods before publishing the timetable.');await conflicts(client,plan,await checkedCells(client,plan,cells));}
    const values=[input.batch_semester_id,input.section_id,name,from,to,input.is_published,user.user_id];
    result=old?await client.query('UPDATE timetable_schedules SET batch_semester_id=$1,section_id=$2,timetable_name=$3,effective_from=$4,effective_to=$5,is_published=$6,updated_by=$7,updated_at=NOW() WHERE timetable_id=$8 RETURNING timetable_id',[...values,old.timetable_id]):await client.query('INSERT INTO timetable_schedules(batch_semester_id,section_id,timetable_name,effective_from,effective_to,is_published,created_by) VALUES($1,$2,$3,$4,$5,$6,$7) RETURNING timetable_id',values);
   }
  }else if(schedule&&schedule[2]&&req.method==='PUT'){
   const stored=(await client.query('SELECT *,effective_from::text AS effective_from,effective_to::text AS effective_to FROM timetable_schedules WHERE timetable_id=$1 FOR UPDATE',[schedule[1]])).rows[0];if(!stored){await client.query('ROLLBACK');reply(res,404,{error:'Timetable not found.'});return true;}
   const periods=await checkedCells(client,stored,input.cells);if(stored.is_published){if(!periods.length)fail('Unpublish the timetable before removing all periods.');await conflicts(client,stored,periods);}
   await client.query('DELETE FROM timetable_schedule_cells WHERE timetable_id=$1',[stored.timetable_id]);
   for(const row of periods)await client.query('INSERT INTO timetable_schedule_cells(timetable_id,day_of_week,period_number,start_time,end_time,allotment_id,room_id,room_no,notes) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9)',[stored.timetable_id,row.day,row.number,row.start,row.end,row.allotment_id,row.room_id,row.room_no,row.notes]);
   await client.query('UPDATE timetable_schedules SET updated_at=NOW(),updated_by=$2 WHERE timetable_id=$1',[stored.timetable_id,user.user_id]);result={rowCount:1,rows:[{timetable_id:stored.timetable_id}]};
  }else if(access&&((!access[1]&&req.method==='POST')||(access[1]&&req.method==='DELETE'))){
   if(req.method==='DELETE'){const table=access[1]==='faculty'?'timetable_faculty_access':'timetable_course_access';result=await client.query('DELETE FROM '+table+' WHERE access_id=$1 RETURNING access_id',[access[2]]);}
   else{
    if(!positive(input.user_id)||!(await client.query('SELECT user_id FROM users WHERE user_id=$1 AND is_active',[input.user_id])).rowCount)fail('Choose an active viewer.');
    if(input.type==='faculty'){
     if(!positive(input.employee_id)||!(await client.query("SELECT u.user_id FROM users u JOIN user_roles r USING(role_id) WHERE u.user_id=$1 AND r.role_name='Faculty' AND u.is_active",[input.employee_id])).rowCount)fail('Choose an active Faculty member.');
     result=await client.query('INSERT INTO timetable_faculty_access(user_id,employee_id) VALUES($1,$2) ON CONFLICT(user_id,employee_id) DO UPDATE SET is_active=TRUE RETURNING access_id',[input.user_id,input.employee_id]);
    }else if(input.type==='course'){await cohort(client,input.batch_semester_id,input.section_id);result=await client.query('INSERT INTO timetable_course_access(user_id,batch_semester_id,section_id) VALUES($1,$2,$3) ON CONFLICT(user_id,batch_semester_id,section_id) DO UPDATE SET is_active=TRUE RETURNING access_id',[input.user_id,input.batch_semester_id,input.section_id]);}else fail('Choose Faculty or Class access.');
   }
  }else{await client.query('ROLLBACK');reply(res,405,{error:'Method not allowed.'});return true;}
  await client.query('COMMIT');reply(res,result.rowCount?(req.method==='POST'?201:200):404,result.rowCount?{ok:true,id:Object.values(result.rows[0])[0]}:{error:'Record not found.'});
 }catch(error){await client.query('ROLLBACK');throw error;}finally{client.release();}return true;
}
