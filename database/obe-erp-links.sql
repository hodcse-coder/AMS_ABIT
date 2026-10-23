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
