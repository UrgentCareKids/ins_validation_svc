CREATE OR REPLACE PROCEDURE public.insval_distributor(IN in_queue_id integer)
 LANGUAGE plpgsql
AS $procedure$
	
	
declare


begin
	
	call public.wave_recycler (in_queue_id);
	
END;


$procedure$
;

-- Permissions

-- ALTER PROCEDURE public.insval_distributor(int4) OWNER TO babylon;
-- GRANT ALL ON PROCEDURE public.insval_distributor(int4) TO babylon;
