
CREATE TABLE IF NOT EXISTS user_roles (
    role_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    role_name VARCHAR(30) UNIQUE NOT NULL
);

INSERT INTO user_roles (role_name)
VALUES ('Admin'), ('Faculty'),('Student') ON CONFLICT (role_name) DO NOTHING;

CREATE TABLE IF NOT EXISTS users (
    user_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    role_id INTEGER NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE,
    mobile VARCHAR(15),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_user_role
        FOREIGN KEY (role_id)
        REFERENCES user_roles(role_id)
);

CREATE TABLE IF NOT EXISTS admins (
    user_id BIGINT PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    designation VARCHAR(150) NOT NULL DEFAULT 'ERP Administrator'
);
CREATE TABLE IF NOT EXISTS faculty (
    user_id BIGINT PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    employee_code VARCHAR(100) UNIQUE,
    department VARCHAR(150)
);
CREATE TABLE IF NOT EXISTS students (
    user_id BIGINT PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    admission_number VARCHAR(100) UNIQUE,
    department VARCHAR(150),
    semester SMALLINT CHECK (semester BETWEEN 1 AND 12)
);
CREATE TABLE IF NOT EXISTS user_sessions (
    token_hash TEXT PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS user_sessions_expiry_idx ON user_sessions(expires_at);

CREATE TABLE `country` (
  `country_id` int(11) NOT NULL AUTO_INCREMENT,
  `country_name` varchar(35) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`country_id`),
  UNIQUE KEY `country_name` (`country_name`),
  KEY `updated_by` (`updated_by`),
  KEY `created_by` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `state` (
  `state_id` int(11) NOT NULL AUTO_INCREMENT,
  `state_name` varchar(35) NOT NULL,
  `state_country_id` int(11) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`state_id`),
  UNIQUE KEY `state_name` (`state_name`,`state_country_id`),
  KEY `created_by` (`created_by`),
  KEY `updated_by` (`updated_by`),
  KEY `state_country_id` (`state_country_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `city` (
  `city_id` int(11) NOT NULL AUTO_INCREMENT,
  `city_name` varchar(35) NOT NULL,
  `city_state_id` int(11) NOT NULL,
  `city_country_id` int(11) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`city_id`),
  UNIQUE KEY `city_name` (`city_name`,`city_state_id`),
  KEY `created_by` (`created_by`),
  KEY `updated_by` (`updated_by`),
  KEY `city_state_id` (`city_state_id`),
  KEY `city_country_id` (`city_country_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `last_passout_institution` (
  `sl_no` bigint(20) NOT NULL AUTO_INCREMENT,
  `institution_name` text DEFAULT NULL,
  `place` text DEFAULT NULL,
  `district` varchar(100) DEFAULT NULL,
  `institute_type` text DEFAULT NULL,
  `affiliation` text DEFAULT NULL,
  `college_address` text DEFAULT NULL,
  PRIMARY KEY (`sl_no`),
  UNIQUE KEY `sl_no` (`sl_no`),
  KEY `district` (`district`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `document_category` (
  `doc_category_id` int(11) NOT NULL AUTO_INCREMENT,
  `doc_category_name` varchar(50) NOT NULL,
  `doc_category_user_type` char(2) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`doc_category_id`),
  UNIQUE KEY `doc_category_name` (`doc_category_name`,`doc_category_user_type`),
  KEY `created_by` (`created_by`),
  KEY `updated_by` (`updated_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `languages` (
  `language_id` int(11) NOT NULL AUTO_INCREMENT,
  `language_name` varchar(45) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  PRIMARY KEY (`language_id`),
  UNIQUE KEY `language_name` (`language_name`),
  KEY `created_by` (`created_by`),
  KEY `updated_by` (`updated_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `hobbies` (
  `hobby_id` int(11) NOT NULL AUTO_INCREMENT,
  `hobby_name` varchar(45) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  PRIMARY KEY (`hobby_id`),
  UNIQUE KEY `hobby_name` (`hobby_name`),
  KEY `created_by` (`created_by`),
  KEY `updated_by` (`updated_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `national_holidays` (
  `national_holiday_id` int(11) NOT NULL AUTO_INCREMENT,
  `national_holiday_name` varchar(50) NOT NULL,
  `national_holiday_date` date DEFAULT NULL,
  `national_holiday_remarks` varchar(100) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`national_holiday_id`),
  UNIQUE KEY `national_holiday_name` (`national_holiday_name`,`national_holiday_date`),
  KEY `created_by` (`created_by`),
  KEY `updated_by` (`updated_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `nationality` (
  `nationality_id` int(11) NOT NULL AUTO_INCREMENT,
  `nationality_name` varchar(35) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`nationality_id`),
  UNIQUE KEY `nationality_name` (`nationality_name`),
  KEY `created_by` (`created_by`),
  KEY `updated_by` (`updated_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `organization` (
  `org_id` int(11) NOT NULL AUTO_INCREMENT,
  `org_name` varchar(255) NOT NULL,
  `org_alias` varchar(25) NOT NULL,
  `org_address_line1` varchar(255) NOT NULL,
  `org_address_line2` varchar(255) DEFAULT NULL,
  `org_phone` varchar(25) DEFAULT NULL,
  `org_email` varchar(65) DEFAULT NULL,
  `org_website` varchar(120) DEFAULT NULL,
  `org_logo` longblob NOT NULL,
  `org_logo_type` varchar(35) NOT NULL,
  `org_stu_prefix` varchar(10) NOT NULL,
  `org_emp_prefix` varchar(10) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  PRIMARY KEY (`org_id`),
  UNIQUE KEY `org_name` (`org_name`),
  UNIQUE KEY `org_alias` (`org_alias`),
  UNIQUE KEY `org_id` (`org_id`),
  KEY `updated_by` (`updated_by`),
  KEY `created_by` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
CREATE TABLE `courses` (
  `course_id` int(11) NOT NULL AUTO_INCREMENT,
  `course_name` varchar(100) NOT NULL,
  `course_code` varchar(50) NOT NULL,
  `course_alias` varchar(35) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  `is_le` tinyint(1) NOT NULL DEFAULT 0,
  `course_duration` int(11) NOT NULL,
  PRIMARY KEY (`course_id`),
  UNIQUE KEY `course_name` (`course_name`,`course_code`),
  KEY `updated_by` (`updated_by`),
  KEY `created_by` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `batches` (
  `batch_id` int(11) NOT NULL AUTO_INCREMENT,
  `batch_name` varchar(120) NOT NULL,
  `consider_for_placement` varchar(1) NOT NULL DEFAULT 'N',
  `batch_course_id` int(11) NOT NULL,
  `batch_alias` varchar(35) NOT NULL,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  `is_eligible_alumnisurvey` tinyint(1) NOT NULL DEFAULT 1,
  `is_eligible_exitsurvey` tinyint(1) NOT NULL DEFAULT 1,
  `exam_relatin` varchar(10) NOT NULL DEFAULT 'BPUT',
  PRIMARY KEY (`batch_id`),
  UNIQUE KEY `batch_name` (`batch_name`,`batch_course_id`),
  UNIQUE KEY `batch_alias` (`batch_alias`),
  KEY `batch_course_id` (`batch_course_id`),
  KEY `created_by` (`created_by`),
  KEY `updated_by` (`updated_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `section` (
  `section_id` int(11) NOT NULL,
  `s_id` int(11) NOT NULL AUTO_INCREMENT,
  `section_name` varchar(50) DEFAULT NULL,
  `section_batch_id` int(11) DEFAULT NULL,
  `intake` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`s_id`),
  UNIQUE KEY `section_name` (`section_name`,`section_batch_id`),
  KEY `section_batch_id` (`section_batch_id`),
  KEY `created_by` (`created_by`),
  KEY `updated_by` (`updated_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `section_defined` (
  `sid` bigint(20) NOT NULL AUTO_INCREMENT,
  `section_name` text DEFAULT NULL,
  `section_master` bigint(20) NOT NULL DEFAULT 0,
  `rel_course` bigint(20) DEFAULT NULL,
  `rel_coursefecth` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`sid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

CREATE TABLE `section_master` (
  `section_master_id` int(11) NOT NULL AUTO_INCREMENT,
  `section_master_name` varchar(50) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`section_master_id`),
  UNIQUE KEY `section_master_name` (`section_master_name`),
  KEY `created_by` (`created_by`),
  KEY `updated_by` (`updated_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `subjects` (
  `subject_id` int(11) NOT NULL AUTO_INCREMENT,
  `subject_name` varchar(100) DEFAULT NULL,
  `subject_code` varchar(50) DEFAULT NULL,
  `subject_alias` varchar(35) DEFAULT NULL,
  `subject_type` varchar(1) NOT NULL DEFAULT 'T',
  `is_placement_related` tinyint(1) NOT NULL DEFAULT 1,
  `for_branches` text DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `tp_related` tinyint(1) NOT NULL DEFAULT 1,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  `credit` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`subject_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE IF NOT EXISTS abit_academic_year (
    academic_year_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    academic_year VARCHAR(7) NOT NULL UNIQUE,
    start_year INTEGER NOT NULL,
    end_year INTEGER NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_abit_academic_year_consecutive CHECK (end_year = start_year + 1),
    CONSTRAINT chk_abit_academic_year_format CHECK (academic_year ~ '^[0-9]{4}-[0-9]{2}$'),
    CONSTRAINT chk_abit_academic_year_label CHECK (academic_year = start_year::TEXT || '-' || LPAD((end_year % 100)::TEXT, 2, '0')),
    CONSTRAINT chk_abit_academic_year_dates CHECK (end_date >= start_date)
);

CREATE TABLE IF NOT EXISTS abit_semester_master (
    semester_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    semester_number INTEGER NOT NULL UNIQUE,
    semester_name VARCHAR(30) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_abit_semester_number CHECK (semester_number BETWEEN 1 AND 8)
);

-- program_id and admission_batch_id are placeholders for the existing ERP
-- masters. Add foreign keys once their actual table/column names are known.
-- Both are required to prevent different cohorts sharing an incorrect mapping.
CREATE TABLE IF NOT EXISTS abit_academic_year_semester_mapping (
    mapping_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    academic_year_id BIGINT NOT NULL REFERENCES abit_academic_year(academic_year_id),
    semester_id BIGINT NOT NULL REFERENCES abit_semester_master(semester_id),
    program_id BIGINT NOT NULL,
    admission_batch_id BIGINT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_abit_mapping UNIQUE (academic_year_id, semester_id, program_id, admission_batch_id),
    CONSTRAINT uq_abit_cohort_semester UNIQUE (semester_id, program_id, admission_batch_id)
);

CREATE TABLE IF NOT EXISTS abit_subject_master (
    subject_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    mapping_id BIGINT NOT NULL REFERENCES abit_academic_year_semester_mapping(mapping_id),
    subject_name VARCHAR(255) NOT NULL,
    subject_code VARCHAR(50) NOT NULL,
    subject_alias VARCHAR(100) NOT NULL,
    subject_type VARCHAR(20) NOT NULL,
    credit NUMERIC(4,1) NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_abit_subject_type CHECK (subject_type IN ('THEORY', 'PRACTICAL')),
    CONSTRAINT chk_abit_subject_credit CHECK (credit >= 0),
    CONSTRAINT uq_abit_subject_mapping_code_type UNIQUE (mapping_id, subject_code, subject_type)
);

CREATE INDEX IF NOT EXISTS idx_abit_mapping_academic_year ON abit_academic_year_semester_mapping(academic_year_id);
CREATE INDEX IF NOT EXISTS idx_abit_mapping_cohort ON abit_academic_year_semester_mapping(program_id, admission_batch_id);
CREATE INDEX IF NOT EXISTS idx_abit_subject_mapping ON abit_subject_master(mapping_id);
CREATE TABLE academic_branches (
    branch_id BIGSERIAL PRIMARY KEY,

    course_id BIGINT NOT NULL
        REFERENCES academic_courses(course_id),

    branch_code VARCHAR(30) NOT NULL,
    branch_name VARCHAR(200) NOT NULL,
    branch_alias VARCHAR(50) NOT NULL,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_course_branch_code
        UNIQUE (course_id, branch_code)
);

CREATE INDEX idx_academic_branches_course
ON academic_branches(course_id);
-- Link subjects to Branch Master; existing subjects remain available without a branch.
ALTER TABLE subjects ADD COLUMN IF NOT EXISTS branch_id BIGINT REFERENCES academic_branches(branch_id);
DROP INDEX IF EXISTS subjects_year_semester_code_unique;
CREATE UNIQUE INDEX IF NOT EXISTS subjects_year_branch_semester_code_unique ON subjects(academic_year_id,branch_id,semester,upper(subject_code)) WHERE branch_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS subjects_unmapped_branch_code_unique ON subjects(academic_year_id,semester,upper(subject_code)) WHERE branch_id IS NULL AND academic_year_id IS NOT NULL;
CREATE TABLE `lessonplan` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `title_2` (`title`),
  KEY `title` (`title`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- Lesson Plan Organizer: one ordered topic per row; removed topics retain audit history.
CREATE TABLE `lessonplans` (
  `lessonplan_id` int(11) NOT NULL AUTO_INCREMENT,
  `subjectteacher_id` int(11) NOT NULL,
  `subjectteacher_subject_id` int(11) NOT NULL,
  `module` int(11) NOT NULL,
  `topics` text NOT NULL,
  `bookname` text NOT NULL,
  `book_id` int(11) DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  `pagenumber` int(11) NOT NULL,
  `ppt_req` varchar(1) NOT NULL,
  `ppt` text NOT NULL,
  `video_url` text NOT NULL,
  `co` text NOT NULL COMMENT 'One or more CO-1 to CO-5 values, comma separated',
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`lessonplan_id`),
  KEY `created_by` (`created_by`),
  KEY `updated_by` (`updated_by`),
  KEY `lessonplans_book_idx` (`book_id`),
  KEY `lessonplans_subject_order_idx` (`subjectteacher_subject_id`,`module`),
  KEY `subjectteacher_id` (`subjectteacher_id`),
  KEY `subjectteacher_subject_id` (`subjectteacher_subject_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `lessonplan_detail` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lessonplan_id` int(11) DEFAULT NULL,
  `item_name` text DEFAULT NULL,
  `lesson_co` text DEFAULT NULL,
  `lesson_book` text DEFAULT NULL,
  `book_page` int(11) NOT NULL DEFAULT 0,
  `ppt_required` int(11) NOT NULL DEFAULT 0,
  `ppt_url` varchar(150) DEFAULT NULL,
  `ppt_status` int(11) NOT NULL DEFAULT 0,
  `video_url` text DEFAULT NULL,
  `lplan_status` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `lessonplan_id` (`lessonplan_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `lessonplan_docs` (
  `lessonplan_docs_id` int(11) NOT NULL AUTO_INCREMENT,
  `lessonplan_docs_details` varchar(100) DEFAULT NULL,
  `lessonplan_docs_lessonplan_detail_id` int(11) DEFAULT NULL,
  `lessonplan_master_id` bigint(20) DEFAULT NULL,
  `lessonplan_docs_path` varchar(150) DEFAULT NULL,
  `lessonplan_docs_submited_at` datetime DEFAULT NULL,
  `lessonplan_docs_status` tinyint(1) NOT NULL DEFAULT 0,
  `created_by` int(11) DEFAULT NULL,
  `reviewed_by` bigint(20) DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  PRIMARY KEY (`lessonplan_docs_id`),
  UNIQUE KEY `lessonplan_docs_path` (`lessonplan_docs_path`),
  KEY `created_by` (`created_by`),
  KEY `lessonplan_docs_lessonplan_detail_id` (`lessonplan_docs_lessonplan_detail_id`),
  KEY `lessonplan_master_id` (`lessonplan_master_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `co_defined` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `cotype` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- Course Outcomes: co_subject_id maps to subjects for Academic Year, Branch and Semester.
-- codescription stores the outcome; created_by records the entering faculty/user.
CREATE TABLE `courseoutcome` (
  `co_id` int(11) NOT NULL AUTO_INCREMENT,
  `cotype` text NOT NULL,
  `co_subject_id` int(11) NOT NULL,
  `codescription` text NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`co_id`),
  UNIQUE KEY `co_id` (`co_id`,`co_subject_id`),
  KEY `courseoutcome_subject_idx` (`co_subject_id`),
  KEY `created_by` (`created_by`),
  KEY `updated_by` (`updated_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `faculty_books` (
  `book_id` int(11) NOT NULL AUTO_INCREMENT,
  `faculty_id` int(11) NOT NULL,
  `subject_id` int(11) NOT NULL,
  `book_name` text NOT NULL,
  `author` text DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`book_id`),
  KEY `faculty_id` (`faculty_id`),
  KEY `subject_id` (`subject_id`),
  KEY `created_by` (`created_by`),
  KEY `updated_by` (`updated_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Lecture Notes: one uploaded document per row, linked to a teaching assignment.
CREATE TABLE `lecture_notes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `teacher` int(11) NOT NULL,
  `subject` int(11) NOT NULL,
  `sem` int(11) NOT NULL,
  `description` text NOT NULL,
  `attachment` text NOT NULL,
  `assignment_id` bigint(20) DEFAULT NULL,
  `file_name` varchar(255) DEFAULT NULL,
  `file_type` varchar(150) DEFAULT NULL,
  `file_size` bigint(20) DEFAULT NULL,
  `file_data` longblob DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `lecture_notes_assignment_idx` (`assignment_id`),
  KEY `teacher` (`teacher`),
  KEY `subject` (`subject`),
  KEY `updated_by` (`updated_by`),
  KEY `created_by` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `subjectteacher` (
  `subjectteacher_id` int(11) NOT NULL AUTO_INCREMENT,
  `subjectteacher_subject_id` int(11) NOT NULL,
  `subjectteacher_employee_id` int(11) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `ppt_reviewer` bigint(20) DEFAULT NULL,
  `lessonplan_exempted` tinyint(1) NOT NULL DEFAULT 1,
  `study_material_exempted` tinyint(1) NOT NULL DEFAULT 0,
  `study_material` tinyint(1) NOT NULL DEFAULT 1,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`subjectteacher_id`),
  UNIQUE KEY `subjectteacher_subject_id` (`subjectteacher_subject_id`,`subjectteacher_employee_id`),
  KEY `created_by` (`created_by`),
  KEY `updated_by` (`updated_by`),
  KEY `subjectteacher_employee_id` (`subjectteacher_employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `videolecture` (
  `l_id` int(11) NOT NULL AUTO_INCREMENT,
  `related_subject` bigint(20) NOT NULL,
  `brief_description` text NOT NULL,
  `video_url` longtext NOT NULL,
  `file_name` varchar(255) DEFAULT NULL,
  `file_type` varchar(100) DEFAULT NULL,
  `file_size` bigint(20) DEFAULT NULL,
  `file_data` longblob DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `reviewed_by` int(11) DEFAULT NULL,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`l_id`),
  KEY `reviewed_by` (`reviewed_by`),
  KEY `created_by` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `student_attendance` (
  `student_attendance_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `session_id` bigint(20) DEFAULT NULL,
  `student_attendance_date` date DEFAULT NULL,
  `student_attendance_classstarttime` text NOT NULL,
  `student_attendance_classendtime` text NOT NULL,
  `student_attendance_lessonplan_id` bigint(20) NOT NULL,
  `student_attendance_student_id` bigint(20) NOT NULL,
  `student_attendance_present_absent` int(11) NOT NULL,
  `student_attendance_master_id` bigint(20) NOT NULL,
  `student_attendance_user_id` bigint(20) NOT NULL,
  `shst_master_id` int(11) NOT NULL,
  `shst_course_id` int(11) NOT NULL,
  `shst_batch_id` bigint(20) NOT NULL,
  `shst_semester` int(11) NOT NULL,
  `shst_section_house_type` varchar(1) NOT NULL,
  `shst_section_house_id` int(11) NOT NULL,
  `shst_subject_id` int(11) NOT NULL,
  `shst_subject_type` varchar(1) NOT NULL,
  `shst_teacher_emp_info_id` int(11) NOT NULL,
  `shst_teacher_emp_master_id` int(11) NOT NULL,
  `shst_teacher_user_id` int(11) NOT NULL,
  `student_group` varchar(3) NOT NULL DEFAULT 'ALL',
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  `rand_str` text NOT NULL,
  PRIMARY KEY (`student_attendance_id`),
  KEY `updated_by` (`updated_by`),
  KEY `created_by` (`created_by`),
  KEY `student_attendance_lessonplan_id` (`student_attendance_lessonplan_id`),
  KEY `student_attendance_student_id` (`student_attendance_student_id`),
  KEY `student_attendance_master_id` (`student_attendance_master_id`),
  KEY `student_attendance_user_id` (`student_attendance_user_id`),
  KEY `shst_course_id` (`shst_course_id`),
  KEY `shst_batch_id` (`shst_batch_id`),
  KEY `shst_teacher_emp_info_id` (`shst_teacher_emp_info_id`),
  KEY `shst_teacher_emp_master_id` (`shst_teacher_emp_master_id`),
  KEY `shst_teacher_user_id` (`shst_teacher_user_id`),
  KEY `shst_master_id` (`shst_master_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `section_house_subject_teacher` (
  `shst_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `shst_course_id` int(11) NOT NULL,
  `shst_batch_id` varchar(100) NOT NULL,
  `shst_semester` int(11) NOT NULL,
  `shst_section_house_type` varchar(1) NOT NULL,
  `shst_section_house_id` int(11) NOT NULL,
  `shst_semester_master_id` int(11) NOT NULL,
  `shst_subject_id` int(11) NOT NULL,
  `shst_teacher_id` int(11) NOT NULL,
  `teacher_type` varchar(1) NOT NULL,
  `student_group` varchar(3) NOT NULL DEFAULT 'ALL',
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  `duration` text DEFAULT NULL,
  PRIMARY KEY (`shst_id`),
  KEY `updated_by` (`updated_by`),
  KEY `created_by` (`created_by`),
  KEY `shst_semester_master_id` (`shst_semester_master_id`),
  KEY `student_group` (`student_group`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
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

-- Lesson Plan runtime PostgreSQL migration (idempotent; existing rows retained).
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

-- Lecture Notes runtime PostgreSQL migration (retains legacy note records).
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

-- e-Note Upload Report: live PostgreSQL view over lecture_notes.
-- Report directly from saved lecture notes so uploads and availability stay current.
-- lessonplan_docs remains reserved for lesson-plan documents.
CREATE OR REPLACE VIEW lecture_note_upload_report AS
SELECT n.id,n.teacher,n.subject,n.sem,n.description,n.created_at,n.created_by,
 u.full_name AS faculty_name,s.subject_name,s.subject_code,
 COALESCE(NULLIF(n.file_name,''),NULLIF(regexp_replace(replace(n.attachment,chr(92),'/'),'^.*/',''),'')) AS file_name,
 n.file_type,n.file_size,
 COALESCE(octet_length(n.file_data)>0,FALSE) AS downloadable,
 CASE WHEN COALESCE(octet_length(n.file_data)>0,FALSE) THEN 'Available' ELSE 'File Missing' END AS file_status
FROM lecture_notes n
LEFT JOIN users u ON u.user_id=n.teacher
LEFT JOIN subjects s ON s.subject_id=n.subject;

-- Video Lecture runtime PostgreSQL migration.
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

-- Take Attendance runtime PostgreSQL migration: explicit rosters and class sessions.
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

-- Student Attendance report: class totals from saved attendance marks.
-- A class report counts the latest saved mark for each student, including legacy rows.
CREATE OR REPLACE VIEW student_attendance_summary AS
WITH ranked AS (
 SELECT a.*,ROW_NUMBER() OVER(PARTITION BY session_id,student_attendance_master_id,
  student_attendance_date,student_attendance_classstarttime,student_attendance_classendtime,
  shst_course_id,shst_batch_id,shst_section_house_type,shst_section_house_id,shst_semester,
  student_attendance_lessonplan_id,shst_subject_id,shst_subject_type,student_group,student_attendance_student_id
  ORDER BY student_attendance_id DESC) AS mark_rank
 FROM student_attendance a
), totals AS (
 SELECT MIN(student_attendance_id) AS id,session_id,student_attendance_master_id,
  student_attendance_date::text AS attendance_date,student_attendance_classstarttime AS start_time,
  student_attendance_classendtime AS end_time,shst_course_id AS course_id,shst_batch_id AS batch_id,
  shst_section_house_type AS section_type,shst_section_house_id AS section_id,shst_semester AS semester,
  student_attendance_lessonplan_id AS topic_id,shst_subject_id AS subject_id,shst_subject_type AS subject_type,student_group,
  COUNT(*)::integer AS strength,COUNT(*) FILTER(WHERE student_attendance_present_absent=1)::integer AS present,
  COUNT(*) FILTER(WHERE student_attendance_present_absent=0)::integer AS absent
 FROM ranked WHERE mark_rank=1
 GROUP BY session_id,student_attendance_master_id,student_attendance_date,student_attendance_classstarttime,
  student_attendance_classendtime,shst_course_id,shst_batch_id,shst_section_house_type,shst_section_house_id,
  shst_semester,student_attendance_lessonplan_id,shst_subject_id,shst_subject_type,student_group
)
SELECT t.*,c.course_name,c.course_code,b.batch_name,
 CASE WHEN t.section_type='H' THEN h.section_master_name ELSE sec.section_name END AS section_name,
 l.topics AS topic_covered,s.subject_name,s.subject_code
FROM totals t LEFT JOIN courses c ON c.course_id=t.course_id LEFT JOIN batches b ON b.batch_id=t.batch_id
LEFT JOIN section sec ON sec.s_id=t.section_id LEFT JOIN section_master h ON h.section_master_id=t.section_id
LEFT JOIN lessonplans l ON l.lessonplan_id=t.topic_id LEFT JOIN subjects s ON s.subject_id=t.subject_id;



CREATE TABLE `course_semester` (
  `sem_id` int(11) NOT NULL,
  `course_id` int(11) NOT NULL,
  `sem_int` int(11) NOT NULL,
  `sem_name` varchar(10) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `is_status` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `semester_defined` (
  `id` int(11) NOT NULL,
  `sem_course_master_id` int(11) NOT NULL,
  `sem_batch_master_id` int(11) NOT NULL,
  `semester` int(11) NOT NULL,
  `sem_section_house_type` varchar(1) DEFAULT NULL,
  `is_active` tinyint(4) NOT NULL DEFAULT 0,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `consider_for_accounts` tinyint(1) NOT NULL DEFAULT 1,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  `bio` int(11) NOT NULL DEFAULT 2,
  `is_markentry_active` int(11) NOT NULL DEFAULT 0,
  `result_way` int(11) NOT NULL DEFAULT 0,
  `publish_result` int(11) NOT NULL DEFAULT 0,
  `reimprovement_open` varchar(1) NOT NULL DEFAULT 'N',
  `markcalcformulae` text DEFAULT NULL,
  `quizmail` varchar(1) NOT NULL DEFAULT 'N'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `subjectteacher` (
  `subjectteacher_id` int(11) NOT NULL,
  `subjectteacher_subject_id` int(11) NOT NULL,
  `subjectteacher_employee_id` int(11) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `ppt_reviewer` bigint(20) DEFAULT NULL,
  `lessonplan_exempted` tinyint(1) NOT NULL DEFAULT 1,
  `study_material_exempted` tinyint(1) NOT NULL DEFAULT 0,
  `study_material` tinyint(1) NOT NULL DEFAULT 1,
  `is_status` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `section_house_subject_teacher` (
  `shst_id` bigint(20) NOT NULL,
  `shst_course_id` int(11) NOT NULL,
  `shst_batch_id` varchar(100) NOT NULL,
  `shst_semester` int(11) NOT NULL,
  `shst_section_house_type` varchar(1) NOT NULL,
  `shst_section_house_id` int(11) NOT NULL,
  `shst_semester_master_id` int(11) NOT NULL,
  `shst_subject_id` int(11) NOT NULL,
  `shst_teacher_id` int(11) NOT NULL,
  `teacher_type` varchar(1) NOT NULL,
  `student_group` varchar(3) NOT NULL DEFAULT 'ALL',
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  `duration` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `coursefortimetableproxy` (
  `course_id` bigint(20) NOT NULL,
  `user_id` bigint(20) NOT NULL,
  `course_name` text NOT NULL,
  `course_full_name` text NOT NULL,
  `semester` text NOT NULL,
  `section` text NOT NULL,
  `subject_id` text NOT NULL,
  `faculty_id` text NOT NULL,
  `grp` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

CREATE TABLE `facultyproxy` (
  `faculty_id` bigint(20) NOT NULL,
  `user_id` bigint(20) NOT NULL DEFAULT 25,
  `faculty_code` text NOT NULL,
  `faculty_name` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

CREATE TABLE `timetableproxy` (
  `timetable_id` bigint(20) NOT NULL,
  `user_id` bigint(20) NOT NULL,
  `course_full_name` text NOT NULL,
  `year` varchar(20) NOT NULL,
  `semester` varchar(20) NOT NULL,
  `course` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

CREATE TABLE `tablesheetproxy` (
  `id` bigint(20) NOT NULL,
  `cell` bigint(20) NOT NULL,
  `data` text NOT NULL,
  `faculty_name` text NOT NULL,
  `timetable_id` text NOT NULL,
  `user_id` bigint(20) NOT NULL,
  `room_no` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

ALTER TABLE `course_semester`
  ADD PRIMARY KEY (`sem_id`),
  ADD UNIQUE KEY `course_id` (`course_id`,`sem_int`),
  ADD KEY `updated_by` (`updated_by`),
  ADD KEY `created_by` (`created_by`);

ALTER TABLE `course_semester`
  MODIFY `sem_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `semester_defined`
  ADD PRIMARY KEY (`id`),
  ADD KEY `sem_course_master_id` (`sem_course_master_id`,`sem_batch_master_id`,`semester`,`sem_section_house_type`),
  ADD KEY `created_by` (`created_by`),
  ADD KEY `updated_by` (`updated_by`);

ALTER TABLE `semester_defined`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `subjectteacher`
  ADD PRIMARY KEY (`subjectteacher_id`),
  ADD UNIQUE KEY `subjectteacher_subject_id` (`subjectteacher_subject_id`,`subjectteacher_employee_id`),
  ADD KEY `created_by` (`created_by`),
  ADD KEY `updated_by` (`updated_by`),
  ADD KEY `subjectteacher_employee_id` (`subjectteacher_employee_id`);

ALTER TABLE `subjectteacher`
  MODIFY `subjectteacher_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `section_house_subject_teacher`
  ADD PRIMARY KEY (`shst_id`),
  ADD KEY `updated_by` (`updated_by`),
  ADD KEY `created_by` (`created_by`),
  ADD KEY `shst_semester_master_id` (`shst_semester_master_id`),
  ADD KEY `student_group` (`student_group`);

ALTER TABLE `section_house_subject_teacher`
  MODIFY `shst_id` bigint(20) NOT NULL AUTO_INCREMENT;

ALTER TABLE `coursefortimetableproxy`
  ADD PRIMARY KEY (`course_id`);

ALTER TABLE `coursefortimetableproxy`
  MODIFY `course_id` bigint(20) NOT NULL AUTO_INCREMENT;

ALTER TABLE `facultyproxy`
  ADD PRIMARY KEY (`faculty_id`);

ALTER TABLE `facultyproxy`
  MODIFY `faculty_id` bigint(20) NOT NULL AUTO_INCREMENT;

ALTER TABLE `timetableproxy`
  ADD PRIMARY KEY (`timetable_id`);

ALTER TABLE `timetableproxy`
  MODIFY `timetable_id` bigint(20) NOT NULL AUTO_INCREMENT;



-- 1. Course Semester Master
CREATE TABLE academic_course_semesters (
    semester_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    course_id BIGINT NOT NULL
        REFERENCES academic_courses(course_id),
    semester_number INTEGER NOT NULL
        CHECK (semester_number BETWEEN 1 AND 12),
    semester_name VARCHAR(30) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,
    UNIQUE (course_id, semester_number),
    UNIQUE (semester_id, course_id)
);

-- 2. Batch Semester Definition
CREATE TABLE academic_batch_semesters (
    batch_semester_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    course_id BIGINT NOT NULL
        REFERENCES academic_courses(course_id),
    batch_id BIGINT NOT NULL
        REFERENCES academic_batches(batch_id),
    branch_id BIGINT
        REFERENCES academic_branches(branch_id),
    semester_id BIGINT NOT NULL,
    academic_year_id BIGINT NOT NULL
        REFERENCES abit_academic_year(academic_year_id),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    mark_entry_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    result_published BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,
    FOREIGN KEY (semester_id, course_id)
        REFERENCES academic_course_semesters(semester_id, course_id),
    UNIQUE (batch_semester_id, course_id)
);

-- 3. Subject Faculty Eligibility
CREATE TABLE academic_subject_faculty (
    subject_faculty_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    subject_id BIGINT NOT NULL
        REFERENCES abit_subject_master(subject_id),
    employee_id BIGINT NOT NULL
        REFERENCES employee_master(employee_id),
    ppt_reviewer_id BIGINT
        REFERENCES employee_master(employee_id),
    lessonplan_exempted BOOLEAN NOT NULL DEFAULT FALSE,
    study_material_exempted BOOLEAN NOT NULL DEFAULT FALSE,
    study_material_required BOOLEAN NOT NULL DEFAULT TRUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,
    UNIQUE (subject_id, employee_id)
);

-- 4. Class / Teacher Allotment
CREATE TABLE academic_teacher_allotments (
    allotment_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    batch_semester_id BIGINT NOT NULL
        REFERENCES academic_batch_semesters(batch_semester_id),
    section_id BIGINT NOT NULL
        REFERENCES academic_sections(section_id),
    student_group VARCHAR(20) NOT NULL DEFAULT 'ALL',
    subject_faculty_id BIGINT NOT NULL
        REFERENCES academic_subject_faculty(subject_faculty_id),
    teacher_type CHAR(1) NOT NULL
        CHECK (teacher_type IN ('M','C','S')),
    effective_from DATE,
    effective_to DATE,
    duration_notes TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,
    CHECK (
        effective_to IS NULL
        OR effective_from IS NULL
        OR effective_to >= effective_from
    )
);

CREATE INDEX idx_teacher_allotment_semester
    ON academic_teacher_allotments(batch_semester_id);

CREATE INDEX idx_teacher_allotment_faculty
    ON academic_teacher_allotments(subject_faculty_id);

CREATE UNIQUE INDEX uq_teacher_allotment_active
ON academic_teacher_allotments (
    batch_semester_id,
    section_id,
    student_group,
    subject_faculty_id,
    teacher_type
)
WHERE is_active = TRUE;

-- 5. Timetable Course Access
CREATE TABLE timetable_course_access (
    access_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL
        REFERENCES administration_users(user_id),
    batch_semester_id BIGINT NOT NULL
        REFERENCES academic_batch_semesters(batch_semester_id),
    section_id BIGINT NOT NULL
        REFERENCES academic_sections(section_id),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (user_id, batch_semester_id, section_id)
);

-- 6. Timetable Faculty Access
CREATE TABLE timetable_faculty_access (
    access_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL
        REFERENCES administration_users(user_id),
    employee_id BIGINT NOT NULL
        REFERENCES employee_master(employee_id),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (user_id, employee_id)
);

-- 7. Timetable Schedule
CREATE TABLE timetable_schedules (
    timetable_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    batch_semester_id BIGINT NOT NULL
        REFERENCES academic_batch_semesters(batch_semester_id),
    section_id BIGINT NOT NULL
        REFERENCES academic_sections(section_id),
    timetable_name VARCHAR(150) NOT NULL,
    effective_from DATE NOT NULL,
    effective_to DATE,
    is_published BOOLEAN NOT NULL DEFAULT FALSE,
    created_by BIGINT
        REFERENCES administration_users(user_id),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CHECK (effective_to IS NULL OR effective_to >= effective_from)
);

-- 8. Timetable Cells / Periods
CREATE TABLE timetable_schedule_cells (
    cell_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    timetable_id BIGINT NOT NULL
        REFERENCES timetable_schedules(timetable_id)
        ON DELETE CASCADE,
    day_of_week SMALLINT NOT NULL
        CHECK (day_of_week BETWEEN 1 AND 7),
    period_number SMALLINT NOT NULL
        CHECK (period_number > 0),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    allotment_id BIGINT NOT NULL
        REFERENCES academic_teacher_allotments(allotment_id),
    room_no VARCHAR(50),
    notes TEXT,
    CHECK (end_time > start_time),
    UNIQUE (timetable_id, day_of_week, period_number)
);

-- Subject Configuration runtime PostgreSQL migration: semester definitions, faculty eligibility, permanent and substitute allotments.
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

-- Assign Subject Teacher: Academic Year, Branch and Semester context.
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

-- Semester selection follows course duration in years multiplied by two.
-- The API validates the semester against the selected course's duration * 2.
ALTER TABLE semester_defined DROP CONSTRAINT IF EXISTS semester_defined_semester_check;
DO $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='semester_defined_semester_positive' AND conrelid='semester_defined'::regclass) THEN
  ALTER TABLE semester_defined ADD CONSTRAINT semester_defined_semester_positive CHECK(semester>=1) NOT VALID;
 END IF;
END $$;

-- Semester definitions use Section only.
-- New semester definitions use Section only; existing records are retained.
ALTER TABLE semester_defined ALTER COLUMN sem_section_house_type SET DEFAULT 'S';
ALTER TABLE semester_defined DROP CONSTRAINT IF EXISTS semester_defined_sem_section_house_type_check;
DO $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='semester_defined_section_only' AND conrelid='semester_defined'::regclass) THEN
  ALTER TABLE semester_defined ADD CONSTRAINT semester_defined_section_only CHECK(sem_section_house_type='S') NOT VALID;
 END IF;
END $$;

CREATE TABLE `emp_master` (
  `emp_master_id` int(11) NOT NULL AUTO_INCREMENT,
  `emp_master_emp_info_id` int(11) NOT NULL,
  `emp_master_user_id` int(11) NOT NULL,
  `emp_master_department_id` int(11) NOT NULL,
  `emp_master_designation_id` int(11) DEFAULT NULL,
  `emp_master_category_id` int(11) DEFAULT NULL,
  `emp_master_nationality_id` int(11) DEFAULT NULL,
  `emp_master_emp_address_id` int(11) DEFAULT NULL,
  `emp_master_status_id` int(11) NOT NULL DEFAULT 0,
  `deleted_at` datetime DEFAULT NULL,
  `deleted_by` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `is_floormanager` tinyint(1) NOT NULL DEFAULT 0,
  `is_tp_counseller` tinyint(1) NOT NULL DEFAULT 0,
  `is_telecaller` tinyint(1) NOT NULL DEFAULT 0,
  `is_able_for_admission_booking_entry` tinyint(1) NOT NULL DEFAULT 0,
  `is_able_for_admission_booking_approve` tinyint(1) NOT NULL DEFAULT 0,
  `is_able_for_admission_consultant_entry` tinyint(1) NOT NULL DEFAULT 0,
  `is_admission_consultant_approver` tinyint(1) NOT NULL DEFAULT 0,
  `is_able_for_admission_booking_view` tinyint(1) NOT NULL DEFAULT 0,
  `is_able_admission_consultant_view` tinyint(1) NOT NULL DEFAULT 0,
  `is_grievancecell_member` tinyint(1) NOT NULL DEFAULT 0,
  `immediate_higher_officer` bigint(20) NOT NULL DEFAULT 0,
  `boarding1` bigint(20) NOT NULL DEFAULT 0,
  `boarding2` bigint(20) NOT NULL DEFAULT 0,
  `boarding3` bigint(20) NOT NULL DEFAULT 0,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  `cc_target` int(11) NOT NULL DEFAULT 0,
  `cc_branch` int(11) NOT NULL DEFAULT 0,
  `ti_target` int(11) NOT NULL DEFAULT 0,
  `pi_target` int(11) NOT NULL DEFAULT 0,
  `ca_target` int(11) NOT NULL DEFAULT 0,
  `is_payroll` tinyint(1) NOT NULL DEFAULT 0,
  `basic_salary` decimal(10,2) NOT NULL DEFAULT 0.00,
  `is_mentor_newstudent` tinyint(1) NOT NULL DEFAULT 1,
  `emp_cast` text DEFAULT NULL,
  `coa_regd` text DEFAULT NULL,
  `bput_regd` text DEFAULT NULL,
  PRIMARY KEY (`emp_master_id`),
  UNIQUE KEY `emp_master_user_id` (`emp_master_user_id`),
  UNIQUE KEY `emp_master_emp_info_id` (`emp_master_emp_info_id`),
  KEY `emp_master_department_id` (`emp_master_department_id`),
  KEY `emp_master_designation_id` (`emp_master_designation_id`),
  KEY `emp_master_category_id` (`emp_master_category_id`),
  KEY `emp_master_nationality_id` (`emp_master_nationality_id`),
  KEY `emp_master_emp_address_id` (`emp_master_emp_address_id`),
  KEY `created_by` (`created_by`),
  KEY `updated_by` (`updated_by`),
  KEY `emp_master_emp_info_id_frg` (`emp_master_emp_info_id`),
  KEY `emp_master_user_id_frg` (`emp_master_user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `emp_info` (
  `emp_info_id` int(11) NOT NULL AUTO_INCREMENT,
  `emp_unique_id` int(11) NOT NULL,
  `employee_code` varchar(50) DEFAULT NULL,
  `emp_attendance_card_id` varchar(50) DEFAULT NULL,
  `emp_title` varchar(15) DEFAULT NULL,
  `emp_first_name` varchar(35) DEFAULT NULL,
  `emp_middle_name` varchar(35) DEFAULT NULL,
  `emp_last_name` varchar(35) DEFAULT NULL,
  `emp_name_alias` varchar(10) DEFAULT NULL,
  `emp_mother_name` varchar(50) DEFAULT NULL,
  `emp_gender` varchar(20) DEFAULT NULL,
  `emp_dob` date DEFAULT NULL,
  `emp_religion` varchar(50) DEFAULT NULL,
  `emp_bloodgroup` varchar(15) NOT NULL DEFAULT 'Unknown',
  `emp_joining_date` date DEFAULT NULL,
  `emp_birthplace` varchar(50) DEFAULT NULL,
  `emp_email_id` varchar(65) DEFAULT NULL,
  `emp_maritalstatus` varchar(35) DEFAULT NULL,
  `emp_mobile_no` varchar(20) DEFAULT NULL,
  `emp_photo` varchar(150) DEFAULT NULL,
  `emp_languages` varchar(255) DEFAULT NULL,
  `emp_bankaccount_no` varchar(25) DEFAULT NULL,
  `emp_qualification` varchar(50) DEFAULT NULL,
  `emp_specialization` varchar(255) DEFAULT NULL,
  `emp_experience_year` tinyint(4) DEFAULT NULL,
  `emp_experience_month` tinyint(4) DEFAULT NULL,
  `emp_hobbies` varchar(100) DEFAULT NULL,
  `emp_reference` varchar(35) DEFAULT NULL,
  `emp_guardian_name` varchar(65) DEFAULT NULL,
  `emp_guardian_relation` varchar(30) DEFAULT NULL,
  `emp_guardian_qualification` varchar(50) DEFAULT NULL,
  `emp_guardian_occupation` varchar(50) DEFAULT NULL,
  `emp_guardian_income` varchar(50) DEFAULT NULL,
  `emp_guardian_homeadd` varchar(255) DEFAULT NULL,
  `emp_guardian_officeadd` varchar(255) DEFAULT NULL,
  `emp_guardian_mobile_no` bigint(20) DEFAULT NULL,
  `emp_guardian_phone_no` varchar(25) DEFAULT NULL,
  `emp_guardian_email_id` varchar(65) DEFAULT NULL,
  `emp_info_emp_master_id` int(11) DEFAULT NULL,
  `is_lunch` varchar(1) NOT NULL DEFAULT 'N',
  `is_transport` varchar(1) NOT NULL DEFAULT 'N',
  `emp_thumb` bigint(20) NOT NULL DEFAULT 0,
  `emp_paperpublished` text DEFAULT NULL,
  `emp_bookswritten` text DEFAULT NULL,
  `emp_rndprojects` text DEFAULT NULL,
  `emp_membership` text DEFAULT NULL,
  `emp_workshops` text DEFAULT NULL,
  `emp_national_conferences` text DEFAULT NULL,
  `emp_international_conferences` text DEFAULT NULL,
  `emp_aadhaar` text DEFAULT NULL,
  `emp_pan` text DEFAULT NULL,
  `emp_voter` text DEFAULT NULL,
  `emp_bankname` text DEFAULT NULL,
  `emp_ifsc` text DEFAULT NULL,
  PRIMARY KEY (`emp_info_id`),
  UNIQUE KEY `emp_unique_id` (`emp_unique_id`),
  UNIQUE KEY `emp_info_emp_master_id` (`emp_info_emp_master_id`),
  UNIQUE KEY `emp_email_id` (`emp_email_id`),
  UNIQUE KEY `emp_mobile_no` (`emp_mobile_no`),
  UNIQUE KEY `emp_attendance_card_id` (`emp_attendance_card_id`),
  KEY `emp_info_emp_master_id_fgn` (`emp_info_emp_master_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `emp_address` (
  `emp_address_id` int(11) NOT NULL AUTO_INCREMENT,
  `emp_cadd` varchar(255) DEFAULT NULL,
  `emp_cadd_city` int(11) DEFAULT NULL,
  `emp_cadd_state` int(11) DEFAULT NULL,
  `emp_cadd_country` int(11) DEFAULT NULL,
  `emp_cadd_pincode` int(11) DEFAULT NULL,
  `emp_cadd_house_no` varchar(25) DEFAULT NULL,
  `emp_cadd_phone_no` varchar(25) DEFAULT NULL,
  `emp_padd` varchar(255) DEFAULT NULL,
  `emp_padd_city` int(11) DEFAULT NULL,
  `emp_padd_state` int(11) DEFAULT NULL,
  `emp_padd_country` int(11) DEFAULT NULL,
  `emp_padd_pincode` int(11) DEFAULT NULL,
  `emp_padd_house_no` varchar(25) DEFAULT NULL,
  `emp_padd_phone_no` varchar(25) DEFAULT NULL,
  PRIMARY KEY (`emp_address_id`),
  KEY `emp_cadd_city` (`emp_cadd_city`),
  KEY `emp_cadd_state` (`emp_cadd_state`),
  KEY `emp_cadd_country` (`emp_cadd_country`),
  KEY `emp_padd_city` (`emp_padd_city`),
  KEY `emp_padd_state` (`emp_padd_state`),
  KEY `emp_padd_country` (`emp_padd_country`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `emp_docs` (
  `emp_docs_id` int(11) NOT NULL AUTO_INCREMENT,
  `emp_docs_details` varchar(100) DEFAULT NULL,
  `emp_docs_category_id` int(11) DEFAULT NULL,
  `emp_docs_path` varchar(150) DEFAULT NULL,
  `emp_docs_submited_at` datetime DEFAULT NULL,
  `emp_docs_status` tinyint(1) NOT NULL DEFAULT 0,
  `emp_docs_emp_master_id` int(11) DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  PRIMARY KEY (`emp_docs_id`),
  KEY `created_by` (`created_by`),
  KEY `emp_docs_emp_master_id` (`emp_docs_emp_master_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `emp_department` (
  `emp_department_id` int(11) NOT NULL AUTO_INCREMENT,
  `emp_department_name` varchar(65) DEFAULT NULL,
  `emp_department_alias` varchar(10) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  `hide_fromload` varchar(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`emp_department_id`),
  UNIQUE KEY `emp_department_name` (`emp_department_name`),
  UNIQUE KEY `emp_department_alias` (`emp_department_alias`),
  KEY `updated_by` (`updated_by`),
  KEY `created_by` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `emp_designation` (
  `emp_designation_id` int(11) NOT NULL AUTO_INCREMENT,
  `emp_designation_name` varchar(50) DEFAULT NULL,
  `is_store_authority` varchar(1) NOT NULL DEFAULT 'N',
  `emp_designation_alias` varchar(10) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  `daylimit` text DEFAULT NULL,
  `monthlimit` text DEFAULT NULL,
  `authority_1` bigint(20) DEFAULT NULL,
  `monthlimit_1` text DEFAULT NULL,
  `authority_2` bigint(20) DEFAULT NULL,
  `monthlimit_2` text DEFAULT NULL,
  `authority_3` bigint(20) DEFAULT NULL,
  `monthlimit_3` text DEFAULT NULL,
  `authority_4` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`emp_designation_id`),
  UNIQUE KEY `emp_designation_name` (`emp_designation_name`),
  UNIQUE KEY `emp_designation_alias` (`emp_designation_alias`),
  KEY `created_by` (`created_by`),
  KEY `updated_by` (`updated_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `emp_category` (
  `emp_category_id` int(11) NOT NULL AUTO_INCREMENT,
  `emp_category_name` varchar(50) DEFAULT NULL,
  `emp_category_alias` varchar(10) DEFAULT NULL,
  `is_teaching` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`emp_category_id`),
  UNIQUE KEY `emp_category_name` (`emp_category_name`),
  UNIQUE KEY `emp_category_alias` (`emp_category_alias`),
  KEY `updated_by` (`updated_by`),
  KEY `created_by` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `emp_status` (
  `emp_status_id` int(11) NOT NULL AUTO_INCREMENT,
  `emp_status_name` varchar(50) DEFAULT NULL,
  `emp_status_description` varchar(100) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`emp_status_id`),
  UNIQUE KEY `emp_status_name` (`emp_status_name`),
  KEY `created_by` (`created_by`),
  KEY `updated_by` (`updated_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `users` (
  `user_id` int(11) NOT NULL AUTO_INCREMENT,
  `user_login_id` varchar(65) NOT NULL,
  `user_password` varchar(150) NOT NULL,
  `user_type` char(2) NOT NULL,
  `is_block` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `user_login_id` (`user_login_id`),
  KEY `updated_by` (`updated_by`),
  KEY `created_by` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Employee module runtime PostgreSQL tables and login integration.
INSERT INTO user_roles(role_name) VALUES('Employee') ON CONFLICT(role_name) DO NOTHING;
CREATE TABLE IF NOT EXISTS emp_department (
 emp_department_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 emp_department_name VARCHAR(65) NOT NULL UNIQUE,emp_department_alias VARCHAR(10) NOT NULL UNIQUE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),created_by BIGINT REFERENCES users(user_id),updated_at TIMESTAMPTZ,updated_by BIGINT REFERENCES users(user_id),is_status SMALLINT NOT NULL DEFAULT 1
);
CREATE TABLE IF NOT EXISTS emp_designation (
 emp_designation_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 emp_designation_name VARCHAR(50) NOT NULL UNIQUE,emp_designation_alias VARCHAR(10) NOT NULL UNIQUE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),created_by BIGINT REFERENCES users(user_id),updated_at TIMESTAMPTZ,updated_by BIGINT REFERENCES users(user_id),is_status SMALLINT NOT NULL DEFAULT 1
);
CREATE TABLE IF NOT EXISTS emp_category (
 emp_category_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 emp_category_name VARCHAR(50) NOT NULL UNIQUE,emp_category_alias VARCHAR(10) NOT NULL UNIQUE,
 is_teaching BOOLEAN NOT NULL DEFAULT FALSE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),created_by BIGINT REFERENCES users(user_id),updated_at TIMESTAMPTZ,updated_by BIGINT REFERENCES users(user_id),is_status SMALLINT NOT NULL DEFAULT 1
);
CREATE TABLE IF NOT EXISTS emp_info (
 emp_info_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 emp_unique_id BIGINT NOT NULL UNIQUE CHECK(emp_unique_id>0),employee_code VARCHAR(50) NOT NULL UNIQUE,
 emp_title VARCHAR(15),emp_first_name VARCHAR(35) NOT NULL,emp_middle_name VARCHAR(35),emp_last_name VARCHAR(35) NOT NULL,
 emp_name_alias VARCHAR(10),emp_gender VARCHAR(20),emp_dob DATE,emp_joining_date DATE,
 emp_email_id VARCHAR(65),emp_mobile_no VARCHAR(20),emp_maritalstatus VARCHAR(35),
 emp_experience_year SMALLINT NOT NULL DEFAULT 0 CHECK(emp_experience_year BETWEEN 0 AND 80),
 emp_experience_month SMALLINT NOT NULL DEFAULT 0 CHECK(emp_experience_month BETWEEN 0 AND 11)
);
CREATE UNIQUE INDEX IF NOT EXISTS emp_info_email_unique ON emp_info(lower(emp_email_id)) WHERE emp_email_id IS NOT NULL;
CREATE TABLE IF NOT EXISTS emp_master (
 emp_master_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 emp_master_emp_info_id BIGINT NOT NULL UNIQUE REFERENCES emp_info(emp_info_id),
 emp_master_user_id BIGINT NOT NULL UNIQUE REFERENCES users(user_id),
 emp_master_department_id BIGINT NOT NULL REFERENCES emp_department(emp_department_id),
 emp_master_designation_id BIGINT REFERENCES emp_designation(emp_designation_id),
 emp_master_category_id BIGINT NOT NULL REFERENCES emp_category(emp_category_id),
 emp_master_nationality_id BIGINT REFERENCES nationality(nationality_id),emp_cast VARCHAR(35),
 deleted_at TIMESTAMPTZ,deleted_by BIGINT REFERENCES users(user_id),
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),created_by BIGINT REFERENCES users(user_id),updated_at TIMESTAMPTZ,updated_by BIGINT REFERENCES users(user_id),is_status SMALLINT NOT NULL DEFAULT 1
);
CREATE INDEX IF NOT EXISTS emp_master_department_idx ON emp_master(emp_master_department_id);
CREATE INDEX IF NOT EXISTS emp_master_deleted_idx ON emp_master(deleted_at);

CREATE TABLE `stu_master` (
  `stu_master_id` int(11) NOT NULL AUTO_INCREMENT,
  `stu_master_stu_info_id` int(11) DEFAULT NULL,
  `stu_master_user_id` int(11) DEFAULT NULL,
  `stu_master_nationality_id` int(11) DEFAULT NULL,
  `stu_master_category_id` int(11) DEFAULT NULL,
  `stu_master_course_id` int(11) DEFAULT NULL,
  `stu_master_batch_id` int(11) DEFAULT NULL,
  `stu_master_section_id` int(11) DEFAULT NULL,
  `student_master_house_id` int(11) NOT NULL DEFAULT 1,
  `grop` int(11) NOT NULL DEFAULT 0,
  `att_serial` text DEFAULT NULL,
  `honors` varchar(1) NOT NULL DEFAULT 'N',
  `minor` varchar(1) NOT NULL DEFAULT 'N',
  `vcourse1` int(11) DEFAULT NULL,
  `vcourse2` int(11) DEFAULT NULL,
  `vcourse3` int(11) DEFAULT NULL,
  `vcourse4` bigint(20) DEFAULT NULL,
  `vcourse5` bigint(20) DEFAULT NULL,
  `vcourse6` bigint(20) DEFAULT NULL,
  `vcourse7` bigint(20) DEFAULT NULL,
  `vcourse8` bigint(20) DEFAULT NULL,
  `vcourse9` bigint(20) DEFAULT NULL,
  `vcourse10` bigint(20) DEFAULT NULL,
  `vcourse11` bigint(20) DEFAULT NULL,
  `vcourse12` bigint(20) DEFAULT NULL,
  `vcourse13` bigint(20) DEFAULT NULL,
  `vcourse14` bigint(20) DEFAULT NULL,
  `vcourse15` bigint(20) DEFAULT NULL,
  `vcourse16` bigint(20) DEFAULT NULL,
  `mentor_id` bigint(20) NOT NULL DEFAULT 0,
  `stu_master_stu_status_id` int(11) NOT NULL DEFAULT 0,
  `stu_master_stu_address_id` int(11) DEFAULT NULL,
  `tenthschoolname` text DEFAULT NULL,
  `tenthpasoutyear` year(4) DEFAULT NULL,
  `tenth` decimal(4,2) NOT NULL DEFAULT 0.00,
  `twelevethcollegename` text DEFAULT NULL,
  `twelevethpasoutyear` year(4) DEFAULT NULL,
  `tweleveth` decimal(4,2) NOT NULL DEFAULT 0.00,
  `diplomacollegename` text DEFAULT NULL,
  `diplomapasoutyear` year(4) DEFAULT NULL,
  `diploma` decimal(4,2) NOT NULL DEFAULT 0.00,
  `babsccollegename` bigint(20) NOT NULL DEFAULT 0,
  `babscpasoutyear` year(4) DEFAULT NULL,
  `babsc` decimal(4,2) NOT NULL DEFAULT 0.00,
  `bcacollegename` bigint(20) NOT NULL DEFAULT 0,
  `bcapasoutyear` year(4) DEFAULT NULL,
  `bca` decimal(4,2) NOT NULL DEFAULT 0.00,
  `bbacollegename` bigint(20) NOT NULL DEFAULT 0,
  `bbapasoutyear` year(4) DEFAULT NULL,
  `bba` decimal(4,2) NOT NULL DEFAULT 0.00,
  `btechcollegename` bigint(20) NOT NULL DEFAULT 0,
  `btechpasoutyear` year(4) DEFAULT NULL,
  `btech` decimal(4,2) NOT NULL DEFAULT 0.00,
  `other_exam` text DEFAULT NULL,
  `other_mark` decimal(4,2) DEFAULT NULL,
  `sem1` decimal(4,2) NOT NULL DEFAULT 0.00,
  `sem2` decimal(4,2) NOT NULL DEFAULT 0.00,
  `sem3` decimal(4,2) NOT NULL DEFAULT 0.00,
  `sem4` decimal(4,2) NOT NULL DEFAULT 0.00,
  `sem5` decimal(4,2) NOT NULL DEFAULT 0.00,
  `sem6` decimal(4,2) NOT NULL DEFAULT 0.00,
  `sem7` decimal(4,2) NOT NULL DEFAULT 0.00,
  `sem8` decimal(4,2) NOT NULL DEFAULT 0.00,
  `hostel_room` text DEFAULT NULL,
  `boarding1` bigint(20) NOT NULL DEFAULT 0,
  `boarding2` bigint(20) NOT NULL DEFAULT 0,
  `boarding3` bigint(20) NOT NULL DEFAULT 0,
  `career_objective` bigint(20) NOT NULL DEFAULT 0,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `semester_registered` int(11) NOT NULL DEFAULT 0,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  `iticollegename` bigint(20) NOT NULL DEFAULT 0,
  `itiyear` year(4) DEFAULT NULL,
  `itimark` decimal(4,2) NOT NULL DEFAULT 0.00,
  `allotment_status` tinyint(1) NOT NULL DEFAULT 0,
  `is_icard_available` int(11) NOT NULL DEFAULT 0,
  `interested_placement` varchar(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`stu_master_id`),
  UNIQUE KEY `stu_master_stu_info_id` (`stu_master_stu_info_id`),
  UNIQUE KEY `stu_master_user_id` (`stu_master_user_id`),
  KEY `stu_master_nationality_id` (`stu_master_nationality_id`),
  KEY `stu_master_category` (`stu_master_category_id`),
  KEY `stu_master_course_id` (`stu_master_course_id`),
  KEY `stu_master_batch_id` (`stu_master_batch_id`),
  KEY `stu_master_section_id` (`stu_master_section_id`),
  KEY `stu_master_stu_address_id` (`stu_master_stu_address_id`),
  KEY `created_by` (`created_by`),
  KEY `updated_by` (`updated_by`),
  KEY `stu_master_stu_info_id_fng` (`stu_master_stu_info_id`),
  KEY `student_master_house_id` (`student_master_house_id`),
  KEY `mentor_id` (`mentor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `stu_info` (
  `stu_info_id` int(11) NOT NULL AUTO_INCREMENT,
  `stu_unique_id` varchar(20) DEFAULT NULL,
  `stu_aadhaar` bigint(20) DEFAULT NULL,
  `passport` text DEFAULT NULL,
  `driving_license` text DEFAULT NULL,
  `voter_id` text DEFAULT NULL,
  `pan_no` text DEFAULT NULL,
  `stu_title` varchar(15) DEFAULT NULL,
  `stu_first_name` varchar(50) DEFAULT NULL,
  `stu_middle_name` varchar(50) DEFAULT NULL,
  `stu_last_name` varchar(50) DEFAULT NULL,
  `stu_gender` varchar(20) DEFAULT NULL,
  `stu_dob` date DEFAULT NULL,
  `stu_email_id` varchar(200) DEFAULT NULL,
  `stu_domain_email_id` text DEFAULT NULL,
  `stu_bloodgroup` varchar(15) DEFAULT 'Unknown',
  `stu_height` text DEFAULT NULL,
  `stu_weight` text DEFAULT NULL,
  `visionle` text DEFAULT NULL,
  `visionre` text DEFAULT NULL,
  `stu_birthplace` varchar(45) DEFAULT NULL,
  `stu_religion` varchar(50) DEFAULT NULL,
  `stu_admission_date` date DEFAULT NULL,
  `stu_photo` varchar(150) DEFAULT NULL,
  `stu_languages` varchar(255) DEFAULT NULL,
  `stu_hobbies` text DEFAULT NULL,
  `stu_mobile_no` bigint(20) DEFAULT NULL,
  `stu_whatsapp_no` bigint(20) DEFAULT NULL,
  `stu_identification_mark` text DEFAULT NULL,
  `stu_rank_type` text DEFAULT NULL,
  `stu_rank` bigint(20) NOT NULL DEFAULT 0,
  `stu_thumb` bigint(20) NOT NULL DEFAULT 0,
  `is_hostel` varchar(3) NOT NULL DEFAULT 'No',
  `is_transport` varchar(1) NOT NULL DEFAULT 'N',
  `is_lunch` varchar(1) NOT NULL DEFAULT 'N',
  `is_nss` varchar(1) NOT NULL DEFAULT 'N',
  `food_preference` text DEFAULT NULL,
  `court_proceedings` varchar(1) NOT NULL DEFAULT 'N',
  `court_detail` text DEFAULT NULL,
  `chronic_ailments` varchar(1) NOT NULL DEFAULT 'N',
  `chronic_ailments_details` text DEFAULT NULL,
  `stu_info_stu_master_id` int(11) DEFAULT NULL,
  `passout_institute_id` bigint(20) NOT NULL DEFAULT 0,
  PRIMARY KEY (`stu_info_id`),
  UNIQUE KEY `stu_unique_id` (`stu_unique_id`),
  KEY `stu_info_stu_master_id` (`stu_info_stu_master_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `stu_address` (
  `stu_address_id` int(11) NOT NULL AUTO_INCREMENT,
  `stu_cadd` varchar(255) DEFAULT NULL,
  `stu_cadd_city` int(11) DEFAULT NULL,
  `stu_cadd_state` int(11) DEFAULT NULL,
  `stu_cadd_country` int(11) DEFAULT NULL,
  `stu_cadd_pincode` int(11) DEFAULT NULL,
  `stu_cadd_house_no` varchar(25) DEFAULT NULL,
  `stu_cadd_phone_no` varchar(25) DEFAULT NULL,
  `stu_padd` varchar(255) DEFAULT NULL,
  `stu_padd_city` int(11) DEFAULT NULL,
  `stu_padd_state` int(11) DEFAULT NULL,
  `stu_padd_country` int(11) DEFAULT NULL,
  `stu_padd_pincode` int(11) DEFAULT NULL,
  `stu_padd_house_no` varchar(25) DEFAULT NULL,
  `stu_padd_phone_no` varchar(25) DEFAULT NULL,
  PRIMARY KEY (`stu_address_id`),
  KEY `stu_cadd_city` (`stu_cadd_city`),
  KEY `stu_cadd_state` (`stu_cadd_state`),
  KEY `stu_cadd_country` (`stu_cadd_country`),
  KEY `stu_padd_city` (`stu_padd_city`),
  KEY `stu_padd_state` (`stu_padd_state`),
  KEY `stu_padd_country` (`stu_padd_country`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `stu_docs` (
  `stu_docs_id` int(11) NOT NULL AUTO_INCREMENT,
  `stu_docs_details` varchar(100) DEFAULT NULL,
  `stu_docs_category_id` int(11) NOT NULL,
  `stu_docs_path` varchar(150) NOT NULL,
  `stu_docs_submited_at` datetime DEFAULT NULL,
  `stu_docs_status` tinyint(1) NOT NULL DEFAULT 0,
  `stu_docs_stu_master_id` int(11) NOT NULL,
  `created_by` int(11) NOT NULL,
  PRIMARY KEY (`stu_docs_id`),
  KEY `created_by` (`created_by`),
  KEY `stu_docs_stu_master_id` (`stu_docs_stu_master_id`),
  KEY `stu_docs_category_id` (`stu_docs_category_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `stu_guardians` (
  `stu_guardian_id` int(11) NOT NULL AUTO_INCREMENT,
  `guardian_name` varchar(65) DEFAULT NULL,
  `guardian_relation` varchar(30) DEFAULT NULL,
  `guardian_mobile_no` text DEFAULT NULL,
  `guardian_whatsapp_no` bigint(20) DEFAULT NULL,
  `guardian_phone_no` varchar(25) DEFAULT NULL,
  `guardian_qualification` varchar(50) DEFAULT NULL,
  `guardian_occupation` varchar(50) DEFAULT NULL,
  `guardian_income` varchar(50) DEFAULT NULL,
  `guardian_email` varchar(65) DEFAULT NULL,
  `guardian_home_address` varchar(255) DEFAULT NULL,
  `guardian_office_address` varchar(255) DEFAULT NULL,
  `is_emg_contact` tinyint(1) NOT NULL DEFAULT 0,
  `guardia_stu_master_id` int(11) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`stu_guardian_id`),
  UNIQUE KEY `guardian_email` (`guardian_email`),
  KEY `guardia_stu_master_id` (`guardia_stu_master_id`),
  KEY `updated_by` (`updated_by`),
  KEY `created_by` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `stu_status` (
  `stu_status_id` int(11) NOT NULL AUTO_INCREMENT,
  `stu_status_name` varchar(50) NOT NULL,
  `stu_status_description` varchar(100) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`stu_status_id`),
  UNIQUE KEY `stu_status_name` (`stu_status_name`),
  KEY `updated_by` (`updated_by`),
  KEY `created_by` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `stu_category` (
  `stu_category_id` int(11) NOT NULL AUTO_INCREMENT,
  `stu_category_name` varchar(50) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`stu_category_id`),
  KEY `updated_by` (`updated_by`),
  KEY `created_by` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `users` (
  `user_id` int(11) NOT NULL AUTO_INCREMENT,
  `user_login_id` varchar(65) NOT NULL,
  `user_password` varchar(150) NOT NULL,
  `user_type` char(2) NOT NULL,
  `is_block` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `user_login_id` (`user_login_id`),
  KEY `updated_by` (`updated_by`),
  KEY `created_by` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;


-- Student module runtime PostgreSQL schema: profiles, guardians, addresses, admission and login links.
CREATE TABLE IF NOT EXISTS stu_category (
 stu_category_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,stu_category_name VARCHAR(50) NOT NULL UNIQUE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),created_by BIGINT REFERENCES users(user_id),updated_at TIMESTAMPTZ,updated_by BIGINT REFERENCES users(user_id)
);
CREATE TABLE IF NOT EXISTS stu_status (
 stu_status_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,stu_status_name VARCHAR(50) NOT NULL UNIQUE,allows_login BOOLEAN NOT NULL DEFAULT TRUE
);
INSERT INTO stu_status(stu_status_name,allows_login) VALUES('Active',TRUE),('Inactive',FALSE),('Graduated',FALSE),('Transferred',FALSE) ON CONFLICT(stu_status_name) DO NOTHING;
CREATE SEQUENCE IF NOT EXISTS student_registration_seq;
CREATE TABLE IF NOT EXISTS stu_info (
 stu_info_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 stu_unique_id VARCHAR(50) NOT NULL UNIQUE,stu_first_name VARCHAR(50) NOT NULL,stu_middle_name VARCHAR(50),stu_last_name VARCHAR(50),
 stu_dob DATE NOT NULL,stu_email_id VARCHAR(150),stu_domain_email_id VARCHAR(150),stu_mobile_no VARCHAR(20),details JSONB NOT NULL DEFAULT '{}'
);
CREATE UNIQUE INDEX IF NOT EXISTS stu_info_registration_unique ON stu_info(upper(stu_unique_id));
CREATE TABLE IF NOT EXISTS stu_master (
 stu_master_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 stu_master_stu_info_id BIGINT NOT NULL UNIQUE REFERENCES stu_info(stu_info_id),stu_master_user_id BIGINT NOT NULL UNIQUE REFERENCES students(user_id),
 stu_master_category_id BIGINT NOT NULL REFERENCES stu_category(stu_category_id),stu_master_nationality_id BIGINT REFERENCES nationality(nationality_id),
 stu_master_course_id BIGINT NOT NULL REFERENCES courses(course_id),stu_master_batch_id BIGINT NOT NULL,
 stu_master_section_id BIGINT NOT NULL REFERENCES section(s_id),semester_registered SMALLINT NOT NULL DEFAULT 1,
 stu_master_stu_status_id BIGINT NOT NULL REFERENCES stu_status(stu_status_id),allotment_status SMALLINT NOT NULL DEFAULT 0,
 academic_details JSONB NOT NULL DEFAULT '{}',entrance_details JSONB NOT NULL DEFAULT '{}',paid_preferences JSONB NOT NULL DEFAULT '{}',
 deleted_at TIMESTAMPTZ,deleted_by BIGINT REFERENCES users(user_id),
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),created_by BIGINT REFERENCES users(user_id),updated_at TIMESTAMPTZ,updated_by BIGINT REFERENCES users(user_id),
 FOREIGN KEY(stu_master_batch_id,stu_master_course_id) REFERENCES batches(batch_id,batch_course_id)
);
CREATE TABLE IF NOT EXISTS stu_address (
 stu_address_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,student_id BIGINT NOT NULL REFERENCES stu_master(stu_master_id),
 address_type VARCHAR(10) NOT NULL CHECK(address_type IN('current','permanent')),address_text TEXT,country_id INTEGER REFERENCES country(country_id),
 state_id INTEGER REFERENCES state(state_id),city_id INTEGER REFERENCES city(city_id),pincode VARCHAR(12),house_no VARCHAR(25),phone_no VARCHAR(25),UNIQUE(student_id,address_type)
);
CREATE TABLE IF NOT EXISTS stu_guardians (
 stu_guardian_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,guardia_stu_master_id BIGINT NOT NULL REFERENCES stu_master(stu_master_id),
 guardian_relation VARCHAR(10) NOT NULL CHECK(guardian_relation IN('father','mother')),guardian_name VARCHAR(65),guardian_mobile_no VARCHAR(20),guardian_whatsapp_no VARCHAR(20),guardian_email VARCHAR(150),guardian_occupation VARCHAR(200),guardian_income NUMERIC(14,2),UNIQUE(guardia_stu_master_id,guardian_relation)
);
ALTER TABLE course_students ADD COLUMN IF NOT EXISTS section_id BIGINT REFERENCES section(s_id);
ALTER TABLE students DROP CONSTRAINT IF EXISTS students_semester_check;
DO $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='students_semester_positive' AND conrelid='students'::regclass) THEN
  ALTER TABLE students ADD CONSTRAINT students_semester_positive CHECK(semester>0) NOT VALID;
 END IF;
END $$;
CREATE INDEX IF NOT EXISTS stu_master_cohort_idx ON stu_master(stu_master_course_id,stu_master_batch_id,stu_master_section_id);
CREATE INDEX IF NOT EXISTS stu_master_deleted_idx ON stu_master(deleted_at);

ALTER TABLE users ALTER COLUMN mobile TYPE VARCHAR(20);

-- TimeTable
CREATE TABLE `timetable_master` (
  `tt_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `tt_course_id` int(11) DEFAULT NULL,
  `tt_batch_id` varchar(100) DEFAULT NULL,
  `tt_semester` int(11) DEFAULT NULL,
  `tt_section_house_type` varchar(1) DEFAULT NULL,
  `tt_section_house_id` int(11) DEFAULT NULL,
  `starttime` text DEFAULT NULL,
  `endtime` text DEFAULT NULL,
  `lunch_time_start` text DEFAULT NULL,
  `lunch_time_end` text DEFAULT NULL,
  `hobby_day` int(11) DEFAULT 0,
  `hobby_time_start` text DEFAULT NULL,
  `hobby_time_end` text DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  `report_send` tinyint(1) NOT NULL DEFAULT 2,
  `schedule_date` date DEFAULT NULL,
  `onlineclasses` int(11) NOT NULL DEFAULT 0,
  `offlineclasses` int(11) NOT NULL DEFAULT 0,
  `break_time_start_1` text DEFAULT NULL,
  `break_time_start_2` text DEFAULT NULL,
  `break_time_start_3` text DEFAULT NULL,
  `break_time_start_4` text DEFAULT NULL,
  `break_time_start_5` text DEFAULT NULL,
  `break_time_start_6` text DEFAULT NULL,
  `break_time_end_1` text DEFAULT NULL,
  `break_time_end_2` text DEFAULT NULL,
  `break_time_end_3` text DEFAULT NULL,
  `break_time_end_4` text DEFAULT NULL,
  `break_time_end_5` text DEFAULT NULL,
  `break_time_end_6` text DEFAULT NULL,
  PRIMARY KEY (`tt_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `offline_timetable` (
  `ot_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `tt_id` int(11) NOT NULL,
  `ot_day` int(11) NOT NULL,
  `ot_from` time NOT NULL,
  `ot_to` time NOT NULL,
  `ot_subject_id` int(11) NOT NULL,
  `ot_teacher_id` int(11) NOT NULL,
  `ot_link` text NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`ot_id`),
  KEY `updated_by` (`updated_by`),
  KEY `created_by` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `tablesheet` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `cell` bigint(20) DEFAULT NULL,
  `course_tt` bigint(20) DEFAULT NULL,
  `batch_tt` bigint(20) DEFAULT NULL,
  `semester_tt` int(11) DEFAULT NULL,
  `sectionhousetype_tt` varchar(1) DEFAULT NULL,
  `sectionhousename_tt` bigint(20) DEFAULT NULL,
  `subject_tt` bigint(20) DEFAULT NULL,
  `student_group` text DEFAULT NULL,
  `faculty_namett` bigint(20) DEFAULT NULL,
  `faculty_typett` varchar(1) DEFAULT NULL,
  `tt_day` int(11) DEFAULT NULL,
  `timefrom` text DEFAULT NULL,
  `timeto` text DEFAULT NULL,
  `oddeven` varchar(1) DEFAULT NULL,
  `room_no` text DEFAULT NULL,
  `created_by` bigint(20) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_by` bigint(20) DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

CREATE TABLE `tablesheet_public` (
  `cell` bigint(20) NOT NULL,
  `course_tt` bigint(20) NOT NULL,
  `batch_tt` bigint(20) NOT NULL,
  `semester_tt` int(11) NOT NULL,
  `sectionhousetype_tt` varchar(1) NOT NULL,
  `sectionhousename_tt` bigint(20) NOT NULL,
  `subject_tt` bigint(20) NOT NULL,
  `student_group` text NOT NULL,
  `faculty_namett` bigint(20) NOT NULL,
  `faculty_typett` varchar(1) NOT NULL,
  `tt_day` int(11) NOT NULL,
  `timefrom` text NOT NULL,
  `timeto` text NOT NULL,
  `oddeven` varchar(1) NOT NULL,
  `room_no` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

CREATE TABLE `floormanager` (
  `fm_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `class_date` date DEFAULT NULL,
  `tablesheet_id` bigint(20) NOT NULL,
  `cell_id` bigint(20) NOT NULL,
  `mastertimetable_id` bigint(20) NOT NULL,
  `subject_alias` bigint(20) NOT NULL,
  `subject_taught` bigint(20) NOT NULL DEFAULT 0,
  `is_group` text NOT NULL,
  `gr_attended` text NOT NULL,
  `teacher_name` bigint(20) NOT NULL,
  `taken_by` bigint(20) NOT NULL DEFAULT 0,
  `room_no` text NOT NULL,
  `room_occupied` text NOT NULL,
  `late_to_class` int(11) NOT NULL DEFAULT 0,
  `early_from_class` int(11) NOT NULL DEFAULT 0,
  `remarks` text NOT NULL,
  `class_not_held` text NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `created_by` bigint(20) NOT NULL,
  `mail_stats` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`fm_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `tablesheet_floormanager` (
  `today_date` date DEFAULT NULL,
  `course_tt` bigint(20) NOT NULL,
  `batch_tt` bigint(20) NOT NULL,
  `semester_tt` int(11) NOT NULL,
  `sectionhousetype_tt` varchar(1) NOT NULL,
  `sectionhousename_tt` bigint(20) NOT NULL,
  `subject_tt` bigint(20) NOT NULL,
  `subject_taught` bigint(20) NOT NULL,
  `student_group` text NOT NULL,
  `group_attended` text NOT NULL,
  `faculty_namett` bigint(20) NOT NULL,
  `faculty_present` bigint(20) NOT NULL,
  `tt_day` int(11) NOT NULL,
  `timefrom` text NOT NULL,
  `timeto` text NOT NULL,
  `oddeven` varchar(1) NOT NULL,
  `room_no` text NOT NULL,
  `room_occupied` text NOT NULL,
  `class_cancelled` tinyint(1) NOT NULL DEFAULT 0,
  `reason` text NOT NULL,
  `is_late` text NOT NULL,
  `is_early` text NOT NULL,
  `abnormality_observed` text NOT NULL,
  `created_by` bigint(20) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_by` bigint(20) NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  `calculation_status` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

CREATE TABLE `rooms` (
  `ids` bigint(20) NOT NULL AUTO_INCREMENT,
  `room_no` text NOT NULL,
  `room_type` text NOT NULL,
  `max_stu_strength` int(11) NOT NULL DEFAULT 0,
  `room_desc` text DEFAULT NULL,
  `created_by` bigint(20) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_by` bigint(20) DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`ids`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;


-- Connected Timetable runtime schema (PostgreSQL)
-- Runtime equivalents of the timetable tables in ABITDB.sql use existing ERP keys.
CREATE TABLE IF NOT EXISTS timetable_rooms (
 room_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,room_no VARCHAR(50) NOT NULL UNIQUE,
 building VARCHAR(100) NOT NULL,floor_name VARCHAR(30) NOT NULL,capacity INTEGER NOT NULL CHECK(capacity BETWEEN 1 AND 1000),
 room_type VARCHAR(20) NOT NULL CHECK(room_type IN('CLASSROOM','LAB','SEMINAR')),manager_id BIGINT REFERENCES users(user_id),is_active BOOLEAN NOT NULL DEFAULT TRUE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),created_by BIGINT REFERENCES users(user_id),updated_at TIMESTAMPTZ,updated_by BIGINT REFERENCES users(user_id)
);
CREATE TABLE IF NOT EXISTS timetable_schedules (
 timetable_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,batch_semester_id BIGINT NOT NULL REFERENCES semester_defined(id),section_id BIGINT NOT NULL REFERENCES section(s_id),
 timetable_name VARCHAR(150) NOT NULL,effective_from DATE NOT NULL,effective_to DATE,is_published BOOLEAN NOT NULL DEFAULT FALSE,
 created_by BIGINT REFERENCES users(user_id),created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),updated_at TIMESTAMPTZ,updated_by BIGINT REFERENCES users(user_id),
 CHECK(effective_to IS NULL OR effective_to>=effective_from)
);
CREATE TABLE IF NOT EXISTS timetable_schedule_cells (
 cell_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,timetable_id BIGINT NOT NULL REFERENCES timetable_schedules(timetable_id) ON DELETE CASCADE,
 day_of_week SMALLINT NOT NULL CHECK(day_of_week BETWEEN 1 AND 7),period_number SMALLINT NOT NULL CHECK(period_number BETWEEN 1 AND 20),
 start_time TIME NOT NULL,end_time TIME NOT NULL,allotment_id BIGINT NOT NULL REFERENCES section_house_subject_teacher(shst_id),
 room_id BIGINT NOT NULL REFERENCES timetable_rooms(room_id),room_no VARCHAR(50),notes VARCHAR(500),CHECK(end_time>start_time),UNIQUE(timetable_id,day_of_week,period_number)
);
CREATE TABLE IF NOT EXISTS timetable_course_access (
 access_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,user_id BIGINT NOT NULL REFERENCES users(user_id),
 batch_semester_id BIGINT NOT NULL REFERENCES semester_defined(id),section_id BIGINT NOT NULL REFERENCES section(s_id),is_active BOOLEAN NOT NULL DEFAULT TRUE,
 UNIQUE(user_id,batch_semester_id,section_id)
);
-- employee_id refers to the employee's linked Faculty user ID, including legacy Faculty accounts.
CREATE TABLE IF NOT EXISTS timetable_faculty_access (
 access_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,user_id BIGINT NOT NULL REFERENCES users(user_id),employee_id BIGINT NOT NULL REFERENCES users(user_id),
 is_active BOOLEAN NOT NULL DEFAULT TRUE,UNIQUE(user_id,employee_id)
);
CREATE INDEX IF NOT EXISTS timetable_cells_allotment_idx ON timetable_schedule_cells(allotment_id);
CREATE INDEX IF NOT EXISTS timetable_cells_room_idx ON timetable_schedule_cells(room_id,day_of_week);
CREATE INDEX IF NOT EXISTS timetable_schedule_dates_idx ON timetable_schedules(effective_from,effective_to) WHERE is_published;

-- Student Mentoring

CREATE TABLE `studentcounselling` (
  `sc_id` int(11) NOT NULL AUTO_INCREMENT,
  `sc_student_master_id` int(11) DEFAULT NULL,
  `sc_student_user_id` int(11) DEFAULT NULL,
  `sc_emp_master_id` int(11) DEFAULT NULL,
  `sc_emp_user_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `discussed_with` varchar(2) DEFAULT NULL,
  `discussion_type` text DEFAULT NULL,
  `dis_subject` text DEFAULT NULL,
  `mentor_remarks` text DEFAULT NULL,
  `reviewer_one` int(11) DEFAULT NULL,
  `reviewerone_at` datetime DEFAULT NULL,
  `reviewerone_remarks` text DEFAULT NULL,
  `reviewer_two` int(11) DEFAULT NULL,
  `reviewertwo_at` datetime DEFAULT NULL,
  `reviewertwo_remarks` text DEFAULT NULL,
  `reviewer_chief` int(11) DEFAULT NULL,
  `reviewerchief_at` datetime DEFAULT NULL,
  `reviewerchief_remarks` text DEFAULT NULL,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  `urgent` tinyint(1) NOT NULL DEFAULT 0,
  `firstreviewer_verified` text DEFAULT NULL,
  `grading_to_mentor` text DEFAULT NULL,
  `suggestion_tomentor` text DEFAULT NULL,
  `fees_pay_tran_mode` text DEFAULT NULL,
  `fees_pay_tran_date` date DEFAULT NULL,
  `fees_pay_tran_amount` bigint(20) DEFAULT NULL,
  `current_due` int(11) DEFAULT NULL,
  PRIMARY KEY (`sc_id`),
  KEY `sc_student_master_id` (`sc_student_master_id`),
  KEY `sc_student_user_id` (`sc_student_user_id`),
  KEY `sc_emp_master_id` (`sc_emp_master_id`),
  KEY `sc_emp_user_id` (`sc_emp_user_id`),
  KEY `reviewer_one` (`reviewer_one`),
  KEY `reviewer_two` (`reviewer_two`),
  KEY `reviewer_chief` (`reviewer_chief`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `mentorreviewer` (
  `r_id` int(11) NOT NULL AUTO_INCREMENT,
  `r_mentor` int(11) NOT NULL,
  `r_reviewerone` int(11) NOT NULL,
  `r_reviewertwo` int(11) NOT NULL,
  `r_reviewerchief` int(11) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`r_id`),
  UNIQUE KEY `r_mentor` (`r_mentor`,`r_reviewerone`,`r_reviewertwo`,`r_reviewerchief`),
  KEY `created_by` (`created_by`),
  KEY `updated_by` (`updated_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `stu_master` (
  `stu_master_id` int(11) NOT NULL AUTO_INCREMENT,
  `stu_master_stu_info_id` int(11) DEFAULT NULL,
  `stu_master_user_id` int(11) DEFAULT NULL,
  `stu_master_nationality_id` int(11) DEFAULT NULL,
  `stu_master_category_id` int(11) DEFAULT NULL,
  `stu_master_course_id` int(11) DEFAULT NULL,
  `stu_master_batch_id` int(11) DEFAULT NULL,
  `stu_master_section_id` int(11) DEFAULT NULL,
  `student_master_house_id` int(11) NOT NULL DEFAULT 1,
  `grop` int(11) NOT NULL DEFAULT 0,
  `att_serial` text DEFAULT NULL,
  `honors` varchar(1) NOT NULL DEFAULT 'N',
  `minor` varchar(1) NOT NULL DEFAULT 'N',
  `vcourse1` int(11) DEFAULT NULL,
  `vcourse2` int(11) DEFAULT NULL,
  `vcourse3` int(11) DEFAULT NULL,
  `vcourse4` bigint(20) DEFAULT NULL,
  `vcourse5` bigint(20) DEFAULT NULL,
  `vcourse6` bigint(20) DEFAULT NULL,
  `vcourse7` bigint(20) DEFAULT NULL,
  `vcourse8` bigint(20) DEFAULT NULL,
  `vcourse9` bigint(20) DEFAULT NULL,
  `vcourse10` bigint(20) DEFAULT NULL,
  `vcourse11` bigint(20) DEFAULT NULL,
  `vcourse12` bigint(20) DEFAULT NULL,
  `vcourse13` bigint(20) DEFAULT NULL,
  `vcourse14` bigint(20) DEFAULT NULL,
  `vcourse15` bigint(20) DEFAULT NULL,
  `vcourse16` bigint(20) DEFAULT NULL,
  `mentor_id` bigint(20) NOT NULL DEFAULT 0,
  `stu_master_stu_status_id` int(11) NOT NULL DEFAULT 0,
  `stu_master_stu_address_id` int(11) DEFAULT NULL,
  `tenthschoolname` text DEFAULT NULL,
  `tenthpasoutyear` year(4) DEFAULT NULL,
  `tenth` decimal(4,2) NOT NULL DEFAULT 0.00,
  `twelevethcollegename` text DEFAULT NULL,
  `twelevethpasoutyear` year(4) DEFAULT NULL,
  `tweleveth` decimal(4,2) NOT NULL DEFAULT 0.00,
  `diplomacollegename` text DEFAULT NULL,
  `diplomapasoutyear` year(4) DEFAULT NULL,
  `diploma` decimal(4,2) NOT NULL DEFAULT 0.00,
  `babsccollegename` bigint(20) NOT NULL DEFAULT 0,
  `babscpasoutyear` year(4) DEFAULT NULL,
  `babsc` decimal(4,2) NOT NULL DEFAULT 0.00,
  `bcacollegename` bigint(20) NOT NULL DEFAULT 0,
  `bcapasoutyear` year(4) DEFAULT NULL,
  `bca` decimal(4,2) NOT NULL DEFAULT 0.00,
  `bbacollegename` bigint(20) NOT NULL DEFAULT 0,
  `bbapasoutyear` year(4) DEFAULT NULL,
  `bba` decimal(4,2) NOT NULL DEFAULT 0.00,
  `btechcollegename` bigint(20) NOT NULL DEFAULT 0,
  `btechpasoutyear` year(4) DEFAULT NULL,
  `btech` decimal(4,2) NOT NULL DEFAULT 0.00,
  `other_exam` text DEFAULT NULL,
  `other_mark` decimal(4,2) DEFAULT NULL,
  `sem1` decimal(4,2) NOT NULL DEFAULT 0.00,
  `sem2` decimal(4,2) NOT NULL DEFAULT 0.00,
  `sem3` decimal(4,2) NOT NULL DEFAULT 0.00,
  `sem4` decimal(4,2) NOT NULL DEFAULT 0.00,
  `sem5` decimal(4,2) NOT NULL DEFAULT 0.00,
  `sem6` decimal(4,2) NOT NULL DEFAULT 0.00,
  `sem7` decimal(4,2) NOT NULL DEFAULT 0.00,
  `sem8` decimal(4,2) NOT NULL DEFAULT 0.00,
  `hostel_room` text DEFAULT NULL,
  `boarding1` bigint(20) NOT NULL DEFAULT 0,
  `boarding2` bigint(20) NOT NULL DEFAULT 0,
  `boarding3` bigint(20) NOT NULL DEFAULT 0,
  `career_objective` bigint(20) NOT NULL DEFAULT 0,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `semester_registered` int(11) NOT NULL DEFAULT 0,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  `iticollegename` bigint(20) NOT NULL DEFAULT 0,
  `itiyear` year(4) DEFAULT NULL,
  `itimark` decimal(4,2) NOT NULL DEFAULT 0.00,
  `allotment_status` tinyint(1) NOT NULL DEFAULT 0,
  `is_icard_available` int(11) NOT NULL DEFAULT 0,
  `interested_placement` varchar(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`stu_master_id`),
  UNIQUE KEY `stu_master_stu_info_id` (`stu_master_stu_info_id`),
  UNIQUE KEY `stu_master_user_id` (`stu_master_user_id`),
  KEY `stu_master_nationality_id` (`stu_master_nationality_id`),
  KEY `stu_master_category` (`stu_master_category_id`),
  KEY `stu_master_course_id` (`stu_master_course_id`),
  KEY `stu_master_batch_id` (`stu_master_batch_id`),
  KEY `stu_master_section_id` (`stu_master_section_id`),
  KEY `stu_master_stu_address_id` (`stu_master_stu_address_id`),
  KEY `created_by` (`created_by`),
  KEY `updated_by` (`updated_by`),
  KEY `stu_master_stu_info_id_fng` (`stu_master_stu_info_id`),
  KEY `student_master_house_id` (`student_master_house_id`),
  KEY `mentor_id` (`mentor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;


-- Connected Student Mentoring runtime schema (PostgreSQL; source MySQL definitions above)
-- PostgreSQL runtime mapping of the supplied studentcounselling / mentorreviewer tables.
-- All mentor/reviewer IDs refer to emp_master; user IDs are separate linked login accounts.
ALTER TABLE stu_master ADD COLUMN IF NOT EXISTS mentor_id BIGINT REFERENCES emp_master(emp_master_id);
ALTER TABLE stu_master ADD COLUMN IF NOT EXISTS mentor_allotted_at TIMESTAMPTZ;
ALTER TABLE stu_master ADD COLUMN IF NOT EXISTS mentor_allotted_by BIGINT REFERENCES users(user_id);
CREATE INDEX IF NOT EXISTS stu_master_mentor_idx ON stu_master(mentor_id);
CREATE TABLE IF NOT EXISTS mentorreviewer (
 r_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,r_mentor BIGINT NOT NULL UNIQUE REFERENCES emp_master(emp_master_id),
 r_reviewerone BIGINT NOT NULL REFERENCES emp_master(emp_master_id),r_reviewertwo BIGINT NOT NULL REFERENCES emp_master(emp_master_id),r_reviewerchief BIGINT NOT NULL REFERENCES emp_master(emp_master_id),
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),created_by BIGINT NOT NULL REFERENCES users(user_id),updated_at TIMESTAMPTZ,updated_by BIGINT REFERENCES users(user_id),
 is_status SMALLINT NOT NULL DEFAULT 1 CHECK(is_status IN(0,1)),
 CHECK(r_mentor<>r_reviewerone AND r_mentor<>r_reviewertwo AND r_mentor<>r_reviewerchief AND r_reviewerone<>r_reviewertwo AND r_reviewerone<>r_reviewerchief AND r_reviewertwo<>r_reviewerchief)
);
CREATE TABLE IF NOT EXISTS studentcounselling (
 sc_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,sc_student_master_id BIGINT NOT NULL REFERENCES stu_master(stu_master_id),sc_student_user_id BIGINT NOT NULL REFERENCES students(user_id),
 sc_emp_master_id BIGINT NOT NULL REFERENCES emp_master(emp_master_id),sc_emp_user_id BIGINT NOT NULL REFERENCES users(user_id),created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),created_by BIGINT NOT NULL REFERENCES users(user_id),
 discussed_with VARCHAR(2) NOT NULL CHECK(discussed_with IN('S','P','B')),discussion_type VARCHAR(30) NOT NULL,dis_subject VARCHAR(200) NOT NULL,mentor_remarks TEXT NOT NULL,
 reviewer_one BIGINT NOT NULL REFERENCES emp_master(emp_master_id),reviewerone_at TIMESTAMPTZ,reviewerone_remarks TEXT,reviewerone_by BIGINT REFERENCES users(user_id),
 reviewer_two BIGINT NOT NULL REFERENCES emp_master(emp_master_id),reviewertwo_at TIMESTAMPTZ,reviewertwo_remarks TEXT,reviewertwo_by BIGINT REFERENCES users(user_id),
 reviewer_chief BIGINT NOT NULL REFERENCES emp_master(emp_master_id),reviewerchief_at TIMESTAMPTZ,reviewerchief_remarks TEXT,reviewerchief_by BIGINT REFERENCES users(user_id),
 is_status SMALLINT NOT NULL DEFAULT 0 CHECK(is_status IN(0,1,2)),urgent SMALLINT NOT NULL DEFAULT 0 CHECK(urgent IN(0,1)),
 firstreviewer_verified VARCHAR(3) CHECK(firstreviewer_verified IN('YES','NO')),grading_to_mentor VARCHAR(30),suggestion_tomentor TEXT,
 fees_pay_tran_mode VARCHAR(30),fees_pay_tran_date DATE,fees_pay_tran_amount NUMERIC(14,2) CHECK(fees_pay_tran_amount>=0),current_due NUMERIC(14,2) CHECK(current_due>=0),
 updated_at TIMESTAMPTZ,updated_by BIGINT REFERENCES users(user_id)
);
CREATE TABLE IF NOT EXISTS mentor_allotment_history (
 id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,student_id BIGINT NOT NULL REFERENCES stu_master(stu_master_id),
 previous_mentor_id BIGINT REFERENCES emp_master(emp_master_id),mentor_id BIGINT REFERENCES emp_master(emp_master_id),
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),created_by BIGINT NOT NULL REFERENCES users(user_id)
);
CREATE INDEX IF NOT EXISTS counselling_student_idx ON studentcounselling(sc_student_master_id,created_at);
CREATE INDEX IF NOT EXISTS counselling_mentor_idx ON studentcounselling(sc_emp_master_id);
CREATE INDEX IF NOT EXISTS counselling_first_reviewer_idx ON studentcounselling(reviewer_one,is_status);
CREATE INDEX IF NOT EXISTS counselling_second_reviewer_idx ON studentcounselling(reviewer_two);
CREATE INDEX IF NOT EXISTS counselling_chief_reviewer_idx ON studentcounselling(reviewer_chief);


-- User Management runtime schema (PostgreSQL)
-- Access roles supplement the existing login/profile account types in user_roles.
CREATE TABLE IF NOT EXISTS access_routes (
 route_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,route_key VARCHAR(100) NOT NULL UNIQUE,module VARCHAR(50) NOT NULL,
 label VARCHAR(150) NOT NULL,method VARCHAR(10) NOT NULL CHECK(method IN('GET','POST','PATCH','PUT','DELETE')),path_pattern VARCHAR(200) NOT NULL,
 is_active BOOLEAN NOT NULL DEFAULT TRUE,created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),updated_at TIMESTAMPTZ,updated_by BIGINT REFERENCES users(user_id),UNIQUE(method,path_pattern)
);
CREATE TABLE IF NOT EXISTS access_permissions (
 permission_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,name VARCHAR(100) NOT NULL UNIQUE,description VARCHAR(500),is_active BOOLEAN NOT NULL DEFAULT TRUE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),created_by BIGINT NOT NULL REFERENCES users(user_id),updated_at TIMESTAMPTZ,updated_by BIGINT REFERENCES users(user_id)
);
CREATE TABLE IF NOT EXISTS access_roles (
 access_role_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,name VARCHAR(100) NOT NULL UNIQUE,description VARCHAR(500),is_active BOOLEAN NOT NULL DEFAULT TRUE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),created_by BIGINT NOT NULL REFERENCES users(user_id),updated_at TIMESTAMPTZ,updated_by BIGINT REFERENCES users(user_id)
);
CREATE TABLE IF NOT EXISTS access_permission_routes (
 permission_id BIGINT NOT NULL REFERENCES access_permissions(permission_id) ON DELETE CASCADE,route_id BIGINT NOT NULL REFERENCES access_routes(route_id),PRIMARY KEY(permission_id,route_id)
);
CREATE TABLE IF NOT EXISTS access_role_permissions (
 access_role_id BIGINT NOT NULL REFERENCES access_roles(access_role_id) ON DELETE CASCADE,permission_id BIGINT NOT NULL REFERENCES access_permissions(permission_id),PRIMARY KEY(access_role_id,permission_id)
);
CREATE TABLE IF NOT EXISTS access_assignments (
 user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,access_role_id BIGINT NOT NULL REFERENCES access_roles(access_role_id),
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),created_by BIGINT NOT NULL REFERENCES users(user_id),PRIMARY KEY(user_id,access_role_id)
);
CREATE TABLE IF NOT EXISTS access_audit (
 id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,actor_id BIGINT NOT NULL REFERENCES users(user_id),action VARCHAR(60) NOT NULL,record_id BIGINT,
 before_value JSONB,after_value JSONB,created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS access_assignments_role_idx ON access_assignments(access_role_id);

--Dashboard
CREATE TABLE `msg_of_day` (
  `msg_of_day_id` int(11) NOT NULL AUTO_INCREMENT,
  `msg_details` varchar(100) NOT NULL,
  `msg_user_type` char(3) NOT NULL DEFAULT '0',
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`msg_of_day_id`),
  UNIQUE KEY `msg_details` (`msg_details`),
  KEY `created_by` (`created_by`),
  KEY `updated_by` (`updated_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `notice` (
  `notice_id` int(11) NOT NULL AUTO_INCREMENT,
  `notice_title` varchar(25) NOT NULL,
  `notice_description` varchar(255) DEFAULT NULL,
  `notice_user_type` char(3) NOT NULL,
  `notice_date` date DEFAULT NULL,
  `notice_file_path` varchar(100) DEFAULT NULL,
  `rel_dept` text NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `is_status` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`notice_id`),
  KEY `created_by` (`created_by`),
  KEY `updated_by` (`updated_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;


-- Dashboard Configuration connected runtime schema (PostgreSQL)
-- Connected PostgreSQL equivalents of the supplied msg_of_day and notice tables.
CREATE TABLE IF NOT EXISTS msg_of_day (
 msg_of_day_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,msg_details VARCHAR(100) NOT NULL UNIQUE,
 msg_user_type VARCHAR(3) NOT NULL DEFAULT '0' CHECK(msg_user_type IN('0','STU','FAC','EMP','ADM')),
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),created_by BIGINT NOT NULL REFERENCES users(user_id),updated_at TIMESTAMPTZ,updated_by BIGINT REFERENCES users(user_id),
 is_status SMALLINT NOT NULL DEFAULT 1 CHECK(is_status IN(0,1))
);
CREATE TABLE IF NOT EXISTS notice (
 notice_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,notice_title VARCHAR(25) NOT NULL,notice_description VARCHAR(255),
 notice_user_type VARCHAR(3) NOT NULL DEFAULT '0' CHECK(notice_user_type IN('0','STU','FAC','EMP','ADM')),notice_date DATE,
 notice_file_path VARCHAR(100),rel_dept TEXT NOT NULL DEFAULT '',file_type VARCHAR(100),file_data BYTEA,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),created_by BIGINT NOT NULL REFERENCES users(user_id),updated_at TIMESTAMPTZ,updated_by BIGINT REFERENCES users(user_id),
 is_status SMALLINT NOT NULL DEFAULT 1 CHECK(is_status IN(0,1)),CHECK(file_data IS NULL OR octet_length(file_data)<=5242880)
);
CREATE TABLE IF NOT EXISTS notice_departments (
 notice_id BIGINT NOT NULL REFERENCES notice(notice_id) ON DELETE CASCADE,department_id BIGINT NOT NULL REFERENCES emp_department(emp_department_id),PRIMARY KEY(notice_id,department_id)
);
CREATE INDEX IF NOT EXISTS msg_of_day_published_idx ON msg_of_day(is_status,msg_user_type);
CREATE INDEX IF NOT EXISTS notice_published_idx ON notice(is_status,notice_date);


-- Connected OBE business tables in the ERP database
-- OBE business schema adapted from https://github.com/hodcse-coder/OBE
-- Source commit 14670a65e23171c170ff17e80962462208e57d17; schema only, no repository accounts or records.
CREATE SCHEMA IF NOT EXISTS obe;
DO $obe_bootstrap$ BEGIN
IF to_regclass('obe.department') IS NULL THEN
CREATE TABLE obe.academic_years (
    academic_year_id integer NOT NULL,
    academic_year character varying(20) NOT NULL,
    start_date date,
    end_date date,
    status character varying(20) DEFAULT 'Active'::character varying
);

CREATE TABLE obe.admission_batches (
    admission_batch_id integer NOT NULL,
    programme_id integer NOT NULL,
    start_academic_year_id integer NOT NULL,
    batch_code character varying(20) NOT NULL,
    admission_year integer NOT NULL,
    completion_year integer NOT NULL,
    status character varying(20) DEFAULT 'Active'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    department_id integer,
    duration_years integer DEFAULT 4,
    total_semesters integer DEFAULT 8,
    starting_academic_year character varying(20) DEFAULT ''::character varying,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    erp_id bigint,
    CONSTRAINT admission_batches_check CHECK ((completion_year > admission_year)),
    CONSTRAINT admission_batches_status_check CHECK (((status)::text = ANY (ARRAY[('Active'::character varying)::text, ('Completed'::character varying)::text, ('Inactive'::character varying)::text])))
);

CREATE TABLE obe.articulation_matrix (
    articulation_id integer NOT NULL,
    course_id integer NOT NULL,
    co_id integer NOT NULL,
    component_id integer DEFAULT 1 NOT NULL,
    articulation_level integer NOT NULL,
    academic_year character varying(20) DEFAULT '2024-25'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    department_id integer,
    programme_id integer,
    semester_id integer,
    outcome_id integer,
    department_name character varying(150),
    programme_name character varying(180),
    semester_name character varying(80),
    course_code character varying(40),
    course_name character varying(180),
    co_code character varying(20),
    co_statement text DEFAULT ''::text,
    outcome_type character varying(10),
    outcome_code character varying(20),
    outcome_title character varying(180) DEFAULT ''::character varying,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    attend integer DEFAULT 0,
    a1 integer DEFAULT 0,
    a2 integer DEFAULT 0,
    qt1 integer DEFAULT 0,
    qt2 integer DEFAULT 0,
    st1 integer DEFAULT 0,
    st2 integer DEFAULT 0,
    ct1 integer DEFAULT 0,
    ct2 integer DEFAULT 0,
    end_sem integer DEFAULT 0,
    CONSTRAINT articulation_matrix_articulation_level_check CHECK (((articulation_level >= 0) AND (articulation_level <= 3)))
);

CREATE TABLE obe.assessment_attainment_levels (
    level_id integer NOT NULL,
    academic_year character varying(20) NOT NULL,
    assessment_category character varying(120) NOT NULL,
    level_number integer NOT NULL,
    code character varying(10) NOT NULL,
    level_name character varying(80) NOT NULL,
    min_percentage numeric(6,2) NOT NULL,
    max_percentage numeric(6,2) NOT NULL,
    condition_text character varying(180) DEFAULT ''::character varying,
    remarks text DEFAULT ''::text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    level_no integer
);

CREATE TABLE obe.assessment_co_mapping (
    id integer NOT NULL,
    assessment_id integer,
    co_id integer,
    max_marks numeric(5,2)
);

CREATE TABLE obe.assessment_target_configuration (
    target_id integer NOT NULL,
    course_id integer NOT NULL,
    component_id integer NOT NULL,
    academic_year character varying(20) NOT NULL,
    weightage numeric(6,2) NOT NULL,
    target_average numeric(6,2),
    attainment_percentage numeric(6,2),
    level_code character varying(10),
    level_point integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT assessment_target_configuration_level_point_check CHECK (((level_point >= 1) AND (level_point <= 3)))
);

CREATE TABLE obe.assessments (
    assessment_id integer NOT NULL,
    course_id integer,
    assessment_name character varying(50),
    assessment_type character varying(50),
    max_marks numeric(5,2),
    weightage numeric(5,2)
);

CREATE TABLE obe.attainment_targets (
    target_id integer NOT NULL,
    course_id integer,
    academic_year character varying(20),
    level1_percent numeric(5,2),
    level2_percent numeric(5,2),
    level3_percent numeric(5,2)
);

CREATE TABLE obe.bloom_level (
    bloom_id integer NOT NULL,
    bloom_code character varying(20) NOT NULL,
    bloom_level character varying(80) NOT NULL,
    learning_outcome_verbs text NOT NULL
);

CREATE TABLE obe.co_attainment (
    attainment_id integer NOT NULL,
    course_id integer,
    co_id integer,
    academic_year character varying(20),
    internal_attainment numeric(5,2),
    external_attainment numeric(5,2),
    final_attainment numeric(5,2)
);

CREATE TABLE obe.co_attainment_calculation (
    calculation_id integer NOT NULL,
    course_id integer NOT NULL,
    co_id integer NOT NULL,
    academic_year character varying(20) NOT NULL,
    batch character varying(20),
    internal_attainment numeric(6,2),
    external_attainment numeric(6,2),
    overall_attainment numeric(6,2),
    internal_weightage numeric(5,2) DEFAULT 80,
    external_weightage numeric(5,2) DEFAULT 20,
    status character varying(20) DEFAULT 'Calculated'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    department_id integer,
    programme_id integer,
    semester_id integer,
    internal_weight numeric(6,2) DEFAULT 80,
    external_weight numeric(6,2) DEFAULT 20,
    row_data jsonb DEFAULT '{}'::jsonb,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE obe.co_attainment_external_details (
    external_detail_id integer NOT NULL,
    calculation_id integer NOT NULL,
    question_paper_id integer,
    end_sem_rubric_mapping integer,
    external_level_code character varying(10),
    external_level_point integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT co_attainment_external_details_end_sem_rubric_mapping_check CHECK (((end_sem_rubric_mapping >= 1) AND (end_sem_rubric_mapping <= 3))),
    CONSTRAINT co_attainment_external_details_external_level_point_check CHECK (((external_level_point >= 1) AND (external_level_point <= 3)))
);

CREATE TABLE obe.co_attainment_internal_details (
    detail_id integer NOT NULL,
    calculation_id integer NOT NULL,
    component_id integer NOT NULL,
    articulation_level integer,
    component_level_code character varying(10),
    component_level_point integer,
    weighted_value numeric(6,2),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT co_attainment_internal_details_articulation_level_check CHECK (((articulation_level >= 0) AND (articulation_level <= 3))),
    CONSTRAINT co_attainment_internal_details_component_level_point_check CHECK (((component_level_point >= 1) AND (component_level_point <= 3)))
);

CREATE TABLE obe.co_po_attainment (
    co_po_attainment_id integer NOT NULL,
    department_id integer,
    programme_id integer,
    semester_id integer,
    course_id integer,
    academic_year character varying(20) NOT NULL,
    row_data jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE obe.co_po_mapping (
    mapping_id integer NOT NULL,
    co_id integer NOT NULL,
    po_id integer NOT NULL,
    mapping_level integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT co_po_mapping_mapping_level_check CHECK (((mapping_level >= 0) AND (mapping_level <= 3)))
);

CREATE TABLE obe.co_pso_attainment (
    co_pso_attainment_id integer NOT NULL,
    department_id integer,
    programme_id integer,
    semester_id integer,
    course_id integer,
    academic_year character varying(20) NOT NULL,
    row_data jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE obe.co_pso_mapping (
    mapping_id integer NOT NULL,
    co_id integer,
    pso_id integer,
    mapping_level integer,
    CONSTRAINT co_pso_mapping_mapping_level_check CHECK (((mapping_level >= 0) AND (mapping_level <= 3)))
);

CREATE TABLE obe.course_outcomes (
    co_id integer NOT NULL,
    course_id integer,
    co_code character varying(20),
    co_statement text,
    bloom_level character varying(50),
    department_id integer,
    programme_id integer,
    semester_id integer,
    bloom_id integer,
    bloom_code character varying(20) DEFAULT ''::character varying,
    target_level numeric(5,2) DEFAULT 2.50,
    status character varying(20) DEFAULT 'Active'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE obe.courses (
    course_id integer NOT NULL,
    semester_id integer,
    course_code character varying(20) NOT NULL,
    course_name character varying(150) NOT NULL,
    credits integer,
    department_id integer,
    programme_id integer,
    course_type character varying(30) DEFAULT 'Theory'::character varying,
    lecture_hours integer DEFAULT 3,
    tutorial_hours integer DEFAULT 1,
    practical_hours integer DEFAULT 0,
    total_marks integer DEFAULT 100,
    status character varying(20) DEFAULT 'Active'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    erp_id bigint
);

CREATE TABLE obe.dashboard_content (
    dashboard_content_id integer NOT NULL,
    content_type character varying(30) NOT NULL,
    content_label character varying(80) NOT NULL,
    icon character varying(20) DEFAULT ''::character varying,
    theme_color character varying(20) DEFAULT '#374151'::character varying,
    status character varying(20) DEFAULT 'Active'::character varying,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    content_statement text DEFAULT ''::text
);

CREATE TABLE obe.department (
    department_id integer NOT NULL,
    department_code character varying(20) NOT NULL,
    department_name character varying(150) NOT NULL,
    institute_college character varying(150) DEFAULT ''::character varying,
    hod character varying(150) DEFAULT ''::character varying,
    email character varying(150) DEFAULT ''::character varying,
    phone character varying(40) DEFAULT ''::character varying,
    status character varying(20) DEFAULT 'Active'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    erp_id bigint
);

CREATE TABLE obe.department_vision_mission (
    department_vision_mission_id integer NOT NULL,
    department_id integer NOT NULL,
    content_type character varying(20) NOT NULL,
    content_title character varying(120) NOT NULL,
    content_statement text NOT NULL,
    status character varying(20) DEFAULT 'Active'::character varying,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE obe.external_marks_upload (
    mark_id integer NOT NULL,
    department_id integer,
    programme_id integer,
    semester_id integer,
    course_id integer,
    academic_year character varying(20) NOT NULL,
    sl_no integer,
    regd_no character varying(60) NOT NULL,
    student_name character varying(180) NOT NULL,
    sgpa numeric(6,2),
    grade character varying(20) DEFAULT ''::character varying,
    course_code character varying(40) DEFAULT ''::character varying,
    course_name character varying(180) DEFAULT ''::character varying,
    percent_mark numeric(7,2) NOT NULL,
    average_mark numeric(7,2) NOT NULL,
    target_average numeric(7,2) NOT NULL,
    attainment_value numeric(10,5) NOT NULL,
    uploaded_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    calculation_summary jsonb DEFAULT '{}'::jsonb
);

CREATE TABLE obe.faculty (
    faculty_id integer NOT NULL,
    department_id integer,
    faculty_name character varying(100),
    email character varying(100),
    designation character varying(100),
    faculty_code character varying(80),
    status character varying(20) DEFAULT 'Active'::character varying,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    erp_id bigint
);

CREATE TABLE obe.internal_assessment_components (
    component_id integer NOT NULL,
    course_id integer NOT NULL,
    component_code character varying(20) NOT NULL,
    component_name character varying(100) NOT NULL,
    max_marks numeric(6,2) NOT NULL,
    display_order integer DEFAULT 1,
    academic_year character varying(20) NOT NULL,
    status character varying(20) DEFAULT 'Active'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE obe.internal_marks_upload (
    internal_mark_id integer NOT NULL,
    department_id integer,
    programme_id integer,
    semester_id integer,
    course_id integer,
    academic_year character varying(20) NOT NULL,
    branch character varying(40) DEFAULT ''::character varying,
    sl_no integer,
    regd_no character varying(60) NOT NULL,
    student_name character varying(180) NOT NULL,
    attd numeric(7,2) DEFAULT 0,
    a1 numeric(7,2) DEFAULT 0,
    a2 numeric(7,2) DEFAULT 0,
    qt1 numeric(7,2) DEFAULT 0,
    qt2 numeric(7,2) DEFAULT 0,
    st1 numeric(7,2) DEFAULT 0,
    st2 numeric(7,2) DEFAULT 0,
    ct1 numeric(7,2) DEFAULT 0,
    ct2 numeric(7,2) DEFAULT 0,
    internal_mark numeric(7,2) NOT NULL,
    uploaded_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE obe.mark_attainment (
    mark_attainment_id integer NOT NULL,
    department_id integer,
    programme_id integer,
    semester_id integer,
    course_id integer,
    academic_year character varying(20) NOT NULL,
    assessment_tool character varying(40) NOT NULL,
    tool_label character varying(80) NOT NULL,
    weightage numeric(8,2) DEFAULT 0 NOT NULL,
    target_average numeric(10,2) DEFAULT 0 NOT NULL,
    attainment_percent numeric(10,2) DEFAULT 0 NOT NULL,
    level character varying(10) DEFAULT ''::character varying NOT NULL,
    level_point integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE obe.po_attainment (
    po_attainment_id integer NOT NULL,
    programme_id integer,
    po_id integer,
    academic_year character varying(20),
    attainment_value numeric(5,2)
);

CREATE TABLE obe.po_attainment_details (
    detail_id integer NOT NULL,
    po_attainment_id integer NOT NULL,
    course_id integer NOT NULL,
    co_id integer NOT NULL,
    mapping_level integer NOT NULL,
    co_attainment numeric(6,2) NOT NULL,
    weighted_value numeric(8,2) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT po_attainment_details_mapping_level_check CHECK (((mapping_level >= 1) AND (mapping_level <= 3)))
);

CREATE TABLE obe.programme_outcomes (
    po_id integer NOT NULL,
    po_code character varying(20) DEFAULT ''::character varying,
    po_statement text DEFAULT ''::text,
    outcome_id integer NOT NULL,
    department_id integer,
    programme_id integer,
    outcome_type character varying(10),
    outcome_code character varying(20),
    pso_code character varying(20) DEFAULT ''::character varying,
    po_title character varying(180) DEFAULT ''::character varying,
    pso_title character varying(180) DEFAULT ''::character varying,
    pso_statement text DEFAULT ''::text,
    outcome_title character varying(180),
    outcome_statement text,
    status character varying(20) DEFAULT 'Active'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE obe.programme_specific_outcomes (
    pso_id integer NOT NULL,
    programme_id integer,
    pso_code character varying(20),
    pso_statement text
);

CREATE TABLE obe.programmes (
    programme_id integer NOT NULL,
    department_id integer,
    programme_name character varying(100) NOT NULL,
    programme_code character varying(20) NOT NULL,
    duration_years integer,
    programme_type character varying(30) DEFAULT 'UG'::character varying,
    total_semesters integer DEFAULT 8,
    accreditation_status character varying(40) DEFAULT 'Accredited'::character varying,
    status character varying(20) DEFAULT 'Active'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    erp_id bigint
);

CREATE TABLE obe.pso_attainment (
    pso_attainment_id integer NOT NULL,
    programme_id integer NOT NULL,
    academic_year character varying(20) NOT NULL,
    admission_batch_id integer,
    calculation_method character varying(20) DEFAULT 'Direct'::character varying,
    calculated_by integer,
    calculated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    status character varying(20) DEFAULT 'Calculated'::character varying,
    CONSTRAINT pso_attainment_calculation_method_check CHECK (((calculation_method)::text = ANY (ARRAY[('Direct'::character varying)::text, ('Indirect'::character varying)::text, ('Overall'::character varying)::text])))
);

CREATE TABLE obe.pso_attainment_details (
    detail_id integer NOT NULL,
    pso_attainment_id integer NOT NULL,
    co_id integer NOT NULL,
    pso_id integer NOT NULL,
    co_attainment numeric(6,2) NOT NULL,
    mapping_level integer NOT NULL,
    weighted_value numeric(8,2),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pso_attainment_details_mapping_level_check CHECK (((mapping_level >= 0) AND (mapping_level <= 3)))
);

CREATE TABLE obe.pso_attainment_summary (
    summary_id integer NOT NULL,
    pso_attainment_id integer NOT NULL,
    pso_id integer NOT NULL,
    direct_attainment numeric(6,2),
    level_code character varying(10),
    level_point integer,
    remarks text,
    CONSTRAINT pso_attainment_summary_level_point_check CHECK (((level_point >= 1) AND (level_point <= 3)))
);

CREATE TABLE obe.semesters (
    semester_id integer NOT NULL,
    programme_id integer,
    semester_no integer NOT NULL,
    department_id integer,
    semester_number integer,
    semester_name character varying(80) DEFAULT ''::character varying,
    academic_year character varying(20) DEFAULT ''::character varying,
    status character varying(20) DEFAULT 'Active'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    admission_batch_id integer,
    erp_id bigint
);

CREATE TABLE obe.student_course_enrollments (
    enrollment_id integer NOT NULL,
    student_id integer NOT NULL,
    course_offering_id integer,
    enrollment_status character varying(20) DEFAULT 'Enrolled'::character varying,
    enrolled_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    course_id integer,
    faculty_id integer,
    academic_year character varying(20) DEFAULT ''::character varying,
    section character varying(20) DEFAULT 'A'::character varying,
    status character varying(20) DEFAULT 'Active'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT student_course_enrollments_enrollment_status_check CHECK (((enrollment_status)::text = ANY (ARRAY[('Enrolled'::character varying)::text, ('Dropped'::character varying)::text, ('Completed'::character varying)::text, ('Backlog'::character varying)::text])))
);

CREATE TABLE obe.students (
    student_id integer NOT NULL,
    programme_id integer,
    regd_no character varying(30) NOT NULL,
    student_name character varying(100),
    batch character varying(20),
    department_id integer,
    semester_id integer,
    section character varying(20) DEFAULT 'A'::character varying,
    academic_year character varying(20) DEFAULT ''::character varying,
    registration_no character varying(60),
    university_regd character varying(60) DEFAULT ''::character varying,
    roll_number character varying(60) DEFAULT ''::character varying,
    status character varying(20) DEFAULT 'Active'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    erp_id bigint
);

CREATE TABLE obe.university_question_mapping (
    question_mapping_id integer NOT NULL,
    department_id integer,
    programme_id integer,
    semester_id integer,
    course_id integer,
    academic_year character varying(20) NOT NULL,
    exam_type character varying(40) NOT NULL,
    exam_month character varying(40) NOT NULL,
    exam_year integer NOT NULL,
    total_marks numeric(7,2) NOT NULL,
    question_no character varying(20) NOT NULL,
    sub_question character varying(20) NOT NULL,
    co_code character varying(20) NOT NULL,
    carrying_mark numeric(7,2) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);

CREATE SEQUENCE obe.academic_years_academic_year_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.admission_batches_admission_batch_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.articulation_matrix_articulation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.assessment_attainment_levels_level_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.assessment_co_mapping_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.assessment_target_configuration_target_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.assessments_assessment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.attainment_targets_target_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.bloom_level_bloom_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.co_attainment_attainment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.co_attainment_calculation_calculation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.co_attainment_external_details_external_detail_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.co_attainment_internal_details_detail_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.co_po_attainment_co_po_attainment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.co_po_mapping_mapping_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.co_pso_attainment_co_pso_attainment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.co_pso_mapping_mapping_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.course_outcomes_co_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.courses_course_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.dashboard_content_dashboard_content_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.department_department_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.department_vision_mission_department_vision_mission_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.external_marks_upload_mark_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.faculty_faculty_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.internal_assessment_components_component_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.internal_marks_upload_internal_mark_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.mark_attainment_mark_attainment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.po_attainment_details_detail_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.po_attainment_po_attainment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.programme_outcomes_outcome_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.programme_outcomes_po_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.programme_specific_outcomes_pso_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.programmes_programme_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.pso_attainment_details_detail_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.pso_attainment_pso_attainment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.pso_attainment_summary_summary_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.semesters_semester_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.student_course_enrollments_enrollment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.students_student_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE obe.university_question_mapping_question_mapping_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE obe.academic_years_academic_year_id_seq OWNED BY obe.academic_years.academic_year_id;

ALTER SEQUENCE obe.admission_batches_admission_batch_id_seq OWNED BY obe.admission_batches.admission_batch_id;

ALTER SEQUENCE obe.articulation_matrix_articulation_id_seq OWNED BY obe.articulation_matrix.articulation_id;

ALTER SEQUENCE obe.assessment_attainment_levels_level_id_seq OWNED BY obe.assessment_attainment_levels.level_id;

ALTER SEQUENCE obe.assessment_co_mapping_id_seq OWNED BY obe.assessment_co_mapping.id;

ALTER SEQUENCE obe.assessment_target_configuration_target_id_seq OWNED BY obe.assessment_target_configuration.target_id;

ALTER SEQUENCE obe.assessments_assessment_id_seq OWNED BY obe.assessments.assessment_id;

ALTER SEQUENCE obe.attainment_targets_target_id_seq OWNED BY obe.attainment_targets.target_id;

ALTER SEQUENCE obe.bloom_level_bloom_id_seq OWNED BY obe.bloom_level.bloom_id;

ALTER SEQUENCE obe.co_attainment_attainment_id_seq OWNED BY obe.co_attainment.attainment_id;

ALTER SEQUENCE obe.co_attainment_calculation_calculation_id_seq OWNED BY obe.co_attainment_calculation.calculation_id;

ALTER SEQUENCE obe.co_attainment_external_details_external_detail_id_seq OWNED BY obe.co_attainment_external_details.external_detail_id;

ALTER SEQUENCE obe.co_attainment_internal_details_detail_id_seq OWNED BY obe.co_attainment_internal_details.detail_id;

ALTER SEQUENCE obe.co_po_attainment_co_po_attainment_id_seq OWNED BY obe.co_po_attainment.co_po_attainment_id;

ALTER SEQUENCE obe.co_po_mapping_mapping_id_seq OWNED BY obe.co_po_mapping.mapping_id;

ALTER SEQUENCE obe.co_pso_attainment_co_pso_attainment_id_seq OWNED BY obe.co_pso_attainment.co_pso_attainment_id;

ALTER SEQUENCE obe.co_pso_mapping_mapping_id_seq OWNED BY obe.co_pso_mapping.mapping_id;

ALTER SEQUENCE obe.course_outcomes_co_id_seq OWNED BY obe.course_outcomes.co_id;

ALTER SEQUENCE obe.courses_course_id_seq OWNED BY obe.courses.course_id;

ALTER SEQUENCE obe.dashboard_content_dashboard_content_id_seq OWNED BY obe.dashboard_content.dashboard_content_id;

ALTER SEQUENCE obe.department_department_id_seq OWNED BY obe.department.department_id;

ALTER SEQUENCE obe.department_vision_mission_department_vision_mission_id_seq OWNED BY obe.department_vision_mission.department_vision_mission_id;

ALTER SEQUENCE obe.external_marks_upload_mark_id_seq OWNED BY obe.external_marks_upload.mark_id;

ALTER SEQUENCE obe.faculty_faculty_id_seq OWNED BY obe.faculty.faculty_id;

ALTER SEQUENCE obe.internal_assessment_components_component_id_seq OWNED BY obe.internal_assessment_components.component_id;

ALTER SEQUENCE obe.internal_marks_upload_internal_mark_id_seq OWNED BY obe.internal_marks_upload.internal_mark_id;

ALTER SEQUENCE obe.mark_attainment_mark_attainment_id_seq OWNED BY obe.mark_attainment.mark_attainment_id;

ALTER SEQUENCE obe.po_attainment_details_detail_id_seq OWNED BY obe.po_attainment_details.detail_id;

ALTER SEQUENCE obe.po_attainment_po_attainment_id_seq OWNED BY obe.po_attainment.po_attainment_id;

ALTER SEQUENCE obe.programme_outcomes_outcome_id_seq OWNED BY obe.programme_outcomes.outcome_id;

ALTER SEQUENCE obe.programme_outcomes_po_id_seq OWNED BY obe.programme_outcomes.po_id;

ALTER SEQUENCE obe.programme_specific_outcomes_pso_id_seq OWNED BY obe.programme_specific_outcomes.pso_id;

ALTER SEQUENCE obe.programmes_programme_id_seq OWNED BY obe.programmes.programme_id;

ALTER SEQUENCE obe.pso_attainment_details_detail_id_seq OWNED BY obe.pso_attainment_details.detail_id;

ALTER SEQUENCE obe.pso_attainment_pso_attainment_id_seq OWNED BY obe.pso_attainment.pso_attainment_id;

ALTER SEQUENCE obe.pso_attainment_summary_summary_id_seq OWNED BY obe.pso_attainment_summary.summary_id;

ALTER SEQUENCE obe.semesters_semester_id_seq OWNED BY obe.semesters.semester_id;

ALTER SEQUENCE obe.student_course_enrollments_enrollment_id_seq OWNED BY obe.student_course_enrollments.enrollment_id;

ALTER SEQUENCE obe.students_student_id_seq OWNED BY obe.students.student_id;

ALTER SEQUENCE obe.university_question_mapping_question_mapping_id_seq OWNED BY obe.university_question_mapping.question_mapping_id;

ALTER TABLE ONLY obe.academic_years ALTER COLUMN academic_year_id SET DEFAULT nextval('obe.academic_years_academic_year_id_seq'::regclass);

ALTER TABLE ONLY obe.admission_batches ALTER COLUMN admission_batch_id SET DEFAULT nextval('obe.admission_batches_admission_batch_id_seq'::regclass);

ALTER TABLE ONLY obe.articulation_matrix ALTER COLUMN articulation_id SET DEFAULT nextval('obe.articulation_matrix_articulation_id_seq'::regclass);

ALTER TABLE ONLY obe.assessment_attainment_levels ALTER COLUMN level_id SET DEFAULT nextval('obe.assessment_attainment_levels_level_id_seq'::regclass);

ALTER TABLE ONLY obe.assessment_co_mapping ALTER COLUMN id SET DEFAULT nextval('obe.assessment_co_mapping_id_seq'::regclass);

ALTER TABLE ONLY obe.assessment_target_configuration ALTER COLUMN target_id SET DEFAULT nextval('obe.assessment_target_configuration_target_id_seq'::regclass);

ALTER TABLE ONLY obe.assessments ALTER COLUMN assessment_id SET DEFAULT nextval('obe.assessments_assessment_id_seq'::regclass);

ALTER TABLE ONLY obe.attainment_targets ALTER COLUMN target_id SET DEFAULT nextval('obe.attainment_targets_target_id_seq'::regclass);

ALTER TABLE ONLY obe.bloom_level ALTER COLUMN bloom_id SET DEFAULT nextval('obe.bloom_level_bloom_id_seq'::regclass);

ALTER TABLE ONLY obe.co_attainment ALTER COLUMN attainment_id SET DEFAULT nextval('obe.co_attainment_attainment_id_seq'::regclass);

ALTER TABLE ONLY obe.co_attainment_calculation ALTER COLUMN calculation_id SET DEFAULT nextval('obe.co_attainment_calculation_calculation_id_seq'::regclass);

ALTER TABLE ONLY obe.co_attainment_external_details ALTER COLUMN external_detail_id SET DEFAULT nextval('obe.co_attainment_external_details_external_detail_id_seq'::regclass);

ALTER TABLE ONLY obe.co_attainment_internal_details ALTER COLUMN detail_id SET DEFAULT nextval('obe.co_attainment_internal_details_detail_id_seq'::regclass);

ALTER TABLE ONLY obe.co_po_attainment ALTER COLUMN co_po_attainment_id SET DEFAULT nextval('obe.co_po_attainment_co_po_attainment_id_seq'::regclass);

ALTER TABLE ONLY obe.co_po_mapping ALTER COLUMN mapping_id SET DEFAULT nextval('obe.co_po_mapping_mapping_id_seq'::regclass);

ALTER TABLE ONLY obe.co_pso_attainment ALTER COLUMN co_pso_attainment_id SET DEFAULT nextval('obe.co_pso_attainment_co_pso_attainment_id_seq'::regclass);

ALTER TABLE ONLY obe.co_pso_mapping ALTER COLUMN mapping_id SET DEFAULT nextval('obe.co_pso_mapping_mapping_id_seq'::regclass);

ALTER TABLE ONLY obe.course_outcomes ALTER COLUMN co_id SET DEFAULT nextval('obe.course_outcomes_co_id_seq'::regclass);

ALTER TABLE ONLY obe.courses ALTER COLUMN course_id SET DEFAULT nextval('obe.courses_course_id_seq'::regclass);

ALTER TABLE ONLY obe.dashboard_content ALTER COLUMN dashboard_content_id SET DEFAULT nextval('obe.dashboard_content_dashboard_content_id_seq'::regclass);

ALTER TABLE ONLY obe.department ALTER COLUMN department_id SET DEFAULT nextval('obe.department_department_id_seq'::regclass);

ALTER TABLE ONLY obe.department_vision_mission ALTER COLUMN department_vision_mission_id SET DEFAULT nextval('obe.department_vision_mission_department_vision_mission_id_seq'::regclass);

ALTER TABLE ONLY obe.external_marks_upload ALTER COLUMN mark_id SET DEFAULT nextval('obe.external_marks_upload_mark_id_seq'::regclass);

ALTER TABLE ONLY obe.faculty ALTER COLUMN faculty_id SET DEFAULT nextval('obe.faculty_faculty_id_seq'::regclass);

ALTER TABLE ONLY obe.internal_assessment_components ALTER COLUMN component_id SET DEFAULT nextval('obe.internal_assessment_components_component_id_seq'::regclass);

ALTER TABLE ONLY obe.internal_marks_upload ALTER COLUMN internal_mark_id SET DEFAULT nextval('obe.internal_marks_upload_internal_mark_id_seq'::regclass);

ALTER TABLE ONLY obe.mark_attainment ALTER COLUMN mark_attainment_id SET DEFAULT nextval('obe.mark_attainment_mark_attainment_id_seq'::regclass);

ALTER TABLE ONLY obe.po_attainment ALTER COLUMN po_attainment_id SET DEFAULT nextval('obe.po_attainment_po_attainment_id_seq'::regclass);

ALTER TABLE ONLY obe.po_attainment_details ALTER COLUMN detail_id SET DEFAULT nextval('obe.po_attainment_details_detail_id_seq'::regclass);

ALTER TABLE ONLY obe.programme_outcomes ALTER COLUMN po_id SET DEFAULT nextval('obe.programme_outcomes_po_id_seq'::regclass);

ALTER TABLE ONLY obe.programme_outcomes ALTER COLUMN outcome_id SET DEFAULT nextval('obe.programme_outcomes_outcome_id_seq'::regclass);

ALTER TABLE ONLY obe.programme_specific_outcomes ALTER COLUMN pso_id SET DEFAULT nextval('obe.programme_specific_outcomes_pso_id_seq'::regclass);

ALTER TABLE ONLY obe.programmes ALTER COLUMN programme_id SET DEFAULT nextval('obe.programmes_programme_id_seq'::regclass);

ALTER TABLE ONLY obe.pso_attainment ALTER COLUMN pso_attainment_id SET DEFAULT nextval('obe.pso_attainment_pso_attainment_id_seq'::regclass);

ALTER TABLE ONLY obe.pso_attainment_details ALTER COLUMN detail_id SET DEFAULT nextval('obe.pso_attainment_details_detail_id_seq'::regclass);

ALTER TABLE ONLY obe.pso_attainment_summary ALTER COLUMN summary_id SET DEFAULT nextval('obe.pso_attainment_summary_summary_id_seq'::regclass);

ALTER TABLE ONLY obe.semesters ALTER COLUMN semester_id SET DEFAULT nextval('obe.semesters_semester_id_seq'::regclass);

ALTER TABLE ONLY obe.student_course_enrollments ALTER COLUMN enrollment_id SET DEFAULT nextval('obe.student_course_enrollments_enrollment_id_seq'::regclass);

ALTER TABLE ONLY obe.students ALTER COLUMN student_id SET DEFAULT nextval('obe.students_student_id_seq'::regclass);

ALTER TABLE ONLY obe.university_question_mapping ALTER COLUMN question_mapping_id SET DEFAULT nextval('obe.university_question_mapping_question_mapping_id_seq'::regclass);

ALTER TABLE ONLY obe.academic_years
    ADD CONSTRAINT academic_years_pkey PRIMARY KEY (academic_year_id);

ALTER TABLE ONLY obe.admission_batches
    ADD CONSTRAINT admission_batches_pkey PRIMARY KEY (admission_batch_id);

ALTER TABLE ONLY obe.admission_batches
    ADD CONSTRAINT admission_batches_programme_id_batch_code_key UNIQUE (programme_id, batch_code);

ALTER TABLE ONLY obe.articulation_matrix
    ADD CONSTRAINT articulation_matrix_course_id_co_id_component_id_academic_y_key UNIQUE (course_id, co_id, component_id, academic_year);

ALTER TABLE ONLY obe.articulation_matrix
    ADD CONSTRAINT articulation_matrix_pkey PRIMARY KEY (articulation_id);

ALTER TABLE ONLY obe.assessment_attainment_levels
    ADD CONSTRAINT assessment_attainment_levels_academic_year_assessment_categ_key UNIQUE (academic_year, assessment_category, level_number);

ALTER TABLE ONLY obe.assessment_attainment_levels
    ADD CONSTRAINT assessment_attainment_levels_pkey PRIMARY KEY (level_id);

ALTER TABLE ONLY obe.assessment_co_mapping
    ADD CONSTRAINT assessment_co_mapping_pkey PRIMARY KEY (id);

ALTER TABLE ONLY obe.assessment_target_configuration
    ADD CONSTRAINT assessment_target_configurati_course_id_component_id_academ_key UNIQUE (course_id, component_id, academic_year);

ALTER TABLE ONLY obe.assessment_target_configuration
    ADD CONSTRAINT assessment_target_configuration_pkey PRIMARY KEY (target_id);

ALTER TABLE ONLY obe.assessments
    ADD CONSTRAINT assessments_pkey PRIMARY KEY (assessment_id);

ALTER TABLE ONLY obe.attainment_targets
    ADD CONSTRAINT attainment_targets_pkey PRIMARY KEY (target_id);

ALTER TABLE ONLY obe.bloom_level
    ADD CONSTRAINT bloom_level_pkey PRIMARY KEY (bloom_id);

ALTER TABLE ONLY obe.co_attainment_calculation
    ADD CONSTRAINT co_attainment_calculation_course_id_co_id_academic_year_bat_key UNIQUE (course_id, co_id, academic_year, batch);

ALTER TABLE ONLY obe.co_attainment_calculation
    ADD CONSTRAINT co_attainment_calculation_pkey PRIMARY KEY (calculation_id);

ALTER TABLE ONLY obe.co_attainment_external_details
    ADD CONSTRAINT co_attainment_external_detail_calculation_id_question_paper_key UNIQUE (calculation_id, question_paper_id);

ALTER TABLE ONLY obe.co_attainment_external_details
    ADD CONSTRAINT co_attainment_external_details_pkey PRIMARY KEY (external_detail_id);

ALTER TABLE ONLY obe.co_attainment_internal_details
    ADD CONSTRAINT co_attainment_internal_details_calculation_id_component_id_key UNIQUE (calculation_id, component_id);

ALTER TABLE ONLY obe.co_attainment_internal_details
    ADD CONSTRAINT co_attainment_internal_details_pkey PRIMARY KEY (detail_id);

ALTER TABLE ONLY obe.co_attainment
    ADD CONSTRAINT co_attainment_pkey PRIMARY KEY (attainment_id);

ALTER TABLE ONLY obe.co_po_attainment
    ADD CONSTRAINT co_po_attainment_course_id_academic_year_key UNIQUE (course_id, academic_year);

ALTER TABLE ONLY obe.co_po_attainment
    ADD CONSTRAINT co_po_attainment_pkey PRIMARY KEY (co_po_attainment_id);

ALTER TABLE ONLY obe.co_po_mapping
    ADD CONSTRAINT co_po_mapping_co_id_po_id_key UNIQUE (co_id, po_id);

ALTER TABLE ONLY obe.co_po_mapping
    ADD CONSTRAINT co_po_mapping_pkey PRIMARY KEY (mapping_id);

ALTER TABLE ONLY obe.co_pso_attainment
    ADD CONSTRAINT co_pso_attainment_course_id_academic_year_key UNIQUE (course_id, academic_year);

ALTER TABLE ONLY obe.co_pso_attainment
    ADD CONSTRAINT co_pso_attainment_pkey PRIMARY KEY (co_pso_attainment_id);

ALTER TABLE ONLY obe.co_pso_mapping
    ADD CONSTRAINT co_pso_mapping_pkey PRIMARY KEY (mapping_id);

ALTER TABLE ONLY obe.course_outcomes
    ADD CONSTRAINT course_outcomes_pkey PRIMARY KEY (co_id);

ALTER TABLE ONLY obe.courses
    ADD CONSTRAINT courses_course_code_key UNIQUE (course_code);

ALTER TABLE ONLY obe.courses
    ADD CONSTRAINT courses_pkey PRIMARY KEY (course_id);

ALTER TABLE ONLY obe.dashboard_content
    ADD CONSTRAINT dashboard_content_content_type_key UNIQUE (content_type);

ALTER TABLE ONLY obe.dashboard_content
    ADD CONSTRAINT dashboard_content_pkey PRIMARY KEY (dashboard_content_id);

ALTER TABLE ONLY obe.department
    ADD CONSTRAINT department_pkey PRIMARY KEY (department_id);

ALTER TABLE ONLY obe.department_vision_mission
    ADD CONSTRAINT department_vision_mission_department_id_content_type_key UNIQUE (department_id, content_type);

ALTER TABLE ONLY obe.department_vision_mission
    ADD CONSTRAINT department_vision_mission_pkey PRIMARY KEY (department_vision_mission_id);

ALTER TABLE ONLY obe.external_marks_upload
    ADD CONSTRAINT external_marks_upload_pkey PRIMARY KEY (mark_id);

ALTER TABLE ONLY obe.faculty
    ADD CONSTRAINT faculty_pkey PRIMARY KEY (faculty_id);

ALTER TABLE ONLY obe.internal_assessment_components
    ADD CONSTRAINT internal_assessment_component_course_id_component_code_acad_key UNIQUE (course_id, component_code, academic_year);

ALTER TABLE ONLY obe.internal_assessment_components
    ADD CONSTRAINT internal_assessment_components_pkey PRIMARY KEY (component_id);

ALTER TABLE ONLY obe.internal_marks_upload
    ADD CONSTRAINT internal_marks_upload_pkey PRIMARY KEY (internal_mark_id);

ALTER TABLE ONLY obe.mark_attainment
    ADD CONSTRAINT mark_attainment_course_id_academic_year_assessment_tool_key UNIQUE (course_id, academic_year, assessment_tool);

ALTER TABLE ONLY obe.mark_attainment
    ADD CONSTRAINT mark_attainment_pkey PRIMARY KEY (mark_attainment_id);

ALTER TABLE ONLY obe.po_attainment_details
    ADD CONSTRAINT po_attainment_details_pkey PRIMARY KEY (detail_id);

ALTER TABLE ONLY obe.po_attainment_details
    ADD CONSTRAINT po_attainment_details_po_attainment_id_co_id_key UNIQUE (po_attainment_id, co_id);

ALTER TABLE ONLY obe.po_attainment
    ADD CONSTRAINT po_attainment_pkey PRIMARY KEY (po_attainment_id);

ALTER TABLE ONLY obe.programme_outcomes
    ADD CONSTRAINT programme_outcomes_pkey PRIMARY KEY (po_id);

ALTER TABLE ONLY obe.programme_specific_outcomes
    ADD CONSTRAINT programme_specific_outcomes_pkey PRIMARY KEY (pso_id);

ALTER TABLE ONLY obe.programmes
    ADD CONSTRAINT programmes_pkey PRIMARY KEY (programme_id);

ALTER TABLE ONLY obe.programmes
    ADD CONSTRAINT programmes_programme_code_key UNIQUE (programme_code);

ALTER TABLE ONLY obe.pso_attainment_details
    ADD CONSTRAINT pso_attainment_details_pkey PRIMARY KEY (detail_id);

ALTER TABLE ONLY obe.pso_attainment_details
    ADD CONSTRAINT pso_attainment_details_pso_attainment_id_co_id_pso_id_key UNIQUE (pso_attainment_id, co_id, pso_id);

ALTER TABLE ONLY obe.pso_attainment
    ADD CONSTRAINT pso_attainment_pkey PRIMARY KEY (pso_attainment_id);

ALTER TABLE ONLY obe.pso_attainment
    ADD CONSTRAINT pso_attainment_programme_id_academic_year_admission_batch_i_key UNIQUE (programme_id, academic_year, admission_batch_id, calculation_method);

ALTER TABLE ONLY obe.pso_attainment_summary
    ADD CONSTRAINT pso_attainment_summary_pkey PRIMARY KEY (summary_id);

ALTER TABLE ONLY obe.pso_attainment_summary
    ADD CONSTRAINT pso_attainment_summary_pso_attainment_id_pso_id_key UNIQUE (pso_attainment_id, pso_id);

ALTER TABLE ONLY obe.semesters
    ADD CONSTRAINT semesters_pkey PRIMARY KEY (semester_id);

ALTER TABLE ONLY obe.student_course_enrollments
    ADD CONSTRAINT student_course_enrollments_pkey PRIMARY KEY (enrollment_id);

ALTER TABLE ONLY obe.student_course_enrollments
    ADD CONSTRAINT student_course_enrollments_student_id_course_offering_id_key UNIQUE (student_id, course_offering_id);

ALTER TABLE ONLY obe.students
    ADD CONSTRAINT students_pkey PRIMARY KEY (student_id);

ALTER TABLE ONLY obe.students
    ADD CONSTRAINT students_regd_no_key UNIQUE (regd_no);

ALTER TABLE ONLY obe.university_question_mapping
    ADD CONSTRAINT university_question_mapping_pkey PRIMARY KEY (question_mapping_id);

ALTER TABLE ONLY obe.admission_batches
    ADD CONSTRAINT admission_batches_department_id_fkey FOREIGN KEY (department_id) REFERENCES obe.department(department_id) ON DELETE SET NULL;

ALTER TABLE ONLY obe.admission_batches
    ADD CONSTRAINT admission_batches_erp_id_fkey FOREIGN KEY (erp_id) REFERENCES public.batches(batch_id);

ALTER TABLE ONLY obe.admission_batches
    ADD CONSTRAINT admission_batches_programme_id_fkey FOREIGN KEY (programme_id) REFERENCES obe.programmes(programme_id) ON DELETE RESTRICT;

ALTER TABLE ONLY obe.articulation_matrix
    ADD CONSTRAINT articulation_matrix_co_id_fkey FOREIGN KEY (co_id) REFERENCES obe.course_outcomes(co_id) ON DELETE CASCADE;

ALTER TABLE ONLY obe.articulation_matrix
    ADD CONSTRAINT articulation_matrix_component_id_fkey FOREIGN KEY (component_id) REFERENCES obe.internal_assessment_components(component_id) ON DELETE CASCADE;

ALTER TABLE ONLY obe.articulation_matrix
    ADD CONSTRAINT articulation_matrix_course_id_fkey FOREIGN KEY (course_id) REFERENCES obe.courses(course_id) ON DELETE CASCADE;

ALTER TABLE ONLY obe.assessment_co_mapping
    ADD CONSTRAINT assessment_co_mapping_assessment_id_fkey FOREIGN KEY (assessment_id) REFERENCES obe.assessments(assessment_id);

ALTER TABLE ONLY obe.assessment_co_mapping
    ADD CONSTRAINT assessment_co_mapping_co_id_fkey FOREIGN KEY (co_id) REFERENCES obe.course_outcomes(co_id);

ALTER TABLE ONLY obe.assessment_target_configuration
    ADD CONSTRAINT assessment_target_configuration_component_id_fkey FOREIGN KEY (component_id) REFERENCES obe.internal_assessment_components(component_id) ON DELETE CASCADE;

ALTER TABLE ONLY obe.assessment_target_configuration
    ADD CONSTRAINT assessment_target_configuration_course_id_fkey FOREIGN KEY (course_id) REFERENCES obe.courses(course_id) ON DELETE CASCADE;

ALTER TABLE ONLY obe.assessments
    ADD CONSTRAINT assessments_course_id_fkey FOREIGN KEY (course_id) REFERENCES obe.courses(course_id);

ALTER TABLE ONLY obe.attainment_targets
    ADD CONSTRAINT attainment_targets_course_id_fkey FOREIGN KEY (course_id) REFERENCES obe.courses(course_id);

ALTER TABLE ONLY obe.co_attainment_calculation
    ADD CONSTRAINT co_attainment_calculation_co_id_fkey FOREIGN KEY (co_id) REFERENCES obe.course_outcomes(co_id) ON DELETE CASCADE;

ALTER TABLE ONLY obe.co_attainment_calculation
    ADD CONSTRAINT co_attainment_calculation_course_id_fkey FOREIGN KEY (course_id) REFERENCES obe.courses(course_id) ON DELETE CASCADE;

ALTER TABLE ONLY obe.co_attainment
    ADD CONSTRAINT co_attainment_co_id_fkey FOREIGN KEY (co_id) REFERENCES obe.course_outcomes(co_id);

ALTER TABLE ONLY obe.co_attainment
    ADD CONSTRAINT co_attainment_course_id_fkey FOREIGN KEY (course_id) REFERENCES obe.courses(course_id);

ALTER TABLE ONLY obe.co_attainment_external_details
    ADD CONSTRAINT co_attainment_external_details_calculation_id_fkey FOREIGN KEY (calculation_id) REFERENCES obe.co_attainment_calculation(calculation_id) ON DELETE CASCADE;

ALTER TABLE ONLY obe.co_attainment_internal_details
    ADD CONSTRAINT co_attainment_internal_details_calculation_id_fkey FOREIGN KEY (calculation_id) REFERENCES obe.co_attainment_calculation(calculation_id) ON DELETE CASCADE;

ALTER TABLE ONLY obe.co_attainment_internal_details
    ADD CONSTRAINT co_attainment_internal_details_component_id_fkey FOREIGN KEY (component_id) REFERENCES obe.internal_assessment_components(component_id) ON DELETE CASCADE;

ALTER TABLE ONLY obe.co_po_attainment
    ADD CONSTRAINT co_po_attainment_course_id_fkey FOREIGN KEY (course_id) REFERENCES obe.courses(course_id) ON DELETE CASCADE;

ALTER TABLE ONLY obe.co_po_attainment
    ADD CONSTRAINT co_po_attainment_department_id_fkey FOREIGN KEY (department_id) REFERENCES obe.department(department_id) ON DELETE SET NULL;

ALTER TABLE ONLY obe.co_po_attainment
    ADD CONSTRAINT co_po_attainment_programme_id_fkey FOREIGN KEY (programme_id) REFERENCES obe.programmes(programme_id) ON DELETE SET NULL;

ALTER TABLE ONLY obe.co_po_attainment
    ADD CONSTRAINT co_po_attainment_semester_id_fkey FOREIGN KEY (semester_id) REFERENCES obe.semesters(semester_id) ON DELETE SET NULL;

ALTER TABLE ONLY obe.co_po_mapping
    ADD CONSTRAINT co_po_mapping_co_id_fkey FOREIGN KEY (co_id) REFERENCES obe.course_outcomes(co_id) ON DELETE CASCADE;

ALTER TABLE ONLY obe.co_po_mapping
    ADD CONSTRAINT co_po_mapping_po_id_fkey FOREIGN KEY (po_id) REFERENCES obe.programme_outcomes(po_id) ON DELETE CASCADE;

ALTER TABLE ONLY obe.co_pso_attainment
    ADD CONSTRAINT co_pso_attainment_course_id_fkey FOREIGN KEY (course_id) REFERENCES obe.courses(course_id) ON DELETE CASCADE;

ALTER TABLE ONLY obe.co_pso_attainment
    ADD CONSTRAINT co_pso_attainment_department_id_fkey FOREIGN KEY (department_id) REFERENCES obe.department(department_id) ON DELETE SET NULL;

ALTER TABLE ONLY obe.co_pso_attainment
    ADD CONSTRAINT co_pso_attainment_programme_id_fkey FOREIGN KEY (programme_id) REFERENCES obe.programmes(programme_id) ON DELETE SET NULL;

ALTER TABLE ONLY obe.co_pso_attainment
    ADD CONSTRAINT co_pso_attainment_semester_id_fkey FOREIGN KEY (semester_id) REFERENCES obe.semesters(semester_id) ON DELETE SET NULL;

ALTER TABLE ONLY obe.co_pso_mapping
    ADD CONSTRAINT co_pso_mapping_co_id_fkey FOREIGN KEY (co_id) REFERENCES obe.course_outcomes(co_id);

ALTER TABLE ONLY obe.co_pso_mapping
    ADD CONSTRAINT co_pso_mapping_pso_id_fkey FOREIGN KEY (pso_id) REFERENCES obe.programme_specific_outcomes(pso_id);

ALTER TABLE ONLY obe.course_outcomes
    ADD CONSTRAINT course_outcomes_course_id_fkey FOREIGN KEY (course_id) REFERENCES obe.courses(course_id) ON DELETE CASCADE;

ALTER TABLE ONLY obe.course_outcomes
    ADD CONSTRAINT course_outcomes_department_id_fkey FOREIGN KEY (department_id) REFERENCES obe.department(department_id) ON DELETE SET NULL;

ALTER TABLE ONLY obe.course_outcomes
    ADD CONSTRAINT course_outcomes_programme_id_fkey FOREIGN KEY (programme_id) REFERENCES obe.programmes(programme_id) ON DELETE SET NULL;

ALTER TABLE ONLY obe.course_outcomes
    ADD CONSTRAINT course_outcomes_semester_id_fkey FOREIGN KEY (semester_id) REFERENCES obe.semesters(semester_id) ON DELETE SET NULL;

ALTER TABLE ONLY obe.courses
    ADD CONSTRAINT courses_department_id_fkey FOREIGN KEY (department_id) REFERENCES obe.department(department_id) ON DELETE SET NULL;

ALTER TABLE ONLY obe.courses
    ADD CONSTRAINT courses_erp_id_fkey FOREIGN KEY (erp_id) REFERENCES public.subjects(subject_id);

ALTER TABLE ONLY obe.courses
    ADD CONSTRAINT courses_programme_id_fkey FOREIGN KEY (programme_id) REFERENCES obe.programmes(programme_id) ON DELETE SET NULL;

ALTER TABLE ONLY obe.courses
    ADD CONSTRAINT courses_semester_id_fkey FOREIGN KEY (semester_id) REFERENCES obe.semesters(semester_id);

ALTER TABLE ONLY obe.department
    ADD CONSTRAINT department_erp_id_fkey FOREIGN KEY (erp_id) REFERENCES public.emp_department(emp_department_id);

ALTER TABLE ONLY obe.department_vision_mission
    ADD CONSTRAINT department_vision_mission_department_id_fkey FOREIGN KEY (department_id) REFERENCES obe.department(department_id) ON DELETE CASCADE;

ALTER TABLE ONLY obe.external_marks_upload
    ADD CONSTRAINT external_marks_upload_course_id_fkey FOREIGN KEY (course_id) REFERENCES obe.courses(course_id) ON DELETE SET NULL;

ALTER TABLE ONLY obe.external_marks_upload
    ADD CONSTRAINT external_marks_upload_department_id_fkey FOREIGN KEY (department_id) REFERENCES obe.department(department_id) ON DELETE SET NULL;

ALTER TABLE ONLY obe.external_marks_upload
    ADD CONSTRAINT external_marks_upload_programme_id_fkey FOREIGN KEY (programme_id) REFERENCES obe.programmes(programme_id) ON DELETE SET NULL;

ALTER TABLE ONLY obe.external_marks_upload
    ADD CONSTRAINT external_marks_upload_semester_id_fkey FOREIGN KEY (semester_id) REFERENCES obe.semesters(semester_id) ON DELETE SET NULL;

ALTER TABLE ONLY obe.faculty
    ADD CONSTRAINT faculty_department_id_fkey FOREIGN KEY (department_id) REFERENCES obe.department(department_id) ON DELETE SET NULL;

ALTER TABLE ONLY obe.faculty
    ADD CONSTRAINT faculty_erp_id_fkey FOREIGN KEY (erp_id) REFERENCES public.emp_master(emp_master_id);

ALTER TABLE ONLY obe.internal_assessment_components
    ADD CONSTRAINT internal_assessment_components_course_id_fkey FOREIGN KEY (course_id) REFERENCES obe.courses(course_id) ON DELETE CASCADE;

ALTER TABLE ONLY obe.internal_marks_upload
    ADD CONSTRAINT internal_marks_upload_course_id_fkey FOREIGN KEY (course_id) REFERENCES obe.courses(course_id) ON DELETE SET NULL;

ALTER TABLE ONLY obe.internal_marks_upload
    ADD CONSTRAINT internal_marks_upload_department_id_fkey FOREIGN KEY (department_id) REFERENCES obe.department(department_id) ON DELETE SET NULL;

ALTER TABLE ONLY obe.internal_marks_upload
    ADD CONSTRAINT internal_marks_upload_programme_id_fkey FOREIGN KEY (programme_id) REFERENCES obe.programmes(programme_id) ON DELETE SET NULL;

ALTER TABLE ONLY obe.internal_marks_upload
    ADD CONSTRAINT internal_marks_upload_semester_id_fkey FOREIGN KEY (semester_id) REFERENCES obe.semesters(semester_id) ON DELETE SET NULL;

ALTER TABLE ONLY obe.mark_attainment
    ADD CONSTRAINT mark_attainment_course_id_fkey FOREIGN KEY (course_id) REFERENCES obe.courses(course_id) ON DELETE CASCADE;

ALTER TABLE ONLY obe.mark_attainment
    ADD CONSTRAINT mark_attainment_department_id_fkey FOREIGN KEY (department_id) REFERENCES obe.department(department_id) ON DELETE SET NULL;

ALTER TABLE ONLY obe.mark_attainment
    ADD CONSTRAINT mark_attainment_programme_id_fkey FOREIGN KEY (programme_id) REFERENCES obe.programmes(programme_id) ON DELETE SET NULL;

ALTER TABLE ONLY obe.mark_attainment
    ADD CONSTRAINT mark_attainment_semester_id_fkey FOREIGN KEY (semester_id) REFERENCES obe.semesters(semester_id) ON DELETE SET NULL;

ALTER TABLE ONLY obe.po_attainment_details
    ADD CONSTRAINT po_attainment_details_co_id_fkey FOREIGN KEY (co_id) REFERENCES obe.course_outcomes(co_id) ON DELETE CASCADE;

ALTER TABLE ONLY obe.po_attainment_details
    ADD CONSTRAINT po_attainment_details_course_id_fkey FOREIGN KEY (course_id) REFERENCES obe.courses(course_id) ON DELETE CASCADE;

ALTER TABLE ONLY obe.po_attainment_details
    ADD CONSTRAINT po_attainment_details_po_attainment_id_fkey FOREIGN KEY (po_attainment_id) REFERENCES obe.po_attainment(po_attainment_id) ON DELETE CASCADE;

ALTER TABLE ONLY obe.po_attainment
    ADD CONSTRAINT po_attainment_po_id_fkey FOREIGN KEY (po_id) REFERENCES obe.programme_outcomes(po_id);

ALTER TABLE ONLY obe.po_attainment
    ADD CONSTRAINT po_attainment_programme_id_fkey FOREIGN KEY (programme_id) REFERENCES obe.programmes(programme_id);

ALTER TABLE ONLY obe.programme_outcomes
    ADD CONSTRAINT programme_outcomes_department_id_fkey FOREIGN KEY (department_id) REFERENCES obe.department(department_id) ON DELETE SET NULL;

ALTER TABLE ONLY obe.programme_outcomes
    ADD CONSTRAINT programme_outcomes_programme_id_fkey FOREIGN KEY (programme_id) REFERENCES obe.programmes(programme_id) ON DELETE CASCADE;

ALTER TABLE ONLY obe.programme_specific_outcomes
    ADD CONSTRAINT programme_specific_outcomes_programme_id_fkey FOREIGN KEY (programme_id) REFERENCES obe.programmes(programme_id);

ALTER TABLE ONLY obe.programmes
    ADD CONSTRAINT programmes_department_id_fkey FOREIGN KEY (department_id) REFERENCES obe.department(department_id) ON DELETE SET NULL;

ALTER TABLE ONLY obe.programmes
    ADD CONSTRAINT programmes_erp_id_fkey FOREIGN KEY (erp_id) REFERENCES public.courses(course_id);

ALTER TABLE ONLY obe.pso_attainment
    ADD CONSTRAINT pso_attainment_admission_batch_id_fkey FOREIGN KEY (admission_batch_id) REFERENCES obe.admission_batches(admission_batch_id) ON DELETE RESTRICT;

ALTER TABLE ONLY obe.pso_attainment_details
    ADD CONSTRAINT pso_attainment_details_co_id_fkey FOREIGN KEY (co_id) REFERENCES obe.course_outcomes(co_id) ON DELETE CASCADE;

ALTER TABLE ONLY obe.pso_attainment_details
    ADD CONSTRAINT pso_attainment_details_pso_attainment_id_fkey FOREIGN KEY (pso_attainment_id) REFERENCES obe.pso_attainment(pso_attainment_id) ON DELETE CASCADE;

ALTER TABLE ONLY obe.pso_attainment_details
    ADD CONSTRAINT pso_attainment_details_pso_id_fkey FOREIGN KEY (pso_id) REFERENCES obe.programme_specific_outcomes(pso_id) ON DELETE CASCADE;

ALTER TABLE ONLY obe.pso_attainment
    ADD CONSTRAINT pso_attainment_programme_id_fkey FOREIGN KEY (programme_id) REFERENCES obe.programmes(programme_id) ON DELETE CASCADE;

ALTER TABLE ONLY obe.pso_attainment_summary
    ADD CONSTRAINT pso_attainment_summary_pso_attainment_id_fkey FOREIGN KEY (pso_attainment_id) REFERENCES obe.pso_attainment(pso_attainment_id) ON DELETE CASCADE;

ALTER TABLE ONLY obe.pso_attainment_summary
    ADD CONSTRAINT pso_attainment_summary_pso_id_fkey FOREIGN KEY (pso_id) REFERENCES obe.programme_specific_outcomes(pso_id) ON DELETE CASCADE;

ALTER TABLE ONLY obe.semesters
    ADD CONSTRAINT semesters_admission_batch_id_fkey FOREIGN KEY (admission_batch_id) REFERENCES obe.admission_batches(admission_batch_id) ON DELETE CASCADE;

ALTER TABLE ONLY obe.semesters
    ADD CONSTRAINT semesters_department_id_fkey FOREIGN KEY (department_id) REFERENCES obe.department(department_id) ON DELETE SET NULL;

ALTER TABLE ONLY obe.semesters
    ADD CONSTRAINT semesters_erp_id_fkey FOREIGN KEY (erp_id) REFERENCES public.semester_defined(id);

ALTER TABLE ONLY obe.semesters
    ADD CONSTRAINT semesters_programme_id_fkey FOREIGN KEY (programme_id) REFERENCES obe.programmes(programme_id);

ALTER TABLE ONLY obe.student_course_enrollments
    ADD CONSTRAINT student_course_enrollments_course_id_fkey FOREIGN KEY (course_id) REFERENCES obe.courses(course_id) ON DELETE CASCADE;

ALTER TABLE ONLY obe.student_course_enrollments
    ADD CONSTRAINT student_course_enrollments_faculty_id_fkey FOREIGN KEY (faculty_id) REFERENCES obe.faculty(faculty_id) ON DELETE CASCADE;

ALTER TABLE ONLY obe.student_course_enrollments
    ADD CONSTRAINT student_course_enrollments_student_id_fkey FOREIGN KEY (student_id) REFERENCES obe.students(student_id) ON DELETE CASCADE;

ALTER TABLE ONLY obe.students
    ADD CONSTRAINT students_erp_id_fkey FOREIGN KEY (erp_id) REFERENCES public.stu_master(stu_master_id);

ALTER TABLE ONLY obe.students
    ADD CONSTRAINT students_programme_id_fkey FOREIGN KEY (programme_id) REFERENCES obe.programmes(programme_id);

ALTER TABLE ONLY obe.university_question_mapping
    ADD CONSTRAINT university_question_mapping_course_id_fkey FOREIGN KEY (course_id) REFERENCES obe.courses(course_id) ON DELETE CASCADE;

ALTER TABLE ONLY obe.university_question_mapping
    ADD CONSTRAINT university_question_mapping_department_id_fkey FOREIGN KEY (department_id) REFERENCES obe.department(department_id) ON DELETE SET NULL;

ALTER TABLE ONLY obe.university_question_mapping
    ADD CONSTRAINT university_question_mapping_programme_id_fkey FOREIGN KEY (programme_id) REFERENCES obe.programmes(programme_id) ON DELETE SET NULL;

ALTER TABLE ONLY obe.university_question_mapping
    ADD CONSTRAINT university_question_mapping_semester_id_fkey FOREIGN KEY (semester_id) REFERENCES obe.semesters(semester_id) ON DELETE SET NULL;

CREATE UNIQUE INDEX admission_batches_generated_id_key ON obe.admission_batches USING btree (admission_batch_id);

CREATE UNIQUE INDEX department_vision_mission_department_type_key ON obe.department_vision_mission USING btree (department_id, content_type);

CREATE UNIQUE INDEX obe_faculty_erp_unique ON obe.faculty USING btree (erp_id) WHERE (erp_id IS NOT NULL);
END IF;
END $obe_bootstrap$;
INSERT INTO obe.dashboard_content(content_type,content_label,icon,theme_color,status) VALUES('VISION','VISION','','#c62828','Active'),('MISSION','MISSION','','#c62828','Active') ON CONFLICT(content_type) DO NOTHING;
INSERT INTO obe.bloom_level(bloom_code,bloom_level,learning_outcome_verbs) SELECT 'L1','Remember','define, list, recall, recognize, identify, state, name, label' WHERE NOT EXISTS(SELECT 1 FROM obe.bloom_level WHERE bloom_code='L1');
INSERT INTO obe.bloom_level(bloom_code,bloom_level,learning_outcome_verbs) SELECT 'L2','Understand','understand, explain, describe, discuss, classify, summarize, interpret' WHERE NOT EXISTS(SELECT 1 FROM obe.bloom_level WHERE bloom_code='L2');
INSERT INTO obe.bloom_level(bloom_code,bloom_level,learning_outcome_verbs) SELECT 'L3','Apply','apply, solve, use, demonstrate, calculate, implement, execute' WHERE NOT EXISTS(SELECT 1 FROM obe.bloom_level WHERE bloom_code='L3');
INSERT INTO obe.bloom_level(bloom_code,bloom_level,learning_outcome_verbs) SELECT 'L4','Analyze','analyze, compare, differentiate, examine, test, categorize' WHERE NOT EXISTS(SELECT 1 FROM obe.bloom_level WHERE bloom_code='L4');
INSERT INTO obe.bloom_level(bloom_code,bloom_level,learning_outcome_verbs) SELECT 'L5','Evaluate','evaluate, justify, assess, critique, validate, judge' WHERE NOT EXISTS(SELECT 1 FROM obe.bloom_level WHERE bloom_code='L5');
INSERT INTO obe.bloom_level(bloom_code,bloom_level,learning_outcome_verbs) SELECT 'L6','Create','create, design, develop, formulate, construct, compose' WHERE NOT EXISTS(SELECT 1 FROM obe.bloom_level WHERE bloom_code='L6');

-- Explicit links preserve the repository's OBE model while connecting existing ERP masters.
ALTER TABLE obe.department ADD COLUMN IF NOT EXISTS erp_id BIGINT REFERENCES public.emp_department(emp_department_id);
ALTER TABLE obe.programmes ADD COLUMN IF NOT EXISTS erp_id BIGINT REFERENCES public.courses(course_id);
ALTER TABLE obe.admission_batches ADD COLUMN IF NOT EXISTS erp_id BIGINT REFERENCES public.batches(batch_id);
ALTER TABLE obe.semesters ADD COLUMN IF NOT EXISTS erp_id BIGINT REFERENCES public.semester_defined(id);
ALTER TABLE obe.courses ADD COLUMN IF NOT EXISTS erp_id BIGINT REFERENCES public.subjects(subject_id);
ALTER TABLE obe.faculty ADD COLUMN IF NOT EXISTS erp_id BIGINT REFERENCES public.emp_master(emp_master_id);
ALTER TABLE obe.students ADD COLUMN IF NOT EXISTS erp_id BIGINT REFERENCES public.stu_master(stu_master_id);
CREATE UNIQUE INDEX IF NOT EXISTS obe_faculty_erp_unique ON obe.faculty(erp_id) WHERE erp_id IS NOT NULL;
ALTER TABLE obe.faculty DROP COLUMN IF EXISTS user_id;
ALTER TABLE obe.faculty DROP COLUMN IF EXISTS login_username;


-- The repository archive has per-CO rows; its current page saves a whole-course
-- calculation. Retain both forms and give summary rows their own upsert key.
ALTER TABLE obe.co_attainment_calculation ALTER COLUMN co_id DROP NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS obe_co_calculation_summary_unique ON obe.co_attainment_calculation(course_id,academic_year,batch) WHERE co_id IS NULL;

-- Admin account photos (PostgreSQL). Existing accounts may upload a photo when edited.
ALTER TABLE users ADD COLUMN IF NOT EXISTS photo_data BYTEA;
ALTER TABLE users ADD COLUMN IF NOT EXISTS photo_type VARCHAR(30);
ALTER TABLE users ADD COLUMN IF NOT EXISTS photo_name VARCHAR(150);
