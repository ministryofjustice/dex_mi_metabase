-- How to create read-only user on live replication environment
CREATE ROLE read_access;
GRANT USAGE ON SCHEMA public TO read_access;
GRANT SELECT ON delayed_jobs, groups_view, memberships, permitted_domains, queued_notifications_view, reports_view, people_view TO read_access;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO read_access;
GRANT CONNECT ON DATABASE '<database name>' to read_access;
create user "<user_name>" with password '<password>';
GRANT read_access TO "<user_name>";
