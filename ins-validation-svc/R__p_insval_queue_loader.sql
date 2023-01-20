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


--	with check_payor_code as (
--	select
--		mtfd.primary_ins_id, 
--		ic.pri_ins_id,
--		ic.ext_id 
--	from
--		stg_pg_master_data.mat_tmp_fast_demographics mtfd
--	left join map_srv.ins_cx ic on mtfd.primary_ins_id = ic.pri_ins_id
--	where
--		mtfd.primary_ins_id ilike ic.pri_ins_id  and ic.ext_source = 'WAVE' and i_patient_id = mtfd.master_id 
--	)
--	
--	select ext_id into i_payer_code from check_payor_code;
--
--	select case when i_payer_code is null then 'DISCO' else 'ELIG' end into i_request_type;
--	
	
	if exists (select patient_id from public.insval_queue where patient_id = i_patient_id and create_ts >=  current_timestamp  - interval '10 minutes' limit 1)
		then
		else
		--raise notice 'it is true - doing stuff';
INSERT INTO public.insval_queue (tbl_nm, patient_id, sent_to_wave, is_recycled, task_available,create_ts, update_ts)
		VALUES('mat_tmp_fast_demographics' ,i_patient_id,  false, false, true, 'now'::text::timestamp with time zone, 'now'::text::timestamp with time zone);
	end if;
	
END;


$procedure$
;

-- Permissions

ALTER PROCEDURE public.insval_queue_loader(inout int4, in json) OWNER TO babylon;
GRANT ALL ON PROCEDURE public.insval_queue_loader(inout int4, in json) TO babylon;
