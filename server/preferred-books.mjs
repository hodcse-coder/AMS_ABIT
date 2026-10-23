import {pool} from './db.mjs';
const fail=message=>{throw Object.assign(new Error(message),{status:400});};
export async function handlePreferredBooks(req,res,path,user,body,reply){
 const match=path.match(/^\/api\/admin\/academics\/preferred-books(?:\/(\d+))?$/);if(!match)return false;const id=match[1];
 if(req.method==='GET'&&!id){const {rows}=await pool.query('SELECT b.*,s.subject_name,s.academic_year_id,s.branch_id,s.semester,y.academic_year,br.branch_name,u.full_name AS faculty_name FROM faculty_books b LEFT JOIN subjects s ON s.subject_id=b.subject_id LEFT JOIN academic_years y ON y.academic_year_id=s.academic_year_id LEFT JOIN academic_branches br ON br.branch_id=s.branch_id LEFT JOIN users u ON u.user_id=b.faculty_id ORDER BY b.book_id DESC');reply(res,200,{records:rows});return true;}
 if(req.method==='DELETE'&&id){const result=await pool.query('DELETE FROM faculty_books WHERE book_id=$1 RETURNING book_id',[id]);reply(res,result.rowCount?200:404,result.rowCount?{ok:true}:{error:'Book not found.'});return true;}
 if((req.method==='POST'&&!id)||(req.method==='PATCH'&&id)){
  const input=await body(req),subjectId=Number(input.subject_id),author=typeof input.author==='string'?input.author.trim().toUpperCase():'';
  if(!Number.isSafeInteger(subjectId)||subjectId<=0||!author||author.length>500)fail('Select a Subject and enter an Author (up to 500 characters).');
  const bookName=input.book_name==null?null:typeof input.book_name==='string'?input.book_name.trim():'';
  if(bookName!==null&&(!bookName||bookName.length>2000))fail('Enter a Book Name (up to 2000 characters).');
  const client=await pool.connect();try{await client.query('BEGIN');const subject=(await client.query('SELECT academic_year_id,branch_id,semester FROM subjects WHERE subject_id=$1 FOR SHARE',[subjectId])).rows[0];
   if(!subject||!subject.academic_year_id||!subject.branch_id||![1,2].includes(subject.semester)||String(subject.academic_year_id)!==String(input.academic_year_id)||String(subject.branch_id)!==String(input.branch_id)||String(subject.semester)!==String(input.semester))fail('Select a Subject matching the Academic Year, Branch and Semester.');
   const result=id?await client.query('UPDATE faculty_books SET subject_id=$1,author=$2,book_name=COALESCE($5,book_name),updated_at=NOW(),updated_by=$3 WHERE book_id=$4 RETURNING book_id',[subjectId,author,user.user_id,id,bookName]):await client.query('INSERT INTO faculty_books(faculty_id,subject_id,author,book_name,created_at,created_by,is_status) VALUES($1,$2,$3,$4,NOW(),$1,1) RETURNING book_id',[user.user_id,subjectId,author,bookName??'']);
   await client.query('COMMIT');reply(res,result.rowCount?(id?200:201):404,result.rowCount?{ok:true,id:result.rows[0].book_id}:{error:'Book not found.'});
  }catch(error){await client.query('ROLLBACK');throw error;}finally{client.release();}return true;
 }
 reply(res,405,{error:'Method not allowed.'});return true;
}
