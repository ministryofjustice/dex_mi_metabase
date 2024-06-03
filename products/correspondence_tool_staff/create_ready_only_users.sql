-- How to create read-only user on QA environment
CREATE ROLE readaccess;
GRANT USAGE ON SCHEMA public TO readaccess;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readaccess;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO readaccess;
GRANT CONNECT ON DATABASE '<database name>' to readaccess;
create user <user_name> with password '<password>';
GRANT readaccess TO <user_name>;

-- How to create read-only user on live replication environment
CREATE ROLE branson_read_access;
GRANT USAGE ON SCHEMA public TO branson_read_access;
GRANT SELECT ON cases_outcome_reasons, category_references, retention_schedules, tmp_partial_cases, data_requests, contacts,
  offender_subject_type_volume_exclude_rejected_case_view, offender_subject_type_volume_rejected_case_view, offender_sar_vetting_track_view,
  offender_data_requests_volume_view, warehouse_case_report_for_london_disclosure_related, warehouse_case_report_for_offender_sar_related TO branson_read_access;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO branson_read_access;
GRANT CONNECT ON DATABASE '<database name>' to branson_read_access;
create user "<user_name>" with password '<password>';
GRANT branson_read_access TO "<user_name>";


-- remove a user
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM <user_name>;
revoke  USAGE ON SCHEMA public from <user_name>;
revoke CONNECT ON DATABASE <database name> from <user_name>;
revoke SELECT ON ALL TABLES IN SCHEMA public from <user_name>;
drop user <user_name>
