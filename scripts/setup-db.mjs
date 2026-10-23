import {syncAccessRoutes} from '../server/user-management.mjs';
import { readFile } from 'node:fs/promises';
import { randomBytes } from 'node:crypto';
import { pool } from '../server/db.mjs';
import { hashPassword } from '../server/passwords.mjs';

const client = await pool.connect();
try {
  await client.query('BEGIN');
  await client.query(await readFile(new URL('../database/auth.sql', import.meta.url), 'utf8'));
  await client.query(await readFile(new URL('../database/configuration.sql', import.meta.url), 'utf8'));
  await client.query(await readFile(new URL('../database/uppercase.sql', import.meta.url), 'utf8'));
  await client.query(await readFile(new URL('../database/courses.sql', import.meta.url), 'utf8'));
  await client.query(await readFile(new URL('../database/academics.sql', import.meta.url), 'utf8'));
  await client.query(await readFile(new URL('../database/branches.sql', import.meta.url), 'utf8'));
  await client.query(await readFile(new URL('../database/academic-resources.sql', import.meta.url), 'utf8'));
  await client.query(await readFile(new URL('../database/preferred-books.sql', import.meta.url), 'utf8'));
  await client.query(await readFile(new URL('../database/course-outcomes.sql', import.meta.url), 'utf8'));
  await client.query(await readFile(new URL('../database/lesson-plans.sql', import.meta.url), 'utf8'));
  await client.query(await readFile(new URL('../database/lecture-notes.sql', import.meta.url), 'utf8'));
  await client.query(await readFile(new URL('../database/note-upload-report.sql', import.meta.url), 'utf8'));
  await client.query(await readFile(new URL('../database/video-lectures.sql', import.meta.url), 'utf8'));
  await client.query(await readFile(new URL('../database/attendance.sql', import.meta.url), 'utf8'));
  await client.query(await readFile(new URL('../database/student-attendance-report.sql', import.meta.url), 'utf8'));
  await client.query(await readFile(new URL('../database/subject-configuration.sql', import.meta.url), 'utf8'));
  await client.query(await readFile(new URL('../database/subject-teacher-context.sql', import.meta.url), 'utf8'));
  await client.query(await readFile(new URL('../database/course-duration-semesters.sql', import.meta.url), 'utf8'));
  await client.query(await readFile(new URL('../database/semester-section-only.sql', import.meta.url), 'utf8'));
  await client.query(await readFile(new URL('../database/employees.sql', import.meta.url), 'utf8'));
  await client.query(await readFile(new URL('../database/students.sql', import.meta.url), 'utf8'));
  await client.query(await readFile(new URL('../database/timetable.sql', import.meta.url), 'utf8'));
  await client.query(await readFile(new URL('../database/mentoring.sql', import.meta.url), 'utf8'));
  await client.query(await readFile(new URL('../database/user-management.sql', import.meta.url), 'utf8'));
  await client.query(await readFile(new URL('../database/dashboard-configuration.sql', import.meta.url), 'utf8'));
  await client.query(await readFile(new URL('../database/obe.sql', import.meta.url), 'utf8'));
  await client.query(await readFile(new URL('../database/obe-compatibility.sql', import.meta.url), 'utf8'));
  await client.query(await readFile(new URL('../database/obe-erp-links.sql', import.meta.url), 'utf8'));
  await client.query(await readFile(new URL('../database/admin-account-photos.sql', import.meta.url), 'utf8'));
  await syncAccessRoutes(client);
  const existing = await client.query("SELECT u.user_id FROM users u JOIN user_roles r USING(role_id) WHERE r.role_name='Admin'");
  let password;
  if (!existing.rowCount) {
    password = process.env.ADMIN_PASSWORD || randomBytes(18).toString('base64url');
    if (password.length < 8) throw new Error('ADMIN_PASSWORD must contain at least 8 characters.');
    const result = await client.query("INSERT INTO users(role_id,username,password_hash,full_name) SELECT role_id,$1,$2,$3 FROM user_roles WHERE role_name='Admin' RETURNING user_id", [process.env.ADMIN_USERNAME || 'admin', await hashPassword(password), 'ERP Administrator']);
    await client.query('INSERT INTO admins(user_id) VALUES($1)', [result.rows[0].user_id]);
  }
  await client.query('COMMIT');
  console.log('ABITDB tables and roles are ready.');
  if (password) {
    console.log(`Admin username: ${process.env.ADMIN_USERNAME || 'admin'}`);
    console.log(`Initial admin password: ${password}`);
    console.log('Save this password securely; it is not stored in plaintext.');
  }
} catch (error) {
  await client.query('ROLLBACK');
  console.error('Database setup failed:', error.message);
  process.exitCode = 1;
} finally {
  client.release();
  await pool.end();
}
