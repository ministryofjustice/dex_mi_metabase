 DROP view if exists groups_view;
 DROP view if exists people_view;
 DROP view if exists queued_notifications_view;
 DROP view if exists reports_view;
CREATE view groups_view as
 SELECT groups.id,
    groups.name,
    groups.ancestry,
    groups.ancestry_depth,
    groups.acronym,
    groups.description_reminder_email_at,
    groups.members_completion_score,
    groups.created_at,
    groups.updated_at
   FROM groups;

CREATE view people_view as
 SELECT people.id,
    people.works_monday,
    people.works_tuesday,
    people.works_wednesday,
    people.works_thursday,
    people.works_friday,
    people.works_saturday,
    people.created_at,
    people.updated_at,
    people.login_count,
    people.last_login_at,
    people.building,
    people.city,
    people.last_reminder_email_at
   FROM people;

CREATE view queued_notifications_view as
 SELECT queued_notifications.id,
    queued_notifications.email_template,
    queued_notifications.session_id,
    queued_notifications.person_id,
    queued_notifications.current_user_id,
    queued_notifications.edit_finalised,
    queued_notifications.processing_started_at,
    queued_notifications.sent,
    queued_notifications.created_at,
    queued_notifications.updated_at
   FROM queued_notifications;


CREATE view reports_view as
 SELECT reports.id,
    reports.name,
    reports.extension,
    reports.mime_type,
    reports.created_at,
    reports.updated_at
   FROM reports;
