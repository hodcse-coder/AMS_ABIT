import { pool } from './db.mjs';
export async function handleSectionMasters(req,res,path,user,body,reply){
 const match=path.match(/^\/api\/admin\/course-modules\/section-masters(?:\/(\d+))?$/);
 if(!match)return false;
 const id=match[1];
 if(req.method==='GET'&&!id){const {rows}=await pool.query('SELECT * FROM section_master ORDER BY section_master_name,section_master_id');reply(res,200,{masters:rows});return true;}
 if(req.method==='DELETE'&&id){
  const client=await pool.connect();
  try{await client.query('BEGIN');const found=await client.query('SELECT section_master_id FROM section_master WHERE section_master_id=$1 FOR UPDATE',[id]);
   if(!found.rowCount){await client.query('ROLLBACK');reply(res,404,{error:'Section Master not found.'});return true;}
   if((await client.query('SELECT 1 FROM section_defined WHERE section_master=$1 LIMIT 1',[id])).rowCount){await client.query('ROLLBACK');reply(res,409,{error:'This Section Master is used by a Section. Update or remove those Sections before deleting it.'});return true;}
   await client.query('DELETE FROM section_master WHERE section_master_id=$1',[id]);await client.query('COMMIT');reply(res,200,{ok:true});
  }catch(error){await client.query('ROLLBACK');throw error;}finally{client.release();}
  return true;
 }
 if((req.method==='POST'&&!id)||(req.method==='PATCH'&&id)){
  const input=await body(req),name=typeof input.section_master_name==='string'?input.section_master_name.trim().toUpperCase():'';
  if(!name||name.length>50||input.is_status!==undefined&&![0,1].includes(input.is_status)){reply(res,400,{error:'Enter a Section Master Name of up to 50 characters and a valid status.'});return true;}
  const result=id?await pool.query('UPDATE section_master SET section_master_name=$1,is_status=COALESCE($2,is_status),updated_at=NOW(),updated_by=$3 WHERE section_master_id=$4 RETURNING section_master_id',[name,input.is_status??null,user.user_id,id]):await pool.query('INSERT INTO section_master(section_master_name,is_status,created_at,created_by) VALUES($1,$2,NOW(),$3) RETURNING section_master_id',[name,input.is_status??1,user.user_id]);
  reply(res,result.rowCount?(id?200:201):404,result.rowCount?{ok:true,id:result.rows[0].section_master_id}:{error:'Section Master not found.'});return true;
 }
 reply(res,405,{error:'Method not allowed.'});return true;
}
