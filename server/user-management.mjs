import {pool} from './db.mjs';
import {registeredAccessRoutes} from '../shared/user-management.mjs';
const base='/api/admin/user-management';
const fail=message=>{throw Object.assign(new Error(message),{status:400});};
const positive=value=>Number.isSafeInteger(Number(value))&&Number(value)>0;
const text=(value,label,max,required=true)=>{const result=typeof value==='string'?value.trim():'';if(required&&!result||result.length>max)fail('Enter '+label+' (up to '+max+' characters).');return result||null;};
function ids(value,label){if(!Array.isArray(value)||value.length>500||value.some(id=>!positive(id)))fail('Select valid '+label+'.');return [...new Set(value.map(String))];}
const effectiveRoutes=`SELECT DISTINCT rt.route_key,rt.module FROM access_assignments a JOIN access_roles r USING(access_role_id) JOIN access_role_permissions rp USING(access_role_id)
 JOIN access_permissions p USING(permission_id) JOIN access_permission_routes pr USING(permission_id) JOIN access_routes rt USING(route_id)
 WHERE a.user_id=$1 AND r.is_active AND p.is_active AND rt.is_active`;
export async function accessForUser(user){
 if(user.role_name==='Admin')return {access_modules:registeredAccessRoutes.filter(r=>r.method==='GET').map(r=>r.module)};
 const rows=(await pool.query(effectiveRoutes,[user.user_id])).rows;
 return {access_modules:[...new Set(rows.filter(row=>registeredAccessRoutes.some(route=>route.route_key===row.route_key&&route.method==='GET'&&!route.exact)).map(row=>row.module))]};
}
export async function authorizedAccessModule(user,method,path){
 const routes=registeredAccessRoutes.filter(route=>route.method===method&&(path===route.prefix||!route.exact&&path.startsWith(route.prefix+'/')));if(!routes.length)return null;
 const allowed=(await pool.query(effectiveRoutes+' AND rt.route_key=ANY($2::text[])',[user.user_id,routes.map(route=>route.route_key)])).rows[0];return allowed?.module||null;
}
export async function syncAccessRoutes(client=pool){
 for(const route of registeredAccessRoutes)await client.query(`INSERT INTO access_routes(route_key,module,label,method,path_pattern) VALUES($1,$2,$3,$4,$5)
 ON CONFLICT(route_key) DO UPDATE SET module=EXCLUDED.module,label=EXCLUDED.label,method=EXCLUDED.method,path_pattern=EXCLUDED.path_pattern`,[route.route_key,route.module,route.label,route.method,route.path_pattern]);
 await client.query('UPDATE access_routes SET is_active=FALSE WHERE NOT(route_key=ANY($1::text[]))',[registeredAccessRoutes.map(route=>route.route_key)]);
}
export async function handleUserManagement(req,res,path,user,body,reply){
 if(path!==base&&!path.startsWith(base+'/'))return false;
 if(user.role_name!=='Admin'){reply(res,403,{error:'Administrator access required.'});return true;}
 if(req.method==='GET'&&path===base+'/data'){
  const [users,roles,permissions,routes,assignments,profileRoles]=await Promise.all([
   pool.query('SELECT u.user_id,u.full_name,u.username,u.is_active,r.role_name FROM users u JOIN user_roles r USING(role_id) ORDER BY u.full_name'),
   pool.query(`SELECT r.*,COALESCE((SELECT json_agg(rp.permission_id::text) FROM access_role_permissions rp WHERE rp.access_role_id=r.access_role_id),'[]') AS permission_ids,(SELECT COUNT(*)::integer FROM access_assignments a WHERE a.access_role_id=r.access_role_id) AS user_count FROM access_roles r ORDER BY r.name`),
   pool.query(`SELECT p.*,COALESCE((SELECT json_agg(pr.route_id::text) FROM access_permission_routes pr WHERE pr.permission_id=p.permission_id),'[]') AS route_ids FROM access_permissions p ORDER BY p.name`),
   pool.query('SELECT * FROM access_routes WHERE route_key=ANY($1::text[]) ORDER BY module,method',[registeredAccessRoutes.map(route=>route.route_key)]),pool.query('SELECT user_id,access_role_id FROM access_assignments'),pool.query('SELECT role_id,role_name FROM user_roles ORDER BY role_name')]);
  reply(res,200,{users:users.rows,roles:roles.rows,permissions:permissions.rows,routes:routes.rows,assignments:assignments.rows,profile_roles:profileRoles.rows});return true;
 }
 const record=path.match(/^\/api\/admin\/user-management\/(roles|permissions)(?:\/(\d+))?$/),assignment=path.match(/^\/api\/admin\/user-management\/assignments\/(\d+)$/),route=path.match(/^\/api\/admin\/user-management\/routes\/(\d+)$/);
 if(!['POST','PATCH','PUT','DELETE'].includes(req.method)){reply(res,405,{error:'Method not allowed.'});return true;}
 const client=await pool.connect();try{
  await client.query('BEGIN');await client.query('SELECT pg_advisory_xact_lock(84102733)');
  const input=req.method==='DELETE'?{}:await body(req);if(!input||typeof input!=='object'||Array.isArray(input))fail('Provide the form details.');let result,before=null,after=null,action;
  if(record&&((!record[2]&&req.method==='POST')||(record[2]&&['PATCH','DELETE'].includes(req.method)))){
   const roles=record[1]==='roles',table=roles?'access_roles':'access_permissions',pk=roles?'access_role_id':'permission_id';action=record[1]+':'+req.method.toLowerCase();
   if(record[2]){before=(await client.query('SELECT * FROM '+table+' WHERE '+pk+'=$1 FOR UPDATE',[record[2]])).rows[0];if(!before){await client.query('ROLLBACK');reply(res,404,{error:'Record not found.'});return true;}}
   if(before){before.linked_ids=(await client.query(roles?'SELECT permission_id AS id FROM access_role_permissions WHERE access_role_id=$1':'SELECT route_id AS id FROM access_permission_routes WHERE permission_id=$1',[record[2]])).rows.map(row=>row.id);}
   if(req.method==='DELETE')result=await client.query('DELETE FROM '+table+' WHERE '+pk+'=$1 RETURNING '+pk+' AS id',[record[2]]);
   else{
    const name=text(input.name,roles?'Role Name':'Permission Name',100),description=text(input.description,'Description',500,false);if(typeof input.is_active!=='boolean')fail('Select the active status.');
    const linked=ids(roles?input.permission_ids:input.route_ids,roles?'Permissions':'Routes'),linkTable=roles?'access_role_permissions':'access_permission_routes',targetTable=roles?'access_permissions':'access_routes',targetKey=roles?'permission_id':'route_id';
    if(!roles&&!linked.length)fail('Select at least one registered Route.');
    const found=await client.query('SELECT '+targetKey+' FROM '+targetTable+' WHERE '+targetKey+'=ANY($1::bigint[]) FOR SHARE',[linked]);if(found.rowCount!==linked.length)fail('A selected Permission or Route no longer exists.');
    result=record[2]?await client.query('UPDATE '+table+' SET name=$1,description=$2,is_active=$3,updated_by=$4,updated_at=NOW() WHERE '+pk+'=$5 RETURNING '+pk+' AS id',[name,description,input.is_active,user.user_id,record[2]]):await client.query('INSERT INTO '+table+'(name,description,is_active,created_by) VALUES($1,$2,$3,$4) RETURNING '+pk+' AS id',[name,description,input.is_active,user.user_id]);
    const id=result.rows[0].id;await client.query('DELETE FROM '+linkTable+' WHERE '+pk+'=$1',[id]);for(const target of linked)await client.query('INSERT INTO '+linkTable+'('+pk+','+targetKey+') VALUES($1,$2)',[id,target]);
    after={name,description,is_active:input.is_active,linked_ids:linked};
   }
  }else if(assignment&&req.method==='PUT'){
   const account=(await client.query('SELECT user_id,is_active FROM users WHERE user_id=$1 FOR SHARE',[assignment[1]])).rows[0];if(!account)fail('Select an existing user.');
   const selected=ids(input.role_ids,'Roles');if(selected.length&&!account.is_active)fail('Activate this account before assigning Roles.');
   if((await client.query('SELECT access_role_id FROM access_roles WHERE access_role_id=ANY($1::bigint[]) AND is_active FOR SHARE',[selected])).rowCount!==selected.length)fail('Select active Roles.');
   before=(await client.query('SELECT access_role_id FROM access_assignments WHERE user_id=$1',[account.user_id])).rows;
   await client.query('DELETE FROM access_assignments WHERE user_id=$1',[account.user_id]);for(const id of selected)await client.query('INSERT INTO access_assignments(user_id,access_role_id,created_by) VALUES($1,$2,$3)',[account.user_id,id,user.user_id]);
   after={role_ids:selected};action='assignments:replace';result={rowCount:1,rows:[{id:account.user_id}]};
  }else if(route&&req.method==='PATCH'){
   if(typeof input.is_active!=='boolean')fail('Select the active status.');before=(await client.query('SELECT * FROM access_routes WHERE route_id=$1 FOR UPDATE',[route[1]])).rows[0];
   result=await client.query('UPDATE access_routes SET is_active=$1,updated_by=$2,updated_at=NOW() WHERE route_id=$3 RETURNING route_id AS id',[input.is_active,user.user_id,route[1]]);after={is_active:input.is_active};action='routes:status';
  }else if(path===base+'/routes/sync'&&req.method==='POST'){await syncAccessRoutes(client);result={rowCount:1,rows:[{id:null}]};action='routes:sync';}
  else{await client.query('ROLLBACK');reply(res,405,{error:'Method not allowed.'});return true;}
  if(result.rowCount)await client.query('INSERT INTO access_audit(actor_id,action,record_id,before_value,after_value) VALUES($1,$2,$3,$4,$5)',[user.user_id,action,result.rows[0].id,JSON.stringify(before),JSON.stringify(after)]);
  await client.query('COMMIT');reply(res,result.rowCount?(req.method==='POST'?201:200):404,result.rowCount?{ok:true,id:result.rows[0].id}:{error:'Record not found.'});
 }catch(error){await client.query('ROLLBACK');throw error;}finally{client.release();}return true;
}
