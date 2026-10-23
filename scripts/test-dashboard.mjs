import assert from 'node:assert/strict';
import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { createServer } from 'vite';

const vite = await createServer({ server: { middlewareMode: true, hmr: false } });
try {
  const { default: DashboardOverview } = await vite.ssrLoadModule('/src/DashboardOverview.jsx');
  const now = new Date().toISOString();
  const users = [
    { user_id: '1', full_name: 'CAMPUS ADMIN', username: 'admin', role_name: 'Admin', is_active: true, created_at: now },
    { user_id: '2', full_name: 'FACULTY MEMBER', username: 'faculty', role_name: 'Faculty', is_active: true, created_at: now },
    { user_id: '3', full_name: 'STUDENT MEMBER', username: 'student', role_name: 'Student', is_active: false, created_at: now },
  ];
  const adminHtml = renderToStaticMarkup(React.createElement(DashboardOverview, { user: users[0], users, onNavigate() {} }));
  assert.ok(adminHtml.includes('aria-label="Admin: 1, Faculty: 1, Student: 1"'));
  assert.ok(adminHtml.includes('1 inactive accounts'));
  assert.ok(adminHtml.includes('Monthly account registrations:'));
  assert.ok(adminHtml.includes('STUDENT MEMBER'));
  assert.ok(adminHtml.includes('Master configuration'));
  const studentHtml = renderToStaticMarkup(React.createElement(DashboardOverview, { user: users[2], users, onNavigate() {} }));
  assert.ok(studentHtml.includes('Welcome, STUDENT MEMBER'));
  assert.ok(!studentHtml.includes('CAMPUS ADMIN'));
  assert.ok(!studentHtml.includes('Manage accounts'));
  assert.ok(!studentHtml.includes('Master configuration'));
  const emptyHtml = renderToStaticMarkup(React.createElement(DashboardOverview, { user: users[0], users: [], onNavigate() {} }));
  assert.ok(emptyHtml.includes('No accounts yet.'));
  assert.ok(!emptyHtml.includes('NaN'));
  console.log('PASS: Dashboard role totals, account status, registration chart, empty state and role-based visibility.');
} finally {
  await vite.close();
}
