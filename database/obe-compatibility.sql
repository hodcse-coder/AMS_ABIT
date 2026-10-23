-- The repository archive has per-CO rows; its current page saves a whole-course
-- calculation. Retain both forms and give summary rows their own upsert key.
ALTER TABLE obe.co_attainment_calculation ALTER COLUMN co_id DROP NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS obe_co_calculation_summary_unique ON obe.co_attainment_calculation(course_id,academic_year,batch) WHERE co_id IS NULL;
