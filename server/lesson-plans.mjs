import {pool} from './db.mjs';

const fail = message => { throw Object.assign(new Error(message), {status:400}); };
const positiveId = value => Number.isSafeInteger(Number(value)) && Number(value)>0;
const validUrl = value => {
 if (!value) return true;
 try { return ['http:','https:'].includes(new URL(value).protocol); } catch { return false; }
};

export async function handleLessonPlans(req,res,path,user,body,reply) {
 const match=path.match(/^\/api\/admin\/academics\/lesson-plan(?:\/subjects\/(\d+))?$/);
 if(!match)return false;
 const subjectId=match[1];
 if(req.method==='GET'&&!subjectId){
  const {rows}=await pool.query(`SELECT s.*,y.academic_year,b.branch_name,
   (SELECT COUNT(*)::integer FROM lessonplans l WHERE l.subjectteacher_subject_id=s.subject_id AND l.deleted_at IS NULL) AS topic_count
   FROM subjects s LEFT JOIN academic_years y USING(academic_year_id) LEFT JOIN academic_branches b USING(branch_id)
   ORDER BY y.academic_year DESC NULLS LAST,s.subject_name,s.subject_id`);
  reply(res,200,{records:rows});return true;
 }
 if(req.method==='GET'&&subjectId){
  const subject=(await pool.query(`SELECT s.*,y.academic_year,b.branch_name FROM subjects s
   LEFT JOIN academic_years y USING(academic_year_id) LEFT JOIN academic_branches b USING(branch_id) WHERE s.subject_id=$1`,[subjectId])).rows[0];
  if(!subject){reply(res,404,{error:'Subject not found.'});return true;}
  const books=(await pool.query("SELECT book_id,book_name,author FROM faculty_books WHERE subject_id=$1 AND BTRIM(book_name)<>'' ORDER BY book_id",[subjectId])).rows;
  const outcomes=(await pool.query('SELECT co_id,cotype,codescription FROM courseoutcome WHERE co_subject_id=$1 ORDER BY cotype,co_id',[subjectId])).rows;
  const topics=(await pool.query(`SELECT l.*,b.book_name AS current_book_name FROM lessonplans l LEFT JOIN faculty_books b USING(book_id)
   WHERE l.subjectteacher_subject_id=$1 AND l.deleted_at IS NULL ORDER BY l.module,l.lessonplan_id`,[subjectId])).rows;
  reply(res,200,{subject,books,outcomes,topics});return true;
 }
 if(req.method==='PUT'&&subjectId){
  const input=await body(req);
  if(!Array.isArray(input?.topics)||input.topics.length>100)fail('Provide up to 100 topics.');
  const topics=input.topics.map((row,index)=>{
   if(!row||typeof row!=='object')fail('Invalid topic.');
   const topics=typeof row.topics==='string'?row.topics.trim():'';
   const selections=Array.isArray(row.co)?row.co:typeof row.co==='string'?row.co.split(',').map(value=>value.trim()):[];
   const co=[...new Set(selections)].sort().join(', '),video=typeof row.video_url==='string'?row.video_url.trim():'';
   if(!topics||topics.length>5000)fail(`Topic ${index+1}: enter a description of up to 5000 characters.`);
   if(!selections.length||selections.length>5||selections.some(value=>!['CO-1','CO-2','CO-3','CO-4','CO-5'].includes(value)))fail(`Topic ${index+1}: select one or more COs from CO-1 to CO-5.`);
   if(!positiveId(row.book_id))fail(`Topic ${index+1}: choose a book.`);
   const page=row.pagenumber===''||row.pagenumber==null?0:Number(row.pagenumber);
   if(!Number.isSafeInteger(page)||page<0||page>1000000)fail(`Topic ${index+1}: enter a valid page number.`);
   if(!['0','1'].includes(String(row.ppt_req)))fail(`Topic ${index+1}: select the PPT requirement.`);
   if(video.length>2000||!validUrl(video))fail(`Topic ${index+1}: enter an http or https video URL.`);
   if(row.lessonplan_id!=null&&!positiveId(row.lessonplan_id))fail('Invalid topic ID.');
   return {id:row.lessonplan_id==null?null:String(row.lessonplan_id),topics,co,book_id:String(row.book_id),page,ppt_req:String(row.ppt_req),video};
  });
  const ids=topics.filter(row=>row.id).map(row=>row.id);
  if(new Set(ids).size!==ids.length)fail('A topic cannot appear twice.');
  const client=await pool.connect();
  try{
   await client.query('BEGIN');
   const subject=(await client.query('SELECT subject_id FROM subjects WHERE subject_id=$1 FOR UPDATE',[subjectId])).rows[0];
   if(!subject){await client.query('ROLLBACK');reply(res,404,{error:'Subject not found.'});return true;}
   const existing=(await client.query('SELECT lessonplan_id FROM lessonplans WHERE subjectteacher_subject_id=$1 AND deleted_at IS NULL FOR UPDATE',[subjectId])).rows;
   const allowed=new Set(existing.map(row=>String(row.lessonplan_id)));
   if(ids.some(id=>!allowed.has(id)))fail('A topic does not belong to this subject or has been removed. Reload the lesson plan.');
   const books=(await client.query("SELECT book_id,book_name FROM faculty_books WHERE subject_id=$1 AND BTRIM(book_name)<>'' FOR SHARE",[subjectId])).rows;
   if(topics.length&&!books.length)fail('Enter at least one book name in Preferred Books before adding topics.');
   const bookMap=new Map(books.map(row=>[String(row.book_id),row.book_name]));
   if(topics.some(row=>!bookMap.has(row.book_id)))fail('Choose a book belonging to this subject.');
   for(const [index,row] of topics.entries()){
    const values=[subjectId,index+1,row.topics,bookMap.get(row.book_id),row.page,row.ppt_req,row.video,row.co,row.book_id,user.user_id];
    if(row.id)await client.query(`UPDATE lessonplans SET module=$2,topics=$3,bookname=$4,pagenumber=$5,ppt_req=$6,video_url=$7,co=$8,book_id=$9,
     updated_at=NOW(),updated_by=$10 WHERE lessonplan_id=$11 AND subjectteacher_subject_id=$1`,[...values,row.id]);
    else await client.query(`INSERT INTO lessonplans(subjectteacher_subject_id,module,topics,bookname,pagenumber,ppt_req,video_url,co,book_id,created_by,subjectteacher_id,ppt,created_at,is_status)
     VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,0,'',NOW(),1)`,values);
   }
   // Retain removed topics for existing lesson-plan document and attendance references.
   const removed=existing.filter(row=>!ids.includes(String(row.lessonplan_id))).map(row=>row.lessonplan_id);
   if(removed.length)await client.query('UPDATE lessonplans SET deleted_at=NOW(),updated_at=NOW(),updated_by=$2 WHERE lessonplan_id=ANY($1::bigint[])',[removed,user.user_id]);
   await client.query('COMMIT');reply(res,200,{ok:true});
  }catch(error){await client.query('ROLLBACK');throw error;}finally{client.release();}
  return true;
 }
 reply(res,405,{error:'Method not allowed.'});return true;
}
