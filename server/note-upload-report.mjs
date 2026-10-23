import {pool} from './db.mjs';

export async function handleNoteUploadReport(req,res,path,user,body,reply){
 if(path!=='/api/admin/academics/note-upload-report')return false;
 if(req.method!=='GET'){reply(res,405,{error:'Method not allowed.'});return true;}
 const {rows}=await pool.query('SELECT * FROM lecture_note_upload_report ORDER BY id DESC');
 reply(res,200,{records:rows});return true;
}
