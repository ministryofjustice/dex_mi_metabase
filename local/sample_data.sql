-- Synthetic schema + data mimicking the Correspondence Tool warehouse tables
-- used by products/correspondence_tool_staff/views.sql. Not real data.

DROP TABLE IF EXISTS case_transitions CASCADE;
DROP TABLE IF EXISTS data_requests CASCADE;
DROP TABLE IF EXISTS warehouse_case_reports CASCADE;

CREATE TABLE warehouse_case_reports (
    case_id integer PRIMARY KEY,
    created_at timestamp,
    updated_at timestamp,
    creator_id integer,
    responding_team_id integer,
    responder_id integer,
    number varchar(20),
    case_type varchar(60),
    current_state varchar(40),
    responding_team varchar(80),
    responder varchar(80),
    date_received date,
    external_deadline date,
    date_responded date,
    outcome varchar(40),
    appeal_outcome varchar(40),
    third_party boolean,
    sar_subject_type varchar(40),
    created_by varchar(80),
    in_target boolean,
    user_dealing_with_vetting varchar(80),
    number_of_days_for_vetting integer,
    number_of_days_late integer,
    number_of_days_taken integer,
    number_of_exempt_pages integer,
    number_of_final_pages integer,
    third_party_company_name varchar(120),
    complaint_subtype varchar(60),
    priority varchar(20),
    total_cost numeric(10,2),
    settlement_cost numeric(10,2),
    request_method varchar(40),
    sent_to_sscl boolean,
    rejected varchar(3),
    case_originally_rejected varchar(3),
    rejected_reasons varchar(200),
    other_rejected_reason varchar(200),
    user_made_valid varchar(80)
);

CREATE TABLE data_requests (
    id serial PRIMARY KEY,
    case_id integer REFERENCES warehouse_case_reports(case_id),
    request_type varchar(60),
    cached_num_pages integer
);

CREATE TABLE case_transitions (
    id serial PRIMARY KEY,
    case_id integer REFERENCES warehouse_case_reports(case_id),
    event varchar(60),
    created_at timestamp
);

-- 500 synthetic cases spread across the last 24 months
INSERT INTO warehouse_case_reports (
    case_id, created_at, updated_at, creator_id, responding_team_id, responder_id,
    number, case_type, current_state, responding_team, responder,
    date_received, external_deadline, date_responded, outcome, appeal_outcome,
    third_party, sar_subject_type, created_by, in_target, user_dealing_with_vetting,
    number_of_days_for_vetting, number_of_days_late, number_of_days_taken,
    number_of_exempt_pages, number_of_final_pages, third_party_company_name,
    complaint_subtype, priority, total_cost, settlement_cost, request_method,
    sent_to_sscl, rejected, case_originally_rejected, rejected_reasons,
    other_rejected_reason, user_made_valid
)
SELECT
    gs AS case_id,
    received AS created_at,
    received + (floor(random()*20))::int * interval '1 day' AS updated_at,
    (random()*50)::int + 1,
    (random()*10)::int + 1,
    (random()*50)::int + 1,
    'CASE-' || to_char(received, 'YYYY') || '-' || lpad(gs::text, 5, '0'),
    case_type,
    (ARRAY['Closed','Open','To be opened'])[(random()*2)::int + 1],
    (ARRAY['Disclosure Team','Offender Management Team','Complaints Team'])[(random()*2)::int + 1],
    'Responder ' || ((random()*30)::int + 1),
    received,
    received + interval '20 days',
    responded,
    (ARRAY['Granted','Partially granted','Refused','Not held'])[(random()*3)::int + 1],
    CASE WHEN random() < 0.1 THEN (ARRAY['Upheld','Overturned'])[(random()*1)::int + 1] ELSE NULL END,
    random() < 0.3,
    (ARRAY['Offender','Ex offender','Detainee','Ex detainee','Probation service user','Ex probation service user'])[(random()*5)::int + 1],
    'Caseworker ' || ((random()*20)::int + 1),
    random() < 0.75,
    'Vetting Officer ' || ((random()*10)::int + 1),
    (random()*10)::int,
    GREATEST(0, (random()*15)::int - 10),
    extract(day from (responded - received))::int,
    (random()*300)::int,
    (random()*280)::int,
    CASE WHEN random() < 0.25 THEN 'Some Company Ltd' ELSE NULL END,
    CASE WHEN case_type LIKE 'Complaint%' THEN (ARRAY['Standard','ICO','Litigation'])[(random()*2)::int + 1] ELSE NULL END,
    (ARRAY['Normal','High'])[(random()*1)::int + 1],
    round((random()*500)::numeric, 2),
    CASE WHEN random() < 0.05 THEN round((random()*2000)::numeric, 2) ELSE 0 END,
    (ARRAY['Online','Email','Post'])[(random()*2)::int + 1],
    random() < 0.4,
    CASE WHEN random() < 0.15 THEN 'Yes' ELSE 'No' END,
    CASE WHEN random() < 0.2 THEN 'Yes' ELSE 'No' END,
    CASE WHEN random() < 0.15 THEN 'Not enough information provided' ELSE NULL END,
    NULL,
    'Caseworker ' || ((random()*20)::int + 1)
FROM (
    SELECT
        gs,
        (CURRENT_DATE - (random()*730)::int) AS received,
        (ARRAY['FOI','SAR','Offender SAR','Rejected Offender SAR','ICO appeal (SAR)','ICO appeal (FOI)',
               'Complaint - Standard','Complaint - ICO','Complaint - Litigation'])[(random()*8)::int + 1] AS case_type
    FROM generate_series(1, 500) gs
) base,
LATERAL (SELECT received + (5 + (random()*30)::int) * interval '1 day' AS responded) r;

-- data requests: 1-4 per case
INSERT INTO data_requests (case_id, request_type, cached_num_pages)
SELECT
    wcr.case_id,
    (ARRAY['all_prison_records','security_records','nomis_records','nomis_other','nomis_contact_logs',
           'probation_records','cctv_and_bwcf','cctv','bwcf','telephone_recordings','telephone_pin_logs',
           'probation_archive','mappa','pdp','court','dps','other'])[(random()*16)::int + 1],
    (random()*200)::int
FROM warehouse_case_reports wcr
CROSS JOIN generate_series(1, (1 + (random()*3)::int))
WHERE wcr.case_type IN ('Offender SAR','Rejected Offender SAR');

-- case transitions: mark_as_ready_to_copy for most offender SAR cases
INSERT INTO case_transitions (case_id, event, created_at)
SELECT case_id, 'mark_as_ready_to_copy', created_at + (2 + (random()*5)::int) * interval '1 day'
FROM warehouse_case_reports
WHERE case_type IN ('Offender SAR','Rejected Offender SAR') AND random() < 0.8;

-- Now apply the real view definitions from products/correspondence_tool_staff/views.sql
 DROP view if exists offender_data_requests_volume_view;
 DROP view if exists offender_subject_type_volume_rejected_case_view;
 DROP view if exists offender_subject_type_volume_exclude_rejected_case_view;
 DROP view if exists offender_sar_vetting_track_view;
 DROP view if exists warehouse_case_report_for_offender_sar_related;
 DROP view if exists warehouse_case_report_for_london_disclosure_related;

-- warehouse_case_report_for_london_disclosure_related
 CREATE view warehouse_case_report_for_london_disclosure_related as
 SELECT warehouse_case_reports.case_id,
    warehouse_case_reports.created_at,
    warehouse_case_reports.updated_at,
    warehouse_case_reports.creator_id,
    warehouse_case_reports.responding_team_id,
    warehouse_case_reports.responder_id,
    warehouse_case_reports.number,
    warehouse_case_reports.case_type,
    warehouse_case_reports.current_state,
    warehouse_case_reports.responding_team,
    warehouse_case_reports.responder,
    warehouse_case_reports.date_received,
    warehouse_case_reports.external_deadline,
    warehouse_case_reports.date_responded,
    warehouse_case_reports.outcome,
    warehouse_case_reports.appeal_outcome,
    warehouse_case_reports.third_party,
    warehouse_case_reports.sar_subject_type,
    warehouse_case_reports.created_by,
    warehouse_case_reports.in_target,
    warehouse_case_reports.user_dealing_with_vetting,
    warehouse_case_reports.number_of_days_for_vetting,
    warehouse_case_reports.number_of_days_late,
    warehouse_case_reports.number_of_days_taken,
    warehouse_case_reports.number_of_exempt_pages,
    warehouse_case_reports.number_of_final_pages,
    warehouse_case_reports.third_party_company_name,
    warehouse_case_reports.complaint_subtype,
    warehouse_case_reports.priority,
    warehouse_case_reports.total_cost,
    warehouse_case_reports.settlement_cost,
    warehouse_case_reports.request_method,
        CASE
            WHEN warehouse_case_reports.third_party_company_name IS NULL THEN 'Data subject'::text
            WHEN warehouse_case_reports.third_party_company_name::text = ''::text THEN 'Data subject'::text
            ELSE 'Third party'::text
        END AS requester_from
   FROM warehouse_case_reports
  WHERE warehouse_case_reports.case_type::text = ANY (ARRAY['FOI'::character varying::text, 'SAR'::character varying::text, 'ICO appeal (SAR)'::character varying::text, 'ICO appeal (FOI)'::character varying::text, 'ICO overturned (FOI)'::character varying::text, 'ICO overturned (SAR)'::character varying::text, 'SAR Internal Review - compliance'::character varying::text, 'SAR Internal Review - timeliness'::character varying::text, 'FOI - Internal review for compliance'::character varying::text, 'FOI - Internal review for timeliness'::character varying::text]);


-- warehouse_case_report_for_offender_sar_related
 CREATE view warehouse_case_report_for_offender_sar_related as
 SELECT warehouse_case_reports.case_id,
    warehouse_case_reports.created_at,
    warehouse_case_reports.updated_at,
    warehouse_case_reports.creator_id,
    warehouse_case_reports.responding_team_id,
    warehouse_case_reports.responder_id,
    warehouse_case_reports.number,
    warehouse_case_reports.case_type,
    warehouse_case_reports.current_state,
    warehouse_case_reports.responding_team,
    warehouse_case_reports.responder,
    warehouse_case_reports.date_received,
    warehouse_case_reports.external_deadline,
    warehouse_case_reports.date_responded,
    warehouse_case_reports.outcome,
    warehouse_case_reports.appeal_outcome,
    warehouse_case_reports.third_party,
    warehouse_case_reports.sar_subject_type,
    warehouse_case_reports.created_by,
    warehouse_case_reports.in_target,
    warehouse_case_reports.user_dealing_with_vetting,
    warehouse_case_reports.number_of_days_for_vetting,
    warehouse_case_reports.number_of_days_late,
    warehouse_case_reports.number_of_days_taken,
    warehouse_case_reports.number_of_exempt_pages,
    warehouse_case_reports.number_of_final_pages,
    warehouse_case_reports.third_party_company_name,
    warehouse_case_reports.complaint_subtype,
    warehouse_case_reports.priority,
    warehouse_case_reports.total_cost,
    warehouse_case_reports.settlement_cost,
    warehouse_case_reports.sent_to_sscl,
    warehouse_case_reports.request_method,
    warehouse_case_reports.rejected,
    warehouse_case_reports.case_originally_rejected,
    warehouse_case_reports.rejected_reasons,
    warehouse_case_reports.other_rejected_reason,
    warehouse_case_reports.user_made_valid,
        CASE
            WHEN warehouse_case_reports.third_party_company_name IS NULL THEN 'Data subject'::text
            WHEN warehouse_case_reports.third_party_company_name::text = ''::text THEN 'Data subject'::text
            ELSE 'Third party'::text
        END AS requester_from
   FROM warehouse_case_reports
  WHERE warehouse_case_reports.case_type::text = ANY (ARRAY['Offender SAR'::character varying::text, 'Rejected Offender SAR'::character varying::text, 'Complaint - Standard'::character varying::text, 'Complaint - ICO'::character varying::text, 'Complaint - Litigation'::character varying::text]);


 -- offender_data_requests_volume_view
 CREATE view  offender_data_requests_volume_view as
 SELECT stats_base_categories.request_type,
    stats_base_categories.stats_month,
    concat(stats_base_categories.stats_month, ' - ', to_char(to_date(stats_base_categories.stats_month::text, 'MM'::text)::timestamp with time zone, 'Month'::text)) AS "Month Name",
    stats_current_year.current_year_volume,
    stats_previous_year.previous_year_volume
   FROM ( SELECT a.stats_month,
            b.request_type
           FROM ( SELECT to_char(generate_series(to_char(CURRENT_DATE::timestamp with time zone, 'YYYY-01-01'::text)::timestamp without time zone, CURRENT_DATE::timestamp without time zone, '1 mon'::interval), 'MM'::text)::integer AS stats_month) a
             CROSS JOIN ( SELECT t.request_type
                   FROM ( VALUES ('all_prison_records'::text), ('security_records'::text), ('nomis_records'::text), ('nomis_other'::text), ('nomis_contact_logs'::text), ('probation_records'::text), ('cctv_and_bwcf'::text), ('cctv'::text), ('bwcf'::text), ('telephone_recordings'::text), ('telephone_pin_logs'::text), ('probation_archive'::text), ('mappa'::text), ('pdp'::text), ('court'::text), ('dps'::text), ('other'::text)) t(request_type)) b) stats_base_categories
     LEFT JOIN ( SELECT data_requests.request_type,
            date_part('year'::text, warehouse_case_report_for_offender_sar_related.date_received) AS stats_year,
            date_part('month'::text, warehouse_case_report_for_offender_sar_related.date_received) AS stats_month,
            count(DISTINCT data_requests.case_id) AS current_year_volume
           FROM data_requests
             JOIN warehouse_case_report_for_offender_sar_related ON data_requests.case_id = warehouse_case_report_for_offender_sar_related.case_id
          WHERE date_part('year'::text, warehouse_case_report_for_offender_sar_related.date_received) = date_part('year'::text, CURRENT_DATE) AND warehouse_case_report_for_offender_sar_related.case_type::text = 'Offender SAR'::text
          GROUP BY data_requests.request_type, (date_part('year'::text, warehouse_case_report_for_offender_sar_related.date_received)), (date_part('month'::text, warehouse_case_report_for_offender_sar_related.date_received))
          ORDER BY (date_part('year'::text, warehouse_case_report_for_offender_sar_related.date_received)), (date_part('month'::text, warehouse_case_report_for_offender_sar_related.date_received))) stats_current_year ON stats_base_categories.request_type = stats_current_year.request_type::text AND stats_base_categories.stats_month::double precision = stats_current_year.stats_month
     LEFT JOIN ( SELECT data_requests.request_type,
            date_part('year'::text, warehouse_case_report_for_offender_sar_related.date_received) AS stats_year,
            date_part('month'::text, warehouse_case_report_for_offender_sar_related.date_received) AS stats_month,
            count(DISTINCT data_requests.case_id) AS previous_year_volume
           FROM data_requests
             JOIN warehouse_case_report_for_offender_sar_related ON data_requests.case_id = warehouse_case_report_for_offender_sar_related.case_id
          WHERE date_part('year'::text, warehouse_case_report_for_offender_sar_related.date_received) = (date_part('year'::text, CURRENT_DATE) - 1::double precision) AND warehouse_case_report_for_offender_sar_related.case_type::text = 'Offender SAR'::text
          GROUP BY data_requests.request_type, (date_part('year'::text, warehouse_case_report_for_offender_sar_related.date_received)), (date_part('month'::text, warehouse_case_report_for_offender_sar_related.date_received))
          ORDER BY (date_part('year'::text, warehouse_case_report_for_offender_sar_related.date_received)), (date_part('month'::text, warehouse_case_report_for_offender_sar_related.date_received))) stats_previous_year ON stats_base_categories.request_type = stats_previous_year.request_type::text AND stats_base_categories.stats_month::double precision = stats_previous_year.stats_month;

 -- offender_subject_type_volume_rejected_case_view
 CREATE view offender_subject_type_volume_rejected_case_view as
 SELECT stats_base_categories.sar_subject_type,
        stats_base_categories.stats_month,
        concat(stats_base_categories.stats_month, ' - ', to_char(to_date(stats_base_categories.stats_month::text, 'MM'::text)::timestamp with time zone, 'Month'::text)) AS "Month Name",
        stats_base_categories.requester_type,
        stats_current_year.current_year_volume,
        stats_previous_year.previous_year_volume
 FROM ( SELECT a.stats_month,
               b.sar_subject_type,
               c.requester_type
        FROM ( SELECT to_char(generate_series(to_char(CURRENT_DATE::timestamp with time zone, 'YYYY-01-01'::text)::timestamp without time zone, CURRENT_DATE::timestamp without time zone, '1 mon'::interval), 'MM'::text)::integer AS stats_month) a
                 CROSS JOIN ( SELECT t.sar_subject_type
                              FROM ( VALUES ('Offender'::text), ('Ex offender'::text), ('Detainee'::text), ('Ex detainee'::text), ('Probation service user'::text), ('Ex probation service user'::text)) t(sar_subject_type)) b
                 CROSS JOIN ( SELECT t.requester_type
                              FROM ( VALUES ('Third party'::text), ('Data subject'::text)) t(requester_type)) c) stats_base_categories
          LEFT JOIN ( SELECT warehouse_case_report_for_offender_sar_related.sar_subject_type,
                             warehouse_case_report_for_offender_sar_related.requester_from,
                             date_part('year'::text, warehouse_case_report_for_offender_sar_related.date_received) AS stats_year,
                             date_part('month'::text, warehouse_case_report_for_offender_sar_related.date_received) AS stats_month,
                             count(warehouse_case_report_for_offender_sar_related.case_id) AS current_year_volume
                      FROM warehouse_case_report_for_offender_sar_related
                      WHERE date_part('year'::text, warehouse_case_report_for_offender_sar_related.date_received) = date_part('year'::text, CURRENT_DATE) AND warehouse_case_report_for_offender_sar_related.rejected::text = 'Yes'::text
                      GROUP BY warehouse_case_report_for_offender_sar_related.sar_subject_type, (date_part('year'::text, warehouse_case_report_for_offender_sar_related.date_received)), (date_part('month'::text, warehouse_case_report_for_offender_sar_related.date_received)), warehouse_case_report_for_offender_sar_related.requester_from
                      ORDER BY (date_part('year'::text, warehouse_case_report_for_offender_sar_related.date_received)), (date_part('month'::text, warehouse_case_report_for_offender_sar_related.date_received))) stats_current_year ON stats_base_categories.sar_subject_type = stats_current_year.sar_subject_type::text AND stats_base_categories.stats_month::double precision = stats_current_year.stats_month AND stats_base_categories.requester_type = stats_current_year.requester_from
     LEFT JOIN ( SELECT warehouse_case_report_for_offender_sar_related.sar_subject_type,
            warehouse_case_report_for_offender_sar_related.requester_from,
            date_part('year'::text, warehouse_case_report_for_offender_sar_related.date_received) AS stats_year,
            date_part('month'::text, warehouse_case_report_for_offender_sar_related.date_received) AS stats_month,
            count(warehouse_case_report_for_offender_sar_related.case_id) AS previous_year_volume
           FROM warehouse_case_report_for_offender_sar_related
          WHERE date_part('year'::text, warehouse_case_report_for_offender_sar_related.date_received) = (date_part('year'::text, CURRENT_DATE) - 1::double precision) AND warehouse_case_report_for_offender_sar_related.rejected::text = 'Yes'::text
          GROUP BY warehouse_case_report_for_offender_sar_related.sar_subject_type, (date_part('year'::text, warehouse_case_report_for_offender_sar_related.date_received)), (date_part('month'::text, warehouse_case_report_for_offender_sar_related.date_received)), warehouse_case_report_for_offender_sar_related.requester_from
          ORDER BY (date_part('year'::text, warehouse_case_report_for_offender_sar_related.date_received)), (date_part('month'::text, warehouse_case_report_for_offender_sar_related.date_received))) stats_previous_year ON stats_base_categories.sar_subject_type = stats_previous_year.sar_subject_type::text AND stats_base_categories.stats_month::double precision = stats_previous_year.stats_month AND stats_base_categories.requester_type = stats_previous_year.requester_from;

 -- offender_subject_type_volume_exclude_rejected_case_view
 CREATE view offender_subject_type_volume_exclude_rejected_case_view as
 SELECT stats_base_categories.sar_subject_type,
    stats_base_categories.stats_month,
    concat(stats_base_categories.stats_month, ' - ', to_char(to_date(stats_base_categories.stats_month::text, 'MM'::text)::timestamp with time zone, 'Month'::text)) AS "Month Name",
    stats_base_categories.requester_type,
    stats_current_year.current_year_volume,
    stats_previous_year.previous_year_volume
   FROM ( SELECT a.stats_month,
            b.sar_subject_type,
            c.requester_type
           FROM ( SELECT to_char(generate_series(to_char(CURRENT_DATE::timestamp with time zone, 'YYYY-01-01'::text)::timestamp without time zone, CURRENT_DATE::timestamp without time zone, '1 mon'::interval), 'MM'::text)::integer AS stats_month) a
             CROSS JOIN ( SELECT t.sar_subject_type
                   FROM ( VALUES ('Offender'::text), ('Ex offender'::text), ('Detainee'::text), ('Ex detainee'::text), ('Probation service user'::text), ('Ex probation service user'::text)) t(sar_subject_type)) b
             CROSS JOIN ( SELECT t.requester_type
                   FROM ( VALUES ('Third party'::text), ('Data subject'::text)) t(requester_type)) c) stats_base_categories
     LEFT JOIN ( SELECT warehouse_case_report_for_offender_sar_related.sar_subject_type,
            warehouse_case_report_for_offender_sar_related.requester_from,
            date_part('year'::text, warehouse_case_report_for_offender_sar_related.date_received) AS stats_year,
            date_part('month'::text, warehouse_case_report_for_offender_sar_related.date_received) AS stats_month,
            count(warehouse_case_report_for_offender_sar_related.case_id) AS current_year_volume
           FROM warehouse_case_report_for_offender_sar_related
          WHERE date_part('year'::text, warehouse_case_report_for_offender_sar_related.date_received) = date_part('year'::text, CURRENT_DATE) AND warehouse_case_report_for_offender_sar_related.case_type::text = 'Offender SAR'::text
          GROUP BY warehouse_case_report_for_offender_sar_related.sar_subject_type, (date_part('year'::text, warehouse_case_report_for_offender_sar_related.date_received)), (date_part('month'::text, warehouse_case_report_for_offender_sar_related.date_received)), warehouse_case_report_for_offender_sar_related.requester_from
          ORDER BY (date_part('year'::text, warehouse_case_report_for_offender_sar_related.date_received)), (date_part('month'::text, warehouse_case_report_for_offender_sar_related.date_received))) stats_current_year ON stats_base_categories.sar_subject_type = stats_current_year.sar_subject_type::text AND stats_base_categories.stats_month::double precision = stats_current_year.stats_month AND stats_base_categories.requester_type = stats_current_year.requester_from
     LEFT JOIN ( SELECT warehouse_case_report_for_offender_sar_related.sar_subject_type,
            warehouse_case_report_for_offender_sar_related.requester_from,
            date_part('year'::text, warehouse_case_report_for_offender_sar_related.date_received) AS stats_year,
            date_part('month'::text, warehouse_case_report_for_offender_sar_related.date_received) AS stats_month,
            count(warehouse_case_report_for_offender_sar_related.case_id) AS previous_year_volume
           FROM warehouse_case_report_for_offender_sar_related
          WHERE date_part('year'::text, warehouse_case_report_for_offender_sar_related.date_received) = (date_part('year'::text, CURRENT_DATE) - 1::double precision) AND warehouse_case_report_for_offender_sar_related.case_type::text = 'Offender SAR'::text
          GROUP BY warehouse_case_report_for_offender_sar_related.sar_subject_type, (date_part('year'::text, warehouse_case_report_for_offender_sar_related.date_received)), (date_part('month'::text, warehouse_case_report_for_offender_sar_related.date_received)), warehouse_case_report_for_offender_sar_related.requester_from
          ORDER BY (date_part('year'::text, warehouse_case_report_for_offender_sar_related.date_received)), (date_part('month'::text, warehouse_case_report_for_offender_sar_related.date_received))) stats_previous_year ON stats_base_categories.sar_subject_type = stats_previous_year.sar_subject_type::text AND stats_base_categories.stats_month::double precision = stats_previous_year.stats_month AND stats_base_categories.requester_type = stats_previous_year.requester_from;

-- offender_sar_vetting_track_view
 CREATE view offender_sar_vetting_track_view as
 SELECT data_request_pages_received.case_id,
    data_request_pages_received.total_page_received,
    ready_to_copy.date_for_completing_vetting
   FROM ( SELECT data_requests.case_id,
            sum(data_requests.cached_num_pages) AS total_page_received
           FROM data_requests
          GROUP BY data_requests.case_id) data_request_pages_received
     JOIN ( SELECT case_transitions.case_id,
            case_transitions.created_at AS date_for_completing_vetting
           FROM case_transitions
             JOIN ( SELECT case_transitions_1.case_id,
                    max(case_transitions_1.id) AS transition_id
                   FROM case_transitions case_transitions_1
                  WHERE case_transitions_1.event::text = 'mark_as_ready_to_copy'::text
                  GROUP BY case_transitions_1.case_id) ready_to_copy_transitions ON case_transitions.id = ready_to_copy_transitions.transition_id) ready_to_copy ON data_request_pages_received.case_id = ready_to_copy.case_id;
