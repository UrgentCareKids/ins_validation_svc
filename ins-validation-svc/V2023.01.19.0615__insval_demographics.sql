CREATE TABLE IF NOT EXISTS public.insval_demographics
(
	queue_id integer 
	,patient_id varchar    
	,patient_first_name varchar
    ,patient_middle_name varchar
    ,patient_last_name varchar
    ,patient_dob date
    ,primary_ins_ph_first_name varchar
    ,primary_ins_ph_middle_name varchar
    ,primary_ins_ph_last_name varchar
    ,primary_ins_ph_dob date
	,create_ts timestamptz  DEFAULT current_timestamp  
	,update_ts timestamptz default current_timestamp  
)
;