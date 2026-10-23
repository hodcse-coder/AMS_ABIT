ALTER TABLE videolecture ADD COLUMN IF NOT EXISTS file_name VARCHAR(255);
ALTER TABLE videolecture ADD COLUMN IF NOT EXISTS file_type VARCHAR(100);
ALTER TABLE videolecture ADD COLUMN IF NOT EXISTS file_size BIGINT;
ALTER TABLE videolecture ADD COLUMN IF NOT EXISTS file_data BYTEA;
DO $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='videolecture_subject_fk' AND conrelid='videolecture'::regclass) THEN
  ALTER TABLE videolecture ADD CONSTRAINT videolecture_subject_fk FOREIGN KEY(related_subject) REFERENCES subjects(subject_id) NOT VALID;
 END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='videolecture_file_check' AND conrelid='videolecture'::regclass) THEN
  ALTER TABLE videolecture ADD CONSTRAINT videolecture_file_check CHECK(file_data IS NULL OR (file_name IS NOT NULL AND file_type IS NOT NULL AND file_size=octet_length(file_data) AND file_size BETWEEN 1 AND 26214400)) NOT VALID;
 END IF;
END $$;
CREATE INDEX IF NOT EXISTS videolecture_subject_idx ON videolecture(related_subject);
CREATE INDEX IF NOT EXISTS videolecture_uploader_idx ON videolecture(created_by);
