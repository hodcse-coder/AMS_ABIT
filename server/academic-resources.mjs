import {handleStudentAttendanceReport} from './student-attendance-report.mjs';
import {handleAttendance} from './attendance.mjs';
import {handleVideoLectures} from './video-lectures.mjs';
import {handleNoteUploadReport} from './note-upload-report.mjs';
import {handleLectureNotes} from './lecture-notes.mjs';
import {handleLessonPlans} from './lesson-plans.mjs';
import {handleCourseOutcomes} from './course-outcomes.mjs';
import {handlePreferredBooks} from './preferred-books.mjs';
﻿import {pool} from './db.mjs';
import {academicResources} from '../shared/academic-resources.mjs';
export async function handleAcademicResources(req,res,path,user,body,reply){
 if(await handleStudentAttendanceReport(req,res,path,user,body,reply))return true;
 if(await handleAttendance(req,res,path,user,body,reply))return true;
 if(await handleVideoLectures(req,res,path,user,body,reply))return true;
 if(await handleNoteUploadReport(req,res,path,user,body,reply))return true;
 if(await handleLectureNotes(req,res,path,user,body,reply))return true;
 if(await handleLessonPlans(req,res,path,user,body,reply))return true;
 if(await handleCourseOutcomes(req,res,path,user,body,reply))return true;
 if(await handlePreferredBooks(req,res,path,user,body,reply))return true;
 if(path==='/api/admin/academics'&&req.method==='GET'){const counts={};for(const item of academicResources){counts[item.key]=Number((await pool.query('SELECT COUNT(*) AS total FROM '+item.table)).rows[0].total);}reply(res,200,{counts});return true;}
 if(!path.startsWith('/api/admin/academics/'))return false;
 const item=academicResources.find(item=>path==='/api/admin/academics/'+item.key);
 if(!item){reply(res,404,{error:'Academic module not found.'});return true;}
 if(req.method!=='GET'){reply(res,405,{error:'Method not allowed.'});return true;}
 const subjectKeys={lessonplans:'subjectteacher_subject_id',courseoutcome:'co_subject_id',faculty_books:'subject_id',lecture_notes:'subject',videolecture:'related_subject',student_attendance:'shst_subject_id'};
 const facultyKeys={faculty_books:'faculty_id',lecture_notes:'teacher'};
 const joins=[];const fields=['r.*'];
 if(subjectKeys[item.table]){joins.push('LEFT JOIN subjects s ON s.subject_id=r.'+subjectKeys[item.table]);fields.push('s.subject_name');}
 if(facultyKeys[item.table]){joins.push('LEFT JOIN users f ON f.user_id=r.'+facultyKeys[item.table]);fields.push('f.full_name AS faculty_name');}
 if(item.table==='student_attendance'){joins.push('LEFT JOIN users u ON u.user_id=r.student_attendance_student_id');fields.push('u.full_name AS student_name');}
 const {rows}=await pool.query('SELECT '+fields.join(',')+' FROM '+item.table+' r '+joins.join(' ')+' ORDER BY r.'+item.id+' DESC');
 reply(res,200,{records:rows});return true;
}
