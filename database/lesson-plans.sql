-- A lessonplans row is one ordered topic for a subject. Preserve legacy rows.
ALTER TABLE lessonplans ADD COLUMN IF NOT EXISTS book_id BIGINT;
ALTER TABLE lessonplans ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
CREATE UNIQUE INDEX IF NOT EXISTS faculty_books_id_subject_unique ON faculty_books(book_id,subject_id);
CREATE UNIQUE INDEX IF NOT EXISTS faculty_books_id_subject_unique ON faculty_books(book_id,subject_id);
DO $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='lessonplans_subject_fk' AND conrelid='lessonplans'::regclass) THEN
  ALTER TABLE lessonplans ADD CONSTRAINT lessonplans_subject_fk FOREIGN KEY(subjectteacher_subject_id) REFERENCES subjects(subject_id) NOT VALID;
 END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='lessonplans_book_fk' AND conrelid='lessonplans'::regclass) THEN
  ALTER TABLE lessonplans ADD CONSTRAINT lessonplans_book_fk FOREIGN KEY(book_id) REFERENCES faculty_books(book_id) NOT VALID;
 END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='lessonplans_book_subject_fk' AND conrelid='lessonplans'::regclass) THEN
  ALTER TABLE lessonplans ADD CONSTRAINT lessonplans_book_subject_fk FOREIGN KEY(book_id,subjectteacher_subject_id) REFERENCES faculty_books(book_id,subject_id) NOT VALID;
 END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='lessonplans_book_subject_fk' AND conrelid='lessonplans'::regclass) THEN
  ALTER TABLE lessonplans ADD CONSTRAINT lessonplans_book_subject_fk FOREIGN KEY(book_id,subjectteacher_subject_id) REFERENCES faculty_books(book_id,subject_id) NOT VALID;
 END IF;
END $$;
CREATE INDEX IF NOT EXISTS lessonplans_subject_order_idx ON lessonplans(subjectteacher_subject_id,module) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS lessonplans_book_idx ON lessonplans(book_id);
