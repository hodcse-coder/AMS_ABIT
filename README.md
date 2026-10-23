# ABIT Academic Management System

React login with a Node.js API and PostgreSQL-backed accounts. The campus design is preserved, with Faculty, Student, and Admin sign-in.

## Run locally

```powershell
cd C:\AMS_ABIT
npm.cmd install
npm.cmd start
```

The app runs at http://127.0.0.1:3000 directly from `C:\AMS_ABIT`. `npm.cmd run dev` also starts both the API and React development server. Restart the process after changing server files.

## Lecture Notes

Open Academics → Lecture Notes. Use Assign Faculty to link a course, batch, semester, section/house, subject and active faculty account. Courses, batches, sections and faculty accounts must already exist. The table filters by course, batch, semester, subject, faculty and teacher type.

Upload accepts PDF, DOC, DOCX, PPT and PPTX documents up to 10 MB with a note title. Files are stored in PostgreSQL and downloaded through the authenticated API. Older note records remain visible; unavailable legacy attachments must be uploaded again. `database/lecture-notes.sql` is included in database setup, and `node --env-file=.env scripts/test-lecture-notes.mjs` checks assignment and document handling.

Open the local URL printed by Vite. React development requires a web server; opening index.html directly is no longer supported.

```powershell
npm.cmd run build
npm.cmd run preview
```

`preview` serves only the built interface; authenticated login requires the Node.js API started by `npm.cmd start`. The current combined server is intended for local development.

## PostgreSQL

PostgreSQL 17 is installed as the Windows service `postgresql-x64-17`. The `ABITDB` database is created and the ignored `.env` is configured for it. The earlier `abit_ams` database remains unchanged. `npm.cmd run db:check` verifies the active connection.
Verify availability:

```powershell
& 'C:/Program Files/PostgreSQL/17/bin/pg_isready.exe' -h localhost -p 5432
```

For setup on another machine, create the database and copy the connection template (enter that machine's PostgreSQL administrator password when prompted):

```powershell
& 'C:/Program Files/PostgreSQL/17/bin/createdb.exe' -h localhost -p 5432 -U postgres -W ABITDB
Copy-Item .env.example .env
```

Set DATABASE_URL in .env with the database credentials, then run:

```powershell
npm.cmd run db:check
npm.cmd run db:setup
```

`database/auth.sql` creates `user_roles`, `users`, `admins`, `faculty`, `students`, and `user_sessions`. It builds on the user/role structure supplied in `ABITDB.sql`. That source also contains MySQL-style ERP tables; those are preserved and are not imported by `db:setup`.

Setup is repeatable and creates an initial Admin only when no Admin exists. Set ADMIN_USERNAME and ADMIN_PASSWORD in the server environment to choose bootstrap credentials, or save the generated password printed on first setup. Existing Admin passwords are never reset by setup.

Select Admin on the login page. The Admin ERP panel lists accounts, creates Admin/Faculty/Student accounts, and activates or deactivates access. It blocks self-deactivation. Faculty and Student users have a basic portal, with Admin API access denied by the server. All roles can change their own password; changing a password revokes their sessions and requires sign-in again.

Passwords are salted scrypt hashes; session tokens are stored as hashes with expiry. Authentication uses HttpOnly, SameSite=Strict cookies. Database credentials stay server-side. Set COOKIE_SECURE=true when adapting the server for HTTPS.

To run integration checks against a running server, set TEST_ADMIN_PASSWORD locally and run `node --env-file=.env scripts/test-auth.mjs`. The checks create temporary Faculty/Student accounts and remove them afterwards.

## Dashboard and Configuration

Sign-in opens a campus overview styled after the supplied DashboardPack reference: a collapsible sidebar, compact header, teal accents and rounded panels. Admins see live account totals, monthly registrations, role distribution, recent accounts and Configuration counts. Faculty/Student accounts see their personal welcome and password settings. The sidebar includes searchable menus, Configuration, User Management, Change Password and sign-out. No sample records are seeded. Configuration follows the forms/lists in Configuration Dashboard Page.docx.

Run `node scripts/test-dashboard.mjs` to check dashboard totals, empty states and role visibility. Browser-based visual verification requires a local browser.

Success, error, validation, and deletion-confirmation messages use shared dialogs centered in the viewport. Delete waits for explicit confirmation; Cancel and Escape preserve the record. Dialogs use the native HTML dialog focus trap and modal backdrop, with consistent ABIT styling instead of browser alert/confirm popups.

| Configuration menu | PostgreSQL table |
| --- | --- |
| Country | country |
| State/Province | state |
| City/Town | city |
| Institute | last_passout_institution |
| Languages | languages |
| National Holidays | national_holidays |
| Document Categories | document_category |
| Nationality | nationality |

`database/configuration.sql` translates these definitions from the MySQL-style portion of `ABITDB.sql` to PostgreSQL. Existing source column names are retained; identities replace AUTO_INCREMENT and BYTEA replaces the organization logo BLOB. Country/state/city relationships are enforced. Document categories use ST for Student and EM for Employee. The supplied file's other tables are outside this Configuration menu.

Run `npm.cmd run db:setup` to apply the repeatable schema. Each Configuration item supports creation, editing, search, and deletion; records referenced by another table cannot be deleted. Configuration APIs require an active Admin session.

Run `node --env-file=.env scripts/test-configuration.mjs` against the local server to verify all eight tables, relationships, validation, and access control. Temporary test records and users are removed afterwards.

Descriptive text is saved in CAPITAL LETTERS, including names, addresses, departments, profile codes, prefixes, and remarks. Configuration forms normalize these values and PostgreSQL triggers enforce the rule for direct database writes as well. `database/uppercase.sql` also converts existing descriptive records transactionally during `db:setup`. Usernames, passwords/hashes, email addresses, website URLs, role identifiers, MIME types, files, and session tokens preserve their original casing.

The updated Word reference maps Institute to last_passout_institution: Type, District, Institute Name, Nearest Place, Affiliation, and Postal Address. Type provides the nine reference options. District is a searchable combobox with reference suggestions and saved districts; new names can be entered. The organization table remains intact. State and City forms follow Country / State / City selection order. Lists provide column filters and View/Edit/Delete actions.

Configuration is an expandable sidebar menu, ordered Country, State/Province, City/Town, Add College, Document Category, Languages, Hobbies, National Holiday, Nationality, Institute. Add College maps to last_passout_institution; Institute maps to organization; Hobbies maps to hobbies. Each submenu opens its database form directly. Course remains immediately below Configuration.
Institute opens a read-only setup-details table with the saved logo and created/updated user and time. Add Institute and Edit reveal the form; Cancel returns to details. Editing without selecting a replacement image preserves the stored logo. Run node scripts/test-institute.mjs for the default-view rendering checks.

Course opens Manage Course Modules with live Course/Batch/Section totals and an active-course list. database/courses.sql adds courses, course_batches, course_sections and course_students. Create controls add courses, batches and batch sections; course rows support student lists, filtered batch lists, details, editing and deletion. Linked batches/students prevent course deletion. No reference screenshot sample records are seeded. Assign Section and Subjects remain blank workspaces. Run node --env-file=.env scripts/test-courses.mjs against a running server to check the Course APIs.

Course setup now follows the courses, batches, section, section_defined, section_master and subjects definitions supplied in ABITDB.sql. PostgreSQL identities replace AUTO_INCREMENT, and existing course_batches/course_sections data is renamed in place to batches/section. The Add Course form creates a course and initial batch in one transaction, with an optional initial section/intake. Course Name, Code, Alias, Duration, Batch Name/Alias and Start/End Dates are required. Failed child inserts roll back the entire creation. Manage Courses provides column filters, status icons, view/edit/delete and ADD. Editing a course does not recreate its initial batch. Dates remain date-only strings.
Batch opens the screenshot-style Add Batch form and Manage Batches table, backed by the existing source-aligned batches table. Required fields are Batch Name, Batch Course, Batch Alias, Start Date and End Date. The table includes column filters, status icons, alumni/exit survey eligibility dropdowns and View/Edit/Delete actions. Eligibility and status use 1 for enabled and 0 for disabled. Updates record updated_at and updated_by; batches with linked sections or students cannot be deleted. All operation messages use centered dialogs.

Assign Section follows the supplied form/list layout. Its Section dropdown uses section_defined; Batch uses batches; assignments save to section with the selected definition ID, name, batch and optional intake. The page has Section/Batch/Intake filters, status icons, and View/Edit/Delete controls. Add Section now creates dropdown definitions, optionally tied to one course. Course-specific definitions can only be assigned to batches belonging to that course. Duplicate section names in the same batch are rejected. Intake must be a non-negative whole number; zero is preserved. All APIs require an active Admin session.

Add Section now follows the four-field reference layout: Section Name, Section Master, Course (For Admission Form), and Course. These map respectively to section_defined.section_name, section_master, rel_course, and rel_coursefecth. Dropdowns load saved section_master and courses records. Manage Section supports sorting, individual column filters, edit and confirmed delete. Renaming a definition updates linked assignment names transactionally. Definitions with assignments cannot be deleted. Assign Section uses the selected Course when supplied, otherwise the Admission Form Course, to validate compatible batches.

Section Master now has its own screenshot-style Add/Edit form and sortable, filterable table with status and View/Edit/Delete icons. It uses the existing section_master table. Names save in uppercase and remain unique. Create defaults to active status; edits can change status and record audit information. Referenced masters cannot be deleted. Saved masters populate the Add Section dropdown. Run node --env-file=.env scripts/test-section-masters.mjs against the running server to verify these operations.

Academic Year is available under Course. database/academics.sql extends the supplied subjects schema with academic_year_id and semester, and creates academic_years plus academic_year_semesters. Every Academic Year maps to Semester 1 and Semester 2, as requested. Labels use consecutive YYYY-YY format (for example 2026-27). Subjects require Academic Year, Semester, Name, Code, Alias and Type (Theory or Practical); Credit is an optional non-negative integer. Duplicate subject codes in the same year and semester are rejected, while the same code can be used in another semester or year. Existing unmapped subjects are preserved. Year deletion is blocked while subjects reference it. Both pages support editing and deletion with centered messages. Run node --env-file=.env scripts/test-academics.mjs to verify the database behavior.


Timetable is below Subject Configuration, with nested Offline Timetable views, My Offline Timetable, Manage Timetable and Manage Class Rooms. Run npm run db:setup to apply database/timetable.sql. Create rooms, then draft a timetable for an existing course/batch/semester/section; add allotted subject/teacher periods and publish. Publishing rejects overlapping teacher, room or class times. Faculty academic load is calculated weekly from published periods effective on the selected date. My Offline Timetable uses the signed-in faculty/student class or explicit viewer grants; floor managers see their assigned rooms. Run node --env-file=.env scripts/test-timetable.mjs for integration checks.


Student Mentoring is below Student, with Mentoring > Existing Student, 1st Reviewer Remarks, All Counselling & Reviews, Reviewer Allotment, Mentor Allotment > Existing Student, and Mentor Allotment Report. Run npm run db:setup for database/mentoring.sql. Allot an active employee as Mentor, configure that Mentor's three distinct Reviewers, then create counselling. Reviews proceed from first to second to chief; submitted reviews preserve their audit details. Mentor/reviewer allotment changes preserve the original assignments on existing counselling records. Admin manages allotments and sees all records; Faculty/Employee accounts see only their own mentees and assigned counselling/reviews. Reports support course/batch/section/mentor filters and XLSX export. The reference mentoring URL requires authentication; layouts follow the supplied SQL fields and Country styling. Run node --env-file=.env scripts/test-mentoring.mjs.


User Management now contains Assignment (User Assignments, Manage Accounts), Permission (Create/Manage Permissions), Role (Create/Manage Roles), and Route (Manage Routes). Run npm run db:setup to install database/user-management.sql and synchronize the registered routes. Permissions select module API methods and required lookup routes; access roles group permissions, and user assignments grant/revoke those roles. Existing Admin/Faculty/Student/Employee account types are preserved; Admin retains full access. Enabled grants are checked on every API request, including existing sessions. User Management, account administration and mentoring-wide access remain Admin-only. Refresh the signed-in page after changing grants to refresh its menus. Audit records retain changes; assigned roles and permissions used by roles cannot be deleted. Run node --env-file=.env scripts/test-user-management.mjs for HTTP authorization and CRUD checks.


Dashboard Configuration appears below Student Mentoring, with Message and Notice pages in the Country style. database/dashboard-configuration.sql maps the supplied msg_of_day and notice tables to PostgreSQL, adds department relations and stores authenticated PDF/PNG/JPG attachments up to 5 MB. Run npm run db:setup. The latest active message for the signed-in audience appears in the workspace header and updates immediately after saving; other sessions refresh it on focus or within 60 seconds. Active notices appear on Dashboard from their Notice Date onward. Staff department targeting uses the employee master; Student notices use All Departments. Configure Dashboard Configuration access via User Management for delegated managers. Run node --env-file=.env scripts/test-dashboard-configuration.mjs.


OBE is integrated from hodcse-coder/OBE at commit 14670a65e23171c170ff17e80962462208e57d17, below Student Mentoring. Its setup, outcomes, mappings, mark uploads, attainment and report pages share the ERP shell and Country styling. There is no second OBE login or user manager. The 39-table obe schema is in ABITDB with explicit links to ERP masters; run npm run db:setup. Use OBE > Setting > ERP Links for existing records, and Faculty from ERP to add/refresh teaching profiles. User Management lists OBE and Dashboard Configuration routes. The header breadcrumb has been removed; saved dashboard messages oscillate in that space, pause on hover, and honor reduced-motion preferences. See docs/OBE-INTEGRATION.md for page/table integration details and checks.
#   A M S _ A B I T  
 