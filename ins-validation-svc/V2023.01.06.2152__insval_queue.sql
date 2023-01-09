-- insval_queue definition

-- Drop table

-- DROP TABLE nsval_queue;

--DROP TABLE insval_queue;

CREATE TABLE IF NOT EXISTS insval_queue
(
	queue_id  bigserial
	,visit_id VARCHAR(256) 
	,tbl_nm VARCHAR(256)
	,sent_to_wave BOOLEAN 
	,create_ts timestamptz default current_timestamp
	,update_ts timestamptz default current_timestamp
	,payer_code VARCHAR(256) 
	,process_type VARCHAR(256)
	,request_type VARCHAR(256)  
	,patient_id VARCHAR(256) 
	,is_recycled BOOLEAN   
	,task_available BOOLEAN  
);
--ALTER TABLE insval_queue owner to babylon;

-- Permissions

--GRANT ALL ON TABLE insval_queue TO babylon;
