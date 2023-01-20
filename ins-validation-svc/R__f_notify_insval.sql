CREATE OR REPLACE FUNCTION public.mstr_notify_ins_validation()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$ 
begin 
	perform pg_notify('ins_validation_channel', (concat('{"queue_id":"',new.queue_id,'", "patient_id":"',new.patient_id,'"}')::text));
	return null;
end;
$function$
;

-- Permissions

-- ALTER FUNCTION public.mstr_notify_ins_validation() OWNER TO babylon;
-- GRANT ALL ON FUNCTION public.mstr_notify_ins_validation() TO babylon;
