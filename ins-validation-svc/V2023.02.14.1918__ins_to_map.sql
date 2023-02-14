-- map_srv.ins_to_map definition

-- Drop table

-- DROP TABLE map_srv.ins_to_map;

--DROP TABLE map_srv.ins_to_map;
CREATE TABLE IF NOT EXISTS public.ins_to_map
(
	seq_id bigserial NOT NULL   
	,inc_source VARCHAR(256) NOT NULL   
	,inc_id VARCHAR(256) NOT NULL   
	,inc_name VARCHAR(256) NOT NULL   
	,ins_is_ignored BOOLEAN  DEFAULT false  
	,create_ts timestamptz default current_timestamp 
)
;

-- Permissions

