 DROP view if exists offender_data_requests_volume_view;
 DROP view if exists offender_subject_type_volume_view;
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
                   FROM ( VALUES ('all_prison_records'::text), ('security_records'::text), ('nomis_records'::text), ('nomis_other'::text), ('nomis_contact_logs'::text), ('probation_records'::text), ('cctv_and_bwcf'::text), ('telephone_recordings'::text), ('telephone_pin_logs'::text), ('probation_archive'::text), ('mappa'::text), ('pdp'::text), ('court'::text), ('dps'::text), ('other'::text)) t(request_type)) b) stats_base_categories
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


-- offender_subject_type_volume_view
 CREATE view offender_subject_type_volume_view as
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

