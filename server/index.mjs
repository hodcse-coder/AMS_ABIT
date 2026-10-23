import {handleAdminAccounts} from './admin-accounts.mjs';
import {handleObe} from './obe.mjs';
import {handleDashboardOverview} from './dashboard-overview.mjs';
import {handleDashboardConfiguration} from './dashboard-configuration.mjs';
import {handleUserManagement,accessForUser,authorizedAccessModule} from './user-management.mjs';
import {handleMentoring} from './mentoring.mjs';
import {handleTimetable} from './timetable.mjs';
import {handleStudents} from './students.mjs';
import {handleEmployees} from './employees.mjs';
import {handleSubjectConfiguration} from './subject-configuration.mjs';
import {handleAcademicResources} from './academic-resources.mjs';
import http from 'node:http';
import { randomBytes, createHash } from 'node:crypto';
import { createServer as createViteServer } from 'vite';
import { pool } from './db.mjs';
import { hashPassword, verifyPassword } from './passwords.mjs';
import { handleConfiguration } from './configuration.mjs';
import { handleCourses } from './courses.mjs';

let vite;
const digest = value => createHash('sha256').update(value).digest('hex');
const failures = new Map();
const dummyHash = await hashPassword(randomBytes(24).toString('hex'));
function reply(res, status, body) {
  res.writeHead(status, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' });
  res.end(JSON.stringify(body));
}
async function body(req) {
  let text = '';
  for await (const chunk of req) {
    text += chunk;
    if (text.length > (req.url?.startsWith('/api/admin/accounts') ? 2900000 : req.url?.startsWith('/api/admin/obe') ? 16000000 : req.url?.startsWith('/api/admin/dashboard-configuration') ? 7200000 : req.url?.startsWith('/api/admin/configuration/organization') ? 1500000 : req.url?.split('?')[0]==='/api/admin/students/import' ? 5700000 : req.url?.startsWith('/api/admin/students') ? 100000 : req.url?.startsWith('/api/admin/timetable') ? 200000 : req.url?.startsWith('/api/mentoring') ? 100000 : req.url?.startsWith('/api/admin/academics/take-attendance') ? 150000 : req.url?.split('?')[0]==='/api/admin/academics/video-lecture' ? 35500000 : req.url?.startsWith('/api/admin/academics/lecture-notes/assignments/') ? 14500000 : req.url?.startsWith('/api/admin/academics/lesson-plan/subjects/') ? 650000 : 16384)) throw Object.assign(new Error('Request too large.'), { status: 413 });
  }
  try { return JSON.parse(text); } catch { throw Object.assign(new Error('Invalid JSON.'), { status: 400 }); }
}
const cookie = (res, token, age) => res.setHeader('Set-Cookie', `abit_session=${token}; HttpOnly; SameSite=Strict; Path=/; Max-Age=${age}${process.env.COOKIE_SECURE === 'true' ? '; Secure' : ''}`);
async function session(req) {
  const token = req.headers.cookie?.match(/(?:^|;\s*)abit_session=([a-f0-9]{64})(?:;|$)/)?.[1];
  if (!token) return null;
  const result = await pool.query('SELECT u.user_id,u.username,u.full_name,r.role_name FROM user_sessions s JOIN users u USING(user_id) JOIN user_roles r USING(role_id) WHERE s.token_hash=$1 AND s.expires_at>NOW() AND u.is_active=TRUE', [digest(token)]);
  return result.rows[0] || null;
}

export const server = http.createServer(async (req, res) => {
  const path = req.url?.split('?')[0];
  if (!path?.startsWith('/api/')) {
    if (!vite) { res.writeHead(503, { 'Retry-After': '1' }); return res.end('Application is starting. Please refresh.'); }
    return vite.middlewares(req, res);
  }
  try {
    if (req.method !== 'GET' && req.headers.origin !== `http://${req.headers.host}` && req.headers.origin !== `https://${req.headers.host}`) return reply(res, 403, { error: 'Invalid request origin.' });
    if (path === '/api/login' && req.method === 'POST') {
      const key = req.socket.remoteAddress;
      const now = Date.now();
      if (failures.size > 1000) for (const [ip, entry] of failures) if (entry.until < now) failures.delete(ip);
      const previous = failures.get(key);
      if (previous?.until > now && previous.count >= 10) return reply(res, 429, { error: 'Too many attempts. Try again in 15 minutes.' });
      const input = await body(req);
      if (typeof input.username !== 'string' || typeof input.password !== 'string' || input.username.length > 100 || input.password.length > 1024 || !['Admin', 'Faculty', 'Student', 'Employee'].includes(input.role)) return reply(res, 400, { error: 'Enter a valid username, password, and role.' });
      const result = await pool.query('SELECT u.*,r.role_name FROM users u JOIN user_roles r USING(role_id) WHERE u.username=$1 AND r.role_name=$2', [input.username.trim(), input.role]);
      const user = result.rows[0];
      const valid = await verifyPassword(input.password, user?.password_hash || dummyHash);
      if (!user?.is_active || !valid) {
        failures.set(key, { count: previous?.until > now ? previous.count + 1 : 1, until: now + 900000 });
        return reply(res, 401, { error: 'Invalid credentials or inactive account.' });
      }
      failures.delete(key);
      const token = randomBytes(32).toString('hex');
      const age = input.remember === true ? 604800 : 28800;
      await pool.query('DELETE FROM user_sessions WHERE expires_at < NOW()');
      await pool.query("INSERT INTO user_sessions(token_hash,user_id,expires_at) VALUES($1,$2,NOW()+($3 * INTERVAL '1 second'))", [digest(token), user.user_id, age]);
      cookie(res, token, age);
      return reply(res, 200, { user: { user_id: user.user_id, username: user.username, full_name: user.full_name, role_name: user.role_name,...await accessForUser(user) } });
    }
    const user = await session(req);
    if (!user) return reply(res, 401, { error: 'Please sign in.' });
    if (path === '/api/me' && req.method === 'GET') return reply(res, 200, { user:{...user,...await accessForUser(user)} });
    if (path === '/api/me/photo' && req.method === 'GET') {
      const {rows:[photo]}=await pool.query('SELECT photo_data,photo_type FROM users WHERE user_id=$1',[user.user_id]);
      if(!photo?.photo_data)return reply(res,404,{error:'Photo not found.'});
      res.writeHead(200,{'Content-Type':photo.photo_type,'Cache-Control':'no-store','X-Content-Type-Options':'nosniff'});
      return res.end(photo.photo_data);
    }
    if (path === '/api/password' && req.method === 'POST') {
      const input = await body(req);
      if (typeof input.new_password !== 'string' || input.new_password.length < 8 || input.new_password.length > 1024) return reply(res, 400, { error: 'Enter a new password of at least 8 characters.' });
      if (input.confirm_password !== input.new_password) return reply(res, 400, { error: 'New Password and Confirm Password must match.' });
      if (typeof input.current_password !== 'string' || input.current_password.length > 1024) return reply(res, 400, { error: 'Enter your current password.' });
      const result = await pool.query('SELECT password_hash FROM users WHERE user_id=$1', [user.user_id]);
      if (!await verifyPassword(input.current_password, result.rows[0].password_hash)) return reply(res, 401, { error: 'Current password is incorrect.' });
      await pool.query('UPDATE users SET password_hash=$1,updated_at=NOW() WHERE user_id=$2', [await hashPassword(input.new_password), user.user_id]);
      await pool.query('DELETE FROM user_sessions WHERE user_id=$1', [user.user_id]);
      cookie(res, '', 0);
      return reply(res, 200, { ok: true });
    }
    if (path === '/api/logout' && req.method === 'POST') {
      const token = req.headers.cookie?.match(/abit_session=([a-f0-9]{64})/)?.[1];
      if (token) await pool.query('DELETE FROM user_sessions WHERE token_hash=$1', [digest(token)]);
      cookie(res, '', 0);
      return reply(res, 200, { ok: true });
    }
    if((path==='/api/dashboard-content'||path.startsWith('/api/dashboard-content/'))&&await handleDashboardConfiguration(req,res,path,user,body,reply)) return;
    if (await handleMentoring(req,res,path,user,body,reply)) return;
    if (['/api/timetable/mine','/api/timetable/floor'].includes(path)&&await handleTimetable(req,res,path,user,body,reply)) return;
    if(await handleUserManagement(req,res,path,user,body,reply)) return;
    if(user.role_name!=='Admin'){const module=await authorizedAccessModule(user,req.method,path);if(!module)return reply(res,403,{error:'You do not have permission for this action.'});user.authorized_module=module;}
    if (await handleDashboardOverview(req,res,path,user,reply)) return;
    if (await handleObe(req,res,path,user,body,reply)) return;
    if (await handleDashboardConfiguration(req,res,path,user,body,reply)) return;
    if (await handleTimetable(req,res,path,user,body,reply)) return;
    if (await handleStudents(req,res,path,user,body,reply)) return;
    if (await handleEmployees(req,res,path,user,body,reply)) return;
    if (await handleSubjectConfiguration(req,res,path,user,body,reply)) return;
    if (await handleAcademicResources(req,res,path,user,body,reply)) return;
    if (await handleConfiguration(req, res, path, user, body, reply)) return;
    if (await handleCourses(req, res, path, user, body, reply)) return;
    if (await handleAdminAccounts(req,res,path,user,body,reply)) return;
    if (path === '/api/admin/users' && req.method === 'GET') {
      const { rows } = await pool.query('SELECT u.user_id,u.username,u.full_name,u.email,u.is_active,u.created_at,u.updated_at,r.role_name FROM users u JOIN user_roles r USING(role_id) ORDER BY u.user_id');
      return reply(res, 200, { users: rows });
    }
    if (path === '/api/admin/users' && req.method === 'POST') {
      const input = await body(req);
      if (input.role !== 'Admin' || typeof input.username !== 'string' || !/^[A-Za-z0-9._-]{3,100}$/.test(input.username) || typeof input.full_name !== 'string' || !input.full_name.trim() || input.full_name.length > 150 || typeof input.password !== 'string' || input.password.length < 8 || input.password.length > 1024 || (input.email && (typeof input.email !== 'string' || input.email.length > 150 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(input.email)))) return reply(res, 400, { error: 'Provide a valid role, username (3–100 letters, numbers, dots, underscores or hyphens), name, email, and password (8+ characters).' });
      const passwordHash = await hashPassword(input.password);
      const client = await pool.connect();
      try {
        await client.query('BEGIN');
        const result = await client.query('INSERT INTO users(role_id,username,password_hash,full_name,email) SELECT role_id,$1,$2,$3,$4 FROM user_roles WHERE role_name=$5 RETURNING user_id', [input.username, passwordHash, input.full_name.trim(), input.email || null, input.role]);
        const table = { Admin: 'admins', Faculty: 'faculty', Student: 'students' }[input.role];
        await client.query(`INSERT INTO ${table}(user_id) VALUES($1)`, [result.rows[0].user_id]);
        await client.query('COMMIT');
        return reply(res, 201, { ok: true });
      } catch (error) { await client.query('ROLLBACK'); throw error; } finally { client.release(); }
    }
    const match = path.match(/^\/api\/admin\/users\/(\d+)\/status$/);
    if (match && req.method === 'POST') {
      const input = await body(req);
      if (typeof input.is_active !== 'boolean') return reply(res, 400, { error: 'Invalid account status.' });
      if (match[1] === String(user.user_id)) return reply(res, 400, { error: 'You cannot deactivate your own account.' });
      const result = await pool.query('UPDATE users SET is_active=$1,updated_at=NOW() WHERE user_id=$2 RETURNING user_id', [input.is_active, match[1]]);
      if (!result.rowCount) return reply(res, 404, { error: 'Account not found.' });
      if (!input.is_active) await pool.query('DELETE FROM user_sessions WHERE user_id=$1', [match[1]]);
      return reply(res, 200, { ok: true });
    }
    return reply(res, 404, { error: 'Not found.' });
  } catch (error) {
    if (error.code === '23505') return reply(res, 409, { error: 'A record with these unique details already exists.' });
    if (error.code === '23503') return reply(res, 409, { error: 'Linked records prevent this change, or a selected parent record no longer exists.' });
    if (error.code === '22008' || error.code === '22007') return reply(res, 400, { error: 'Enter a valid calendar date.' });
    if (error.code === '22001') return reply(res, 400, { error: 'A value is too long after conversion to capital letters. Please shorten it.' });
    console.error('API request failed:', error.code || error.name);
    return reply(res, error.status || 500, { error: error.status ? error.message : 'Unable to complete request.' });
  }
});
const port = Number(process.env.PORT || 3000);
server.on('error', async error => {
  if (error.code === 'EADDRINUSE') {
    console.error(`Port ${port} is already in use. If ABIT ERP is running, open http://127.0.0.1:${port} instead of starting it again.`);
    console.error('To restart, press Ctrl+C in the existing server terminal, then run npm.cmd start. To use another port, set PORT in .env.');
  } else {
    console.error(`Unable to start ABIT ERP: ${error.message}`);
  }
  await vite?.close();
  await pool.end();
  process.exitCode = 1;
});
server.listen(port, '127.0.0.1', async () => {
  try {
    vite = await createViteServer({ server: { middlewareMode: true, hmr: { server } } });
    console.log(`ABIT ERP: http://127.0.0.1:${port}`);
  } catch (error) {
    console.error(`Unable to start React development server: ${error.message}`);
    server.close();
    await pool.end();
    process.exitCode = 1;
  }
});
