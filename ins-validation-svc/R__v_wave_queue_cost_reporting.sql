--drop view if exists public.wave_queue_cost_reporting;

CREATE OR REPLACE VIEW public.wave_queue_cost_reporting
AS WITH queue_detail AS (
         SELECT wq.queue_id,
            wq.visit_id,
            wq.patient_id,
            wq.sent_to_wave,
            wq.create_ts,
            wq.update_ts,
            wq.payer_code AS sent_payor_code,
                CASE
                    WHEN wq.payer_code IS NULL THEN 'DISCO'::text
                    ELSE 'ELIG'::text
                END AS request_type,
            (date_trunc('month'::text, now()) + '1 mon -1 days'::interval)::date AS month_end,
            count(wq.visit_id) OVER (PARTITION BY wq.request_type, ((date_trunc('month'::text, now()) + '1 mon -1 days'::interval)::date) ORDER BY wq.request_type ROWS UNBOUNDED PRECEDING) AS monthly_request_cnt
           FROM insval_queue wq
          ORDER BY wq.create_ts
        ), cost AS (
         SELECT qd.queue_id,
            qd.visit_id,
            qd.patient_id,
            qd.sent_to_wave,
            qd.create_ts,
            qd.update_ts,
            qd.sent_payor_code,
            qd.request_type,
            qd.month_end,
            qd.monthly_request_cnt,
            wc.request_cost,
            row_number() OVER (PARTITION BY qd.queue_id, wc.request_type, qd.month_end ORDER BY wc.request_amount) AS rnk
           FROM wave_cost wc
             LEFT JOIN ( SELECT queue_detail.queue_id,
                    queue_detail.visit_id,
                    queue_detail.patient_id,
                    queue_detail.sent_to_wave,
                    queue_detail.create_ts,
                    queue_detail.update_ts,
                    queue_detail.sent_payor_code,
                    queue_detail.request_type,
                    queue_detail.month_end,
                    queue_detail.monthly_request_cnt
                   FROM queue_detail) qd ON wc.request_type::text = qd.request_type
          WHERE qd.monthly_request_cnt < wc.request_amount AND wc.is_active = true
        ), wave_response AS (
         SELECT wpj.queue_id,
            wpj.visit_id,
            wpj.ssn,
            wpj.coveragestatus,
            wpj.payercode,
            row_number() OVER (PARTITION BY wpj.queue_id) AS dedupe
           FROM wave_parsed_json wpj
          --WHERE wpj.coveragestatus::text = 'ACTIVE'::text and 
          ORDER BY wpj.hierarchy_level
        )
 select -- mt.patient_id AS master_id,
    c.queue_id,
    c.visit_id,
    c.patient_id,
    c.sent_to_wave,
    c.create_ts,
    c.update_ts,
    c.sent_payor_code,
    c.request_type,
    c.month_end,
    c.monthly_request_cnt,
    c.request_cost,
    c.rnk,
    wr.ssn,
    wr.coveragestatus,
    wr.payercode,
        CASE
            WHEN wr.payercode::text <> 'DISCO'::text AND c.request_type = 'DISCO'::text AND c.sent_to_wave IS TRUE THEN 'Wave Insurance Found'::text
            WHEN (wr.payercode::text = 'DISCO'::text or wr.payercode is null) AND c.request_type = 'DISCO'::text AND c.sent_to_wave IS TRUE THEN 'Wave Insurance Not Found'::text
            WHEN wr.coveragestatus::text = 'ACTIVE'::text AND c.request_type = 'ELIG'::text AND c.sent_to_wave IS TRUE THEN 'Wave Insurance Validated'::text
            WHEN (wr.coveragestatus::text <> 'ACTIVE'::text or wr.coveragestatus is null) AND c.request_type = 'ELIG'::text AND c.sent_to_wave IS TRUE THEN 'Wave Insurance Not Validated'::text
     		WHEN c.request_type = 'DISCO'::text and c.sent_to_wave IS FALSE THEN 'Wave Request Not Sent Yet'::text
     		WHEN c.request_type = 'ELIG'::text and c.sent_to_wave IS FALSE THEN 'Wave Eligibility Not Sent Yet'::text
            ELSE NULL::text
        END AS ins_found_status
   FROM cost c
     LEFT JOIN wave_response wr ON wr.queue_id = c.queue_id AND wr.dedupe = 1
    -- LEFT JOIN insval_demographics mt ON mt.patient_id::text = c.patient_id::text
  WHERE c.rnk = 1
  and c.request_type = 'DISCO'
  ORDER BY c.queue_id DESC;
  
 GRANT SELECT ON TABLE public.wave_queue_cost_reporting TO group readonly_access;  