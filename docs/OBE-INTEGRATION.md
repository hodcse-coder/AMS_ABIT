# OBE integration

Source: https://github.com/hodcse-coder/OBE
Pinned commit: 14670a65e23171c170ff17e80962462208e57d17

Only business pages, formulas and domain schema are adapted. The standalone shell, login, user management, passwords and access-control database are excluded. The supplied PostgreSQL archive is inspected for schema only; its records are not restored. ERP authentication and User Management govern access under /api/admin/obe. Domain tables use the obe schema in ABITDB.

The OBE menu is below Student Mentoring and before Dashboard Configuration. It exposes General Information, Setting, OBE Setting, Attainment and Reports. Country styling is scoped to .obe-workspace and the OBE bundle loads only when opened.

ERP Links connects OBE Department to Employee Department, Programme to ERP Course, Admission Batch to Batch, Semester to Create Semester, OBE Course to ERP Subject, Faculty to Employee, and OBE Student to Student. These are explicit foreign-key links so ambiguous academic records are selected by the administrator rather than guessed. Faculty from ERP copies the selected employee's teaching profile without creating any account.

/api/admin/obe uses the existing ERP session and registered User Management grants for GET/POST/PUT/PATCH/DELETE. Dashboard Configuration remains registered separately. Source business handlers run with a request-scoped PostgreSQL client and search_path=obe,pg_catalog, then reset before release. No source users table or access-control endpoints are included.

Migrations: database/obe.sql (39 domain tables and reference Bloom/vision setup), database/obe-compatibility.sql (whole-course CO calculation summaries), database/obe-erp-links.sql (ERP references). The source archive's rows are never restored. ABITDB.sql includes these connected definitions.

The spreadsheet dependency is the official SheetJS 0.20.3 release: https://docs.sheetjs.com/docs/getting-started/installation/nodejs/ .

Checks: node --env-file=.env scripts/test-obe.mjs and node --env-file=.env scripts/test-user-management.mjs.
