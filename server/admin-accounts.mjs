import {pool} from './db.mjs';
import {hashPassword} from './passwords.mjs';

function readPhoto(input){
  if(!input.photo_base64)return null;
  if(typeof input.photo_base64!=='string'||input.photo_base64.length>2800000||!/^[A-Za-z0-9+/]+={0,2}$/.test(input.photo_base64))throw Object.assign(new Error('Select a JPG, PNG or WebP photo up to 2 MB.'),{status:400});
  const data=Buffer.from(input.photo_base64,'base64');
  const type=data.subarray(0,8).equals(Buffer.from([137,80,78,71,13,10,26,10]))?'image/png':data[0]===255&&data[1]===216&&data[2]===255?'image/jpeg':data.toString('ascii',0,4)==='RIFF'&&data.toString('ascii',8,12)==='WEBP'?'image/webp':null;
  if(!type||data.length>2*1024*1024)throw Object.assign(new Error('Select a JPG, PNG or WebP photo up to 2 MB.'),{status:400});
  return {data,type,name:String(input.photo_name||'photo').slice(0,150)};
}

export async function handleAdminAccounts(req,res,path,user,body,reply){
  const match=path.match(/^\/api\/admin\/accounts(?:\/(\d+)(\/photo)?)?$/);
  if(!match)return false;
  if(user.role_name!=='Admin'){reply(res,403,{error:'Administrator access required.'});return true;}
  if(match[2]){
    if(req.method!=='GET'){reply(res,405,{error:'Method not allowed.'});return true;}
    const {rows:[row]}=await pool.query("SELECT u.photo_data,u.photo_type FROM users u JOIN user_roles r USING(role_id) WHERE u.user_id=$1 AND r.role_name='Admin'",[match[1]]);
    if(!row?.photo_data){reply(res,404,{error:'Photo not found.'});return true;}
    res.writeHead(200,{'Content-Type':row.photo_type,'Cache-Control':'no-store','X-Content-Type-Options':'nosniff'});res.end(row.photo_data);return true;
  }
  if(req.method==='GET'&&!match[1]){
    const {rows}=await pool.query("SELECT u.user_id,u.full_name,u.username,u.email,u.is_active,u.updated_at,(u.photo_data IS NOT NULL) AS has_photo FROM users u JOIN user_roles r USING(role_id) WHERE r.role_name='Admin' ORDER BY u.user_id");
    reply(res,200,{users:rows});return true;
  }
  if((req.method==='PATCH'&&match[1])||(req.method==='POST'&&!match[1])){
    const input=await body(req);
    if(typeof input.full_name!=='string'||!input.full_name.trim()||input.full_name.length>150||typeof input.username!=='string'||!/^[A-Za-z0-9._-]{3,100}$/.test(input.username)||(input.email&&(typeof input.email!=='string'||input.email.length>150||!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(input.email)))||(input.password!==undefined&&input.password!==''&&(typeof input.password!=='string'||input.password.length<8||input.password.length>1024))){reply(res,400,{error:'Enter a valid name, username, email and password of at least 8 characters.'});return true;}
    const client=await pool.connect();
    try{
      await client.query('BEGIN');
      const photo=readPhoto(input);
      if(req.method==='POST'&&(!photo||!input.password)){reply(res,400,{error:'Photo and password are required for a new Admin account.'});await client.query('ROLLBACK');return true;}
      const password=input.password?await hashPassword(input.password):null;
      if(req.method==='POST'){
        const created=await client.query("INSERT INTO users(role_id,full_name,username,email,password_hash,photo_data,photo_type,photo_name) SELECT role_id,$1,$2,$3,$4,$5,$6,$7 FROM user_roles WHERE role_name='Admin' RETURNING user_id",[input.full_name.trim(),input.username,input.email||null,password,photo.data,photo.type,photo.name]);
        await client.query('INSERT INTO admins(user_id) VALUES($1)',[created.rows[0].user_id]);await client.query('COMMIT');reply(res,201,{ok:true});return true;
      }
      const result=await client.query("UPDATE users u SET full_name=$1,username=$2,email=$3,password_hash=coalesce($4,password_hash),updated_at=NOW() FROM user_roles r WHERE u.role_id=r.role_id AND r.role_name='Admin' AND u.user_id=$5 RETURNING u.user_id",[input.full_name.trim(),input.username,input.email||null,password,match[1]]);
      if(photo&&result.rowCount)await client.query('UPDATE users SET photo_data=$1,photo_type=$2,photo_name=$3 WHERE user_id=$4',[photo.data,photo.type,photo.name,match[1]]);
      if(password&&result.rowCount)await client.query('DELETE FROM user_sessions WHERE user_id=$1',[match[1]]);
      await client.query('COMMIT');
      reply(res,result.rowCount?200:404,result.rowCount?{ok:true}:{error:'Admin account not found.'});
    }catch(e){await client.query('ROLLBACK');throw e;}finally{client.release();}
    return true;
  }
  reply(res,405,{error:'Method not allowed.'});return true;
}
