INSERT INTO user_roles(role_name) VALUES('Employee') ON CONFLICT(role_name) DO NOTHING;
CREATE TABLE IF NOT EXISTS emp_department (
 emp_department_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 emp_department_name VARCHAR(65) NOT NULL UNIQUE,emp_department_alias VARCHAR(10) NOT NULL UNIQUE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),created_by BIGINT REFERENCES users(user_id),updated_at TIMESTAMPTZ,updated_by BIGINT REFERENCES users(user_id),is_status SMALLINT NOT NULL DEFAULT 1
);
CREATE TABLE IF NOT EXISTS emp_designation (
 emp_designation_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 emp_designation_name VARCHAR(50) NOT NULL UNIQUE,emp_designation_alias VARCHAR(10) NOT NULL UNIQUE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),created_by BIGINT REFERENCES users(user_id),updated_at TIMESTAMPTZ,updated_by BIGINT REFERENCES users(user_id),is_status SMALLINT NOT NULL DEFAULT 1
);
CREATE TABLE IF NOT EXISTS emp_category (
 emp_category_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 emp_category_name VARCHAR(50) NOT NULL UNIQUE,emp_category_alias VARCHAR(10) NOT NULL UNIQUE,
 is_teaching BOOLEAN NOT NULL DEFAULT FALSE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),created_by BIGINT REFERENCES users(user_id),updated_at TIMESTAMPTZ,updated_by BIGINT REFERENCES users(user_id),is_status SMALLINT NOT NULL DEFAULT 1
);
CREATE TABLE IF NOT EXISTS emp_info (
 emp_info_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 emp_unique_id BIGINT NOT NULL UNIQUE CHECK(emp_unique_id>0),employee_code VARCHAR(50) NOT NULL UNIQUE,
 emp_title VARCHAR(15),emp_first_name VARCHAR(35) NOT NULL,emp_middle_name VARCHAR(35),emp_last_name VARCHAR(35) NOT NULL,
 emp_name_alias VARCHAR(10),emp_gender VARCHAR(20),emp_dob DATE,emp_joining_date DATE,
 emp_email_id VARCHAR(65),emp_mobile_no VARCHAR(20),emp_maritalstatus VARCHAR(35),
 emp_experience_year SMALLINT NOT NULL DEFAULT 0 CHECK(emp_experience_year BETWEEN 0 AND 80),
 emp_experience_month SMALLINT NOT NULL DEFAULT 0 CHECK(emp_experience_month BETWEEN 0 AND 11)
);
CREATE UNIQUE INDEX IF NOT EXISTS emp_info_email_unique ON emp_info(lower(emp_email_id)) WHERE emp_email_id IS NOT NULL;
CREATE TABLE IF NOT EXISTS emp_master (
 emp_master_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 emp_master_emp_info_id BIGINT NOT NULL UNIQUE REFERENCES emp_info(emp_info_id),
 emp_master_user_id BIGINT NOT NULL UNIQUE REFERENCES users(user_id),
 emp_master_department_id BIGINT NOT NULL REFERENCES emp_department(emp_department_id),
 emp_master_designation_id BIGINT REFERENCES emp_designation(emp_designation_id),
 emp_master_category_id BIGINT NOT NULL REFERENCES emp_category(emp_category_id),
 emp_master_nationality_id BIGINT REFERENCES nationality(nationality_id),emp_cast VARCHAR(35),
 deleted_at TIMESTAMPTZ,deleted_by BIGINT REFERENCES users(user_id),
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),created_by BIGINT REFERENCES users(user_id),updated_at TIMESTAMPTZ,updated_by BIGINT REFERENCES users(user_id),is_status SMALLINT NOT NULL DEFAULT 1
);
CREATE INDEX IF NOT EXISTS emp_master_department_idx ON emp_master(emp_master_department_id);
CREATE INDEX IF NOT EXISTS emp_master_deleted_idx ON emp_master(deleted_at);
