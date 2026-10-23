import assert from 'node:assert/strict';
import {randomBytes} from 'node:crypto';
import {pool} from '../server/db.mjs';
import {handleAdminAccounts} from '../server/admin-accounts.mjs';
import {verifyPassword} from '../server/passwords.mjs';
let id;
async function call(path,method='GET',input={},role='Admin'){let result;assert.equal(await handleAdminAccounts({method},{},path,{role_name:role},async()=>input,(_r,status,data)=>{result={status,...data};}),true);return result;}
try{
 const username='admin-check-'+randomBytes(5).toString('hex');
 id=(await pool.query("INSERT INTO users(role_id,username,password_hash,full_name) SELECT role_id,$1,'unused','Admin Test' FROM user_roles WHERE role_name='Admin' RETURNING user_id",[username])).rows[0].user_id;
 await pool.query("INSERT INTO user_sessions(token_hash,user_id,expires_at) VALUES($1,$2,NOW()+INTERVAL '1 hour')",[randomBytes(32).toString('hex'),id]);
 const input={username,full_name:'Updated Admin',email:'',password:'Eight123'};
 assert.equal((await call('/api/admin/accounts/'+id,'PATCH',input)).status,200);
 let row=(await pool.query('SELECT * FROM users WHERE user_id=$1',[id])).rows[0];assert.equal(row.full_name,input.full_name.toUpperCase());assert.ok(await verifyPassword(input.password,row.password_hash));assert.notEqual(row.password_hash,input.password);
 assert.equal((await pool.query('SELECT * FROM user_sessions WHERE user_id=$1',[id])).rowCount,0);
 assert.equal((await call('/api/admin/accounts/'+id,'PATCH',{...input,password:''})).status,200);
 assert.equal((await pool.query('SELECT password_hash FROM users WHERE user_id=$1',[id])).rows[0].password_hash,row.password_hash);
 assert.equal((await call('/api/admin/accounts/'+id,'PATCH',{...input,password:'Seven12'})).status,400);
 assert.equal((await call('/api/admin/accounts','GET',{},'Faculty')).status,403);
 const list=await call('/api/admin/accounts');assert.equal(list.status,200);assert.ok(list.users.some(u=>u.user_id===id));assert.ok(list.users.every(u=>!('password_hash' in u)));
 const photo=Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=','base64');
 assert.equal((await call('/api/admin/accounts/'+id,'PATCH',{...input,password:'',photo_base64:photo.toString('base64'),photo_name:'avatar.png'})).status,200);
 const stored=(await pool.query('SELECT photo_data,photo_type,photo_name FROM users WHERE user_id=$1',[id])).rows[0];assert.deepEqual(stored.photo_data,photo);assert.equal(stored.photo_type,'image/png');
 let downloaded,headers;assert.equal(await handleAdminAccounts({method:'GET'},{writeHead(status,h){assert.equal(status,200);headers=h;},end(data){downloaded=data;}},'/api/admin/accounts/'+id+'/photo',{role_name:'Admin'},async()=>{},()=>{}),true);assert.deepEqual(downloaded,photo);assert.equal(headers['Content-Type'],'image/png');
 await assert.rejects(call('/api/admin/accounts/'+id,'PATCH',{...input,password:'',photo_base64:Buffer.from('invalid image').toString('base64')}),e=>e.status===400);
 assert.equal((await call('/api/admin/accounts','POST',input)).status,400);
 assert.equal((await call('/api/admin/accounts/'+id+'/photo','GET',{},'Student')).status,403);
 const nonAdmin=(await pool.query("SELECT u.user_id FROM users u JOIN user_roles r USING(role_id) WHERE r.role_name<>'Admin' LIMIT 1")).rows[0];if(nonAdmin)assert.equal((await call('/api/admin/accounts/'+nonAdmin.user_id,'PATCH',input)).status,404);
 console.log('PASS: admin list, account editing, hashed password update, blank password preservation, session revocation, validation and access denial.');
}finally{if(id)await pool.query('DELETE FROM users WHERE user_id=$1',[id]);await pool.end();}
