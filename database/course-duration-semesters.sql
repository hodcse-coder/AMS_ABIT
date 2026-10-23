-- The API validates the semester against the selected course's duration * 2.
ALTER TABLE semester_defined DROP CONSTRAINT IF EXISTS semester_defined_semester_check;
DO $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='semester_defined_semester_positive' AND conrelid='semester_defined'::regclass) THEN
  ALTER TABLE semester_defined ADD CONSTRAINT semester_defined_semester_positive CHECK(semester>=1) NOT VALID;
 END IF;
END $$;
