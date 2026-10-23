--
-- PostgreSQL database dump
--

\restrict wU5mF77udFOZGH3NTIlm8kRou41dn2c2PH21C0pM7oq3belKAlaKSVpdMBjOzQ2

-- Dumped from database version 17.10
-- Dumped by pg_dump version 17.10

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: academic_years; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.academic_years (
    academic_year_id integer NOT NULL,
    academic_year character varying(20) NOT NULL,
    start_date date,
    end_date date,
    status character varying(20) DEFAULT 'Active'::character varying,
    CONSTRAINT academic_years_status_check CHECK (((status)::text = ANY ((ARRAY['Active'::character varying, 'Inactive'::character varying, 'Completed'::character varying])::text[])))
);


--
-- Name: academic_years_academic_year_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.academic_years_academic_year_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: academic_years_academic_year_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.academic_years_academic_year_id_seq OWNED BY public.academic_years.academic_year_id;


--
-- Name: admission_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admission_batches (
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
    CONSTRAINT admission_batches_check CHECK ((completion_year > admission_year)),
    CONSTRAINT admission_batches_status_check CHECK (((status)::text = ANY ((ARRAY['Active'::character varying, 'Completed'::character varying, 'Inactive'::character varying])::text[])))
);


--
-- Name: admission_batches_admission_batch_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admission_batches_admission_batch_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admission_batches_admission_batch_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admission_batches_admission_batch_id_seq OWNED BY public.admission_batches.admission_batch_id;


--
-- Name: articulation_matrix; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.articulation_matrix (
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


--
-- Name: articulation_matrix_articulation_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.articulation_matrix_articulation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: articulation_matrix_articulation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.articulation_matrix_articulation_id_seq OWNED BY public.articulation_matrix.articulation_id;


--
-- Name: assessment_attainment_levels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assessment_attainment_levels (
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


--
-- Name: assessment_attainment_levels_level_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assessment_attainment_levels_level_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assessment_attainment_levels_level_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assessment_attainment_levels_level_id_seq OWNED BY public.assessment_attainment_levels.level_id;


--
-- Name: assessment_co_mapping; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assessment_co_mapping (
    id integer NOT NULL,
    assessment_id integer,
    co_id integer,
    max_marks numeric(5,2)
);


--
-- Name: assessment_co_mapping_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assessment_co_mapping_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assessment_co_mapping_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assessment_co_mapping_id_seq OWNED BY public.assessment_co_mapping.id;


--
-- Name: assessment_target_configuration; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assessment_target_configuration (
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


--
-- Name: assessment_target_configuration_target_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assessment_target_configuration_target_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assessment_target_configuration_target_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assessment_target_configuration_target_id_seq OWNED BY public.assessment_target_configuration.target_id;


--
-- Name: assessments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assessments (
    assessment_id integer NOT NULL,
    course_id integer,
    assessment_name character varying(50),
    assessment_type character varying(50),
    max_marks numeric(5,2),
    weightage numeric(5,2)
);


--
-- Name: assessments_assessment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assessments_assessment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assessments_assessment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assessments_assessment_id_seq OWNED BY public.assessments.assessment_id;


--
-- Name: attainment_targets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.attainment_targets (
    target_id integer NOT NULL,
    course_id integer,
    academic_year character varying(20),
    level1_percent numeric(5,2),
    level2_percent numeric(5,2),
    level3_percent numeric(5,2)
);


--
-- Name: attainment_targets_target_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.attainment_targets_target_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: attainment_targets_target_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.attainment_targets_target_id_seq OWNED BY public.attainment_targets.target_id;


--
-- Name: batch_semesters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.batch_semesters (
    batch_semester_id integer NOT NULL,
    admission_batch_id integer NOT NULL,
    academic_year_id integer NOT NULL,
    semester_no integer NOT NULL,
    semester_name character varying(50) NOT NULL,
    study_year_no integer NOT NULL,
    term_no integer NOT NULL,
    start_date date,
    end_date date,
    status character varying(20) DEFAULT 'Planned'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT batch_semesters_semester_no_check CHECK ((semester_no > 0)),
    CONSTRAINT batch_semesters_status_check CHECK (((status)::text = ANY ((ARRAY['Planned'::character varying, 'Active'::character varying, 'Completed'::character varying, 'Cancelled'::character varying])::text[]))),
    CONSTRAINT batch_semesters_study_year_no_check CHECK ((study_year_no > 0)),
    CONSTRAINT batch_semesters_term_no_check CHECK ((term_no = ANY (ARRAY[1, 2])))
);


--
-- Name: batch_semesters_batch_semester_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.batch_semesters_batch_semester_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: batch_semesters_batch_semester_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.batch_semesters_batch_semester_id_seq OWNED BY public.batch_semesters.batch_semester_id;


--
-- Name: bloom_level; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bloom_level (
    bloom_id integer NOT NULL,
    bloom_code character varying(20) NOT NULL,
    bloom_level character varying(80) NOT NULL,
    learning_outcome_verbs text NOT NULL
);


--
-- Name: bloom_level_bloom_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bloom_level_bloom_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bloom_level_bloom_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bloom_level_bloom_id_seq OWNED BY public.bloom_level.bloom_id;


--
-- Name: co_attainment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.co_attainment (
    attainment_id integer NOT NULL,
    course_id integer,
    co_id integer,
    academic_year character varying(20),
    internal_attainment numeric(5,2),
    external_attainment numeric(5,2),
    final_attainment numeric(5,2)
);


--
-- Name: co_attainment_attainment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.co_attainment_attainment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: co_attainment_attainment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.co_attainment_attainment_id_seq OWNED BY public.co_attainment.attainment_id;


--
-- Name: co_attainment_calculation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.co_attainment_calculation (
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


--
-- Name: co_attainment_calculation_calculation_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.co_attainment_calculation_calculation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: co_attainment_calculation_calculation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.co_attainment_calculation_calculation_id_seq OWNED BY public.co_attainment_calculation.calculation_id;


--
-- Name: co_attainment_external_details; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.co_attainment_external_details (
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


--
-- Name: co_attainment_external_details_external_detail_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.co_attainment_external_details_external_detail_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: co_attainment_external_details_external_detail_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.co_attainment_external_details_external_detail_id_seq OWNED BY public.co_attainment_external_details.external_detail_id;


--
-- Name: co_attainment_internal_details; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.co_attainment_internal_details (
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


--
-- Name: co_attainment_internal_details_detail_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.co_attainment_internal_details_detail_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: co_attainment_internal_details_detail_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.co_attainment_internal_details_detail_id_seq OWNED BY public.co_attainment_internal_details.detail_id;


--
-- Name: co_po_attainment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.co_po_attainment (
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


--
-- Name: co_po_attainment_co_po_attainment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.co_po_attainment_co_po_attainment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: co_po_attainment_co_po_attainment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.co_po_attainment_co_po_attainment_id_seq OWNED BY public.co_po_attainment.co_po_attainment_id;


--
-- Name: co_po_mapping; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.co_po_mapping (
    mapping_id integer NOT NULL,
    co_id integer NOT NULL,
    po_id integer NOT NULL,
    mapping_level integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT co_po_mapping_mapping_level_check CHECK (((mapping_level >= 0) AND (mapping_level <= 3)))
);


--
-- Name: co_po_mapping_mapping_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.co_po_mapping_mapping_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: co_po_mapping_mapping_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.co_po_mapping_mapping_id_seq OWNED BY public.co_po_mapping.mapping_id;


--
-- Name: co_pso_mapping; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.co_pso_mapping (
    mapping_id integer NOT NULL,
    co_id integer,
    pso_id integer,
    mapping_level integer,
    CONSTRAINT co_pso_mapping_mapping_level_check CHECK (((mapping_level >= 0) AND (mapping_level <= 3)))
);


--
-- Name: co_pso_mapping_mapping_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.co_pso_mapping_mapping_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: co_pso_mapping_mapping_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.co_pso_mapping_mapping_id_seq OWNED BY public.co_pso_mapping.mapping_id;


--
-- Name: course_faculty; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.course_faculty (
    id integer NOT NULL,
    course_id integer,
    faculty_id integer,
    academic_year character varying(20),
    section character varying(20)
);


--
-- Name: course_faculty_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.course_faculty_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: course_faculty_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.course_faculty_id_seq OWNED BY public.course_faculty.id;


--
-- Name: course_offerings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.course_offerings (
    course_offering_id integer NOT NULL,
    course_id integer NOT NULL,
    faculty_id integer NOT NULL,
    academic_year_id integer NOT NULL,
    semester_id integer NOT NULL,
    section character varying(20),
    status character varying(20) DEFAULT 'Active'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT course_offerings_status_check CHECK (((status)::text = ANY ((ARRAY['Active'::character varying, 'Inactive'::character varying, 'Completed'::character varying])::text[])))
);


--
-- Name: course_offerings_course_offering_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.course_offerings_course_offering_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: course_offerings_course_offering_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.course_offerings_course_offering_id_seq OWNED BY public.course_offerings.course_offering_id;


--
-- Name: course_outcomes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.course_outcomes (
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


--
-- Name: course_outcomes_co_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.course_outcomes_co_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: course_outcomes_co_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.course_outcomes_co_id_seq OWNED BY public.course_outcomes.co_id;


--
-- Name: courses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.courses (
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
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: courses_course_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.courses_course_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: courses_course_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.courses_course_id_seq OWNED BY public.courses.course_id;


--
-- Name: dashboard_content; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dashboard_content (
    dashboard_content_id integer NOT NULL,
    content_type character varying(30) NOT NULL,
    content_label character varying(80) NOT NULL,
    icon character varying(20) DEFAULT ''::character varying,
    theme_color character varying(20) DEFAULT '#374151'::character varying,
    status character varying(20) DEFAULT 'Active'::character varying,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    content_statement text DEFAULT ''::text
);


--
-- Name: dashboard_content_dashboard_content_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dashboard_content_dashboard_content_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dashboard_content_dashboard_content_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dashboard_content_dashboard_content_id_seq OWNED BY public.dashboard_content.dashboard_content_id;


--
-- Name: department; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.department (
    department_id integer NOT NULL,
    department_code character varying(20) NOT NULL,
    department_name character varying(150) NOT NULL,
    institute_college character varying(150) DEFAULT ''::character varying,
    hod character varying(150) DEFAULT ''::character varying,
    email character varying(150) DEFAULT ''::character varying,
    phone character varying(40) DEFAULT ''::character varying,
    status character varying(20) DEFAULT 'Active'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: department_department_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.department_department_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: department_department_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.department_department_id_seq OWNED BY public.department.department_id;


--
-- Name: department_vision_mission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.department_vision_mission (
    department_vision_mission_id integer NOT NULL,
    department_id integer NOT NULL,
    content_type character varying(20) NOT NULL,
    content_title character varying(120) NOT NULL,
    content_statement text NOT NULL,
    status character varying(20) DEFAULT 'Active'::character varying,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: department_vision_mission_department_vision_mission_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.department_vision_mission_department_vision_mission_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: department_vision_mission_department_vision_mission_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.department_vision_mission_department_vision_mission_id_seq OWNED BY public.department_vision_mission.department_vision_mission_id;


--
-- Name: departments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.departments (
    department_id integer NOT NULL,
    department_name character varying(100) NOT NULL,
    department_code character varying(20) NOT NULL
);


--
-- Name: departments_department_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.departments_department_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: departments_department_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.departments_department_id_seq OWNED BY public.departments.department_id;


--
-- Name: external_marks_upload; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.external_marks_upload (
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


--
-- Name: external_marks_upload_mark_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.external_marks_upload_mark_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: external_marks_upload_mark_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.external_marks_upload_mark_id_seq OWNED BY public.external_marks_upload.mark_id;


--
-- Name: faculty; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.faculty (
    faculty_id integer NOT NULL,
    department_id integer,
    faculty_name character varying(100),
    email character varying(100),
    designation character varying(100),
    faculty_code character varying(80),
    login_username character varying(120),
    status character varying(20) DEFAULT 'Active'::character varying,
    user_id integer,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: faculty_course_assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.faculty_course_assignments (
    assignment_id integer NOT NULL,
    faculty_id integer NOT NULL,
    course_id integer NOT NULL,
    academic_year character varying(20) NOT NULL,
    section character varying(20),
    is_course_coordinator boolean DEFAULT false,
    assigned_by integer,
    assigned_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    status character varying(20) DEFAULT 'Active'::character varying,
    CONSTRAINT faculty_course_assignments_status_check CHECK (((status)::text = ANY ((ARRAY['Active'::character varying, 'Inactive'::character varying])::text[])))
);


--
-- Name: faculty_course_assignments_assignment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.faculty_course_assignments_assignment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: faculty_course_assignments_assignment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.faculty_course_assignments_assignment_id_seq OWNED BY public.faculty_course_assignments.assignment_id;


--
-- Name: faculty_department_mapping; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.faculty_department_mapping (
    faculty_department_id integer NOT NULL,
    user_id integer,
    department_id integer,
    academic_year character varying(20) NOT NULL,
    status character varying(20) DEFAULT 'Active'::character varying,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: faculty_department_mapping_faculty_department_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.faculty_department_mapping_faculty_department_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: faculty_department_mapping_faculty_department_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.faculty_department_mapping_faculty_department_id_seq OWNED BY public.faculty_department_mapping.faculty_department_id;


--
-- Name: faculty_faculty_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.faculty_faculty_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: faculty_faculty_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.faculty_faculty_id_seq OWNED BY public.faculty.faculty_id;


--
-- Name: faculty_import_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.faculty_import_batches (
    import_batch_id integer NOT NULL,
    file_name character varying(255) NOT NULL,
    uploaded_by integer,
    total_rows integer DEFAULT 0,
    valid_rows integer DEFAULT 0,
    invalid_rows integer DEFAULT 0,
    import_status character varying(30) DEFAULT 'Previewed'::character varying,
    uploaded_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    completed_at timestamp without time zone,
    CONSTRAINT faculty_import_batches_import_status_check CHECK (((import_status)::text = ANY ((ARRAY['Uploaded'::character varying, 'Previewed'::character varying, 'Completed'::character varying, 'Failed'::character varying])::text[])))
);


--
-- Name: faculty_import_batches_import_batch_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.faculty_import_batches_import_batch_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: faculty_import_batches_import_batch_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.faculty_import_batches_import_batch_id_seq OWNED BY public.faculty_import_batches.import_batch_id;


--
-- Name: faculty_import_rows; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.faculty_import_rows (
    import_row_id integer NOT NULL,
    import_batch_id integer NOT NULL,
    excel_row_no integer NOT NULL,
    faculty_code character varying(30),
    faculty_name character varying(150),
    designation character varying(100),
    department_code character varying(20),
    username character varying(50),
    email character varying(150),
    status character varying(20),
    validation_status character varying(20) DEFAULT 'Pending'::character varying,
    validation_message text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT faculty_import_rows_validation_status_check CHECK (((validation_status)::text = ANY ((ARRAY['Pending'::character varying, 'Valid'::character varying, 'Invalid'::character varying, 'Imported'::character varying])::text[])))
);


--
-- Name: faculty_import_rows_import_row_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.faculty_import_rows_import_row_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: faculty_import_rows_import_row_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.faculty_import_rows_import_row_id_seq OWNED BY public.faculty_import_rows.import_row_id;


--
-- Name: faculty_module_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.faculty_module_permissions (
    faculty_permission_id integer NOT NULL,
    user_id integer,
    module_id integer,
    academic_year character varying(20) NOT NULL,
    can_view boolean DEFAULT false,
    can_create boolean DEFAULT false,
    can_edit boolean DEFAULT false,
    can_delete boolean DEFAULT false,
    can_upload boolean DEFAULT false,
    can_calculate boolean DEFAULT false,
    can_export boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    department_id integer
);


--
-- Name: faculty_module_permissions_faculty_permission_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.faculty_module_permissions_faculty_permission_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: faculty_module_permissions_faculty_permission_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.faculty_module_permissions_faculty_permission_id_seq OWNED BY public.faculty_module_permissions.faculty_permission_id;


--
-- Name: faculty_user_mapping; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.faculty_user_mapping (
    faculty_user_id integer NOT NULL,
    faculty_id integer NOT NULL,
    user_id integer NOT NULL,
    assigned_by integer,
    assigned_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    status character varying(20) DEFAULT 'Active'::character varying,
    CONSTRAINT faculty_user_mapping_status_check CHECK (((status)::text = ANY ((ARRAY['Active'::character varying, 'Inactive'::character varying])::text[])))
);


--
-- Name: faculty_user_mapping_faculty_user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.faculty_user_mapping_faculty_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: faculty_user_mapping_faculty_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.faculty_user_mapping_faculty_user_id_seq OWNED BY public.faculty_user_mapping.faculty_user_id;


--
-- Name: institute_vision_mission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.institute_vision_mission (
    institute_vm_id integer NOT NULL,
    institute_name character varying(250) NOT NULL,
    vision text NOT NULL,
    mission1 text NOT NULL,
    mission2 text,
    mission3 text,
    mission4 text,
    mission5 text,
    effective_from date NOT NULL,
    effective_to date,
    status character varying(20) DEFAULT 'Active'::character varying,
    created_by integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT institute_vision_mission_status_check CHECK (((status)::text = ANY ((ARRAY['Active'::character varying, 'Inactive'::character varying])::text[])))
);


--
-- Name: institute_vision_mission_institute_vm_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.institute_vision_mission_institute_vm_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: institute_vision_mission_institute_vm_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.institute_vision_mission_institute_vm_id_seq OWNED BY public.institute_vision_mission.institute_vm_id;


--
-- Name: internal_assessment_components; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.internal_assessment_components (
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


--
-- Name: internal_assessment_components_component_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.internal_assessment_components_component_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: internal_assessment_components_component_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.internal_assessment_components_component_id_seq OWNED BY public.internal_assessment_components.component_id;


--
-- Name: internal_marks_upload; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.internal_marks_upload (
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


--
-- Name: internal_marks_upload_internal_mark_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.internal_marks_upload_internal_mark_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: internal_marks_upload_internal_mark_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.internal_marks_upload_internal_mark_id_seq OWNED BY public.internal_marks_upload.internal_mark_id;


--
-- Name: mark_attainment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mark_attainment (
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


--
-- Name: mark_attainment_mark_attainment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mark_attainment_mark_attainment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mark_attainment_mark_attainment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mark_attainment_mark_attainment_id_seq OWNED BY public.mark_attainment.mark_attainment_id;


--
-- Name: modules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.modules (
    module_id integer NOT NULL,
    module_name character varying(120) NOT NULL,
    status character varying(20) DEFAULT 'Active'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: modules_module_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.modules_module_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: modules_module_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.modules_module_id_seq OWNED BY public.modules.module_id;


--
-- Name: po_attainment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.po_attainment (
    po_attainment_id integer NOT NULL,
    programme_id integer,
    po_id integer,
    academic_year character varying(20),
    attainment_value numeric(5,2)
);


--
-- Name: po_attainment_details; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.po_attainment_details (
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


--
-- Name: po_attainment_details_detail_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.po_attainment_details_detail_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: po_attainment_details_detail_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.po_attainment_details_detail_id_seq OWNED BY public.po_attainment_details.detail_id;


--
-- Name: po_attainment_po_attainment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.po_attainment_po_attainment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: po_attainment_po_attainment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.po_attainment_po_attainment_id_seq OWNED BY public.po_attainment.po_attainment_id;


--
-- Name: programme_outcomes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.programme_outcomes (
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


--
-- Name: programme_outcomes_outcome_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.programme_outcomes_outcome_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: programme_outcomes_outcome_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.programme_outcomes_outcome_id_seq OWNED BY public.programme_outcomes.outcome_id;


--
-- Name: programme_outcomes_po_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.programme_outcomes_po_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: programme_outcomes_po_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.programme_outcomes_po_id_seq OWNED BY public.programme_outcomes.po_id;


--
-- Name: programme_specific_outcomes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.programme_specific_outcomes (
    pso_id integer NOT NULL,
    programme_id integer,
    pso_code character varying(20),
    pso_statement text
);


--
-- Name: programme_specific_outcomes_pso_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.programme_specific_outcomes_pso_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: programme_specific_outcomes_pso_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.programme_specific_outcomes_pso_id_seq OWNED BY public.programme_specific_outcomes.pso_id;


--
-- Name: programmes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.programmes (
    programme_id integer NOT NULL,
    department_id integer,
    programme_name character varying(100) NOT NULL,
    programme_code character varying(20) NOT NULL,
    duration_years integer,
    programme_type character varying(30) DEFAULT 'UG'::character varying,
    total_semesters integer DEFAULT 8,
    accreditation_status character varying(40) DEFAULT 'Accredited'::character varying,
    status character varying(20) DEFAULT 'Active'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: programmes_programme_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.programmes_programme_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: programmes_programme_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.programmes_programme_id_seq OWNED BY public.programmes.programme_id;


--
-- Name: pso_attainment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pso_attainment (
    pso_attainment_id integer NOT NULL,
    programme_id integer NOT NULL,
    academic_year character varying(20) NOT NULL,
    admission_batch_id integer,
    calculation_method character varying(20) DEFAULT 'Direct'::character varying,
    calculated_by integer,
    calculated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    status character varying(20) DEFAULT 'Calculated'::character varying,
    CONSTRAINT pso_attainment_calculation_method_check CHECK (((calculation_method)::text = ANY ((ARRAY['Direct'::character varying, 'Indirect'::character varying, 'Overall'::character varying])::text[])))
);


--
-- Name: pso_attainment_details; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pso_attainment_details (
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


--
-- Name: pso_attainment_details_detail_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pso_attainment_details_detail_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pso_attainment_details_detail_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pso_attainment_details_detail_id_seq OWNED BY public.pso_attainment_details.detail_id;


--
-- Name: pso_attainment_pso_attainment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pso_attainment_pso_attainment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pso_attainment_pso_attainment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pso_attainment_pso_attainment_id_seq OWNED BY public.pso_attainment.pso_attainment_id;


--
-- Name: pso_attainment_summary; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pso_attainment_summary (
    summary_id integer NOT NULL,
    pso_attainment_id integer NOT NULL,
    pso_id integer NOT NULL,
    direct_attainment numeric(6,2),
    level_code character varying(10),
    level_point integer,
    remarks text,
    CONSTRAINT pso_attainment_summary_level_point_check CHECK (((level_point >= 1) AND (level_point <= 3)))
);


--
-- Name: pso_attainment_summary_summary_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pso_attainment_summary_summary_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pso_attainment_summary_summary_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pso_attainment_summary_summary_id_seq OWNED BY public.pso_attainment_summary.summary_id;


--
-- Name: semesters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.semesters (
    semester_id integer NOT NULL,
    programme_id integer,
    semester_no integer NOT NULL,
    department_id integer,
    semester_number integer,
    semester_name character varying(80) DEFAULT ''::character varying,
    academic_year character varying(20) DEFAULT ''::character varying,
    status character varying(20) DEFAULT 'Active'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    admission_batch_id integer
);


--
-- Name: semesters_semester_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.semesters_semester_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: semesters_semester_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.semesters_semester_id_seq OWNED BY public.semesters.semester_id;


--
-- Name: student_course_enrollments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.student_course_enrollments (
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
    CONSTRAINT student_course_enrollments_enrollment_status_check CHECK (((enrollment_status)::text = ANY ((ARRAY['Enrolled'::character varying, 'Dropped'::character varying, 'Completed'::character varying, 'Backlog'::character varying])::text[])))
);


--
-- Name: student_course_enrollments_enrollment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.student_course_enrollments_enrollment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: student_course_enrollments_enrollment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.student_course_enrollments_enrollment_id_seq OWNED BY public.student_course_enrollments.enrollment_id;


--
-- Name: student_marks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.student_marks (
    mark_id integer NOT NULL,
    student_id integer,
    assessment_id integer,
    marks_obtained numeric(5,2)
);


--
-- Name: student_marks_mark_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.student_marks_mark_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: student_marks_mark_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.student_marks_mark_id_seq OWNED BY public.student_marks.mark_id;


--
-- Name: students; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.students (
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
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: students_student_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.students_student_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: students_student_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.students_student_id_seq OWNED BY public.students.student_id;


--
-- Name: university_question_mapping; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.university_question_mapping (
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


--
-- Name: university_question_mapping_question_mapping_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.university_question_mapping_question_mapping_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: university_question_mapping_question_mapping_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.university_question_mapping_question_mapping_id_seq OWNED BY public.university_question_mapping.question_mapping_id;


--
-- Name: university_question_papers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.university_question_papers (
    question_paper_id integer NOT NULL,
    course_id integer NOT NULL,
    academic_year character varying(20) NOT NULL,
    exam_type character varying(50) NOT NULL,
    exam_month character varying(20),
    exam_year integer,
    total_marks numeric(6,2),
    status character varying(20) DEFAULT 'Active'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: university_question_papers_question_paper_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.university_question_papers_question_paper_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: university_question_papers_question_paper_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.university_question_papers_question_paper_id_seq OWNED BY public.university_question_papers.question_paper_id;


--
-- Name: user_course_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_course_permissions (
    user_course_permission_id integer NOT NULL,
    user_id integer NOT NULL,
    course_id integer NOT NULL,
    academic_year character varying(20),
    can_view boolean DEFAULT true,
    can_upload_marks boolean DEFAULT false,
    can_save_marks boolean DEFAULT false,
    can_calculate_attainment boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: user_course_permissions_user_course_permission_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_course_permissions_user_course_permission_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_course_permissions_user_course_permission_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_course_permissions_user_course_permission_id_seq OWNED BY public.user_course_permissions.user_course_permission_id;


--
-- Name: user_module_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_module_permissions (
    permission_id integer NOT NULL,
    user_id integer,
    module_id integer,
    can_access boolean DEFAULT true
);


--
-- Name: user_module_permissions_permission_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_module_permissions_permission_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_module_permissions_permission_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_module_permissions_permission_id_seq OWNED BY public.user_module_permissions.permission_id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    user_id integer NOT NULL,
    full_name character varying(100) NOT NULL,
    email character varying(100) NOT NULL,
    password_hash text NOT NULL,
    department_id integer,
    user_type character varying(20) DEFAULT 'User'::character varying NOT NULL,
    status character varying(20) DEFAULT 'Active'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    role character varying(20) DEFAULT 'User'::character varying,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    username character varying(120),
    CONSTRAINT users_user_type_check CHECK (((user_type)::text = ANY ((ARRAY['Admin'::character varying, 'User'::character varying])::text[])))
);


--
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_user_id_seq OWNED BY public.users.user_id;


--
-- Name: academic_years academic_year_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.academic_years ALTER COLUMN academic_year_id SET DEFAULT nextval('public.academic_years_academic_year_id_seq'::regclass);


--
-- Name: admission_batches admission_batch_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admission_batches ALTER COLUMN admission_batch_id SET DEFAULT nextval('public.admission_batches_admission_batch_id_seq'::regclass);


--
-- Name: articulation_matrix articulation_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.articulation_matrix ALTER COLUMN articulation_id SET DEFAULT nextval('public.articulation_matrix_articulation_id_seq'::regclass);


--
-- Name: assessment_attainment_levels level_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_attainment_levels ALTER COLUMN level_id SET DEFAULT nextval('public.assessment_attainment_levels_level_id_seq'::regclass);


--
-- Name: assessment_co_mapping id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_co_mapping ALTER COLUMN id SET DEFAULT nextval('public.assessment_co_mapping_id_seq'::regclass);


--
-- Name: assessment_target_configuration target_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_target_configuration ALTER COLUMN target_id SET DEFAULT nextval('public.assessment_target_configuration_target_id_seq'::regclass);


--
-- Name: assessments assessment_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessments ALTER COLUMN assessment_id SET DEFAULT nextval('public.assessments_assessment_id_seq'::regclass);


--
-- Name: attainment_targets target_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attainment_targets ALTER COLUMN target_id SET DEFAULT nextval('public.attainment_targets_target_id_seq'::regclass);


--
-- Name: batch_semesters batch_semester_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.batch_semesters ALTER COLUMN batch_semester_id SET DEFAULT nextval('public.batch_semesters_batch_semester_id_seq'::regclass);


--
-- Name: bloom_level bloom_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bloom_level ALTER COLUMN bloom_id SET DEFAULT nextval('public.bloom_level_bloom_id_seq'::regclass);


--
-- Name: co_attainment attainment_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.co_attainment ALTER COLUMN attainment_id SET DEFAULT nextval('public.co_attainment_attainment_id_seq'::regclass);


--
-- Name: co_attainment_calculation calculation_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.co_attainment_calculation ALTER COLUMN calculation_id SET DEFAULT nextval('public.co_attainment_calculation_calculation_id_seq'::regclass);


--
-- Name: co_attainment_external_details external_detail_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.co_attainment_external_details ALTER COLUMN external_detail_id SET DEFAULT nextval('public.co_attainment_external_details_external_detail_id_seq'::regclass);


--
-- Name: co_attainment_internal_details detail_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.co_attainment_internal_details ALTER COLUMN detail_id SET DEFAULT nextval('public.co_attainment_internal_details_detail_id_seq'::regclass);


--
-- Name: co_po_attainment co_po_attainment_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.co_po_attainment ALTER COLUMN co_po_attainment_id SET DEFAULT nextval('public.co_po_attainment_co_po_attainment_id_seq'::regclass);


--
-- Name: co_po_mapping mapping_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.co_po_mapping ALTER COLUMN mapping_id SET DEFAULT nextval('public.co_po_mapping_mapping_id_seq'::regclass);


--
-- Name: co_pso_mapping mapping_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.co_pso_mapping ALTER COLUMN mapping_id SET DEFAULT nextval('public.co_pso_mapping_mapping_id_seq'::regclass);


--
-- Name: course_faculty id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_faculty ALTER COLUMN id SET DEFAULT nextval('public.course_faculty_id_seq'::regclass);


--
-- Name: course_offerings course_offering_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_offerings ALTER COLUMN course_offering_id SET DEFAULT nextval('public.course_offerings_course_offering_id_seq'::regclass);


--
-- Name: course_outcomes co_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_outcomes ALTER COLUMN co_id SET DEFAULT nextval('public.course_outcomes_co_id_seq'::regclass);


--
-- Name: courses course_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses ALTER COLUMN course_id SET DEFAULT nextval('public.courses_course_id_seq'::regclass);


--
-- Name: dashboard_content dashboard_content_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dashboard_content ALTER COLUMN dashboard_content_id SET DEFAULT nextval('public.dashboard_content_dashboard_content_id_seq'::regclass);


--
-- Name: department department_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.department ALTER COLUMN department_id SET DEFAULT nextval('public.department_department_id_seq'::regclass);


--
-- Name: department_vision_mission department_vision_mission_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.department_vision_mission ALTER COLUMN department_vision_mission_id SET DEFAULT nextval('public.department_vision_mission_department_vision_mission_id_seq'::regclass);


--
-- Name: departments department_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments ALTER COLUMN department_id SET DEFAULT nextval('public.departments_department_id_seq'::regclass);


--
-- Name: external_marks_upload mark_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_marks_upload ALTER COLUMN mark_id SET DEFAULT nextval('public.external_marks_upload_mark_id_seq'::regclass);


--
-- Name: faculty faculty_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculty ALTER COLUMN faculty_id SET DEFAULT nextval('public.faculty_faculty_id_seq'::regclass);


--
-- Name: faculty_course_assignments assignment_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculty_course_assignments ALTER COLUMN assignment_id SET DEFAULT nextval('public.faculty_course_assignments_assignment_id_seq'::regclass);


--
-- Name: faculty_department_mapping faculty_department_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculty_department_mapping ALTER COLUMN faculty_department_id SET DEFAULT nextval('public.faculty_department_mapping_faculty_department_id_seq'::regclass);


--
-- Name: faculty_import_batches import_batch_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculty_import_batches ALTER COLUMN import_batch_id SET DEFAULT nextval('public.faculty_import_batches_import_batch_id_seq'::regclass);


--
-- Name: faculty_import_rows import_row_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculty_import_rows ALTER COLUMN import_row_id SET DEFAULT nextval('public.faculty_import_rows_import_row_id_seq'::regclass);


--
-- Name: faculty_module_permissions faculty_permission_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculty_module_permissions ALTER COLUMN faculty_permission_id SET DEFAULT nextval('public.faculty_module_permissions_faculty_permission_id_seq'::regclass);


--
-- Name: faculty_user_mapping faculty_user_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculty_user_mapping ALTER COLUMN faculty_user_id SET DEFAULT nextval('public.faculty_user_mapping_faculty_user_id_seq'::regclass);


--
-- Name: institute_vision_mission institute_vm_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.institute_vision_mission ALTER COLUMN institute_vm_id SET DEFAULT nextval('public.institute_vision_mission_institute_vm_id_seq'::regclass);


--
-- Name: internal_assessment_components component_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.internal_assessment_components ALTER COLUMN component_id SET DEFAULT nextval('public.internal_assessment_components_component_id_seq'::regclass);


--
-- Name: internal_marks_upload internal_mark_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.internal_marks_upload ALTER COLUMN internal_mark_id SET DEFAULT nextval('public.internal_marks_upload_internal_mark_id_seq'::regclass);


--
-- Name: mark_attainment mark_attainment_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mark_attainment ALTER COLUMN mark_attainment_id SET DEFAULT nextval('public.mark_attainment_mark_attainment_id_seq'::regclass);


--
-- Name: modules module_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modules ALTER COLUMN module_id SET DEFAULT nextval('public.modules_module_id_seq'::regclass);


--
-- Name: po_attainment po_attainment_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.po_attainment ALTER COLUMN po_attainment_id SET DEFAULT nextval('public.po_attainment_po_attainment_id_seq'::regclass);


--
-- Name: po_attainment_details detail_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.po_attainment_details ALTER COLUMN detail_id SET DEFAULT nextval('public.po_attainment_details_detail_id_seq'::regclass);


--
-- Name: programme_outcomes po_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programme_outcomes ALTER COLUMN po_id SET DEFAULT nextval('public.programme_outcomes_po_id_seq'::regclass);


--
-- Name: programme_outcomes outcome_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programme_outcomes ALTER COLUMN outcome_id SET DEFAULT nextval('public.programme_outcomes_outcome_id_seq'::regclass);


--
-- Name: programme_specific_outcomes pso_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programme_specific_outcomes ALTER COLUMN pso_id SET DEFAULT nextval('public.programme_specific_outcomes_pso_id_seq'::regclass);


--
-- Name: programmes programme_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programmes ALTER COLUMN programme_id SET DEFAULT nextval('public.programmes_programme_id_seq'::regclass);


--
-- Name: pso_attainment pso_attainment_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pso_attainment ALTER COLUMN pso_attainment_id SET DEFAULT nextval('public.pso_attainment_pso_attainment_id_seq'::regclass);


--
-- Name: pso_attainment_details detail_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pso_attainment_details ALTER COLUMN detail_id SET DEFAULT nextval('public.pso_attainment_details_detail_id_seq'::regclass);


--
-- Name: pso_attainment_summary summary_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pso_attainment_summary ALTER COLUMN summary_id SET DEFAULT nextval('public.pso_attainment_summary_summary_id_seq'::regclass);


--
-- Name: semesters semester_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.semesters ALTER COLUMN semester_id SET DEFAULT nextval('public.semesters_semester_id_seq'::regclass);


--
-- Name: student_course_enrollments enrollment_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_course_enrollments ALTER COLUMN enrollment_id SET DEFAULT nextval('public.student_course_enrollments_enrollment_id_seq'::regclass);


--
-- Name: student_marks mark_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_marks ALTER COLUMN mark_id SET DEFAULT nextval('public.student_marks_mark_id_seq'::regclass);


--
-- Name: students student_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.students ALTER COLUMN student_id SET DEFAULT nextval('public.students_student_id_seq'::regclass);


--
-- Name: university_question_mapping question_mapping_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.university_question_mapping ALTER COLUMN question_mapping_id SET DEFAULT nextval('public.university_question_mapping_question_mapping_id_seq'::regclass);


--
-- Name: university_question_papers question_paper_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.university_question_papers ALTER COLUMN question_paper_id SET DEFAULT nextval('public.university_question_papers_question_paper_id_seq'::regclass);


--
-- Name: user_course_permissions user_course_permission_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_course_permissions ALTER COLUMN user_course_permission_id SET DEFAULT nextval('public.user_course_permissions_user_course_permission_id_seq'::regclass);


--
-- Name: user_module_permissions permission_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_module_permissions ALTER COLUMN permission_id SET DEFAULT nextval('public.user_module_permissions_permission_id_seq'::regclass);


--
-- Name: users user_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN user_id SET DEFAULT nextval('public.users_user_id_seq'::regclass);


--
-- Name: academic_years academic_years_academic_year_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.academic_years
    ADD CONSTRAINT academic_years_academic_year_key UNIQUE (academic_year);


--
-- Name: academic_years academic_years_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.academic_years
    ADD CONSTRAINT academic_years_pkey PRIMARY KEY (academic_year_id);


--
-- Name: admission_batches admission_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admission_batches
    ADD CONSTRAINT admission_batches_pkey PRIMARY KEY (admission_batch_id);


--
-- Name: admission_batches admission_batches_programme_id_batch_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admission_batches
    ADD CONSTRAINT admission_batches_programme_id_batch_code_key UNIQUE (programme_id, batch_code);


--
-- Name: articulation_matrix articulation_matrix_course_id_co_id_component_id_academic_y_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.articulation_matrix
    ADD CONSTRAINT articulation_matrix_course_id_co_id_component_id_academic_y_key UNIQUE (course_id, co_id, component_id, academic_year);


--
-- Name: articulation_matrix articulation_matrix_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.articulation_matrix
    ADD CONSTRAINT articulation_matrix_pkey PRIMARY KEY (articulation_id);


--
-- Name: assessment_attainment_levels assessment_attainment_levels_academic_year_assessment_categ_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_attainment_levels
    ADD CONSTRAINT assessment_attainment_levels_academic_year_assessment_categ_key UNIQUE (academic_year, assessment_category, level_number);


--
-- Name: assessment_attainment_levels assessment_attainment_levels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_attainment_levels
    ADD CONSTRAINT assessment_attainment_levels_pkey PRIMARY KEY (level_id);


--
-- Name: assessment_co_mapping assessment_co_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_co_mapping
    ADD CONSTRAINT assessment_co_mapping_pkey PRIMARY KEY (id);


--
-- Name: assessment_target_configuration assessment_target_configurati_course_id_component_id_academ_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_target_configuration
    ADD CONSTRAINT assessment_target_configurati_course_id_component_id_academ_key UNIQUE (course_id, component_id, academic_year);


--
-- Name: assessment_target_configuration assessment_target_configuration_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_target_configuration
    ADD CONSTRAINT assessment_target_configuration_pkey PRIMARY KEY (target_id);


--
-- Name: assessments assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessments
    ADD CONSTRAINT assessments_pkey PRIMARY KEY (assessment_id);


--
-- Name: attainment_targets attainment_targets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attainment_targets
    ADD CONSTRAINT attainment_targets_pkey PRIMARY KEY (target_id);


--
-- Name: batch_semesters batch_semesters_admission_batch_id_semester_no_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.batch_semesters
    ADD CONSTRAINT batch_semesters_admission_batch_id_semester_no_key UNIQUE (admission_batch_id, semester_no);


--
-- Name: batch_semesters batch_semesters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.batch_semesters
    ADD CONSTRAINT batch_semesters_pkey PRIMARY KEY (batch_semester_id);


--
-- Name: bloom_level bloom_level_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bloom_level
    ADD CONSTRAINT bloom_level_pkey PRIMARY KEY (bloom_id);


--
-- Name: co_attainment_calculation co_attainment_calculation_course_id_co_id_academic_year_bat_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.co_attainment_calculation
    ADD CONSTRAINT co_attainment_calculation_course_id_co_id_academic_year_bat_key UNIQUE (course_id, co_id, academic_year, batch);


--
-- Name: co_attainment_calculation co_attainment_calculation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.co_attainment_calculation
    ADD CONSTRAINT co_attainment_calculation_pkey PRIMARY KEY (calculation_id);


--
-- Name: co_attainment_external_details co_attainment_external_detail_calculation_id_question_paper_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.co_attainment_external_details
    ADD CONSTRAINT co_attainment_external_detail_calculation_id_question_paper_key UNIQUE (calculation_id, question_paper_id);


--
-- Name: co_attainment_external_details co_attainment_external_details_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.co_attainment_external_details
    ADD CONSTRAINT co_attainment_external_details_pkey PRIMARY KEY (external_detail_id);


--
-- Name: co_attainment_internal_details co_attainment_internal_details_calculation_id_component_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.co_attainment_internal_details
    ADD CONSTRAINT co_attainment_internal_details_calculation_id_component_id_key UNIQUE (calculation_id, component_id);


--
-- Name: co_attainment_internal_details co_attainment_internal_details_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.co_attainment_internal_details
    ADD CONSTRAINT co_attainment_internal_details_pkey PRIMARY KEY (detail_id);


--
-- Name: co_attainment co_attainment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.co_attainment
    ADD CONSTRAINT co_attainment_pkey PRIMARY KEY (attainment_id);


--
-- Name: co_po_attainment co_po_attainment_course_id_academic_year_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.co_po_attainment
    ADD CONSTRAINT co_po_attainment_course_id_academic_year_key UNIQUE (course_id, academic_year);


--
-- Name: co_po_attainment co_po_attainment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.co_po_attainment
    ADD CONSTRAINT co_po_attainment_pkey PRIMARY KEY (co_po_attainment_id);


--
-- Name: co_po_mapping co_po_mapping_co_id_po_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.co_po_mapping
    ADD CONSTRAINT co_po_mapping_co_id_po_id_key UNIQUE (co_id, po_id);


--
-- Name: co_po_mapping co_po_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.co_po_mapping
    ADD CONSTRAINT co_po_mapping_pkey PRIMARY KEY (mapping_id);


--
-- Name: co_pso_mapping co_pso_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.co_pso_mapping
    ADD CONSTRAINT co_pso_mapping_pkey PRIMARY KEY (mapping_id);


--
-- Name: course_faculty course_faculty_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_faculty
    ADD CONSTRAINT course_faculty_pkey PRIMARY KEY (id);


--
-- Name: course_offerings course_offerings_course_id_faculty_id_academic_year_id_seme_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_offerings
    ADD CONSTRAINT course_offerings_course_id_faculty_id_academic_year_id_seme_key UNIQUE (course_id, faculty_id, academic_year_id, semester_id, section);


--
-- Name: course_offerings course_offerings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_offerings
    ADD CONSTRAINT course_offerings_pkey PRIMARY KEY (course_offering_id);


--
-- Name: course_outcomes course_outcomes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_outcomes
    ADD CONSTRAINT course_outcomes_pkey PRIMARY KEY (co_id);


--
-- Name: courses courses_course_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT courses_course_code_key UNIQUE (course_code);


--
-- Name: courses courses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT courses_pkey PRIMARY KEY (course_id);


--
-- Name: dashboard_content dashboard_content_content_type_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dashboard_content
    ADD CONSTRAINT dashboard_content_content_type_key UNIQUE (content_type);


--
-- Name: dashboard_content dashboard_content_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dashboard_content
    ADD CONSTRAINT dashboard_content_pkey PRIMARY KEY (dashboard_content_id);


--
-- Name: department department_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.department
    ADD CONSTRAINT department_pkey PRIMARY KEY (department_id);


--
-- Name: department_vision_mission department_vision_mission_department_id_content_type_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.department_vision_mission
    ADD CONSTRAINT department_vision_mission_department_id_content_type_key UNIQUE (department_id, content_type);


--
-- Name: department_vision_mission department_vision_mission_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.department_vision_mission
    ADD CONSTRAINT department_vision_mission_pkey PRIMARY KEY (department_vision_mission_id);


--
-- Name: departments departments_department_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_department_code_key UNIQUE (department_code);


--
-- Name: departments departments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (department_id);


--
-- Name: external_marks_upload external_marks_upload_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_marks_upload
    ADD CONSTRAINT external_marks_upload_pkey PRIMARY KEY (mark_id);


--
-- Name: faculty_course_assignments faculty_course_assignments_faculty_id_course_id_academic_ye_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculty_course_assignments
    ADD CONSTRAINT faculty_course_assignments_faculty_id_course_id_academic_ye_key UNIQUE (faculty_id, course_id, academic_year, section);


--
-- Name: faculty_course_assignments faculty_course_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculty_course_assignments
    ADD CONSTRAINT faculty_course_assignments_pkey PRIMARY KEY (assignment_id);


--
-- Name: faculty_department_mapping faculty_department_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculty_department_mapping
    ADD CONSTRAINT faculty_department_mapping_pkey PRIMARY KEY (faculty_department_id);


--
-- Name: faculty_department_mapping faculty_department_mapping_user_id_department_id_academic_y_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculty_department_mapping
    ADD CONSTRAINT faculty_department_mapping_user_id_department_id_academic_y_key UNIQUE (user_id, department_id, academic_year);


--
-- Name: faculty_import_batches faculty_import_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculty_import_batches
    ADD CONSTRAINT faculty_import_batches_pkey PRIMARY KEY (import_batch_id);


--
-- Name: faculty_import_rows faculty_import_rows_import_batch_id_excel_row_no_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculty_import_rows
    ADD CONSTRAINT faculty_import_rows_import_batch_id_excel_row_no_key UNIQUE (import_batch_id, excel_row_no);


--
-- Name: faculty_import_rows faculty_import_rows_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculty_import_rows
    ADD CONSTRAINT faculty_import_rows_pkey PRIMARY KEY (import_row_id);


--
-- Name: faculty_module_permissions faculty_module_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculty_module_permissions
    ADD CONSTRAINT faculty_module_permissions_pkey PRIMARY KEY (faculty_permission_id);


--
-- Name: faculty_module_permissions faculty_module_permissions_user_department_module_year_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculty_module_permissions
    ADD CONSTRAINT faculty_module_permissions_user_department_module_year_key UNIQUE (user_id, department_id, module_id, academic_year);


--
-- Name: faculty faculty_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculty
    ADD CONSTRAINT faculty_pkey PRIMARY KEY (faculty_id);


--
-- Name: faculty_user_mapping faculty_user_mapping_faculty_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculty_user_mapping
    ADD CONSTRAINT faculty_user_mapping_faculty_id_key UNIQUE (faculty_id);


--
-- Name: faculty_user_mapping faculty_user_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculty_user_mapping
    ADD CONSTRAINT faculty_user_mapping_pkey PRIMARY KEY (faculty_user_id);


--
-- Name: faculty_user_mapping faculty_user_mapping_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculty_user_mapping
    ADD CONSTRAINT faculty_user_mapping_user_id_key UNIQUE (user_id);


--
-- Name: institute_vision_mission institute_vision_mission_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.institute_vision_mission
    ADD CONSTRAINT institute_vision_mission_pkey PRIMARY KEY (institute_vm_id);


--
-- Name: internal_assessment_components internal_assessment_component_course_id_component_code_acad_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.internal_assessment_components
    ADD CONSTRAINT internal_assessment_component_course_id_component_code_acad_key UNIQUE (course_id, component_code, academic_year);


--
-- Name: internal_assessment_components internal_assessment_components_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.internal_assessment_components
    ADD CONSTRAINT internal_assessment_components_pkey PRIMARY KEY (component_id);


--
-- Name: internal_marks_upload internal_marks_upload_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.internal_marks_upload
    ADD CONSTRAINT internal_marks_upload_pkey PRIMARY KEY (internal_mark_id);


--
-- Name: mark_attainment mark_attainment_course_id_academic_year_assessment_tool_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mark_attainment
    ADD CONSTRAINT mark_attainment_course_id_academic_year_assessment_tool_key UNIQUE (course_id, academic_year, assessment_tool);


--
-- Name: mark_attainment mark_attainment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mark_attainment
    ADD CONSTRAINT mark_attainment_pkey PRIMARY KEY (mark_attainment_id);


--
-- Name: modules modules_module_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modules
    ADD CONSTRAINT modules_module_name_key UNIQUE (module_name);


--
-- Name: modules modules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modules
    ADD CONSTRAINT modules_pkey PRIMARY KEY (module_id);


--
-- Name: po_attainment_details po_attainment_details_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.po_attainment_details
    ADD CONSTRAINT po_attainment_details_pkey PRIMARY KEY (detail_id);


--
-- Name: po_attainment_details po_attainment_details_po_attainment_id_co_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.po_attainment_details
    ADD CONSTRAINT po_attainment_details_po_attainment_id_co_id_key UNIQUE (po_attainment_id, co_id);


--
-- Name: po_attainment po_attainment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.po_attainment
    ADD CONSTRAINT po_attainment_pkey PRIMARY KEY (po_attainment_id);


--
-- Name: programme_outcomes programme_outcomes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programme_outcomes
    ADD CONSTRAINT programme_outcomes_pkey PRIMARY KEY (po_id);


--
-- Name: programme_specific_outcomes programme_specific_outcomes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programme_specific_outcomes
    ADD CONSTRAINT programme_specific_outcomes_pkey PRIMARY KEY (pso_id);


--
-- Name: programmes programmes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programmes
    ADD CONSTRAINT programmes_pkey PRIMARY KEY (programme_id);


--
-- Name: programmes programmes_programme_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programmes
    ADD CONSTRAINT programmes_programme_code_key UNIQUE (programme_code);


--
-- Name: pso_attainment_details pso_attainment_details_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pso_attainment_details
    ADD CONSTRAINT pso_attainment_details_pkey PRIMARY KEY (detail_id);


--
-- Name: pso_attainment_details pso_attainment_details_pso_attainment_id_co_id_pso_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pso_attainment_details
    ADD CONSTRAINT pso_attainment_details_pso_attainment_id_co_id_pso_id_key UNIQUE (pso_attainment_id, co_id, pso_id);


--
-- Name: pso_attainment pso_attainment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pso_attainment
    ADD CONSTRAINT pso_attainment_pkey PRIMARY KEY (pso_attainment_id);


--
-- Name: pso_attainment pso_attainment_programme_id_academic_year_admission_batch_i_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pso_attainment
    ADD CONSTRAINT pso_attainment_programme_id_academic_year_admission_batch_i_key UNIQUE (programme_id, academic_year, admission_batch_id, calculation_method);


--
-- Name: pso_attainment_summary pso_attainment_summary_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pso_attainment_summary
    ADD CONSTRAINT pso_attainment_summary_pkey PRIMARY KEY (summary_id);


--
-- Name: pso_attainment_summary pso_attainment_summary_pso_attainment_id_pso_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pso_attainment_summary
    ADD CONSTRAINT pso_attainment_summary_pso_attainment_id_pso_id_key UNIQUE (pso_attainment_id, pso_id);


--
-- Name: semesters semesters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.semesters
    ADD CONSTRAINT semesters_pkey PRIMARY KEY (semester_id);


--
-- Name: student_course_enrollments student_course_enrollments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_course_enrollments
    ADD CONSTRAINT student_course_enrollments_pkey PRIMARY KEY (enrollment_id);


--
-- Name: student_course_enrollments student_course_enrollments_student_id_course_offering_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_course_enrollments
    ADD CONSTRAINT student_course_enrollments_student_id_course_offering_id_key UNIQUE (student_id, course_offering_id);


--
-- Name: student_marks student_marks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_marks
    ADD CONSTRAINT student_marks_pkey PRIMARY KEY (mark_id);


--
-- Name: students students_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_pkey PRIMARY KEY (student_id);


--
-- Name: students students_regd_no_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_regd_no_key UNIQUE (regd_no);


--
-- Name: university_question_mapping university_question_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.university_question_mapping
    ADD CONSTRAINT university_question_mapping_pkey PRIMARY KEY (question_mapping_id);


--
-- Name: university_question_papers university_question_papers_course_id_academic_year_exam_typ_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.university_question_papers
    ADD CONSTRAINT university_question_papers_course_id_academic_year_exam_typ_key UNIQUE (course_id, academic_year, exam_type, exam_month, exam_year);


--
-- Name: university_question_papers university_question_papers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.university_question_papers
    ADD CONSTRAINT university_question_papers_pkey PRIMARY KEY (question_paper_id);


--
-- Name: user_course_permissions user_course_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_course_permissions
    ADD CONSTRAINT user_course_permissions_pkey PRIMARY KEY (user_course_permission_id);


--
-- Name: user_course_permissions user_course_permissions_user_id_course_id_academic_year_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_course_permissions
    ADD CONSTRAINT user_course_permissions_user_id_course_id_academic_year_key UNIQUE (user_id, course_id, academic_year);


--
-- Name: user_module_permissions user_module_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_module_permissions
    ADD CONSTRAINT user_module_permissions_pkey PRIMARY KEY (permission_id);


--
-- Name: user_module_permissions user_module_permissions_user_id_module_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_module_permissions
    ADD CONSTRAINT user_module_permissions_user_id_module_id_key UNIQUE (user_id, module_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: admission_batches_generated_id_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX admission_batches_generated_id_key ON public.admission_batches USING btree (admission_batch_id);


--
-- Name: department_vision_mission_department_type_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX department_vision_mission_department_type_key ON public.department_vision_mission USING btree (department_id, content_type);


--
-- Name: admission_batches admission_batches_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admission_batches
    ADD CONSTRAINT admission_batches_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.department(department_id) ON DELETE SET NULL;


--
-- Name: admission_batches admission_batches_programme_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admission_batches
    ADD CONSTRAINT admission_batches_programme_id_fkey FOREIGN KEY (programme_id) REFERENCES public.programmes(programme_id) ON DELETE RESTRICT;


--
-- Name: admission_batches admission_batches_start_academic_year_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admission_batches
    ADD CONSTRAINT admission_batches_start_academic_year_id_fkey FOREIGN KEY (start_academic_year_id) REFERENCES public.academic_years(academic_year_id) ON DELETE RESTRICT;


--
-- Name: articulation_matrix articulation_matrix_co_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.articulation_matrix
    ADD CONSTRAINT articulation_matrix_co_id_fkey FOREIGN KEY (co_id) REFERENCES public.course_outcomes(co_id) ON DELETE CASCADE;


--
-- Name: articulation_matrix articulation_matrix_component_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.articulation_matrix
    ADD CONSTRAINT articulation_matrix_component_id_fkey FOREIGN KEY (component_id) REFERENCES public.internal_assessment_components(component_id) ON DELETE CASCADE;


--
-- Name: articulation_matrix articulation_matrix_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.articulation_matrix
    ADD CONSTRAINT articulation_matrix_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(course_id) ON DELETE CASCADE;


--
-- Name: assessment_co_mapping assessment_co_mapping_assessment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_co_mapping
    ADD CONSTRAINT assessment_co_mapping_assessment_id_fkey FOREIGN KEY (assessment_id) REFERENCES public.assessments(assessment_id);


--
-- Name: assessment_co_mapping assessment_co_mapping_co_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_co_mapping
    ADD CONSTRAINT assessment_co_mapping_co_id_fkey FOREIGN KEY (co_id) REFERENCES public.course_outcomes(co_id);


--
-- Name: assessment_target_configuration assessment_target_configuration_component_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_target_configuration
    ADD CONSTRAINT assessment_target_configuration_component_id_fkey FOREIGN KEY (component_id) REFERENCES public.internal_assessment_components(component_id) ON DELETE CASCADE;


--
-- Name: assessment_target_configuration assessment_target_configuration_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_target_configuration
    ADD CONSTRAINT assessment_target_configuration_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(course_id) ON DELETE CASCADE;


--
-- Name: assessments assessments_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessments
    ADD CONSTRAINT assessments_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(course_id);


--
-- Name: attainment_targets attainment_targets_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attainment_targets
    ADD CONSTRAINT attainment_targets_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(course_id);


--
-- Name: batch_semesters batch_semesters_academic_year_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.batch_semesters
    ADD CONSTRAINT batch_semesters_academic_year_id_fkey FOREIGN KEY (academic_year_id) REFERENCES public.academic_years(academic_year_id) ON DELETE RESTRICT;


--
-- Name: batch_semesters batch_semesters_admission_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.batch_semesters
    ADD CONSTRAINT batch_semesters_admission_batch_id_fkey FOREIGN KEY (admission_batch_id) REFERENCES public.admission_batches(admission_batch_id) ON DELETE CASCADE;


--
-- Name: co_attainment_calculation co_attainment_calculation_co_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.co_attainment_calculation
    ADD CONSTRAINT co_attainment_calculation_co_id_fkey FOREIGN KEY (co_id) REFERENCES public.course_outcomes(co_id) ON DELETE CASCADE;


--
-- Name: co_attainment_calculation co_attainment_calculation_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.co_attainment_calculation
    ADD CONSTRAINT co_attainment_calculation_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(course_id) ON DELETE CASCADE;


--
-- Name: co_attainment co_attainment_co_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.co_attainment
    ADD CONSTRAINT co_attainment_co_id_fkey FOREIGN KEY (co_id) REFERENCES public.course_outcomes(co_id);


--
-- Name: co_attainment co_attainment_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.co_attainment
    ADD CONSTRAINT co_attainment_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(course_id);


--
-- Name: co_attainment_external_details co_attainment_external_details_calculation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.co_attainment_external_details
    ADD CONSTRAINT co_attainment_external_details_calculation_id_fkey FOREIGN KEY (calculation_id) REFERENCES public.co_attainment_calculation(calculation_id) ON DELETE CASCADE;


--
-- Name: co_attainment_external_details co_attainment_external_details_question_paper_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.co_attainment_external_details
    ADD CONSTRAINT co_attainment_external_details_question_paper_id_fkey FOREIGN KEY (question_paper_id) REFERENCES public.university_question_papers(question_paper_id) ON DELETE CASCADE;


--
-- Name: co_attainment_internal_details co_attainment_internal_details_calculation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.co_attainment_internal_details
    ADD CONSTRAINT co_attainment_internal_details_calculation_id_fkey FOREIGN KEY (calculation_id) REFERENCES public.co_attainment_calculation(calculation_id) ON DELETE CASCADE;


--
-- Name: co_attainment_internal_details co_attainment_internal_details_component_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.co_attainment_internal_details
    ADD CONSTRAINT co_attainment_internal_details_component_id_fkey FOREIGN KEY (component_id) REFERENCES public.internal_assessment_components(component_id) ON DELETE CASCADE;


--
-- Name: co_po_attainment co_po_attainment_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.co_po_attainment
    ADD CONSTRAINT co_po_attainment_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(course_id) ON DELETE CASCADE;


--
-- Name: co_po_attainment co_po_attainment_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.co_po_attainment
    ADD CONSTRAINT co_po_attainment_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.department(department_id) ON DELETE SET NULL;


--
-- Name: co_po_attainment co_po_attainment_programme_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.co_po_attainment
    ADD CONSTRAINT co_po_attainment_programme_id_fkey FOREIGN KEY (programme_id) REFERENCES public.programmes(programme_id) ON DELETE SET NULL;


--
-- Name: co_po_attainment co_po_attainment_semester_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.co_po_attainment
    ADD CONSTRAINT co_po_attainment_semester_id_fkey FOREIGN KEY (semester_id) REFERENCES public.semesters(semester_id) ON DELETE SET NULL;


--
-- Name: co_po_mapping co_po_mapping_co_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.co_po_mapping
    ADD CONSTRAINT co_po_mapping_co_id_fkey FOREIGN KEY (co_id) REFERENCES public.course_outcomes(co_id) ON DELETE CASCADE;


--
-- Name: co_po_mapping co_po_mapping_po_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.co_po_mapping
    ADD CONSTRAINT co_po_mapping_po_id_fkey FOREIGN KEY (po_id) REFERENCES public.programme_outcomes(po_id) ON DELETE CASCADE;


--
-- Name: co_pso_mapping co_pso_mapping_co_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.co_pso_mapping
    ADD CONSTRAINT co_pso_mapping_co_id_fkey FOREIGN KEY (co_id) REFERENCES public.course_outcomes(co_id);


--
-- Name: co_pso_mapping co_pso_mapping_pso_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.co_pso_mapping
    ADD CONSTRAINT co_pso_mapping_pso_id_fkey FOREIGN KEY (pso_id) REFERENCES public.programme_specific_outcomes(pso_id);


--
-- Name: course_faculty course_faculty_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_faculty
    ADD CONSTRAINT course_faculty_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(course_id);


--
-- Name: course_faculty course_faculty_faculty_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_faculty
    ADD CONSTRAINT course_faculty_faculty_id_fkey FOREIGN KEY (faculty_id) REFERENCES public.faculty(faculty_id);


--
-- Name: course_offerings course_offerings_academic_year_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_offerings
    ADD CONSTRAINT course_offerings_academic_year_id_fkey FOREIGN KEY (academic_year_id) REFERENCES public.academic_years(academic_year_id) ON DELETE RESTRICT;


--
-- Name: course_offerings course_offerings_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_offerings
    ADD CONSTRAINT course_offerings_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(course_id) ON DELETE CASCADE;


--
-- Name: course_offerings course_offerings_faculty_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_offerings
    ADD CONSTRAINT course_offerings_faculty_id_fkey FOREIGN KEY (faculty_id) REFERENCES public.faculty(faculty_id) ON DELETE RESTRICT;


--
-- Name: course_offerings course_offerings_semester_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_offerings
    ADD CONSTRAINT course_offerings_semester_id_fkey FOREIGN KEY (semester_id) REFERENCES public.semesters(semester_id) ON DELETE RESTRICT;


--
-- Name: course_outcomes course_outcomes_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_outcomes
    ADD CONSTRAINT course_outcomes_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(course_id) ON DELETE CASCADE;


--
-- Name: course_outcomes course_outcomes_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_outcomes
    ADD CONSTRAINT course_outcomes_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.department(department_id) ON DELETE SET NULL;


--
-- Name: course_outcomes course_outcomes_programme_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_outcomes
    ADD CONSTRAINT course_outcomes_programme_id_fkey FOREIGN KEY (programme_id) REFERENCES public.programmes(programme_id) ON DELETE SET NULL;


--
-- Name: course_outcomes course_outcomes_semester_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_outcomes
    ADD CONSTRAINT course_outcomes_semester_id_fkey FOREIGN KEY (semester_id) REFERENCES public.semesters(semester_id) ON DELETE SET NULL;


--
-- Name: courses courses_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT courses_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.department(department_id) ON DELETE SET NULL;


--
-- Name: courses courses_programme_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT courses_programme_id_fkey FOREIGN KEY (programme_id) REFERENCES public.programmes(programme_id) ON DELETE SET NULL;


--
-- Name: courses courses_semester_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT courses_semester_id_fkey FOREIGN KEY (semester_id) REFERENCES public.semesters(semester_id);


--
-- Name: department_vision_mission department_vision_mission_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.department_vision_mission
    ADD CONSTRAINT department_vision_mission_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.department(department_id) ON DELETE CASCADE;


--
-- Name: external_marks_upload external_marks_upload_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_marks_upload
    ADD CONSTRAINT external_marks_upload_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(course_id) ON DELETE SET NULL;


--
-- Name: external_marks_upload external_marks_upload_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_marks_upload
    ADD CONSTRAINT external_marks_upload_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.department(department_id) ON DELETE SET NULL;


--
-- Name: external_marks_upload external_marks_upload_programme_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_marks_upload
    ADD CONSTRAINT external_marks_upload_programme_id_fkey FOREIGN KEY (programme_id) REFERENCES public.programmes(programme_id) ON DELETE SET NULL;


--
-- Name: external_marks_upload external_marks_upload_semester_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_marks_upload
    ADD CONSTRAINT external_marks_upload_semester_id_fkey FOREIGN KEY (semester_id) REFERENCES public.semesters(semester_id) ON DELETE SET NULL;


--
-- Name: faculty_course_assignments faculty_course_assignments_assigned_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculty_course_assignments
    ADD CONSTRAINT faculty_course_assignments_assigned_by_fkey FOREIGN KEY (assigned_by) REFERENCES public.users(user_id) ON DELETE SET NULL;


--
-- Name: faculty_course_assignments faculty_course_assignments_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculty_course_assignments
    ADD CONSTRAINT faculty_course_assignments_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(course_id) ON DELETE CASCADE;


--
-- Name: faculty_course_assignments faculty_course_assignments_faculty_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculty_course_assignments
    ADD CONSTRAINT faculty_course_assignments_faculty_id_fkey FOREIGN KEY (faculty_id) REFERENCES public.faculty(faculty_id) ON DELETE CASCADE;


--
-- Name: faculty faculty_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculty
    ADD CONSTRAINT faculty_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.department(department_id) ON DELETE SET NULL;


--
-- Name: faculty_department_mapping faculty_department_mapping_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculty_department_mapping
    ADD CONSTRAINT faculty_department_mapping_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.department(department_id) ON DELETE CASCADE;


--
-- Name: faculty_department_mapping faculty_department_mapping_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculty_department_mapping
    ADD CONSTRAINT faculty_department_mapping_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: faculty_import_batches faculty_import_batches_uploaded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculty_import_batches
    ADD CONSTRAINT faculty_import_batches_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES public.users(user_id) ON DELETE SET NULL;


--
-- Name: faculty_import_rows faculty_import_rows_import_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculty_import_rows
    ADD CONSTRAINT faculty_import_rows_import_batch_id_fkey FOREIGN KEY (import_batch_id) REFERENCES public.faculty_import_batches(import_batch_id) ON DELETE CASCADE;


--
-- Name: faculty_module_permissions faculty_module_permissions_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculty_module_permissions
    ADD CONSTRAINT faculty_module_permissions_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.department(department_id) ON DELETE CASCADE;


--
-- Name: faculty_module_permissions faculty_module_permissions_module_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculty_module_permissions
    ADD CONSTRAINT faculty_module_permissions_module_id_fkey FOREIGN KEY (module_id) REFERENCES public.modules(module_id) ON DELETE CASCADE;


--
-- Name: faculty_module_permissions faculty_module_permissions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculty_module_permissions
    ADD CONSTRAINT faculty_module_permissions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: faculty faculty_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculty
    ADD CONSTRAINT faculty_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: faculty_user_mapping faculty_user_mapping_assigned_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculty_user_mapping
    ADD CONSTRAINT faculty_user_mapping_assigned_by_fkey FOREIGN KEY (assigned_by) REFERENCES public.users(user_id) ON DELETE SET NULL;


--
-- Name: faculty_user_mapping faculty_user_mapping_faculty_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculty_user_mapping
    ADD CONSTRAINT faculty_user_mapping_faculty_id_fkey FOREIGN KEY (faculty_id) REFERENCES public.faculty(faculty_id) ON DELETE CASCADE;


--
-- Name: faculty_user_mapping faculty_user_mapping_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculty_user_mapping
    ADD CONSTRAINT faculty_user_mapping_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: institute_vision_mission institute_vision_mission_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.institute_vision_mission
    ADD CONSTRAINT institute_vision_mission_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: internal_assessment_components internal_assessment_components_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.internal_assessment_components
    ADD CONSTRAINT internal_assessment_components_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(course_id) ON DELETE CASCADE;


--
-- Name: internal_marks_upload internal_marks_upload_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.internal_marks_upload
    ADD CONSTRAINT internal_marks_upload_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(course_id) ON DELETE SET NULL;


--
-- Name: internal_marks_upload internal_marks_upload_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.internal_marks_upload
    ADD CONSTRAINT internal_marks_upload_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.department(department_id) ON DELETE SET NULL;


--
-- Name: internal_marks_upload internal_marks_upload_programme_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.internal_marks_upload
    ADD CONSTRAINT internal_marks_upload_programme_id_fkey FOREIGN KEY (programme_id) REFERENCES public.programmes(programme_id) ON DELETE SET NULL;


--
-- Name: internal_marks_upload internal_marks_upload_semester_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.internal_marks_upload
    ADD CONSTRAINT internal_marks_upload_semester_id_fkey FOREIGN KEY (semester_id) REFERENCES public.semesters(semester_id) ON DELETE SET NULL;


--
-- Name: mark_attainment mark_attainment_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mark_attainment
    ADD CONSTRAINT mark_attainment_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(course_id) ON DELETE CASCADE;


--
-- Name: mark_attainment mark_attainment_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mark_attainment
    ADD CONSTRAINT mark_attainment_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.department(department_id) ON DELETE SET NULL;


--
-- Name: mark_attainment mark_attainment_programme_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mark_attainment
    ADD CONSTRAINT mark_attainment_programme_id_fkey FOREIGN KEY (programme_id) REFERENCES public.programmes(programme_id) ON DELETE SET NULL;


--
-- Name: mark_attainment mark_attainment_semester_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mark_attainment
    ADD CONSTRAINT mark_attainment_semester_id_fkey FOREIGN KEY (semester_id) REFERENCES public.semesters(semester_id) ON DELETE SET NULL;


--
-- Name: po_attainment_details po_attainment_details_co_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.po_attainment_details
    ADD CONSTRAINT po_attainment_details_co_id_fkey FOREIGN KEY (co_id) REFERENCES public.course_outcomes(co_id) ON DELETE CASCADE;


--
-- Name: po_attainment_details po_attainment_details_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.po_attainment_details
    ADD CONSTRAINT po_attainment_details_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(course_id) ON DELETE CASCADE;


--
-- Name: po_attainment_details po_attainment_details_po_attainment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.po_attainment_details
    ADD CONSTRAINT po_attainment_details_po_attainment_id_fkey FOREIGN KEY (po_attainment_id) REFERENCES public.po_attainment(po_attainment_id) ON DELETE CASCADE;


--
-- Name: po_attainment po_attainment_po_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.po_attainment
    ADD CONSTRAINT po_attainment_po_id_fkey FOREIGN KEY (po_id) REFERENCES public.programme_outcomes(po_id);


--
-- Name: po_attainment po_attainment_programme_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.po_attainment
    ADD CONSTRAINT po_attainment_programme_id_fkey FOREIGN KEY (programme_id) REFERENCES public.programmes(programme_id);


--
-- Name: programme_outcomes programme_outcomes_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programme_outcomes
    ADD CONSTRAINT programme_outcomes_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.department(department_id) ON DELETE SET NULL;


--
-- Name: programme_outcomes programme_outcomes_programme_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programme_outcomes
    ADD CONSTRAINT programme_outcomes_programme_id_fkey FOREIGN KEY (programme_id) REFERENCES public.programmes(programme_id) ON DELETE CASCADE;


--
-- Name: programme_specific_outcomes programme_specific_outcomes_programme_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programme_specific_outcomes
    ADD CONSTRAINT programme_specific_outcomes_programme_id_fkey FOREIGN KEY (programme_id) REFERENCES public.programmes(programme_id);


--
-- Name: programmes programmes_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programmes
    ADD CONSTRAINT programmes_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.department(department_id) ON DELETE SET NULL;


--
-- Name: pso_attainment pso_attainment_admission_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pso_attainment
    ADD CONSTRAINT pso_attainment_admission_batch_id_fkey FOREIGN KEY (admission_batch_id) REFERENCES public.admission_batches(admission_batch_id) ON DELETE RESTRICT;


--
-- Name: pso_attainment pso_attainment_calculated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pso_attainment
    ADD CONSTRAINT pso_attainment_calculated_by_fkey FOREIGN KEY (calculated_by) REFERENCES public.users(user_id);


--
-- Name: pso_attainment_details pso_attainment_details_co_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pso_attainment_details
    ADD CONSTRAINT pso_attainment_details_co_id_fkey FOREIGN KEY (co_id) REFERENCES public.course_outcomes(co_id) ON DELETE CASCADE;


--
-- Name: pso_attainment_details pso_attainment_details_pso_attainment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pso_attainment_details
    ADD CONSTRAINT pso_attainment_details_pso_attainment_id_fkey FOREIGN KEY (pso_attainment_id) REFERENCES public.pso_attainment(pso_attainment_id) ON DELETE CASCADE;


--
-- Name: pso_attainment_details pso_attainment_details_pso_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pso_attainment_details
    ADD CONSTRAINT pso_attainment_details_pso_id_fkey FOREIGN KEY (pso_id) REFERENCES public.programme_specific_outcomes(pso_id) ON DELETE CASCADE;


--
-- Name: pso_attainment pso_attainment_programme_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pso_attainment
    ADD CONSTRAINT pso_attainment_programme_id_fkey FOREIGN KEY (programme_id) REFERENCES public.programmes(programme_id) ON DELETE CASCADE;


--
-- Name: pso_attainment_summary pso_attainment_summary_pso_attainment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pso_attainment_summary
    ADD CONSTRAINT pso_attainment_summary_pso_attainment_id_fkey FOREIGN KEY (pso_attainment_id) REFERENCES public.pso_attainment(pso_attainment_id) ON DELETE CASCADE;


--
-- Name: pso_attainment_summary pso_attainment_summary_pso_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pso_attainment_summary
    ADD CONSTRAINT pso_attainment_summary_pso_id_fkey FOREIGN KEY (pso_id) REFERENCES public.programme_specific_outcomes(pso_id) ON DELETE CASCADE;


--
-- Name: semesters semesters_admission_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.semesters
    ADD CONSTRAINT semesters_admission_batch_id_fkey FOREIGN KEY (admission_batch_id) REFERENCES public.admission_batches(admission_batch_id) ON DELETE CASCADE;


--
-- Name: semesters semesters_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.semesters
    ADD CONSTRAINT semesters_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.department(department_id) ON DELETE SET NULL;


--
-- Name: semesters semesters_programme_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.semesters
    ADD CONSTRAINT semesters_programme_id_fkey FOREIGN KEY (programme_id) REFERENCES public.programmes(programme_id);


--
-- Name: student_course_enrollments student_course_enrollments_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_course_enrollments
    ADD CONSTRAINT student_course_enrollments_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(course_id) ON DELETE CASCADE;


--
-- Name: student_course_enrollments student_course_enrollments_course_offering_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_course_enrollments
    ADD CONSTRAINT student_course_enrollments_course_offering_id_fkey FOREIGN KEY (course_offering_id) REFERENCES public.course_offerings(course_offering_id) ON DELETE CASCADE;


--
-- Name: student_course_enrollments student_course_enrollments_faculty_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_course_enrollments
    ADD CONSTRAINT student_course_enrollments_faculty_id_fkey FOREIGN KEY (faculty_id) REFERENCES public.faculty(faculty_id) ON DELETE CASCADE;


--
-- Name: student_course_enrollments student_course_enrollments_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_course_enrollments
    ADD CONSTRAINT student_course_enrollments_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(student_id) ON DELETE CASCADE;


--
-- Name: student_marks student_marks_assessment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_marks
    ADD CONSTRAINT student_marks_assessment_id_fkey FOREIGN KEY (assessment_id) REFERENCES public.assessments(assessment_id);


--
-- Name: student_marks student_marks_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_marks
    ADD CONSTRAINT student_marks_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(student_id);


--
-- Name: students students_programme_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_programme_id_fkey FOREIGN KEY (programme_id) REFERENCES public.programmes(programme_id);


--
-- Name: university_question_mapping university_question_mapping_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.university_question_mapping
    ADD CONSTRAINT university_question_mapping_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(course_id) ON DELETE CASCADE;


--
-- Name: university_question_mapping university_question_mapping_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.university_question_mapping
    ADD CONSTRAINT university_question_mapping_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.department(department_id) ON DELETE SET NULL;


--
-- Name: university_question_mapping university_question_mapping_programme_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.university_question_mapping
    ADD CONSTRAINT university_question_mapping_programme_id_fkey FOREIGN KEY (programme_id) REFERENCES public.programmes(programme_id) ON DELETE SET NULL;


--
-- Name: university_question_mapping university_question_mapping_semester_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.university_question_mapping
    ADD CONSTRAINT university_question_mapping_semester_id_fkey FOREIGN KEY (semester_id) REFERENCES public.semesters(semester_id) ON DELETE SET NULL;


--
-- Name: university_question_papers university_question_papers_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.university_question_papers
    ADD CONSTRAINT university_question_papers_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(course_id) ON DELETE CASCADE;


--
-- Name: user_course_permissions user_course_permissions_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_course_permissions
    ADD CONSTRAINT user_course_permissions_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(course_id) ON DELETE CASCADE;


--
-- Name: user_course_permissions user_course_permissions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_course_permissions
    ADD CONSTRAINT user_course_permissions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: user_module_permissions user_module_permissions_module_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_module_permissions
    ADD CONSTRAINT user_module_permissions_module_id_fkey FOREIGN KEY (module_id) REFERENCES public.modules(module_id) ON DELETE CASCADE;


--
-- Name: user_module_permissions user_module_permissions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_module_permissions
    ADD CONSTRAINT user_module_permissions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: users users_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.department(department_id) ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

\unrestrict wU5mF77udFOZGH3NTIlm8kRou41dn2c2PH21C0pM7oq3belKAlaKSVpdMBjOzQ2

