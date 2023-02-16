CREATE OR REPLACE FUNCTION public.mstr_notify_wave_validation(i_queue_id integer)
 RETURNS text
 LANGUAGE plpgsql
AS $function$ 
begin 
	perform pg_notify('wave_validation_channel', (concat('{"queue_id":"',i_queue_id,'"}')::text));
	return null;
end;
$function$
;


CREATE OR REPLACE PROCEDURE public.wave_return_insurance(IN in_queue_id integer, OUT payload jsonb)
 LANGUAGE plpgsql
AS $procedure$
	
	
declare
i_pri_payer_code varchar;
i_sec_payer_code varchar;
i_pri_ins_id varchar;

begin
	

select nullif(wpj.payercode,'') payercode into i_pri_payer_code from wave_parsed_json wpj 
where 
	hierarchy_level::int = 1
	and coveragestatus_nr::int = 1
	and confidencelevel::int = 1
	and wpj.queue_id = in_queue_id
	and patient_id is not null;

select pri_ins_id 
into i_pri_ins_id
from ins_cx ic
where i_pri_payer_code = ic.ext_id and ext_source = 'WAVE'
limit 1;

select nullif(wpj.payername,'') payername into i_sec_payer_code from wave_parsed_json wpj 
where 
	hierarchy_level::int = 2
	and coveragestatus_nr::int = 1
	and confidencelevel::int = 1
	and wpj.queue_id = in_queue_id
	and patient_id is not null;


with primary_ins as (
select
	wpj.create_ts create_ts,
	wpj.queue_id , 
	nullif(wpj.patient_id, '') patient_id ,
	nullif(wpj.payername,'') payername ,
	nullif(wpj.planname,'') planname ,
	nullif(wpj.groupnumber,'') groupnumber, 
	nullif(wpj.payercode,'') payercode ,
	nullif(wpj.first_nm,'') first_nm ,
	nullif(wpj.last_nm,'') last_nm ,
	nullif(wpj.middle_nm,'') middle_nm ,
	nullif(wpj.dob::varchar,'') dob ,
	nullif(wpj.gender,'') gender ,
	wpj.policystart  ,
	wpj.policyend 
	
	from wave_parsed_json wpj
where
	hierarchy_level::int = 1
	and coveragestatus_nr::int = 1
	and confidencelevel::int = 1
	and wpj.queue_id = in_queue_id
	and patient_id is not null
),
secondary_ins as(
select
	wpj2.queue_id,
	nullif(wpj2.payername,'') as payername2,
	nullif(wpj2.planname,'') as planname2,
	nullif(wpj2.payercode,'') as payercode2,
	nullif(wpj2.groupnumber,'') groupnumber2, 
	nullif(wpj2.first_nm,'') as first_nm2,
	nullif(wpj2.last_nm,'') as last_nm2,
	nullif(wpj2.middle_nm,'') as middle_nm2,
	nullif(wpj2.dob::varchar,'') as dob2,
	nullif(wpj2.gender,'') as gender2,
	wpj2.policystart as policystart2,
	wpj2.policyend as policyend2
	from wave_parsed_json wpj2
where
	hierarchy_level::int = 2
	and coveragestatus_nr::int = 1
	and confidencelevel::int = 1
	and wpj2.queue_id = in_queue_id
	and patient_id is not null
	) 




select
json_strip_nulls(json_build_object('secondary_ins_group_number', groupnumber2, 'primary_ins_group_id',groupnumber,'wave_ts',create_ts,'secondary_ins_id', i_sec_payer_code,'primary_ins_id',i_pri_ins_id,'transaction_type','ins_validation','id', p.patient_id, 'primary_ins_carrier', payername, 'primary_ins_plan', planname, 'primary_ext_ins_id', payercode, 'primary_ins_ph_first_name', first_nm, 'primary_ins_ph_last_name', last_nm, 'primary_ins_ph_middle_name', middle_nm, 'primary_ins_ph_dob', dob, 'primary_ins_ph_birth_sex', gender, 'primary_ins_ph_policy_start', policystart, 'primary_ins_ph_policy_end', policyend, 'secondary_ins_carrier', payername, 'secondary_ins_plan', planname, 'secondary_ext_ins_id', payercode2, 'secondary_ins_ph_first_name', first_nm2, 'secondary_ins_ph_last_name', last_nm2, 'secondary_ins_ph_middle_name', middle_nm2, 'secondary_ins_ph_dob', dob2, 'secondary_ins_ph_birth_sex', gender2, 'secondary_ins_ph_policy_start', policystart2, 'secondary_ins_ph_policy_end', policyend2))
from
into payload 
primary_ins p
left join secondary_ins s on p.queue_id = s.queue_id;

	
END;


$procedure$
;


CREATE OR REPLACE PROCEDURE public.manual_queue_loader()
 LANGUAGE plpgsql
AS $procedure$
	
	
declare
r_record_id record;
i_queue_id int;

begin
	
--get queue id and insert into insval_queue 
	for r_record_id in (
	select distinct request_id  from manual_validation_request mvr where queue_id is null
	)
	loop
		with queue_insert as (
			INSERT INTO insval_queue  (sent_to_wave, create_ts, update_ts, payer_code, process_type, request_type, patient_id, is_recycled, task_available)
			SELECT false, current_timestamp , current_timestamp, null, 'manual_request', 'DISCO', patient_id , false, true 
			FROM manual_validation_request mvr
			where r_record_id.request_id = mvr.request_id 
			returning queue_id
		)
		select queue_id into i_queue_id from queue_insert;
	
	--update manual_validation_request with queue_id
	update manual_validation_request 
		set queue_id = i_queue_id,
			update_ts = current_timestamp 
			where r_record_id.request_id = request_id  ;
	
--	call insval_distributor(:in_queue_id) 
raise notice 'before call %', i_queue_id;
	call insval_distributor(i_queue_id);
--error catch goes here TBD

	commit;
	
	end loop;
	



	
END;


$procedure$
;


CREATE OR REPLACE FUNCTION public.mstr_notify_ins_validation()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$ 
begin 
	if (new.process_type <> 'manual_request' and TG_OP = 'INSERT')
	then 
	perform pg_notify('ins_validation_channel_insert', (concat('{"queue_id":"',new.queue_id,'", "patient_id":"',new.patient_id,'"}')::text));
	elsif (TG_OP = 'UPDATE' AND NEW.send_to_patient_service = true) 
	then
	perform pg_notify('ins_validation_channel_update', (concat('{"queue_id":"',new.queue_id,'", "patient_id":"',new.patient_id,'"}')::text));
	end if;
	return null;
end;
$function$
;


CREATE OR REPLACE PROCEDURE public.insval_distributor(IN in_queue_id integer)
 LANGUAGE plpgsql
AS $procedure$
	
	
declare
i_process_type varchar;

begin
	raise notice 'distributing here %', in_queue_id;
	select process_type into i_process_type from insval_queue iq where iq.queue_id = in_queue_id;
	raise notice 'process type here %', i_process_type;

	if i_process_type = 'manual_request'
	

	then

		INSERT INTO public.insval_demographics
		(queue_id, patient_id, patient_first_name, patient_middle_name, patient_last_name, patient_dob, primary_ins_ph_first_name, primary_ins_ph_middle_name, primary_ins_ph_last_name, primary_ins_ph_dob, patient_address1, patient_address2, patient_address_city, patient_address_state, patient_address_zip, date_of_service)
		select queue_id, patient_id , patient_first_name , patient_middle_name , patient_last_name , patient_dob , primary_ins_ph_first_name , primary_ins_ph_middle_name , primary_ins_ph_last_name , primary_ins_ph_dob , patient_address1 , patient_address2 , patient_address_city , patient_address_state , patient_address_zip , date_of_service   from public.manual_validation_request mvr where queue_id = in_queue_id;
	commit;
		raise notice 'insert complete %', in_queue_id;

	call public.wave_recycler(in_queue_id);
	raise notice 'called recycler';
	else	
		call public.wave_recycler(in_queue_id);
	end if;

	raise notice 'distributing finished %', in_queue_id;

	
END;


$procedure$
;
