alter table public.insval_demographics add column patient_address1 varchar;
alter table public.insval_demographics add column patient_address2 varchar;
alter table public.insval_demographics add column patient_address_city varchar;
alter table public.insval_demographics add column patient_address_state varchar;
alter table public.insval_demographics add column patient_address_zip varchar;
alter table public.insval_demographics add column pri_ins_ph_address1 varchar;
alter table public.insval_demographics add column pri_ins_ph_address2 varchar;
alter table public.insval_demographics add column pri_ins_ph_address_city varchar;
alter table public.insval_demographics add column pri_ins_ph_address_state varchar;
alter table public.insval_demographics add column pri_ins_ph_address_zip varchar;
alter table public.insval_demographics add column date_of_service date;