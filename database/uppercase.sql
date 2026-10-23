-- Uppercase descriptive text while preserving credentials, URLs, email,
-- role identifiers, MIME types, binary files and session tokens.
CREATE OR REPLACE FUNCTION uppercase_record_text() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE field_name TEXT;
DECLARE payload JSONB := to_jsonb(NEW);
BEGIN
  FOREACH field_name IN ARRAY TG_ARGV LOOP
    IF payload ->> field_name IS NOT NULL THEN
      payload := jsonb_set(payload, ARRAY[field_name], to_jsonb(upper(payload ->> field_name)));
    END IF;
  END LOOP;
  NEW := jsonb_populate_record(NEW, payload);
  RETURN NEW;
END;
$$;

DO $$
DECLARE table_name TEXT;
DECLARE fields JSONB;
DECLARE field_name TEXT;
DECLARE assignments TEXT;
DECLARE arguments TEXT;
BEGIN
  FOR table_name, fields IN SELECT key,value FROM jsonb_each('{
    "users":["full_name"],
    "admins":["designation"],
    "faculty":["employee_code","department"],
    "students":["admission_number","department"],
    "country":["country_name"],
    "state":["state_name"],
    "city":["city_name"],
    "organization":["org_name","org_alias","org_address_line1","org_address_line2","org_phone","org_stu_prefix","org_emp_prefix"],
    "last_passout_institution":["institution_name","place","district","institute_type","affiliation","college_address"],
    "languages":["language_name"],
    "hobbies":["hobby_name"],
    "national_holidays":["national_holiday_name","national_holiday_remarks"],
    "document_category":["doc_category_name","doc_category_user_type"],
    "nationality":["nationality_name"]
  }'::jsonb) LOOP
    assignments := ''; arguments := '';
    FOR field_name IN SELECT jsonb_array_elements_text(fields) LOOP
      assignments := assignments || CASE WHEN assignments='' THEN '' ELSE ',' END || format('%I=upper(%I)',field_name,field_name);
      arguments := arguments || CASE WHEN arguments='' THEN '' ELSE ',' END || quote_literal(field_name);
    END LOOP;
    EXECUTE format('DROP TRIGGER IF EXISTS enforce_uppercase ON %I',table_name);
    EXECUTE format('UPDATE %I SET %s',table_name,assignments);
    EXECUTE format('CREATE TRIGGER enforce_uppercase BEFORE INSERT OR UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION uppercase_record_text(%s)',table_name,arguments);
  END LOOP;
END;
$$;
