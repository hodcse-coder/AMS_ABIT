-- Preserve existing records and foreign keys while adopting source table names.
DO $$ BEGIN
 IF to_regclass('public.batches') IS NULL AND to_regclass('public.course_batches') IS NOT NULL THEN
  ALTER TABLE course_batches RENAME TO batches;
  ALTER TABLE batches RENAME COLUMN course_id TO batch_course_id;
 END IF;
 IF to_regclass('public.section') IS NULL AND to_regclass('public.course_sections') IS NOT NULL THEN
  ALTER TABLE course_sections RENAME TO section;
  ALTER TABLE section RENAME COLUMN section_id TO s_id;
  ALTER TABLE section RENAME COLUMN batch_id TO section_batch_id;
 END IF;
END $$;
CREATE TABLE IF NOT EXISTS courses (
 course_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 course_name VARCHAR(100) NOT NULL, course_code VARCHAR(50) NOT NULL,
 course_alias VARCHAR(35) NOT NULL, course_duration INTEGER NOT NULL,
 created_at TIMESTAMPTZ DEFAULT NOW(), created_by BIGINT NOT NULL REFERENCES users(user_id),
 updated_at TIMESTAMPTZ, updated_by BIGINT REFERENCES users(user_id),
 is_status SMALLINT NOT NULL DEFAULT 0, is_le SMALLINT NOT NULL DEFAULT 0,
 is_active BOOLEAN NOT NULL DEFAULT TRUE,
 UNIQUE(course_name,course_code)
);
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='courses' AND column_name='course_code' AND (data_type<>'character varying' OR character_maximum_length IS DISTINCT FROM 50)) THEN
  ALTER TABLE courses ALTER COLUMN course_code TYPE VARCHAR(50);
 END IF;
END $$;
ALTER TABLE courses ADD COLUMN IF NOT EXISTS course_alias VARCHAR(35);
ALTER TABLE courses ADD COLUMN IF NOT EXISTS course_duration INTEGER;
ALTER TABLE courses ADD COLUMN IF NOT EXISTS updated_by BIGINT REFERENCES users(user_id);
ALTER TABLE courses ADD COLUMN IF NOT EXISTS is_status SMALLINT NOT NULL DEFAULT 0;
ALTER TABLE courses ADD COLUMN IF NOT EXISTS is_le SMALLINT NOT NULL DEFAULT 0;
UPDATE courses SET course_alias=left(course_code,35) WHERE course_alias IS NULL;
UPDATE courses SET course_duration=1 WHERE course_duration IS NULL;
ALTER TABLE courses ALTER COLUMN course_alias SET NOT NULL;
ALTER TABLE courses ALTER COLUMN course_duration SET NOT NULL;
ALTER TABLE courses DROP CONSTRAINT IF EXISTS courses_course_name_key;
ALTER TABLE courses DROP CONSTRAINT IF EXISTS courses_course_code_key;
CREATE UNIQUE INDEX IF NOT EXISTS courses_name_code_unique ON courses(course_name,course_code);
CREATE TABLE IF NOT EXISTS batches (
 batch_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 batch_name VARCHAR(120) NOT NULL, batch_course_id BIGINT NOT NULL REFERENCES courses(course_id),
 batch_alias VARCHAR(35) NOT NULL UNIQUE,
 consider_for_placement VARCHAR(1) NOT NULL DEFAULT 'N', start_date DATE, end_date DATE,
 created_at TIMESTAMPTZ DEFAULT NOW(),created_by BIGINT NOT NULL REFERENCES users(user_id),
 updated_at TIMESTAMPTZ,updated_by BIGINT REFERENCES users(user_id),is_status SMALLINT NOT NULL DEFAULT 0,
 is_eligible_alumnisurvey SMALLINT NOT NULL DEFAULT 1,is_eligible_exitsurvey SMALLINT NOT NULL DEFAULT 1,
 exam_relatin VARCHAR(10) NOT NULL DEFAULT 'BPUT',
 UNIQUE(batch_name,batch_course_id),UNIQUE(batch_id,batch_course_id)
);
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='batches' AND column_name='batch_name' AND (data_type<>'character varying' OR character_maximum_length IS DISTINCT FROM 120)) THEN
  ALTER TABLE batches ALTER COLUMN batch_name TYPE VARCHAR(120);
 END IF;
END $$;
ALTER TABLE batches ADD COLUMN IF NOT EXISTS batch_alias VARCHAR(35);
ALTER TABLE batches ADD COLUMN IF NOT EXISTS consider_for_placement VARCHAR(1) NOT NULL DEFAULT 'N';
ALTER TABLE batches ADD COLUMN IF NOT EXISTS start_date DATE;
ALTER TABLE batches ADD COLUMN IF NOT EXISTS end_date DATE;
ALTER TABLE batches ADD COLUMN IF NOT EXISTS created_by BIGINT REFERENCES users(user_id);
ALTER TABLE batches ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ;
ALTER TABLE batches ADD COLUMN IF NOT EXISTS updated_by BIGINT REFERENCES users(user_id);
ALTER TABLE batches ADD COLUMN IF NOT EXISTS is_status SMALLINT NOT NULL DEFAULT 0;
ALTER TABLE batches ADD COLUMN IF NOT EXISTS is_eligible_alumnisurvey SMALLINT NOT NULL DEFAULT 1;
ALTER TABLE batches ADD COLUMN IF NOT EXISTS is_eligible_exitsurvey SMALLINT NOT NULL DEFAULT 1;
ALTER TABLE batches ADD COLUMN IF NOT EXISTS exam_relatin VARCHAR(10) NOT NULL DEFAULT 'BPUT';
UPDATE batches SET batch_alias='BATCH-'||batch_id WHERE batch_alias IS NULL;
UPDATE batches b SET created_by=c.created_by FROM courses c WHERE b.batch_course_id=c.course_id AND b.created_by IS NULL;
ALTER TABLE batches ALTER COLUMN batch_alias SET NOT NULL;
ALTER TABLE batches ALTER COLUMN created_by SET NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS batches_alias_unique ON batches(batch_alias);
CREATE TABLE IF NOT EXISTS section (
 s_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 section_id INTEGER NOT NULL DEFAULT 0, section_name VARCHAR(50),
 section_batch_id BIGINT REFERENCES batches(batch_id),intake INTEGER,
 created_at TIMESTAMPTZ DEFAULT NOW(),created_by BIGINT REFERENCES users(user_id),
 updated_at TIMESTAMPTZ,updated_by BIGINT REFERENCES users(user_id),is_status SMALLINT NOT NULL DEFAULT 0,
 UNIQUE(section_name,section_batch_id)
);
ALTER TABLE section ADD COLUMN IF NOT EXISTS section_id INTEGER NOT NULL DEFAULT 0;
ALTER TABLE section ADD COLUMN IF NOT EXISTS intake INTEGER;
ALTER TABLE section ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE section ADD COLUMN IF NOT EXISTS created_by BIGINT REFERENCES users(user_id);
ALTER TABLE section ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ;
ALTER TABLE section ADD COLUMN IF NOT EXISTS updated_by BIGINT REFERENCES users(user_id);
ALTER TABLE section ADD COLUMN IF NOT EXISTS is_status SMALLINT NOT NULL DEFAULT 0;
CREATE TABLE IF NOT EXISTS course_students (
 user_id BIGINT PRIMARY KEY REFERENCES students(user_id), course_id BIGINT NOT NULL REFERENCES courses(course_id),batch_id BIGINT,
 FOREIGN KEY(batch_id,course_id) REFERENCES batches(batch_id,batch_course_id)
);
CREATE TABLE IF NOT EXISTS section_master (
 section_master_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 section_master_name VARCHAR(50) UNIQUE,created_at TIMESTAMPTZ,created_by BIGINT REFERENCES users(user_id),
 updated_at TIMESTAMPTZ,updated_by BIGINT REFERENCES users(user_id),is_status SMALLINT NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS section_defined (
 sid BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,section_name TEXT,
 section_master BIGINT NOT NULL DEFAULT 0,rel_course BIGINT REFERENCES courses(course_id),rel_coursefecth INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS subjects (
 subject_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 subject_name VARCHAR(100),subject_code VARCHAR(50),subject_alias VARCHAR(35),subject_type VARCHAR(1) NOT NULL DEFAULT 'T',
 is_placement_related SMALLINT NOT NULL DEFAULT 1,for_branches TEXT,
 created_at TIMESTAMPTZ,created_by BIGINT REFERENCES users(user_id),updated_at TIMESTAMPTZ,updated_by BIGINT REFERENCES users(user_id),
 tp_related SMALLINT NOT NULL DEFAULT 1,is_status SMALLINT NOT NULL DEFAULT 0,credit INTEGER NOT NULL DEFAULT 0
);
DROP TRIGGER IF EXISTS enforce_uppercase ON courses;
CREATE TRIGGER enforce_uppercase BEFORE INSERT OR UPDATE ON courses FOR EACH ROW EXECUTE FUNCTION uppercase_record_text('course_name','course_code','course_alias');
DROP TRIGGER IF EXISTS enforce_uppercase ON batches;
CREATE TRIGGER enforce_uppercase BEFORE INSERT OR UPDATE ON batches FOR EACH ROW EXECUTE FUNCTION uppercase_record_text('batch_name','batch_alias','consider_for_placement','exam_relatin');
DROP TRIGGER IF EXISTS enforce_uppercase ON section;
CREATE TRIGGER enforce_uppercase BEFORE INSERT OR UPDATE ON section FOR EACH ROW EXECUTE FUNCTION uppercase_record_text('section_name');
DROP TRIGGER IF EXISTS enforce_uppercase ON section_master;
CREATE TRIGGER enforce_uppercase BEFORE INSERT OR UPDATE ON section_master FOR EACH ROW EXECUTE FUNCTION uppercase_record_text('section_master_name');
DROP TRIGGER IF EXISTS enforce_uppercase ON section_defined;
CREATE TRIGGER enforce_uppercase BEFORE INSERT OR UPDATE ON section_defined FOR EACH ROW EXECUTE FUNCTION uppercase_record_text('section_name');
DROP TRIGGER IF EXISTS enforce_uppercase ON subjects;
CREATE TRIGGER enforce_uppercase BEFORE INSERT OR UPDATE ON subjects FOR EACH ROW EXECUTE FUNCTION uppercase_record_text('subject_name','subject_code','subject_alias','subject_type','for_branches');