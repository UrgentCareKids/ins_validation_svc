CREATE OR REPLACE PROCEDURE public.wave_recycler(IN in_queue_id integer)
 LANGUAGE plpgsql
AS $procedure$
	
	
declare
i_patient_id varchar;
i_request_type varchar;
i_within_days int;
i_recycled_queue_id bigint;

begin
	--take queue id look at control table and see if patient id is in parsed table within control table parameters
	--if yes take parsed data and put with new queue_id	
	select patient_id into i_patient_id from public.insval_queue iq where iq.queue_id = in_queue_id;
	select request_type into i_request_type from public.insval_queue iq where iq.queue_id = in_queue_id;
	select within_days into i_within_days from public.insval_recycler_cntrl irc where irc.request_type = i_request_type;


	--grab the last queue id where patient IDs match and within the control variables and not previously recycled
	select max(queue_id) into i_recycled_queue_id from wave_parsed_json wpj where patient_id = i_patient_id and create_ts > current_date - interval '1 day' * i_within_days and validation_type <> 'recycled';

	if i_recycled_queue_id is not null 
	then
		INSERT INTO public.wave_parsed_json
		(create_ts, visit_id, first_nm, last_nm, middle_nm, dob, gender, ssn, address_line1, address_line2, city, state, zip, zip_extension, reported_on, current_address_ind, patientrelationshiptosubscriber, guarantor, policy_memberid, plan_name, group_name, insurance_name, policystart, policyend, confidencelevel, confidencelevelreason, rejectioncode, rejectioncodes, hierarchy_level, statuscode, payername, coveragestatus_nr, coveragestatus, planidentification, planname, groupnumber, groupname, policystartdate, policyenddate, plantype, validation_type, payercode, ininddeductible, ininddeductibleremaining, inindoutofpocket, inindoutofpocketremaining, row_card, patient_id, queue_id)
		(SELECT current_timestamp, visit_id, first_nm, last_nm, middle_nm, dob, gender, ssn, address_line1, address_line2, city, state, zip, zip_extension, reported_on, current_address_ind, patientrelationshiptosubscriber, guarantor, policy_memberid, plan_name, group_name, insurance_name, policystart, policyend, confidencelevel, confidencelevelreason, rejectioncode, rejectioncodes, hierarchy_level, statuscode, payername, coveragestatus_nr, coveragestatus, planidentification, planname, groupnumber, groupname, policystartdate, policyenddate, plantype, 'recycled', payercode, ininddeductible, ininddeductibleremaining, inindoutofpocket, inindoutofpocketremaining, row_card, patient_id, in_queue_id
		FROM public.wave_parsed_json
		where queue_id = i_recycled_queue_id);
		
		update public.insval_queue 
		set is_recycled = true,
			task_available = false,
			update_ts = current_timestamp
		where queue_id = in_queue_id
			   ;
	else
		--call wave 
		perform pg_notify('wave_validation_channel', (concat('{"queue_id":"',in_queue_id,'"}')::text));
		update public.insval_queue 
		set update_ts = current_timestamp
		where queue_id = in_queue_id;
	end if;
	
END;


$procedure$
;
