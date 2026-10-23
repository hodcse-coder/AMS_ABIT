import { pool } from './db.mjs';

export async function handleDashboardOverview(req, res, path, user, reply) {
  if (path !== '/api/admin/dashboard-overview') return false;
  if (user.role_name !== 'Admin') { reply(res, 403, { error: 'Administrator access required.' }); return true; }
  if (req.method !== 'GET') { reply(res, 405, { error: 'Method not allowed.' }); return true; }
  const { rows: [data] } = await pool.query(`SELECT
    (SELECT count(*)::int FROM courses) AS courses,
    (SELECT count(*)::int FROM emp_department) AS departments,
    (SELECT count(*)::int FROM faculty f WHERE NOT EXISTS
      (SELECT 1 FROM emp_master e WHERE e.emp_master_user_id=f.user_id AND e.deleted_at IS NOT NULL)) AS faculty,
    (SELECT count(*)::int FROM students s WHERE NOT EXISTS
      (SELECT 1 FROM stu_master m WHERE m.stu_master_user_id=s.user_id AND m.deleted_at IS NOT NULL)) AS students,
    (SELECT coalesce(json_agg(c ORDER BY c.course_name,c.course_id),'[]'::json)
      FROM (SELECT course_id,course_name,course_code FROM courses) c) AS course_list`);
  const { course_list, ...counts } = data;
  reply(res, 200, { counts, courses: course_list });
  return true;
}
