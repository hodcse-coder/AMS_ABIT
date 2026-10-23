-- Notes retain the exact teaching assignment and an authenticated downloadable file.
ALTER TABLE lecture_notes ADD COLUMN IF NOT EXISTS assignment_id BIGINT;
ALTER TABLE lecture_notes ADD COLUMN IF NOT EXISTS file_name VARCHAR(255);
ALTER TABLE lecture_notes ADD COLUMN IF NOT EXISTS file_type VARCHAR(150);
ALTER TABLE lecture_notes ADD COLUMN IF NOT EXISTS file_size BIGINT;
ALTER TABLE lecture_notes ADD COLUMN IF NOT EXISTS file_data BYTEA;
DO $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='lecture_notes_assignment_fk' AND conrelid='lecture_notes'::regclass) THEN
  ALTER TABLE lecture_notes ADD CONSTRAINT lecture_notes_assignment_fk FOREIGN KEY(assignment_id) REFERENCES section_house_subject_teacher(shst_id) NOT VALID;
 END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='lecture_notes_subject_fk' AND conrelid='lecture_notes'::regclass) THEN
  ALTER TABLE lecture_notes ADD CONSTRAINT lecture_notes_subject_fk FOREIGN KEY(subject) REFERENCES subjects(subject_id) NOT VALID;
 END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='lecture_notes_teacher_fk' AND conrelid='lecture_notes'::regclass) THEN
  ALTER TABLE lecture_notes ADD CONSTRAINT lecture_notes_teacher_fk FOREIGN KEY(teacher) REFERENCES users(user_id) NOT VALID;
 END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='lecture_notes_file_check' AND conrelid='lecture_notes'::regclass) THEN
  ALTER TABLE lecture_notes ADD CONSTRAINT lecture_notes_file_check CHECK(file_data IS NULL OR (file_name IS NOT NULL AND file_type IS NOT NULL AND file_size=octet_length(file_data) AND file_size BETWEEN 1 AND 10485760)) NOT VALID;
 END IF;
END $$;
CREATE INDEX IF NOT EXISTS lecture_notes_assignment_idx ON lecture_notes(assignment_id);
CREATE INDEX IF NOT EXISTS lecture_notes_legacy_mapping_idx ON lecture_notes(subject,teacher,sem) WHERE assignment_id IS NULL;
