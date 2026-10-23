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
