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
