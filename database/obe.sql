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
