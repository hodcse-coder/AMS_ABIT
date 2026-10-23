ALTER TABLE subjectteacher ADD COLUMN IF NOT EXISTS academic_year_id BIGINT REFERENCES academic_years(academic_year_id);
ALTER TABLE subjectteacher ADD COLUMN IF NOT EXISTS branch_id BIGINT REFERENCES academic_branches(branch_id);
ALTER TABLE subjectteacher ADD COLUMN IF NOT EXISTS semester SMALLINT;
-- Preserve assignments while filling their context from the linked subject.
UPDATE subjectteacher t SET academic_year_id=s.academic_year_id,branch_id=s.branch_id,semester=s.semester
FROM subjects s WHERE s.subject_id=t.subjectteacher_subject_id
 AND t.academic_year_id IS NULL AND t.branch_id IS NULL AND t.semester IS NULL;
DO $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='subjectteacher_academic_semester_fk' AND conrelid='subjectteacher'::regclass) THEN
  ALTER TABLE subjectteacher ADD CONSTRAINT subjectteacher_academic_semester_fk FOREIGN KEY(academic_year_id,semester) REFERENCES academic_year_semesters(academic_year_id,semester) NOT VALID;
 END IF;
END $$;
CREATE INDEX IF NOT EXISTS subjectteacher_context_idx ON subjectteacher(academic_year_id,branch_id,semester);
