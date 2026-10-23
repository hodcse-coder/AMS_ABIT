CREATE TABLE IF NOT EXISTS academic_years (
 academic_year_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 academic_year VARCHAR(7) NOT NULL UNIQUE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),created_by BIGINT NOT NULL REFERENCES users(user_id),
 updated_at TIMESTAMPTZ,updated_by BIGINT REFERENCES users(user_id),
 CHECK(CASE WHEN academic_year ~ '^[0-9]{4}-[0-9]{2}$' THEN right(academic_year,2)::integer=(left(academic_year,4)::integer+1)%100 ELSE FALSE END)
);
CREATE TABLE IF NOT EXISTS academic_year_semesters (
 academic_year_id BIGINT NOT NULL REFERENCES academic_years(academic_year_id) ON DELETE CASCADE,
 semester SMALLINT NOT NULL CHECK(semester IN(1,2)),
 PRIMARY KEY(academic_year_id,semester)
);
ALTER TABLE subjects ADD COLUMN IF NOT EXISTS academic_year_id BIGINT REFERENCES academic_years(academic_year_id);
ALTER TABLE subjects ADD COLUMN IF NOT EXISTS semester SMALLINT;
DO $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='subjects_academic_semester_fk' AND conrelid='subjects'::regclass) THEN
  ALTER TABLE subjects ADD CONSTRAINT subjects_academic_semester_fk FOREIGN KEY(academic_year_id,semester) REFERENCES academic_year_semesters(academic_year_id,semester);
 END IF;
END $$;
