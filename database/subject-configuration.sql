CREATE TABLE IF NOT EXISTS semester_defined (
 id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 sem_course_master_id BIGINT NOT NULL REFERENCES courses(course_id),
 sem_batch_master_id BIGINT NOT NULL,
 semester SMALLINT NOT NULL CHECK(semester BETWEEN 1 AND 12),
 sem_section_house_type CHAR(1) NOT NULL CHECK(sem_section_house_type IN('S','H')),
 is_active SMALLINT NOT NULL DEFAULT 1 CHECK(is_active IN(0,1)),
 consider_for_accounts SMALLINT NOT NULL DEFAULT 0 CHECK(consider_for_accounts IN(0,1)),
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),created_by BIGINT NOT NULL REFERENCES users(user_id),
 updated_at TIMESTAMPTZ,updated_by BIGINT REFERENCES users(user_id),
 FOREIGN KEY(sem_batch_master_id,sem_course_master_id) REFERENCES batches(batch_id,batch_course_id),
 UNIQUE(sem_course_master_id,sem_batch_master_id,semester,sem_section_house_type)
);
ALTER TABLE subjectteacher ADD COLUMN IF NOT EXISTS library_submitted BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE section_house_subject_teacher ADD COLUMN IF NOT EXISTS semester_definition_id BIGINT REFERENCES semester_defined(id);
ALTER TABLE section_house_subject_teacher ADD COLUMN IF NOT EXISTS subjectteacher_id BIGINT REFERENCES subjectteacher(subjectteacher_id);
ALTER TABLE section_house_subject_teacher ADD COLUMN IF NOT EXISTS branch_id BIGINT REFERENCES academic_branches(branch_id);
ALTER TABLE section_house_subject_teacher ADD COLUMN IF NOT EXISTS allotment_kind CHAR(1) NOT NULL DEFAULT 'P' CHECK(allotment_kind IN('P','T'));
CREATE INDEX IF NOT EXISTS shst_semester_definition_idx ON section_house_subject_teacher(semester_definition_id);
CREATE INDEX IF NOT EXISTS shst_subjectteacher_idx ON section_house_subject_teacher(subjectteacher_id);
CREATE INDEX IF NOT EXISTS shst_allotment_kind_idx ON section_house_subject_teacher(allotment_kind);
