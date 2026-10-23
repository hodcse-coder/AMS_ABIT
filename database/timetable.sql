-- Runtime equivalents of the timetable tables in ABITDB.sql use existing ERP keys.
CREATE TABLE IF NOT EXISTS timetable_rooms (
 room_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,room_no VARCHAR(50) NOT NULL UNIQUE,
 building VARCHAR(100) NOT NULL,floor_name VARCHAR(30) NOT NULL,capacity INTEGER NOT NULL CHECK(capacity BETWEEN 1 AND 1000),
 room_type VARCHAR(20) NOT NULL CHECK(room_type IN('CLASSROOM','LAB','SEMINAR')),manager_id BIGINT REFERENCES users(user_id),is_active BOOLEAN NOT NULL DEFAULT TRUE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),created_by BIGINT REFERENCES users(user_id),updated_at TIMESTAMPTZ,updated_by BIGINT REFERENCES users(user_id)
);
CREATE TABLE IF NOT EXISTS timetable_schedules (
 timetable_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,batch_semester_id BIGINT NOT NULL REFERENCES semester_defined(id),section_id BIGINT NOT NULL REFERENCES section(s_id),
 timetable_name VARCHAR(150) NOT NULL,effective_from DATE NOT NULL,effective_to DATE,is_published BOOLEAN NOT NULL DEFAULT FALSE,
 created_by BIGINT REFERENCES users(user_id),created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),updated_at TIMESTAMPTZ,updated_by BIGINT REFERENCES users(user_id),
 CHECK(effective_to IS NULL OR effective_to>=effective_from)
);
CREATE TABLE IF NOT EXISTS timetable_schedule_cells (
 cell_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,timetable_id BIGINT NOT NULL REFERENCES timetable_schedules(timetable_id) ON DELETE CASCADE,
 day_of_week SMALLINT NOT NULL CHECK(day_of_week BETWEEN 1 AND 7),period_number SMALLINT NOT NULL CHECK(period_number BETWEEN 1 AND 20),
 start_time TIME NOT NULL,end_time TIME NOT NULL,allotment_id BIGINT NOT NULL REFERENCES section_house_subject_teacher(shst_id),
 room_id BIGINT NOT NULL REFERENCES timetable_rooms(room_id),room_no VARCHAR(50),notes VARCHAR(500),CHECK(end_time>start_time),UNIQUE(timetable_id,day_of_week,period_number)
);
CREATE TABLE IF NOT EXISTS timetable_course_access (
 access_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,user_id BIGINT NOT NULL REFERENCES users(user_id),
 batch_semester_id BIGINT NOT NULL REFERENCES semester_defined(id),section_id BIGINT NOT NULL REFERENCES section(s_id),is_active BOOLEAN NOT NULL DEFAULT TRUE,
 UNIQUE(user_id,batch_semester_id,section_id)
);
-- employee_id refers to the employee's linked Faculty user ID, including legacy Faculty accounts.
CREATE TABLE IF NOT EXISTS timetable_faculty_access (
 access_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,user_id BIGINT NOT NULL REFERENCES users(user_id),employee_id BIGINT NOT NULL REFERENCES users(user_id),
 is_active BOOLEAN NOT NULL DEFAULT TRUE,UNIQUE(user_id,employee_id)
);
CREATE INDEX IF NOT EXISTS timetable_cells_allotment_idx ON timetable_schedule_cells(allotment_id);
CREATE INDEX IF NOT EXISTS timetable_cells_room_idx ON timetable_schedule_cells(room_id,day_of_week);
CREATE INDEX IF NOT EXISTS timetable_schedule_dates_idx ON timetable_schedules(effective_from,effective_to) WHERE is_published;
