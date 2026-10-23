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
