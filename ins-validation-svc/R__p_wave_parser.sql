CREATE OR REPLACE PROCEDURE public.wave_parser(IN in_queue_id character varying)
 LANGUAGE plpgsql
AS $procedure$
	
	
  

declare
--var area
i_patient_id varchar;
i_payload json;
begin

select patient_id into i_patient_id from stg_wave.insval_queue iq where queue_id = in_queue_id;
select payload into i_payload from public.wave_patient_response_json wprj where queue_id = in_queue_id and ready_to_parse = true;

insert into stg_wave.wave_parsed_json
		(create_ts,
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


with found_coverages_ins as (
select 
	create_ts,
	i_payload::json->>"clientTraceNumber"::int as queue_id,
	i_payload::json->>"statusCode"::int,
	i_payload::json->"foundCoverages"->>"payerName"::varchar,
	i_payload::json->"foundCoverages"->>"coverageStatus"::int as coveragestatus_nr,
	i_payload::json->"foundCoverages"->"ruleResult"->>"PlanIdentification"::varchar,
	i_payload::json->"foundCoverages"->"ruleResult"->>"PlanName"::varchar,
	i_payload::json->"foundCoverages"->"ruleResult"->>"GroupNumber"::varchar,
	i_payload::json->"foundCoverages"->"ruleResult"->>"GroupName"::varchar,
	i_payload::json->"foundCoverages"->"ruleResult"->>"PolicyStartDate"::varchar,
	i_payload::json->"foundCoverages"->"ruleResult"->>"PolicyEndDate"::varchar,
	i_payload::json->"foundCoverages"->"ruleResult"->>"PlanType"::varchar,
	i_payload::json->"foundCoverages"->"ruleResult"->>"CoverageStatus"::varchar,
	i_payload::json->"foundCoverages"->"patient"->>"firstName"::varchar,
	i_payload::json->"foundCoverages"->"patient"->>"lastName"::varchar,
	i_payload::json->"foundCoverages"->"patient"->>"middleName"::varchar,
	i_payload::json->"foundCoverages"->"patient"->>"dateOfBirth"::date,
	i_payload::json->"foundCoverages"->"patient"->>"gender"::varchar,
	i_payload::json->"foundCoverages"->"patient"->>"ssn"::varchar,
	i_payload::json->"foundCoverages"->"patient"->>"addresses"->"addressLine1"::varchar,
	i_payload::json->"foundCoverages"->"patient"->>"addresses"->"addressLine2"::varchar,
	i_payload::json->"foundCoverages"->"patient"->>"addresses"->"city"::varchar,
	i_payload::json->"foundCoverages"->"patient"->>"addresses"->"state"::varchar,
	i_payload::json->"foundCoverages"->"patient"->>"addresses"->"zip"::varchar,
	i_payload::json->"foundCoverages"->"patient"->>"addresses"->"zipExtension"::varchar,
	i_payload::json->"foundCoverages"->"patient"->>"addresses"->"reportedOn"::date,
	i_payload::json->"foundCoverages"->"patient"->>"addresses"->"currentAddress"::bool, 
	i_payload::json->"foundCoverages"->>"patientRelationshipToSubscriber"::varchar,
	i_payload::json->"foundCoverages"->>"subscriber"::varchar as guarantor,
	i_payload::json->"foundCoverages"->>"memberId"::varchar as policy_memberid,
	i_payload::json->"foundCoverages"->"summary"->>"name"::varchar as plan_name,
	i_payload::json->"foundCoverages"->"summary"->>"groupName"::varchar as group_name,
	i_payload::json->"foundCoverages"->"summary"->>"planSponsor"::varchar as insurance_name,
	i_payload::json->"foundCoverages"->"summary"->>"policyStart"::date,
	i_payload::json->"foundCoverages"->"summary"->>"policyEnd"::date,
	i_payload::json->"foundCoverages"->>"confidenceLevel"::int,
	i_payload::json->"foundCoverages"->>"confidenceLevelReason"::varchar,
	i_payload::json->"foundCoverages"->>"rejectionCode"::varchar,
	i_payload::json->"foundCoverages"->>"rejectionCodes"::jsonb ,
	i_payload::json->"foundCoverages"->"hierarchy"::varchar,
	i_payload::json->"foundCoverages"->"payerCode"::varchar,
	i_payload::json->"foundCoverages"->"ruleResult"->>"InIndDeductible"::varchar,
	i_payload::json->"foundCoverages"->"ruleResult"->>"InIndDeductibleRemaining"::varchar,
	i_payload::json->"foundCoverages"->"ruleResult"->>"InIndOutOfPocket"::varchar,
	i_payload::json->"foundCoverages"->"ruleResult"->>"InIndOutOfPocketRemaining"::varchar
from  i_payload where i_payload::json->>"foundCoverages" is not null
),
demographics_only as
(
--...(query assuming only demos)
select 
	create_ts as create_ts,
	i_payload::json->>"clientTraceNumber"::int as queue_id,
	i_payload::json->"demographicResponse"->"patientDemographics"->>"firstName"::varchar,
	i_payload::json->"demographicResponse"->"patientDemographics"->>"lastName"::varchar,
	i_payload::json->"demographicResponse"->"patientDemographics"->>"middleName"::varchar,
	i_payload::json->"demographicResponse"->"patientDemographics"->>"dateOfBirth"::date,
	i_payload::json->"demographicResponse"->"patientDemographics"->>"gender"::varchar,
	i_payload::json->"demographicResponse"->"patientDemographics"->>"ssn"::varchar,
	i_payload::json->"demographicResponse"->"patientDemographics"->"addresses"->>"addressLine1"::varchar,
	i_payload::json->"demographicResponse"->"patientDemographics"->"addresses"->>"addressLine2"::varchar,
	i_payload::json->"demographicResponse"->"patientDemographics"->"addresses"->>"city"::varchar,
	i_payload::json->"demographicResponse"->"patientDemographics"->"addresses"->>"state"::varchar,
	i_payload::json->"demographicResponse"->"patientDemographics"->"addresses"->>"zip"::varchar,
	i_payload::json->"demographicResponse"->"patientDemographics"->"addresses"->>"zipExtension"::varchar,
	i_payload::json->"demographicResponse"->"patientDemographics"->"addresses"->>"reportedOn"::date,
	i_payload::json->"demographicResponse"->"patientDemographics"->"addresses"->>"currentAddress"::bool
from i_payload where i_payload::json->>"foundCoverages" is null
),
final_demographics as (
	select 
		fci.create_ts as create_ts,
		fci.queue_id as queue_id,
		fci."firstName" as first_nm,
		fci."lastName" as last_nm,
		fci."middleName" as middle_nm,
		fci."dateOfBirth" as dob,
		fci."gender" as gender,
		fci."ssn" as ssn,
		fci."addressLine1" as address_line1,
		fci."addressLine2" as address_line2,
		fci."city" as city,
		fci."state" as state,
		fci."zip" as zip,
		fci."zipExtension" as zip_extension,
		fci."reportedOn" as reported_on,
		fci."currentAddress" as current_address_ind,
		fci."patientRelationshipToSubscriber" as patientrelationshiptosubscriber,
		fci.guarantor,
		fci.policy_memberid,
		fci.plan_name,
		fci.group_name,
		fci.insurance_name,
		fci."policyStart" policystart,
		fci."policyEnd" policyend,
		fci."confidenceLevel" confidencelevel,
		fci."confidenceLevelReason" confidencelevelreason,
		fci."rejectionCode" rejectioncode,
		fci."rejectionCodes" rejectioncodes,
		fci."hierarchy" as hierarchy_level,
		fci."statusCode" statuscode,
		fci."payerName" payername,
		fci.coveragestatus_nr,
		fci."CoverageStatus" coveragestatus,
		fci."PlanIdentification" planidentification,
		fci."PlanName" planname,
		fci."GroupNumber" groupnumber,
		fci."GroupName" groupname,
		fci."PolicyStartDate" policystartdate,
		fci."PolicyEndDate" policyenddate,
		fci."PlanType" plantype,
		fci."payerCode" payercode,
		fci."InIndDeductible" ininddeductible,
		fci."InIndDeductibleRemaining" ininddeductibleremaining,
		fci."InIndOutOfPocket" inindoutofpocket,
		fci."InIndOutOfPocketRemaining" inindoutofpocketremaining,
		'Parsed Wave' as validation_type
	from found_coverages_ins fci 

union all

	select 
		c.create_ts,
		c.queue_id,
		c."firstName",
		c."lastName",
		c."middleName",
		c."dateOfBirth",
		c."gender",
		c."ssn",
		c."addressLine1",
		c."addressLine2",
		c."city",
		c."state",
		c."zip",
		c."zipExtension",
		c."reportedOn",
		c."currentAddress",
		null as patientrelationshiptosubscriber,
		null as guarantor,
		null as policy_memberid,
		null as plan_name,
		null as group_name,
		null as insurance_name,
		null as "policyStart",
		null as "policyEnd",
		null as "confidenceLevel",
		null as "confidenceLevelReason",
		null as "rejectionCode",
		null as "rejectionCodes",
		null as hierarchy_level,
		null as "statusCode",
		null as "payerName",
		null as coveragestatus_nr,
		null as "CoverageStatus",
		null as "PlanIdentification",
		null as "PlanName",
		null as "GroupNumber",
		null as "GroupName",
		null as "PolicyStartDate",
		null as "PolicyEndDate",
		null as "PlanType",
		null as "payerCode",
	 	null as "InIndDeductible",
		null as "InIndDeductibleRemaining",
		null as "InIndOutOfPocket",
		null as "InIndOutOfPocketRemaining",

		'Parsed Wave' as validation_type
from demographics_only c
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
		fd.validation_type,
		i_patient_id
		
from final_demographics fd 
left join public.wave_parsed_json wpj on wpj.queue_id = fd.queue_id and wpj.hierarchy_level = fd.hierarchy_level
where wpj.queue_id is null;


update public.wave_patient_response_json set ready_to_parse = false where queue_id = in_queue_id;

END;




$procedure$
;

-- Permissions

-- ALTER PROCEDURE public.wave_parser(varchar) OWNER TO babylon;
-- GRANT ALL ON PROCEDURE public.wave_parser(varchar) TO babylon;
