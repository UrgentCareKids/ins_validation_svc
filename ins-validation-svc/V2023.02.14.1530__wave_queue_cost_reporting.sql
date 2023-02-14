-- if join to stg_wave.wave_patient_response_json use max queue id and max timestamp 
drop view if exists public.wave_queue_cost_reporting;

CREATE OR REPLACE VIEW public.wave_queue_cost_reporting
as


with queue_detail as (     
	select wq.queue_id,
			wq.visit_id, 
			wq.patient_id,
			wq.sent_to_wave,
			wq.create_ts, 
			wq.update_ts, 
			wq.payer_code as sent_payor_code, 
			CASE WHEN wq.payer_code IS NULL THEN 'DISCO'::text
             ELSE 'ELIG'::text END AS request_type,
             (date_trunc('month', now()) + interval '1 month - 1 day')::date as month_end,
             count(visit_id) over (partition by request_type, (date_trunc('month', now()) + interval '1 month - 1 day')::date order by request_type rows unbounded preceding) as monthly_request_cnt
         FROM public.insval_queue wq
         order by wq.create_ts asc      
     )
,cost as (
  select qd.*, wc.request_cost, pg_catalog.row_number()
          OVER( 
          PARTITION BY qd.queue_id, wc.request_type, qd.month_end
          ORDER BY wc.request_amount) AS rnk from public.wave_cost wc
  		left join (select * from queue_detail) qd
  		ON wc.request_type::text = qd.request_type
     WHERE qd.monthly_request_cnt < wc.request_amount AND wc.is_active = true
     )
  ,wave_response as (
   select wpj.queue_id, wpj.visit_id, wpj.ssn, wpj.coveragestatus, wpj.payercode,
   		row_number() over (partition by queue_id) as dedupe
		from public.wave_parsed_json wpj 
   		where coveragestatus = 'ACTIVE'
   		order by hierarchy_level asc
  )
    select
     mt.patient_id as master_id,
     		c.*, wr.ssn, wr.coveragestatus, wr.payercode,
     		case when wr.payercode <> 'DISCO' and request_type = 'DISCO' and sent_to_wave is true then 'Wave Insurance Found'
        		 when wr.payercode = 'DISCO' and request_type = 'DISCO' and sent_to_wave is true then 'Wave Insurance Not Found'			 
     		end as ins_found_status,
     		case when wr.coveragestatus = 'ACTIVE' and request_type = 'ELIG' and sent_to_wave is true then 'Wave Insurance Found'
       			 when wr.coveragestatus <> 'ACTIVE' and request_type = 'ELIG' and sent_to_wave is true then 'Wave Insurance Not Found'
     		end as ins_verification_status
     		from cost c 
     left join wave_response wr on wr.queue_id = c.queue_id and dedupe = 1
     left join public.insval_demographics mt on mt.patient_id  = c.patient_id 
     where rnk= 1 
    order by queue_id desc;