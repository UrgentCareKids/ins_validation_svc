CREATE OR REPLACE PROCEDURE public.insval_queue_loader(INOUT out_queue_id integer, IN in_payload json)
 LANGUAGE plpgsql
AS $procedure$
	
	
declare

i_payer_code varchar;
i_request_type varchar;
i_patient_id varchar;

begin
	
	--assign variable:
	select in_payload::json->>'patient_id' into i_patient_id;


	
	if exists (select patient_id from public.insval_queue where patient_id = i_patient_id and create_ts >=  current_timestamp  - interval '10 minutes' limit 1)
		then
		else
		--raise notice 'it is true - doing stuff';
INSERT INTO public.insval_queue (patient_id, sent_to_wave, is_recycled, task_available,create_ts, update_ts, process_type)
		VALUES(i_patient_id,  false, false, true, 'now'::text::timestamp with time zone, 'now'::text::timestamp with time zone, 'pond_request');
	end if;
	
END;


$procedure$
;
