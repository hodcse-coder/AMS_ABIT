CREATE TABLE IF NOT EXISTS country (
 country_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 country_name VARCHAR(35) NOT NULL UNIQUE,
 created_at TIMESTAMP, created_by INTEGER NOT NULL,
 updated_at TIMESTAMP, updated_by INTEGER,
 is_status SMALLINT NOT NULL DEFAULT 0 CHECK (is_status IN (0,1))
);
CREATE TABLE IF NOT EXISTS state (
 state_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 state_name VARCHAR(35) NOT NULL,
 state_country_id INTEGER NOT NULL REFERENCES country(country_id),
 created_at TIMESTAMP, created_by INTEGER NOT NULL,
 updated_at TIMESTAMP, updated_by INTEGER,
 is_status SMALLINT NOT NULL DEFAULT 0 CHECK (is_status IN (0,1)),
 UNIQUE(state_name,state_country_id), UNIQUE(state_id,state_country_id)
);
CREATE TABLE IF NOT EXISTS city (
 city_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 city_name VARCHAR(35) NOT NULL,
 city_state_id INTEGER NOT NULL,
 city_country_id INTEGER NOT NULL REFERENCES country(country_id),
 created_at TIMESTAMP, created_by INTEGER NOT NULL,
 updated_at TIMESTAMP, updated_by INTEGER,
 is_status SMALLINT NOT NULL DEFAULT 0 CHECK (is_status IN (0,1)),
 UNIQUE(city_name,city_state_id),
 FOREIGN KEY(city_state_id,city_country_id) REFERENCES state(state_id,state_country_id)
);
CREATE TABLE IF NOT EXISTS document_category (
 doc_category_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 doc_category_name VARCHAR(50) NOT NULL,
 doc_category_user_type CHAR(2) NOT NULL,
 created_at TIMESTAMP, created_by INTEGER NOT NULL,
 updated_at TIMESTAMP, updated_by INTEGER,
 is_status SMALLINT NOT NULL DEFAULT 0 CHECK (is_status IN (0,1)),
 UNIQUE(doc_category_name,doc_category_user_type)
);
CREATE TABLE IF NOT EXISTS languages (
 language_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 language_name VARCHAR(45) NOT NULL UNIQUE,
 created_at TIMESTAMP, created_by INTEGER NOT NULL,
 updated_at TIMESTAMP, updated_by INTEGER
);
CREATE TABLE IF NOT EXISTS national_holidays (
 national_holiday_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 national_holiday_name VARCHAR(50) NOT NULL,
 national_holiday_date DATE,
 national_holiday_remarks VARCHAR(100),
 created_at TIMESTAMP, created_by INTEGER NOT NULL,
 updated_at TIMESTAMP, updated_by INTEGER,
 is_status SMALLINT NOT NULL DEFAULT 0 CHECK (is_status IN (0,1)),
 UNIQUE(national_holiday_name,national_holiday_date)
);
CREATE TABLE IF NOT EXISTS nationality (
 nationality_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 nationality_name VARCHAR(35) NOT NULL UNIQUE,
 created_at TIMESTAMP, created_by INTEGER NOT NULL,
 updated_at TIMESTAMP, updated_by INTEGER,
 is_status SMALLINT NOT NULL DEFAULT 0 CHECK (is_status IN (0,1))
);
CREATE TABLE IF NOT EXISTS organization (
 org_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 org_name VARCHAR(255) NOT NULL UNIQUE,
 org_alias VARCHAR(25) NOT NULL UNIQUE,
 org_address_line1 VARCHAR(255) NOT NULL,
 org_address_line2 VARCHAR(255),
 org_phone VARCHAR(25), org_email VARCHAR(65), org_website VARCHAR(120),
 org_logo BYTEA NOT NULL, org_logo_type VARCHAR(35) NOT NULL,
 org_stu_prefix VARCHAR(10) NOT NULL, org_emp_prefix VARCHAR(10) NOT NULL,
 created_at TIMESTAMP, created_by INTEGER,
 updated_at TIMESTAMP, updated_by INTEGER
);

CREATE TABLE IF NOT EXISTS last_passout_institution (
 sl_no BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 institution_name TEXT,
 place TEXT,
 district VARCHAR(100),
 institute_type TEXT,
 affiliation TEXT,
 college_address TEXT
);
CREATE INDEX IF NOT EXISTS last_passout_institution_district_idx ON last_passout_institution(district);

CREATE TABLE IF NOT EXISTS hobbies (
 hobby_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 hobby_name VARCHAR(45) NOT NULL UNIQUE,
 created_at TIMESTAMP, created_by INTEGER NOT NULL,
 updated_at TIMESTAMP, updated_by INTEGER
);
