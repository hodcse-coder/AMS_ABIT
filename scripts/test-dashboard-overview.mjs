import assert from 'node:assert/strict';
import { pool } from '../server/db.mjs';
import { handleDashboardOverview } from '../server/dashboard-overview.mjs';

async function invoke(role='Admin',method='GET') {
  let result;
  assert.equal(await handleDashboardOverview({method},{},'/api/admin/dashboard-overview',{role_name:role},(_res,status,data)=>{result={status,...data};}),true);
  return result;
}
try {
  const result=await invoke();
  assert.equal(result.status,200);
  const courses=(await pool.query('SELECT course_id,course_name,course_code FROM courses ORDER BY course_name,course_id')).rows;
  assert.deepEqual(result.courses.map(c=>({...c,course_id:String(c.course_id)})),courses);
  assert.equal(result.counts.courses,courses.length);
  assert.equal(result.counts.departments,Number((await pool.query('SELECT count(*) FROM emp_department')).rows[0].count));
  for(const value of Object.values(result.counts))assert.ok(Number.isInteger(value)&&value>=0);
  assert.equal((await invoke('Student')).status,403);
  assert.equal((await invoke('Admin','POST')).status,405);
  assert.equal(await handleDashboardOverview({method:'GET'},{},'/other',{role_name:'Admin'},()=>{}),false);
  console.log('PASS: live dashboard counts, complete ordered course list, administrator authorization and GET-only endpoint.');
} finally { await pool.end(); }
