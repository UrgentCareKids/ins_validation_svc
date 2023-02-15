
--drop view if exists public.insval_patient_coverage;

CREATE OR REPLACE VIEW public.insval_patient_coverage
as

select ipl.ins_name, ipl.carrier_code, ipl.is_visible, ipl.is_active, wpj.* from wave_parsed_json wpj
left join ins_cx ic on ic.ext_id = wpj.payercode and ic.ext_source = 'WAVE'
left join ins_pri_list ipl on ipl.pri_ins_id = ic.pri_ins_id ;