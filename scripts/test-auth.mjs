import assert from 'node:assert/strict';
import { randomBytes } from 'node:crypto';
import { pool } from '../server/db.mjs';

const base = process.env.TEST_URL || 'http://127.0.0.1:3000';
const suffix = randomBytes(6).toString('hex');
const names = [`test_faculty_${suffix}`, `test_student_${suffix}`];
const password = randomBytes(18).toString('base64url');
async function request(path, { cookie, data, ...options } = {}) {
  return fetch(`${base}${path}`, { ...options, headers: { Origin: base, 'Content-Type': 'application/json', ...(cookie ? { Cookie: cookie } : {}) }, ...(data ? { body: JSON.stringify(data) } : {}) });
}
async function login(username, password, role) {
  const response = await request('/api/login', { method: 'POST', data: { username, password, role } });
  assert.equal(response.status, 200);
  assert.match(response.headers.get('set-cookie'), /HttpOnly/);
  return response.headers.get('set-cookie').split(';')[0];
}
try {
  assert.ok(process.env.TEST_ADMIN_PASSWORD, 'Set TEST_ADMIN_PASSWORD before testing.');
  assert.equal((await request('/api/admin/users')).status, 401);
  assert.equal((await request('/api/login', { method: 'POST', data: { username: "' OR 1=1 --", password: 'invalid', role: 'Admin' } })).status, 401);
  const adminCookie = await login('admin', process.env.TEST_ADMIN_PASSWORD, 'Admin');
  const adminData = await (await request('/api/me', { cookie: adminCookie })).json();
  assert.equal(adminData.user.role_name, 'Admin');
  assert.equal((await request(`/api/admin/users/${adminData.user.user_id}/status`, { method: 'POST', cookie: adminCookie, data: { is_active: false } })).status, 400);
  for (const [index, role] of ['Faculty', 'Student'].entries()) {
    const data = { username: names[index], password, role, full_name: `Integration ${role}` };
    assert.equal((await request('/api/admin/users', { method: 'POST', cookie: adminCookie, data })).status, 201);
    assert.equal((await request('/api/admin/users', { method: 'POST', cookie: adminCookie, data })).status, 409);
    let cookie = await login(names[index], password, role);
    assert.equal((await request('/api/admin/users', { cookie })).status, 403);
    assert.equal((await request('/api/admin/users', { method: 'POST', cookie, data })).status, 403);
    const { rows } = await pool.query('SELECT user_id,password_hash FROM users WHERE username=$1', [names[index]]);
    assert.ok(rows[0].password_hash.startsWith('scrypt:'));
    assert.notEqual(rows[0].password_hash, password);
    const table = role === 'Faculty' ? 'faculty' : 'students';
    assert.equal((await pool.query(`SELECT user_id FROM ${table} WHERE user_id=$1`, [rows[0].user_id])).rowCount, 1);
    const newPassword = randomBytes(18).toString('base64url');
    assert.equal((await request('/api/password', { method: 'POST', cookie, data: { current_password: 'wrong', new_password: newPassword } })).status, 401);
    assert.equal((await request('/api/password', { method: 'POST', cookie, data: { current_password: password, new_password: newPassword } })).status, 200);
    assert.equal((await request('/api/me', { cookie })).status, 401);
    cookie = await login(names[index], newPassword, role);
    assert.equal((await request(`/api/admin/users/${rows[0].user_id}/status`, { method: 'POST', cookie: adminCookie, data: { is_active: false } })).status, 200);
    assert.equal((await request('/api/me', { cookie })).status, 401);
    assert.equal((await request('/api/login', { method: 'POST', data: { username: names[index], password: newPassword, role } })).status, 401);
  }
  assert.equal((await request('/api/logout', { method: 'POST', cookie: adminCookie, data: {} })).status, 200);
  assert.equal((await request('/api/me', { cookie: adminCookie })).status, 401);
  const crossOrigin = await fetch(`${base}/api/login`, { method: 'POST', headers: { Origin: 'http://untrusted.example', 'Content-Type': 'application/json' }, body: '{}' });
  assert.equal(crossOrigin.status, 403);
  console.log('PASS: Admin login, roles, account creation, duplicate handling, password hashing, password changes, authorization, deactivation, logout and origin checks.');
} finally {
  await pool.query('DELETE FROM users WHERE username = ANY($1::text[])', [names]);
  await pool.end();
}
