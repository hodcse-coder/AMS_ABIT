import assert from 'node:assert/strict';
import { randomBytes } from 'node:crypto';
import { pool } from '../server/db.mjs';
import { hashPassword } from '../server/passwords.mjs';
import { configuration } from '../shared/configuration.mjs';

const base = process.env.TEST_URL || 'http://127.0.0.1:3000';
const suffix = randomBytes(5).toString('hex');
const password = randomBytes(18).toString('base64url');
const created = [];
const testUsers = [];
async function request(path, { cookie, data, ...options } = {}) {
  return fetch(base + path, { ...options, headers: { Origin: base, 'Content-Type': 'application/json', ...(cookie ? { Cookie: cookie } : {}) }, ...(data ? { body: JSON.stringify(data) } : {}) });
}
async function testLogin(role) {
  const username = `config_test_${role}_${suffix}`;
  const result = await pool.query('INSERT INTO users(role_id,username,password_hash,full_name) SELECT role_id,$1,$2,$3 FROM user_roles WHERE role_name=$4 RETURNING user_id', [username, await hashPassword(password), 'Temporary configuration test', role]);
  testUsers.push(result.rows[0].user_id);
  const response = await request('/api/login', { method: 'POST', data: { username, password, role } });
  assert.equal(response.status, 200);
  return response.headers.get('set-cookie').split(';')[0];
}
try {
  assert.equal((await request('/api/admin/configuration')).status, 401);
  const cookie = await testLogin('Admin');
  const facultyCookie = await testLogin('Faculty');
  assert.equal((await request('/api/admin/configuration', { cookie: facultyCookie })).status, 403);
  assert.equal((await request('/api/admin/configuration/country', { cookie: facultyCookie, method: 'POST', data: { country_name: 'Forbidden' } })).status, 403);
  const counts = await (await request('/api/admin/configuration', { cookie })).json();
  assert.equal(Object.keys(counts.counts).length, configuration.length);
  const inputs = {
    country: { country_name: `Test ${suffix}` },
    state: { state_name: `Test ${suffix}` },
    city: { city_name: `Test ${suffix}` },
    last_passout_institution: { institution_name: `Institute ${suffix}`, institute_type: 'CBSE SCHOOL', district: 'Cuttack', place: 'Cuttack', affiliation: 'CBSE', college_address: 'Test postal address' },
    languages: { language_name: `Test ${suffix}` },
    national_holidays: { national_holiday_name: `Test ${suffix}`, national_holiday_date: '2026-10-20' },
    document_category: { doc_category_name: `Test ${suffix}`, doc_category_user_type: 'ST' },
    nationality: { nationality_name: `Test ${suffix}` },
  };
  inputs.hobbies = { hobby_name: `Test ${suffix}` };
  inputs.organization = { org_name: `Institute ${suffix}`, org_alias: suffix, org_address_line1: 'Test address', org_stu_prefix: 'st', org_emp_prefix: 'em', org_email: 'Mixed.Case@example.com', org_website: 'https://example.com/CaseSensitive', org_logo: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a9WQAAAAASUVORK5CYII=' };
  const ids = {};
  for (const spec of configuration) {
    const input = inputs[spec.key];
    if (spec.key === 'last_passout_institution') input.district = (await pool.query('SELECT city_name FROM city WHERE city_id=$1', [ids.city])).rows[0].city_name;
    if (spec.key === 'state') input.state_country_id = ids.country;
    if (spec.key === 'city') { input.city_country_id = ids.country; input.city_state_id = ids.state; }
    const response = await request(`/api/admin/configuration/${spec.key}`, { cookie, method: 'POST', data: input });
    assert.equal(response.status, 201, `${spec.key}: ${await response.clone().text()}`);
    ids[spec.key] = (await response.json()).id;
    created.push([spec, ids[spec.key]]);
    const list = await (await request(`/api/admin/configuration/${spec.key}`, { cookie })).json();
    assert.ok(list.rows.some(row => row[spec.id] === ids[spec.key]));
    const saved = list.rows.find(row => row[spec.id] === ids[spec.key]);
    if (spec.key === 'organization') {
      assert.equal(saved.logo_url, input.org_logo);
      assert.ok(saved.created_at);
      assert.ok(saved.created_user);
      const withoutLogo = { ...input };
      delete withoutLogo.org_logo;
      assert.equal((await request(`/api/admin/configuration/organization/${ids[spec.key]}`, { cookie, method: 'PATCH', data: withoutLogo })).status, 200);
      const reloaded = await (await request('/api/admin/configuration/organization', { cookie })).json();
      const institute = reloaded.rows.find(row => row.org_id === ids[spec.key]);
      assert.equal(institute.logo_url, input.org_logo);
      assert.ok(institute.updated_at);
      assert.ok(institute.updated_user);
    }
    for (const field of spec.fields.filter(field => field.uppercase && input[field.name])) assert.equal(saved[field.name], input[field.name].toUpperCase());
    if (spec.key === 'national_holidays') assert.equal(list.rows.find(row => row[spec.id] === ids[spec.key]).national_holiday_date, input.national_holiday_date);
    assert.equal((await request(`/api/admin/configuration/${spec.key}/${ids[spec.key]}`, { cookie, method: 'PATCH', data: { ...input, [spec.fields[0].name]: `Updated ${suffix}` } })).status, 200);
    const updated = await pool.query(`SELECT ${spec.fields[0].name} AS value FROM ${spec.key} WHERE ${spec.id}=$1`, [ids[spec.key]]);
    assert.equal(updated.rows[0].value, `UPDATED ${suffix.toUpperCase()}`);
  }
  assert.equal((await request(`/api/admin/configuration/country/${ids.country}`, { cookie, method: 'DELETE' })).status, 409);
  assert.equal((await request('/api/admin/configuration/country', { cookie, method: 'POST', data: { country_name: '' } })).status, 400);
  assert.equal((await request('/api/admin/configuration/users', { cookie })).status, 404);
  assert.equal((await request('/api/admin/configuration/last_passout_institution', { cookie, method: 'POST', data: { institution_name: 'Invalid type', district: 'CUTTACK', place: 'CUTTACK', institute_type: 'INVALID' } })).status, 400);
  assert.equal((await request('/api/admin/configuration/country', { cookie, method: 'POST', data: { country_name: `Updated ${suffix}` } })).status, 409);
  for (const [spec, id] of [...created].reverse()) assert.equal((await request(`/api/admin/configuration/${spec.key}/${id}`, { cookie, method: 'DELETE' })).status, 200);
  console.log('PASS: All ten Configuration tables support create/list/update/delete; uppercase storage, authorization, validation, duplicate and relationship checks passed.');
} finally {
  for (const [spec, id] of [...created].reverse()) await pool.query(`DELETE FROM ${spec.key} WHERE ${spec.id}=$1`, [id]);
  await pool.query('DELETE FROM users WHERE user_id=ANY($1::bigint[])', [testUsers]);
  await pool.end();
}
