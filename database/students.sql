CREATE TABLE IF NOT EXISTS stu_category (
 stu_category_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,stu_category_name VARCHAR(50) NOT NULL UNIQUE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),created_by BIGINT REFERENCES users(user_id),updated_at TIMESTAMPTZ,updated_by BIGINT REFERENCES users(user_id)
);
CREATE TABLE IF NOT EXISTS stu_status (
 stu_status_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,stu_status_name VARCHAR(50) NOT NULL UNIQUE,allows_login BOOLEAN NOT NULL DEFAULT TRUE
);
INSERT INTO stu_status(stu_status_name,allows_login) VALUES('Active',TRUE),('Inactive',FALSE),('Graduated',FALSE),('Transferred',FALSE) ON CONFLICT(stu_status_name) DO NOTHING;
CREATE SEQUENCE IF NOT EXISTS student_registration_seq;
CREATE TABLE IF NOT EXISTS stu_info (
 stu_info_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 stu_unique_id VARCHAR(50) NOT NULL UNIQUE,stu_first_name VARCHAR(50) NOT NULL,stu_middle_name VARCHAR(50),stu_last_name VARCHAR(50),
 stu_dob DATE NOT NULL,stu_email_id VARCHAR(150),stu_domain_email_id VARCHAR(150),stu_mobile_no VARCHAR(20),details JSONB NOT NULL DEFAULT '{}'
);
CREATE UNIQUE INDEX IF NOT EXISTS stu_info_registration_unique ON stu_info(upper(stu_unique_id));
CREATE TABLE IF NOT EXISTS stu_master (
 stu_master_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 stu_master_stu_info_id BIGINT NOT NULL UNIQUE REFERENCES stu_info(stu_info_id),stu_master_user_id BIGINT NOT NULL UNIQUE REFERENCES students(user_id),
 stu_master_category_id BIGINT NOT NULL REFERENCES stu_category(stu_category_id),stu_master_nationality_id BIGINT REFERENCES nationality(nationality_id),
 stu_master_course_id BIGINT NOT NULL REFERENCES courses(course_id),stu_master_batch_id BIGINT NOT NULL,
 stu_master_section_id BIGINT NOT NULL REFERENCES section(s_id),semester_registered SMALLINT NOT NULL DEFAULT 1,
 stu_master_stu_status_id BIGINT NOT NULL REFERENCES stu_status(stu_status_id),allotment_status SMALLINT NOT NULL DEFAULT 0,
 academic_details JSONB NOT NULL DEFAULT '{}',entrance_details JSONB NOT NULL DEFAULT '{}',paid_preferences JSONB NOT NULL DEFAULT '{}',
 deleted_at TIMESTAMPTZ,deleted_by BIGINT REFERENCES users(user_id),
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),created_by BIGINT REFERENCES users(user_id),updated_at TIMESTAMPTZ,updated_by BIGINT REFERENCES users(user_id),
 FOREIGN KEY(stu_master_batch_id,stu_master_course_id) REFERENCES batches(batch_id,batch_course_id)
);
CREATE TABLE IF NOT EXISTS stu_address (
 stu_address_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,student_id BIGINT NOT NULL REFERENCES stu_master(stu_master_id),
 address_type VARCHAR(10) NOT NULL CHECK(address_type IN('current','permanent')),address_text TEXT,country_id INTEGER REFERENCES country(country_id),
 state_id INTEGER REFERENCES state(state_id),city_id INTEGER REFERENCES city(city_id),pincode VARCHAR(12),house_no VARCHAR(25),phone_no VARCHAR(25),UNIQUE(student_id,address_type)
);
CREATE TABLE IF NOT EXISTS stu_guardians (
 stu_guardian_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,guardia_stu_master_id BIGINT NOT NULL REFERENCES stu_master(stu_master_id),
 guardian_relation VARCHAR(10) NOT NULL CHECK(guardian_relation IN('father','mother')),guardian_name VARCHAR(65),guardian_mobile_no VARCHAR(20),guardian_whatsapp_no VARCHAR(20),guardian_email VARCHAR(150),guardian_occupation VARCHAR(200),guardian_income NUMERIC(14,2),UNIQUE(guardia_stu_master_id,guardian_relation)
);
ALTER TABLE course_students ADD COLUMN IF NOT EXISTS section_id BIGINT REFERENCES section(s_id);
ALTER TABLE students DROP CONSTRAINT IF EXISTS students_semester_check;
DO $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='students_semester_positive' AND conrelid='students'::regclass) THEN
  ALTER TABLE students ADD CONSTRAINT students_semester_positive CHECK(semester>0) NOT VALID;
 END IF;
END $$;
CREATE INDEX IF NOT EXISTS stu_master_cohort_idx ON stu_master(stu_master_course_id,stu_master_batch_id,stu_master_section_id);
CREATE INDEX IF NOT EXISTS stu_master_deleted_idx ON stu_master(deleted_at);

DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='users' AND column_name='mobile' AND (data_type<>'character varying' OR character_maximum_length IS DISTINCT FROM 20)) THEN
  ALTER TABLE users ALTER COLUMN mobile TYPE VARCHAR(20);
 END IF;
END $$;
