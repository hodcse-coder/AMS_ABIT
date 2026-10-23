import assert from 'node:assert/strict';
import {randomBytes} from 'node:crypto';
import {pool} from '../server/db.mjs';
import {hashPassword} from '../server/passwords.mjs';
const base=process.env.TEST_URL||'http://127.0.0.1:3000',root='/api/admin/course-modules',suffix=randomBytes(5).toString('hex'),users=[];
let masterId,definitionId;
async function request(path,{cookie,data,...options}={}){return fetch(base+path,{...options,headers:{Origin:base,'Content-Type':'application/json',...(cookie?{Cookie:cookie}:{})},...(data?{body:JSON.stringify(data)}:{})});}
async function login(role){const username=`master_test_${role}_${suffix}`,password=randomBytes(18).toString('hex');const result=await pool.query('INSERT INTO users(role_id,username,password_hash,full_name) SELECT role_id,$1,$2,$3 FROM user_roles WHERE role_name=$4 RETURNING user_id',[username,await hashPassword(password),'Master test',role]);users.push(result.rows[0].user_id);const response=await request('/api/login',{method:'POST',data:{username,password,role}});assert.equal(response.status,200);return response.headers.get('set-cookie').split(';')[0];}
try{
 assert.equal((await request(root+'/section-masters')).status,401);
 const cookie=await login('Admin'),faculty=await login('Faculty');assert.equal((await request(root+'/section-masters',{cookie:faculty})).status,403);
 assert.equal((await request(root+'/section-masters',{cookie,method:'POST',data:{section_master_name:''}})).status,400);
 const name=`Civil ${suffix}`;const created=await request(root+'/section-masters',{cookie,method:'POST',data:{section_master_name:name}});assert.equal(created.status,201);masterId=(await created.json()).id;
 assert.equal((await request(root+'/section-masters',{cookie,method:'POST',data:{section_master_name:name.toLowerCase()}})).status,409);
 let rows=(await(await request(root+'/section-masters',{cookie})).json()).masters;assert.equal(rows.find(row=>row.section_master_id===masterId).section_master_name,name.toUpperCase());assert.equal(rows.find(row=>row.section_master_id===masterId).is_status,1);
 const definition=await request(root+'/section-definitions',{cookie,method:'POST',data:{section_name:'Test section',section_master:masterId}});assert.equal(definition.status,201);definitionId=(await definition.json()).id;
 assert.equal((await request(`${root}/section-masters/${masterId}`,{cookie,method:'DELETE'})).status,409);
 assert.equal((await request(`${root}/section-masters/${masterId}`,{cookie,method:'PATCH',data:{section_master_name:`Updated ${suffix}`,is_status:0}})).status,200);
 rows=(await(await request(root+'/section-masters',{cookie})).json()).masters;const edited=rows.find(row=>row.section_master_id===masterId);assert.equal(edited.is_status,0);assert.ok(edited.updated_at);assert.equal(edited.updated_by,users[0]);
 const definitions=(await(await request(root+'/section-definitions',{cookie})).json()).definitions;assert.equal(definitions.find(row=>row.sid===definitionId).section_master_name,`UPDATED ${suffix.toUpperCase()}`);
 assert.equal((await request(`${root}/section-masters/${masterId}`,{cookie,method:'PATCH',data:{section_master_name:'Test',is_status:2}})).status,400);
 assert.equal((await request(`${root}/section-definitions/${definitionId}`,{cookie,method:'DELETE'})).status,200);
 assert.equal((await request(`${root}/section-masters/${masterId}`,{cookie,method:'DELETE'})).status,200);
 assert.equal((await request(`${root}/section-masters/${masterId}`,{cookie,method:'DELETE'})).status,404);
 console.log('PASS: Section Master create/edit/delete, uppercase uniqueness, status, audit details, dropdown names, linked-record protection and role authorization.');
}finally{
 if(definitionId)await pool.query('DELETE FROM section_defined WHERE sid=$1',[definitionId]);
 if(masterId)await pool.query('DELETE FROM section_master WHERE section_master_id=$1',[masterId]);
 await pool.query('DELETE FROM users WHERE user_id=ANY($1::bigint[])',[users]);await pool.end();
}
