
-- Preferred Books uses subject mapping for Academic Year, Branch and Semester.
ALTER TABLE faculty_books ADD COLUMN IF NOT EXISTS author TEXT;
ALTER TABLE faculty_books ALTER COLUMN book_name SET DEFAULT '';
DO $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='faculty_books_subject_fk' AND conrelid='faculty_books'::regclass) THEN
 ALTER TABLE faculty_books ADD CONSTRAINT faculty_books_subject_fk FOREIGN KEY(subject_id) REFERENCES subjects(subject_id) NOT VALID;
 END IF;
END $$;
CREATE INDEX IF NOT EXISTS faculty_books_subject_idx ON faculty_books(subject_id);
DROP TRIGGER IF EXISTS faculty_books_uppercase ON faculty_books;
CREATE TRIGGER faculty_books_uppercase BEFORE INSERT OR UPDATE ON faculty_books FOR EACH ROW EXECUTE FUNCTION uppercase_record_text('author','book_name');
