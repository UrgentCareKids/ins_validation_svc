CREATE OR REPLACE PROCEDURE public.wave_parser(IN in_queue_id character varying)
 LANGUAGE plpgsql
AS $procedure$
	
	
  

declare
--var area
i_patient_id varchar;
i_validation_type varchar;

begin

select patient_id into i_patient_id from public.insval_queue iq where queue_id = in_queue_id::int;
select CASE WHEN (SELECT process_type  FROM public.insval_queue WHERE queue_id = in_queue_id::int) = 'manual_request' THEN 'manual_request' ELSE 'wave_parsed' end into i_validation_type  ;



with found_coverages_ins as (
select 
	create_ts,
	payload::json->>'clientTraceNumber' as queue_id,
	payload::json->>'statusCode' as statuscode,
	payload::json#>'{foundCoverages,0}'->>'payerName' as payername,
	payload::json#>'{foundCoverages,0}'->>'coverageStatus' as coveragestatus_nr,
	payload::json#>'{foundCoverages,0}'->'ruleResult'->>'PlanIdentification' as planidentification,
	payload::json#>'{foundCoverages,0}'->'ruleResult'->>'PlanName' as planname,
	payload::json#>'{foundCoverages,0}'->'ruleResult'->>'GroupNumber' as groupnumber,
	payload::json#>'{foundCoverages,0}'->'ruleResult'->>'GroupName' as group_name,
	payload::json#>'{foundCoverages,0}'->'ruleResult'->>'PolicyStartDate' as policystartdate,
	payload::json#>'{foundCoverages,0}'->'ruleResult'->>'PolicyEndDate' as policyenddate,
	payload::json#>'{foundCoverages,0}'->'ruleResult'->>'PlanType' as plantype,
	payload::json#>'{foundCoverages,0}'->'ruleResult'->>'CoverageStatus' as coveragestatus,
	payload::json#>'{foundCoverages,0}'->'patient'->>'firstName' as first_nm,
	payload::json#>'{foundCoverages,0}'->'patient'->>'lastName' as last_nm,
	payload::json#>'{foundCoverages,0}'->'patient'->>'middleName' as middle_nm,
	payload::json#>'{foundCoverages,0}'->'patient'->>'dateOfBirth' as dob,
	payload::json#>'{foundCoverages,0}'->'patient'->>'gender' as gender,
	payload::json#>'{foundCoverages,0}'->'patient'->>'ssn' as ssn,
	payload::json#>'{foundCoverages,0}'->'patient'#>'{addresses,0}'->>'addressLine1' as address_line1,
	payload::json#>'{foundCoverages,0}'->'patient'#>'{addresses,0}'->>'addressLine2' as address_line2,
	payload::json#>'{foundCoverages,0}'->'patient'#>'{addresses,0}'->>'city' as city,
	payload::json#>'{foundCoverages,0}'->'patient'#>'{addresses,0}'->>'state' as state,
	payload::json#>'{foundCoverages,0}'->'patient'#>'{addresses,0}'->>'zip' as zip,
	payload::json#>'{foundCoverages,0}'->'patient'#>'{addresses,0}'->>'zipExtension' as zip_extension,
	payload::json#>'{foundCoverages,0}'->'patient'#>'{addresses,0}'->>'reportedOn' as reported_on,
	payload::json#>'{foundCoverages,0}'->'patient'#>'{addresses,0}'->>'currentAddress' as current_address_ind, 
	payload::json#>'{foundCoverages,0}'->>'patientRelationshipToSubscriber' as patientrelationshiptosubscriber,
	payload::json#>'{foundCoverages,0}'->>'subscriber' as guarantor,
	payload::json#>'{foundCoverages,0}'->>'memberId' as policy_memberid,
	payload::json#>'{foundCoverages,0}'->'summary'->>'name' as plan_name,
	payload::json#>'{foundCoverages,0}'->'summary'->>'groupName' as groupname,
	payload::json#>'{foundCoverages,0}'->'summary'->>'planSponsor' as insurance_name,
	payload::json#>'{foundCoverages,0}'->'summary'->>'policyStart' as policystart,
	payload::json#>'{foundCoverages,0}'->'summary'->>'policyEnd' as policyend,
	payload::json#>'{foundCoverages,0}'->>'confidenceLevel' as confidencelevel,
	payload::json#>'{foundCoverages,0}'->>'confidenceLevelReason' as confidencelevelreason,
	payload::json#>'{foundCoverages,0}'->>'rejectionCode' as rejectioncode,
	payload::json#>'{foundCoverages,0}'#>'{rejectionCodes,0}' as rejectioncodes,
	payload::json#>'{foundCoverages,0}'->'hierarchy' as hierarchy_level,
	payload::json#>'{foundCoverages,0}'->'payerCode' as payercode,
	payload::json#>'{foundCoverages,0}'->'ruleResult'->>'InIndDeductible' as ininddeductible,
	payload::json#>'{foundCoverages,0}'->'ruleResult'->>'InIndDeductibleRemaining' as ininddeductibleremaining,
	payload::json#>'{foundCoverages,0}'->'ruleResult'->>'InIndOutOfPocket' as inindoutofpocket,
	payload::json#>'{foundCoverages,0}'->'ruleResult'->>'InIndOutOfPocketRemaining' as inindoutofpocketremaining
from  public.wave_patient_response_json wprj  where wprj.payload::json#>>'{foundCoverages,0}' is not null and queue_id = in_queue_id
),
demographics_only as
(
--...(query assuming only demos)
select 
	create_ts as create_ts,
	payload::json->>'clientTraceNumber' as queue_id,
	payload::json->'demographicResponse'->'patientDemographics'->>'firstName' as first_nm,
	payload::json->'demographicResponse'->'patientDemographics'->>'lastName' as last_nm,
	payload::json->'demographicResponse'->'patientDemographics'->>'middleName' as middle_nm,
	payload::json->'demographicResponse'->'patientDemographics'->>'dateOfBirth' as dob,
	payload::json->'demographicResponse'->'patientDemographics'->>'gender' as gender,
	payload::json->'demographicResponse'->'patientDemographics'->>'ssn' as ssn,
	payload::json->'demographicResponse'->'patientDemographics'#>'{addresses,0}'->>'addressLine1' as address_line1,
	payload::json->'demographicResponse'->'patientDemographics'#>'{addresses,0}'->>'addressLine2' as address_line2,
	payload::json->'demographicResponse'->'patientDemographics'#>'{addresses,0}'->>'city' as city,
	payload::json->'demographicResponse'->'patientDemographics'#>'{addresses,0}'->>'state' as state,
	payload::json->'demographicResponse'->'patientDemographics'#>'{addresses,0}'->>'zip' as zip,
	payload::json->'demographicResponse'->'patientDemographics'#>'{addresses,0}'->>'zipExtension' as zip_extension,
	payload::json->'demographicResponse'->'patientDemographics'#>'{addresses,0}'->>'reportedOn' as reported_on,
	payload::json->'demographicResponse'->'patientDemographics'#>'{addresses,0}'->>'currentAddress' as current_address_ind
from public.wave_patient_response_json wprj where wprj.payload::json#>>'{foundCoverages,0}' is null and queue_id = in_queue_id
),
final_demographics as (
	select 
		fci.create_ts,
		fci.queue_id::int,
		fci.first_nm,
		fci.last_nm,
		fci.middle_nm,
		fci.dob::date,
		fci.gender,
		fci.ssn,
		fci.address_line1,
		fci.address_line2,
		fci.city,
		fci.state,
		fci.zip,
		fci.zip_extension,
		fci.reported_on::date,
		fci.current_address_ind::bool,
		fci.patientrelationshiptosubscriber,
		fci.guarantor,
		fci.policy_memberid,
		fci.plan_name,
		fci.group_name,
		fci.insurance_name,
		fci.policystart::date,
		fci.policyend::date,
		fci.confidencelevel::int,
		fci.confidencelevelreason,
		fci.rejectioncode,
		fci.rejectioncodes::jsonb,
		fci.hierarchy_level,
		fci.statuscode::int,
		fci.payername,
		fci.coveragestatus_nr::int,
		fci.coveragestatus,
		fci.planidentification,
		fci.planname,
		fci.groupnumber,
		fci.groupname,
		fci.policystartdate,
		fci.policyenddate,
		fci.plantype,
		fci.payercode,
		fci.ininddeductible,
		fci.ininddeductibleremaining,
		fci.inindoutofpocket,
		fci.inindoutofpocketremaining,
		'parsed_wave' as validation_type
	from found_coverages_ins fci 

union all

	select 
		c.create_ts,
		c.queue_id::int,
		c.first_nm,
		c.last_nm,
		c.middle_nm,
		c.dob::date,
		c.gender,
		c.ssn,
		c.address_line1,
		c.address_line2,
		c.city,
		c.state,
		c.zip,
		c.zip_extension,
		c.reported_on::date,
		c.current_address_ind::bool,
		null as patientrelationshiptosubscriber,
		null as guarantor,
		null as policy_memberid,
		null as plan_name,
		null as group_name,
		null as insurance_name,
		null as policystartdate,
		null as policyend,
		null as confidencelevel,
		null as confidencelevelreason,
		null as rejectioncode,
		null as rejectioncodes,
		null as hierarchy_level,
		null as statuscode,
		null as payername,
		null as coveragestatus_nr,
		null as coveragestatus,
		null as planidentification,
		null as planname,
		null as groupnumber,
		null as groupname,
		null as policystartdate,
		null as policyenddate,
		null as plantype,
		null as payercode,
	 	null as ininddeductible,
		null as ininddeductibleremaining,
		null as inindoutofpocket,
		null as inindoutofpocketremaining,

		'parsed_wave' as validation_type
from demographics_only c
)


insert into public.wave_parsed_json
		(
		create_ts,
		queue_id,
		first_nm,
		last_nm,
		middle_nm,
		dob,
		gender,
		ssn,
		address_line1,
		address_line2,
		city,
		state,
		zip,
		zip_extension,
		reported_on,
		current_address_ind,
		patientrelationshiptosubscriber,
		guarantor,
		policy_memberid,
		plan_name,
		group_name,
		insurance_name,
		policystart,
		policyend,
		confidencelevel,
		confidencelevelreason,
		rejectioncode,
		rejectioncodes,
		hierarchy_level,
		statuscode,
		payername,
		coveragestatus_nr,
		coveragestatus,
		planidentification,
		planname,
		groupnumber,
		groupname,
		policystartdate,
		policyenddate,
		plantype,
		payercode,
		ininddeductible,
		ininddeductibleremaining,
		inindoutofpocket,
		inindoutofpocketremaining,
		validation_type,
		patient_id 
		)
		

	
select 
		fd.create_ts,
		fd.queue_id,
		fd.first_nm,
		fd.last_nm,
		fd.middle_nm,
		fd.dob,
		fd.gender,
		fd.ssn,
		fd.address_line1,
		fd.address_line2,
		fd.city,
		fd.state,
		fd.zip,
		fd.zip_extension,
		fd.reported_on,
		fd.current_address_ind,
		fd.patientrelationshiptosubscriber,
		fd.guarantor,
		fd.policy_memberid,
		fd.plan_name,
		fd.group_name,
		fd.insurance_name,
		fd.policystart,
		fd.policyend,
		fd.confidencelevel,
		fd.confidencelevelreason,
		fd.rejectioncode,
		fd.rejectioncodes,
		fd.hierarchy_level,
		fd.statuscode,
		fd.payername,
		fd.coveragestatus_nr,
		fd.coveragestatus,
		fd.planidentification,
		fd.planname,
		fd.groupnumber,
		fd.groupname,
		fd.policystartdate,
		fd.policyenddate,
		fd.plantype,
		fd.payercode,
		fd.ininddeductible,
		fd.ininddeductibleremaining,
		fd.inindoutofpocket,
		fd.inindoutofpocketremaining,
		i_validation_type,
		i_patient_id
		
from final_demographics fd 
left join public.wave_parsed_json wpj on wpj.queue_id = fd.queue_id and wpj.hierarchy_level = fd.hierarchy_level::varchar
where wpj.queue_id is null;


update public.wave_patient_response_json set ready_to_parse = false where queue_id = in_queue_id;

if i_validation_type <> 'manual_request'
then 
	update insval_queue 
	set send_to_patient_service = true,
		update_ts = current_timestamp 
	where queue_id = in_queue_id::int;
else 
	update insval_queue 
	set send_to_patient_service = false,
		update_ts = current_timestamp 
	where queue_id = in_queue_id::int;
end if;

END;




$procedure$
;
