-- Subject mappings supply academic year, branch and semester for Course Outcomes.
ALTER TABLE courseoutcome ALTER COLUMN cotype SET DEFAULT 'CO';
DO $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='courseoutcome_subject_fk' AND conrelid='courseoutcome'::regclass) THEN
  ALTER TABLE courseoutcome ADD CONSTRAINT courseoutcome_subject_fk FOREIGN KEY(co_subject_id) REFERENCES subjects(subject_id) NOT VALID;
 END IF;
END $$;
CREATE INDEX IF NOT EXISTS courseoutcome_subject_idx ON courseoutcome(co_subject_id);
CREATE INDEX IF NOT EXISTS courseoutcome_creator_idx ON courseoutcome(created_by);
