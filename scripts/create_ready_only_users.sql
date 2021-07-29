-- How to create read-only user
CREATE ROLE readaccess;
GRANT USAGE ON SCHEMA public TO readaccess;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readaccess;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO readaccess;
GRANT CONNECT ON DATABASE '<database name>' to readaccess;
create user <user_name> with password '<password>';
GRANT readaccess TO <user_name>;


-- remove a user
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM <user_name>;
revoke  USAGE ON SCHEMA public from <user_name>;
revoke CONNECT ON DATABASE <database name> from <user_name>;
revoke SELECT ON ALL TABLES IN SCHEMA public from <user_name>;
drop user <user_name>
