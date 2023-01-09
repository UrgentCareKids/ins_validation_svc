-- stg_wave.insval_queue definition

-- Drop table

-- DROP TABLE stg_wave.insval_queue;

--DROP TABLE stg_wave.insval_queue;
CREATE TABLE IF NOT EXISTS stg_wave.insval_queue
(
	queue_id BIGINT  DEFAULT bigserial ENCODE az64
	,visit_id VARCHAR(256)   ENCODE lzo
	,tbl_nm VARCHAR(256)   ENCODE lzo
	,sent_to_wave BOOLEAN   ENCODE RAW
	,create_ts TIMESTAMP WITH TIME ZONE  DEFAULT ('now'::text)::timestamp with time zone ENCODE az64
	,update_ts TIMESTAMP WITH TIME ZONE  DEFAULT ('now'::text)::timestamp with time zone ENCODE az64
	,payer_code VARCHAR(256)   ENCODE lzo
	,"process_type" VARCHAR(256)   ENCODE lzo
	,request_type VARCHAR(256)   ENCODE lzo
	,patient_id VARCHAR(256)   ENCODE lzo
	,is_recycled BOOLEAN   ENCODE RAW
	,task_available BOOLEAN   ENCODE RAW
)
DISTSTYLE AUTO
;
ALTER TABLE stg_wave.insval_queue owner to babylon;

-- Permissions

GRANT ALL ON TABLE stg_wave.insval_queue TO babylon;
