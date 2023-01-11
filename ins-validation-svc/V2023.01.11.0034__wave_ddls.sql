-- public.insval_recycler_cntrl definition

-- Drop table

-- DROP TABLE public.insval_recycler_cntrl;

--DROP TABLE public.insval_recycler_cntrl;
CREATE TABLE IF NOT EXISTS public.insval_recycler_cntrl
(
	request_type VARCHAR(256)  
	,within_days INTEGER    
	,is_active BOOLEAN  DEFAULT true  
	,create_ts timestamptz  DEFAULT current_timestamp  
	,update_ts timestamptz default current_timestamp  
)
;

-- public.wave_cost definition

-- Drop table

-- DROP TABLE public.wave_cost;

--DROP TABLE public.wave_cost;
CREATE TABLE IF NOT EXISTS public.wave_cost
(
	request_type VARCHAR(256)    
	,request_cost NUMERIC(10,2)    
	,request_amount INTEGER    
	,is_active BOOLEAN    
	,effective_date DATE    
	,end_date DATE    
)
;



-- public.wave_parsed_json definition

-- Drop table

-- DROP TABLE public.wave_parsed_json;

--DROP TABLE public.wave_parsed_json;
CREATE TABLE IF NOT EXISTS public.wave_parsed_json
(
	create_ts timestamptz default current_timestamp    
	,visit_id VARCHAR(65535)    
	,first_nm VARCHAR(65535)    
	,last_nm VARCHAR(65535)    
	,middle_nm VARCHAR(65535)    
	,dob DATE    
	,gender VARCHAR(65535)    
	,ssn VARCHAR(65535)    
	,address_line1 VARCHAR(65535)    
	,address_line2 VARCHAR(65535)    
	,city VARCHAR(65535)    
	,state VARCHAR(65535)    
	,zip VARCHAR(65535)    
	,zip_extension VARCHAR(65535)    
	,reported_on DATE    
	,current_address_ind BOOLEAN    
	,patientrelationshiptosubscriber VARCHAR(65535)    
	,guarantor VARCHAR(65535)    
	,policy_memberid VARCHAR(65535)    
	,plan_name VARCHAR(65535)    
	,group_name VARCHAR(65535)    
	,insurance_name VARCHAR(65535)    
	,policystart DATE    
	,policyend DATE    
	,confidencelevel INTEGER    
	,confidencelevelreason VARCHAR(65535)    
	,rejectioncode VARCHAR(65535)    
	,rejectioncodes json    
	,hierarchy_level VARCHAR(65535)    
	,statuscode INTEGER    
	,payername VARCHAR(65535)    
	,coveragestatus_nr INTEGER    
	,coveragestatus VARCHAR(65535)    
	,planidentification VARCHAR(65535)    
	,planname VARCHAR(65535)    
	,groupnumber VARCHAR(65535)    
	,groupname VARCHAR(65535)    
	,policystartdate VARCHAR(65535)    
	,policyenddate VARCHAR(65535)    
	,plantype VARCHAR(65535)    
	,validation_type VARCHAR(256)    
	,payercode VARCHAR(256)    
	,ininddeductible VARCHAR(256)    
	,ininddeductibleremaining VARCHAR(256)    
	,inindoutofpocket VARCHAR(256)    
	,inindoutofpocketremaining VARCHAR(256)    
	,row_card INTEGER    
	,patient_id VARCHAR(256)    
	,queue_id INTEGER    
)
;


-- public.wave_patient_response_json definition

-- Drop table

-- DROP TABLE public.wave_patient_response_json;

--DROP TABLE public.wave_patient_response_json;
CREATE TABLE IF NOT EXISTS public.wave_patient_response_json
(
	create_ts timestamptz default current_timestamp 
	,update_ts timestamptz default current_timestamp 
	,payload json    
	,queue_id VARCHAR(256)    
	,ready_to_parse BOOLEAN  DEFAULT true  
)
;



