import assert from 'node:assert/strict';
import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { createServer } from 'vite';
const vite = await createServer({ server: { middlewareMode: true, hmr: false } });
try {
  const { default: InstituteSetup } = await vite.ssrLoadModule('/src/InstituteSetup.jsx');
  const institute = { org_id: 1, org_name: 'TEST INSTITUTE', org_alias: 'TEST', org_address_line1: 'CAMPUS', org_stu_prefix: 'ST', org_emp_prefix: 'EM', org_logo_type: 'image/png', logo_url: 'data:image/png;base64,dGVzdA==', created_at: '2026-10-20T06:00:00Z', created_user: 'admin' };
  const details = renderToStaticMarkup(React.createElement(InstituteSetup, { rows: [institute], loading: false, onRefresh() {} }));
  assert.ok(details.includes('View Institute Setup Details'));
  assert.ok(details.includes('TEST INSTITUTE'));
  assert.ok(details.includes('Created User'));
  assert.ok(details.includes('data:image/png;base64,dGVzdA=='));
  assert.ok(details.includes('>Edit</button>'));
  assert.ok(!details.includes('>Add Institute</button>'));
  assert.ok(!details.includes('type="file"'));
  assert.ok(!details.includes('<form'));
  const empty = renderToStaticMarkup(React.createElement(InstituteSetup, { rows: [], loading: false, onRefresh() {} }));
  assert.ok(empty.includes('No institute setup has been saved.'));
  assert.ok(empty.includes('Add Institute'));
  assert.ok(!empty.includes('>Edit</button>'));
  console.log('PASS: Institute details and saved logo visible; Add/Edit form hidden by default; empty setup handled.');
} finally { await vite.close(); }
