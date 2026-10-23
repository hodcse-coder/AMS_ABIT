import assert from 'node:assert/strict';
import {randomBytes,createHash} from 'node:crypto';
import {spawn} from 'node:child_process';
import {pool} from '../server/db.mjs';
import {hashPassword} from '../server/passwords.mjs';
import {syncAccessRoutes} from '../server/user-management.mjs';
const suffix=randomBytes(5).toString('hex'),port=3198,origin='http://127.0.0.1:'+port,base='/api/admin/user-management';
const users=[],tokens=[];let child,role,permission,country,viewRoute,viewEnabled;
async function session(role_name){const password=randomBytes(18).toString('hex'),user=(await pool.query('INSERT INTO users(role_id,username,password_hash,full_name) SELECT role_id,$1,$2,$3 FROM user_roles WHERE role_name=$4 RETURNING user_id,username',['access'+role_name+suffix,await hashPassword(password),'ACCESS TEST '+role_name,role_name])).rows[0];users.push(user.user_id);const token=randomBytes(32).toString('hex');tokens.push(token);await pool.query("INSERT INTO user_sessions(token_hash,user_id,expires_at) VALUES($1,$2,NOW()+INTERVAL '5 minutes')",[createHash('sha256').update(token).digest('hex'),user.user_id]);return {...user,token,password,role_name};}
async function request(path,method='GET',input,account){const response=await fetch(origin+path,{method,headers:{...(account?{Cookie:'abit_session='+account.token}:{}),Origin:origin,'Content-Type':'application/json'},...(input===undefined?{}:{body:JSON.stringify(input)})});return {status:response.status,...await response.json()};}
try{
 await syncAccessRoutes();const admin=await session('Admin'),staff=await session('Employee');
 child=spawn(process.execPath,['--env-file=.env','server/index.mjs'],{env:{...process.env,PORT:String(port)},stdio:['ignore','pipe','pipe'],windowsHide:true});
 await new Promise((resolve,reject)=>{const timer=setTimeout(()=>reject(new Error('Test server startup timeout')),15000);child.stdout.on('data',data=>{if(String(data).includes('ABIT ERP:')){clearTimeout(timer);resolve();}});child.stderr.on('data',data=>{if(String(data).includes('Unable to start')){clearTimeout(timer);reject(new Error(String(data)));}});});
 const call=(path,method='GET',input)=>request(base+path,method,input,admin),employee=(path,method='GET',input)=>request(path,method,input,staff);
 assert.equal((await request('/api/dashboard-content')).status,401);assert.equal((await request('/api/dashboard-content','GET',undefined,staff)).status,200);assert.equal((await request(base+'/data')).status,401);assert.equal((await employee(base+'/data')).status,403);
 let data=await call('/data');assert.equal(data.status,200);assert.equal(data.users.some(row=>Object.hasOwn(row,'password_hash')),false);
 const view=data.routes.find(row=>row.route_key==='configuration:get'),write=data.routes.find(row=>row.route_key==='configuration:post');viewRoute=view.route_id;viewEnabled=view.is_active;
 if(!view.is_active)await call('/routes/'+viewRoute,'PATCH',{is_active:true});
 assert.equal((await employee('/api/admin/configuration/country')).status,403);
 const form={name:'ACCESS PERM '+suffix,description:'Test permission',is_active:true,route_ids:[viewRoute]};
 assert.equal((await call('/permissions','POST',{...form,name:''})).status,400);
 assert.equal((await call('/permissions','POST',{...form,route_ids:[999999999]})).status,400);
 const created=await call('/permissions','POST',form);assert.equal(created.status,201);permission=created.id;
 assert.equal((await call('/permissions','POST',form)).status,409);
 const roleForm={name:'ACCESS ROLE '+suffix,description:'Test role',is_active:true,permission_ids:[permission]};
 role=(await call('/roles','POST',roleForm)).id;assert.ok(role);
 assert.equal((await employee(base+'/assignments/'+staff.user_id,'PUT',{role_ids:[role]})).status,403);
 assert.equal((await call('/assignments/'+staff.user_id,'PUT',{role_ids:[role]})).status,200);
 assert.equal((await employee('/api/admin/configuration/country')).status,200);
 assert.deepEqual((await employee('/api/me')).user.access_modules,['configuration']);
 assert.equal((await employee('/api/admin/configuration/country','POST',{country_name:'DENIED'})).status,403);
 assert.equal((await employee('/api/admin/configurationx/country')).status,403);
 assert.equal((await employee('/api/admin/users')).status,403);
 assert.equal((await employee('/api/admin/timetable/options')).status,403);
 assert.equal((await employee(base+'/roles','POST',roleForm)).status,403);
 const obeRoute=data.routes.find(row=>row.route_key==='obe:get');
 const dashboardRoute=data.routes.find(row=>row.route_key==='dashboard-configuration:get');
 const timetableRoute=data.routes.find(row=>row.route_key==='timetable:get'),lookupRoute=data.routes.find(row=>row.route_key==='academics:lookup-subjects');
 await call('/permissions/'+permission,'PATCH',{...form,route_ids:[viewRoute,timetableRoute.route_id,lookupRoute.route_id,dashboardRoute.route_id,obeRoute.route_id]});
 assert.equal((await employee('/api/admin/timetable/options')).status,200);
 assert.equal((await employee('/api/admin/dashboard-configuration/messages')).status,200);
 assert.equal((await employee('/api/admin/obe/departments')).status,200);
 assert.equal((await employee('/api/admin/obe/departments/1','PUT',{})).status,403);
 assert.equal((await employee('/api/admin/obe/login','POST',{})).status,403);
 assert.equal((await employee('/api/admin/course-modules/subjects')).status,200);
 assert.equal((await employee('/api/admin/course-modules/courses')).status,403);
 await call('/permissions/'+permission,'PATCH',form);
 const login=await request('/api/login','POST',{username:staff.username,password:staff.password,role:'Employee'});assert.equal(login.status,200);assert.ok(login.user.access_modules.includes('configuration'));
 assert.equal((await call('/permissions/'+permission,'PATCH',{...form,route_ids:[viewRoute,write.route_id]})).status,200);
 const writeWasActive=write.is_active;if(!writeWasActive)await call('/routes/'+write.route_id,'PATCH',{is_active:true});
 try{const saved=await employee('/api/admin/configuration/country','POST',{country_name:'ACCESS'+suffix});assert.equal(saved.status,201);country=saved.id||saved.row?.country_id;if(!country)country=(await pool.query('SELECT country_id FROM country WHERE country_name=$1',['ACCESS'+suffix.toUpperCase()])).rows[0]?.country_id;}finally{if(!writeWasActive)await call('/routes/'+write.route_id,'PATCH',{is_active:false});}
 assert.equal((await employee('/api/admin/configuration/country/999999999','PATCH',{country_name:'DENIED'})).status,403);
 await call('/permissions/'+permission,'PATCH',{...form,is_active:false});assert.equal((await employee('/api/admin/configuration/country')).status,403);
 await call('/permissions/'+permission,'PATCH',form);assert.equal((await employee('/api/admin/configuration/country')).status,200);
 await call('/roles/'+role,'PATCH',{...roleForm,is_active:false});assert.equal((await employee('/api/admin/configuration/country')).status,403);
 await call('/roles/'+role,'PATCH',roleForm);
 await call('/routes/'+viewRoute,'PATCH',{is_active:false});assert.equal((await employee('/api/admin/configuration/country')).status,403);await call('/routes/'+viewRoute,'PATCH',{is_active:true});
 assert.equal((await call('/roles/'+role,'DELETE')).status,409);assert.equal((await call('/permissions/'+permission,'DELETE')).status,409);
 await call('/assignments/'+staff.user_id,'PUT',{role_ids:[]});assert.equal((await employee('/api/admin/configuration/country')).status,403);
 assert.equal((await call('/roles/'+role,'DELETE')).status,200);role=null;assert.equal((await call('/permissions/'+permission,'DELETE')).status,200);permission=null;
 assert.ok((await pool.query('SELECT id FROM access_audit WHERE actor_id=$1',[admin.user_id])).rowCount>10);
 console.log('PASS: HTTP authentication, Permission/Role CRUD, user assignments, method/path enforcement, immediate revocation, inactive role/permission/route denial, Admin-only administration, login capabilities, audit and linked-record protection.');
}finally{
 child?.kill();
 if(country)await pool.query('DELETE FROM country WHERE country_id=$1',[country]);
 if(viewRoute)await pool.query('UPDATE access_routes SET is_active=$2,updated_by=NULL WHERE route_id=$1',[viewRoute,viewEnabled]);
 if(users.length){await pool.query('DELETE FROM access_assignments WHERE user_id=ANY($1::bigint[])',[users]);await pool.query('DELETE FROM access_audit WHERE actor_id=ANY($1::bigint[])',[users]);}
 if(role)await pool.query('DELETE FROM access_roles WHERE access_role_id=$1',[role]);if(permission)await pool.query('DELETE FROM access_permissions WHERE permission_id=$1',[permission]);
 // Route status audit attributes are also removed when cleaning up test actors.
 if(users.length){await pool.query('UPDATE access_routes SET updated_by=NULL WHERE updated_by=ANY($1::bigint[])',[users]);await pool.query('DELETE FROM users WHERE user_id=ANY($1::bigint[])',[users]);}
 await pool.end();
}
