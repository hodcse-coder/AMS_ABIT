-- New semester definitions use Section only; existing records are retained.
ALTER TABLE semester_defined ALTER COLUMN sem_section_house_type SET DEFAULT 'S';
ALTER TABLE semester_defined DROP CONSTRAINT IF EXISTS semester_defined_sem_section_house_type_check;
DO $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='semester_defined_section_only' AND conrelid='semester_defined'::regclass) THEN
  ALTER TABLE semester_defined ADD CONSTRAINT semester_defined_section_only CHECK(sem_section_house_type='S') NOT VALID;
 END IF;
END $$;
