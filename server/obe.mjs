import {pool} from './db.mjs';
import {createObeBusiness} from './obe/business.mjs';
const base='/api/admin/obe';
const fail=message=>{throw Object.assign(new Error(message),{status:400});};
const positive=value=>Number.isSafeInteger(Number(value))&&Number(value)>0;
export const obeLinkTypes={
 departments:{table:'department',id:'department_id',label:'department_name',erp:'public.emp_department',erpId:'emp_department_id',erpLabel:'emp_department_name'},
 programmes:{table:'programmes',id:'programme_id',label:'programme_name',erp:'public.courses',erpId:'course_id',erpLabel:'course_name'},
 batches:{table:'admission_batches',id:'admission_batch_id',label:'batch_code',erp:'public.batches',erpId:'batch_id',erpLabel:'batch_name'},
 semesters:{table:'semesters',id:'semester_id',label:'semester_name',erp:'public.semester_defined',erpId:'id',erpLabel:"'Semester '||semester::text"},
 courses:{table:'courses',id:'course_id',label:"course_code||' / '||course_name",erp:'public.subjects',erpId:'subject_id',erpLabel:"subject_code||' / '||subject_name"},
 faculty:{table:'faculty',id:'faculty_id',label:'faculty_name',erp:'public.emp_master m JOIN public.users u ON u.user_id=m.emp_master_user_id',erpId:'emp_master_id',erpLabel:'u.full_name'},
 students:{table:'students',id:'student_id',label:"regd_no||' / '||student_name",erp:'public.stu_master m JOIN public.stu_info i ON i.stu_info_id=m.stu_master_stu_info_id',erpId:'stu_master_id',erpLabel:"i.stu_unique_id||' / '||concat_ws(' ',i.stu_first_name,i.stu_last_name)"}
};
export async function initializeObe(client){
 await client.query('SET search_path TO obe,pg_catalog');
 try{await createObeBusiness({query:client.query.bind(client),connect:async()=>({query:client.query.bind(client),release(){}})},true).initialize();}
 finally{await client.query('SET search_path TO public');}
}
export async function handleObe(req,res,path,user,body,reply){
 if(path!==base&&!path.startsWith(base+'/'))return false;
 if(user.role_name!=='Admin'&&user.authorized_module!=='obe'){reply(res,403,{error:'OBE access required.'});return true;}
 const client=await pool.connect();try{
  await client.query('SET search_path TO obe,pg_catalog');
  if(path===base+'/erp-links'&&req.method==='GET'){
   const entities={};for(const [key,spec] of Object.entries(obeLinkTypes)){
    const records=(await client.query(`SELECT ${spec.id} AS id,${spec.label} AS label,erp_id FROM ${spec.table} ORDER BY ${spec.id}`)).rows;
    const erp=(await client.query(`SELECT ${spec.erpId} AS id,${spec.erpLabel} AS label FROM ${spec.erp} ORDER BY ${spec.erpId}`)).rows;
    entities[key]={records,erp};
   }reply(res,200,{entities});return true;
  }
  const link=path.match(/^\/api\/admin\/obe\/erp-links\/([a-z]+)\/(\d+)$/);
  if(link&&req.method==='PATCH'){
   const spec=obeLinkTypes[link[1]];if(!spec){reply(res,404,{error:'Link type not found.'});return true;}
   const input=await body(req);if(input?.erp_id!==null&&(!positive(input?.erp_id)||!(await client.query(`SELECT ${spec.erpId} FROM ${spec.erp} WHERE ${spec.erpId}=$1`,[input.erp_id])).rowCount))fail('Select an existing ERP record.');
   const result=await client.query(`UPDATE ${spec.table} SET erp_id=$1 WHERE ${spec.id}=$2 RETURNING ${spec.id}`,[input.erp_id,link[2]]);reply(res,result.rowCount?200:404,result.rowCount?{ok:true}:{error:'OBE record not found.'});return true;
  }
  if(path===base+'/faculty-management'&&req.method==='GET'){
   reply(res,200,(await client.query('SELECT faculty_id,department_id,faculty_code,faculty_name,designation,email,status,erp_id FROM faculty ORDER BY faculty_name')).rows);return true;
  }
  if(path===base+'/faculty-from-erp'&&req.method==='POST'){
   const input=await body(req);if(!positive(input?.employee_id))fail('Select an Employee.');
   const employee=(await client.query(`SELECT e.emp_master_id,u.full_name,u.email,i.employee_code,d.emp_designation_name FROM public.emp_master e JOIN public.users u ON u.user_id=e.emp_master_user_id JOIN public.emp_info i ON i.emp_info_id=e.emp_master_emp_info_id LEFT JOIN public.emp_designation d ON d.emp_designation_id=e.emp_master_designation_id WHERE e.emp_master_id=$1 AND e.deleted_at IS NULL AND u.is_active`,[input.employee_id])).rows[0];if(!employee)fail('Select an active ERP Employee.');
   if(input.department_id&&!positive(input.department_id))fail('Select an OBE Department.');
   const row=(await client.query('INSERT INTO faculty(faculty_name,faculty_code,email,designation,department_id,status,erp_id) VALUES($1,$2,$3,$4,$5,\'Active\',$6) ON CONFLICT(erp_id) WHERE erp_id IS NOT NULL DO UPDATE SET faculty_name=EXCLUDED.faculty_name,faculty_code=EXCLUDED.faculty_code,email=EXCLUDED.email,designation=EXCLUDED.designation,department_id=EXCLUDED.department_id,updated_at=CURRENT_TIMESTAMP RETURNING faculty_id',[employee.full_name,employee.employee_code,employee.email,employee.emp_designation_name,input.department_id||null,employee.emp_master_id])).rows[0];reply(res,201,{ok:true,id:row.faculty_id});return true;
  }
  const business=createObeBusiness({query:client.query.bind(client),connect:async()=>({query:client.query.bind(client),release(){}})});
  const relative='/api'+path.slice(base.length),route=business.routes.find(route=>route.method===req.method&&matches(route.path,relative));
  if(!route){reply(res,404,{error:'OBE page endpoint not found.'});return true;}
  const request={method:req.method,query:Object.fromEntries(new URL(req.url||path,'http://localhost').searchParams),params:matches(route.path,relative),body:['POST','PUT','PATCH'].includes(req.method)?await body(req):{}};
  let status=200,sent=false;
  const response={status(value){status=value;return response;},json(value){sent=true;reply(res,status,value);return response;},send(){sent=true;res.writeHead(status,{'Cache-Control':'no-store'});res.end();return response;}};
  await route.handler(request,response);if(!sent)reply(res,500,{error:'OBE request did not complete.'});return true;
 }finally{try{await client.query('ROLLBACK');await client.query('SET search_path TO public');}finally{client.release();}}
}
function matches(pattern,path){const a=pattern.split('/'),b=path.split('/');if(a.length!==b.length)return null;const params={};for(let i=0;i<a.length;i++){if(a[i].startsWith(':')){params[a[i].slice(1)]=b[i];}else if(a[i]!==b[i])return null;}return params;}
