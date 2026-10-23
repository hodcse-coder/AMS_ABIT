import {pool} from './db.mjs';
export async function handleStudentAttendanceReport(req,res,path,user,body,reply){
 if(path!=='/api/admin/academics/student-attendance')return false;
 if(req.method!=='GET'){reply(res,405,{error:'Method not allowed.'});return true;}
 const {rows}=await pool.query('SELECT * FROM student_attendance_summary ORDER BY attendance_date DESC NULLS LAST,start_time DESC,id DESC');
 reply(res,200,{records:rows});return true;
}
