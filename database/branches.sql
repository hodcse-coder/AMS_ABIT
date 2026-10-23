-- Branch fields from ABITDB.sql; courses is the ERP's existing course master.
CREATE TABLE IF NOT EXISTS academic_branches (
 branch_id BIGSERIAL PRIMARY KEY,
 course_id BIGINT NOT NULL REFERENCES courses(course_id),
 branch_code VARCHAR(30) NOT NULL,
 branch_name VARCHAR(200) NOT NULL,
 branch_alias VARCHAR(50) NOT NULL,
 is_active BOOLEAN NOT NULL DEFAULT TRUE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
 updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT uq_course_branch_code UNIQUE(course_id,branch_code)
);
CREATE INDEX IF NOT EXISTS idx_academic_branches_course ON academic_branches(course_id);
DROP TRIGGER IF EXISTS academic_branches_uppercase ON academic_branches;
CREATE TRIGGER academic_branches_uppercase BEFORE INSERT OR UPDATE ON academic_branches FOR EACH ROW EXECUTE FUNCTION uppercase_record_text('branch_code','branch_name','branch_alias');

-- Link subjects to Branch Master; existing subjects remain available without a branch.
ALTER TABLE subjects ADD COLUMN IF NOT EXISTS branch_id BIGINT REFERENCES academic_branches(branch_id);
DROP INDEX IF EXISTS subjects_year_semester_code_unique;
CREATE UNIQUE INDEX IF NOT EXISTS subjects_year_branch_semester_code_unique ON subjects(academic_year_id,branch_id,semester,upper(subject_code)) WHERE branch_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS subjects_unmapped_branch_code_unique ON subjects(academic_year_id,semester,upper(subject_code)) WHERE branch_id IS NULL AND academic_year_id IS NOT NULL;
