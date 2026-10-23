import {pool} from './db.mjs';
import {dashboardAudiences} from '../shared/dashboard-configuration.mjs';
import {timetableToday} from '../shared/timetable.mjs';
const base='/api/admin/dashboard-configuration',feed='/api/dashboard-content';
const fail=message=>{throw Object.assign(new Error(message),{status:400});};
const positive=value=>Number.isSafeInteger(Number(value))&&Number(value)>0;
const text=(value,label,max,required=true)=>{const result=typeof value==='string'?value.trim():'';if(required&&!result||result.length>max)fail('Enter '+label+' (up to '+max+' characters).');return result||null;};
function date(value){if(!value)return null;if(typeof value!=='string'||!/^\d{4}-\d{2}-\d{2}$/.test(value)||!Number.isFinite(Date.parse(value+'T00:00:00Z'))||new Date(value+'T00:00:00Z').toISOString().slice(0,10)!==value)fail('Enter a valid Notice Date.');return value;}
const noticeColumns=`n.notice_id,n.notice_title,n.notice_description,n.notice_user_type,n.notice_date::text,n.notice_file_path,n.rel_dept,n.is_status,n.created_at,n.created_by,n.updated_at,n.updated_by,
 (n.file_data IS NOT NULL) AS downloadable,COALESCE((SELECT json_agg(d.department_id::text) FROM notice_departments d WHERE d.notice_id=n.notice_id),'[]') AS department_ids,
 COALESCE((SELECT string_agg(e.emp_department_name,', ' ORDER BY e.emp_department_name) FROM notice_departments d JOIN emp_department e ON e.emp_department_id=d.department_id WHERE d.notice_id=n.notice_id),'All Departments') AS department_names`;
function audiences(role){return ['0',...({Admin:['ADM'],Student:['STU'],Faculty:['FAC','EMP'],Employee:['EMP']}[role]||[])];}
const noticeVisibility=`n.is_status=1 AND (n.notice_date IS NULL OR n.notice_date<=$2::date) AND n.notice_user_type=ANY($1::text[])
 AND (NOT EXISTS(SELECT 1 FROM notice_departments d WHERE d.notice_id=n.notice_id) OR EXISTS(SELECT 1 FROM notice_departments d JOIN emp_master e ON e.emp_master_department_id=d.department_id WHERE d.notice_id=n.notice_id AND e.emp_master_user_id=$3 AND e.deleted_at IS NULL))`;
function attachment(input){
 if(input.file_base64==null&&!input.file_name)return null;
 const name=text(input.file_name,'Attachment Name',100);if(/[\x00-\x1f\x7f/\\]/.test(name)||typeof input.file_base64!=='string'||!input.file_base64||input.file_base64.length>6990508||input.file_base64.length%4!==0||!/^[A-Za-z0-9+/]+={0,2}$/.test(input.file_base64))fail('Choose a PDF, PNG or JPG file up to 5 MB.');
 const bytes=Buffer.from(input.file_base64,'base64');if(!bytes.length||bytes.length>5242880||bytes.toString('base64')!==input.file_base64)fail('Choose an attachment up to 5 MB.');
 const extension=name.split('.').pop().toLowerCase();const valid=extension==='pdf'?bytes.subarray(0,5).toString()==='%PDF-':extension==='png'?bytes.subarray(0,8).equals(Buffer.from('89504e470d0a1a0a','hex')):['jpg','jpeg'].includes(extension)&&bytes.subarray(0,3).equals(Buffer.from('ffd8ff','hex'));
 if(!valid)fail('Attachment contents must match the PDF, PNG or JPG file type.');return {name,bytes,type:extension==='pdf'?'application/pdf':extension==='png'?'image/png':'image/jpeg'};
}
export async function handleDashboardConfiguration(req,res,path,user,body,reply){
 const publicPath=path===feed||path.startsWith(feed+'/');if(!publicPath&&path!==base&&!path.startsWith(base+'/'))return false;
 const admin=user.role_name==='Admin'||user.authorized_module==='dashboard-configuration';
 if(!publicPath&&!admin){reply(res,403,{error:'Dashboard Setup access required.'});return true;}
 const visibilityValues=[audiences(user.role_name),timetableToday(),user.user_id];
 if(path===feed&&req.method==='GET'){
  const [message,notices]=await Promise.all([pool.query('SELECT msg_of_day_id,msg_details FROM msg_of_day WHERE is_status=1 AND msg_user_type=ANY($1::text[]) ORDER BY COALESCE(updated_at,created_at) DESC,msg_of_day_id DESC LIMIT 1',[visibilityValues[0]]),pool.query('SELECT '+noticeColumns+' FROM notice n WHERE '+noticeVisibility+' ORDER BY COALESCE(n.notice_date,n.created_at::date) DESC,n.notice_id DESC LIMIT 100',visibilityValues)]);
  reply(res,200,{message:message.rows[0]||null,notices:notices.rows});return true;
 }
 const file=path.match(/^\/api\/(?:dashboard-content|admin\/dashboard-configuration)\/notices\/(\d+)\/file$/);
 if(file&&req.method==='GET'){
  const visibility=noticeVisibility.replace(/\$(\d+)/g,(_,number)=>'$'+(Number(number)+1));
  const row=(await pool.query('SELECT n.file_data,n.file_type,n.notice_file_path FROM notice n WHERE n.notice_id=$1'+(publicPath?' AND '+visibility:''),publicPath?[file[1],...visibilityValues]:[file[1]])).rows[0];
  if(!row?.file_data){reply(res,404,{error:'Notice attachment not available.'});return true;}
  const name=row.notice_file_path.replace(/[^a-zA-Z0-9._ -]/g,'_');res.writeHead(200,{'Content-Type':'application/octet-stream','Content-Length':row.file_data.length,'Content-Disposition':`attachment; filename="${name}"; filename*=UTF-8''${encodeURIComponent(row.notice_file_path).replace(/['()*]/g,char=>'%'+char.charCodeAt(0).toString(16))}`,'X-Content-Type-Options':'nosniff','Cache-Control':'private, no-store'});res.end(row.file_data);return true;
 }
 if(publicPath){reply(res,405,{error:'Method not allowed.'});return true;}
 if(path===base+'/options'&&req.method==='GET'){reply(res,200,{departments:(await pool.query('SELECT emp_department_id,emp_department_name FROM emp_department ORDER BY emp_department_name')).rows});return true;}
 const match=path.match(/^\/api\/admin\/dashboard-configuration\/(messages|notices)(?:\/(\d+))?$/);
 if(!match){reply(res,404,{error:'Dashboard Setup page not found.'});return true;}
 const messages=match[1]==='messages',table=messages?'msg_of_day':'notice',pk=messages?'msg_of_day_id':'notice_id',id=match[2];
 if(req.method==='GET'&&!id){reply(res,200,{records:(await pool.query(messages?'SELECT m.*,u.full_name AS author FROM msg_of_day m JOIN users u ON u.user_id=m.created_by ORDER BY COALESCE(m.updated_at,m.created_at) DESC,m.msg_of_day_id DESC':'SELECT '+noticeColumns+',u.full_name AS author FROM notice n JOIN users u ON u.user_id=n.created_by ORDER BY n.notice_id DESC')).rows});return true;}
 if(!((req.method==='POST'&&!id)||(['PATCH','DELETE'].includes(req.method)&&id))){reply(res,405,{error:'Method not allowed.'});return true;}
 const client=await pool.connect();try{
  await client.query('BEGIN');let old;if(id){old=(await client.query('SELECT '+pk+' FROM '+table+' WHERE '+pk+'=$1 FOR UPDATE',[id])).rows[0];if(!old){await client.query('ROLLBACK');reply(res,404,{error:'Record not found.'});return true;}}
  if(req.method==='DELETE'){await client.query('DELETE FROM '+table+' WHERE '+pk+'=$1',[id]);await client.query('COMMIT');reply(res,200,{ok:true});return true;}
  const input=await body(req);if(!input||typeof input!=='object'||Array.isArray(input))fail('Provide the form details.');const audience=messages?input.msg_user_type:input.notice_user_type;
  if(!dashboardAudiences.some(([key])=>key===audience)||![0,1].includes(input.is_status))fail('Choose Audience and Active status.');let data;
  if(messages)data={msg_details:text(input.msg_details,'Message',100),msg_user_type:audience,is_status:input.is_status};
  else{
   if(!Array.isArray(input.department_ids)||input.department_ids.length>500||input.department_ids.some(id=>!positive(id)))fail('Choose valid Departments.');const departments=[...new Set(input.department_ids.map(String))];
   if(audience==='STU'&&departments.length)fail('Student notices must use All Departments. Department targeting applies to staff.');
   if((await client.query('SELECT emp_department_id FROM emp_department WHERE emp_department_id=ANY($1::bigint[]) FOR SHARE',[departments])).rowCount!==departments.length)fail('A selected Department no longer exists.');
   data={notice_title:text(input.notice_title,'Notice Title',25),notice_description:text(input.notice_description,'Notice Description',255,false),notice_user_type:audience,notice_date:date(input.notice_date),is_status:input.is_status,rel_dept:departments.join(',')};
   const file=attachment(input);if(file){data.notice_file_path=file.name;data.file_type=file.type;data.file_data=file.bytes;}else if(input.remove_attachment===true){data.notice_file_path=null;data.file_type=null;data.file_data=null;}
  }
  data[id?'updated_by':'created_by']=user.user_id;const keys=Object.keys(data),values=Object.values(data);
  const result=id?await client.query('UPDATE '+table+' SET '+keys.map((key,index)=>key+'=$'+(index+1)).join(',')+',updated_at=NOW() WHERE '+pk+'=$'+(keys.length+1)+' RETURNING '+pk,[...values,id]):await client.query('INSERT INTO '+table+'('+keys.join(',')+') VALUES('+keys.map((_,index)=>'$'+(index+1)).join(',')+') RETURNING '+pk,values);
  const saved=result.rows[0][pk];if(!messages){await client.query('DELETE FROM notice_departments WHERE notice_id=$1',[saved]);for(const dept of [...new Set(input.department_ids.map(String))])await client.query('INSERT INTO notice_departments(notice_id,department_id) VALUES($1,$2)',[saved,dept]);}
  await client.query('COMMIT');reply(res,id?200:201,{ok:true,id:saved});
 }catch(error){await client.query('ROLLBACK');throw error;}finally{client.release();}return true;
}
