-- Connected PostgreSQL equivalents of the supplied msg_of_day and notice tables.
CREATE TABLE IF NOT EXISTS msg_of_day (
 msg_of_day_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,msg_details VARCHAR(100) NOT NULL UNIQUE,
 msg_user_type VARCHAR(3) NOT NULL DEFAULT '0' CHECK(msg_user_type IN('0','STU','FAC','EMP','ADM')),
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),created_by BIGINT NOT NULL REFERENCES users(user_id),updated_at TIMESTAMPTZ,updated_by BIGINT REFERENCES users(user_id),
 is_status SMALLINT NOT NULL DEFAULT 1 CHECK(is_status IN(0,1))
);
CREATE TABLE IF NOT EXISTS notice (
 notice_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,notice_title VARCHAR(25) NOT NULL,notice_description VARCHAR(255),
 notice_user_type VARCHAR(3) NOT NULL DEFAULT '0' CHECK(notice_user_type IN('0','STU','FAC','EMP','ADM')),notice_date DATE,
 notice_file_path VARCHAR(100),rel_dept TEXT NOT NULL DEFAULT '',file_type VARCHAR(100),file_data BYTEA,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),created_by BIGINT NOT NULL REFERENCES users(user_id),updated_at TIMESTAMPTZ,updated_by BIGINT REFERENCES users(user_id),
 is_status SMALLINT NOT NULL DEFAULT 1 CHECK(is_status IN(0,1)),CHECK(file_data IS NULL OR octet_length(file_data)<=5242880)
);
CREATE TABLE IF NOT EXISTS notice_departments (
 notice_id BIGINT NOT NULL REFERENCES notice(notice_id) ON DELETE CASCADE,department_id BIGINT NOT NULL REFERENCES emp_department(emp_department_id),PRIMARY KEY(notice_id,department_id)
);
CREATE INDEX IF NOT EXISTS msg_of_day_published_idx ON msg_of_day(is_status,msg_user_type);
CREATE INDEX IF NOT EXISTS notice_published_idx ON notice(is_status,notice_date);
