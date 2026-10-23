CREATE TABLE IF NOT EXISTS attendance_roster (
 assignment_id BIGINT NOT NULL REFERENCES section_house_subject_teacher(shst_id),
 student_id BIGINT NOT NULL REFERENCES students(user_id),
 PRIMARY KEY(assignment_id,student_id)
);
CREATE TABLE IF NOT EXISTS attendance_sessions (
 session_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 assignment_id BIGINT NOT NULL REFERENCES section_house_subject_teacher(shst_id),
 topic_id BIGINT NOT NULL REFERENCES lessonplans(lessonplan_id),
 attendance_date DATE NOT NULL,
 start_time TIME NOT NULL,end_time TIME NOT NULL,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),created_by BIGINT NOT NULL REFERENCES users(user_id),
 CHECK(end_time>start_time),UNIQUE(assignment_id,attendance_date,start_time)
);
ALTER TABLE student_attendance ADD COLUMN IF NOT EXISTS session_id BIGINT REFERENCES attendance_sessions(session_id);
DO $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='student_attendance_student_fk' AND conrelid='student_attendance'::regclass) THEN
  ALTER TABLE student_attendance ADD CONSTRAINT student_attendance_student_fk FOREIGN KEY(student_attendance_student_id) REFERENCES users(user_id) NOT VALID;
 END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='student_attendance_mark_check' AND conrelid='student_attendance'::regclass) THEN
  ALTER TABLE student_attendance ADD CONSTRAINT student_attendance_mark_check CHECK(session_id IS NULL OR student_attendance_present_absent IN(0,1)) NOT VALID;
 END IF;
END $$;
CREATE UNIQUE INDEX IF NOT EXISTS student_attendance_session_student_unique ON student_attendance(session_id,student_attendance_student_id) WHERE session_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS attendance_sessions_date_idx ON attendance_sessions(attendance_date,assignment_id);
