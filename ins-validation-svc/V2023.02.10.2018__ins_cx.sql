-- public.ins_cx definition

-- Drop table

-- DROP TABLE public.ins_cx;

CREATE TABLE public.ins_cx (
	pri_ins_id int8 NULL,
	ext_source varchar(256) NOT NULL,
	ext_id varchar(256) NOT NULL,
	ext_name varchar(256) NOT NULL,
	ext_is_ignored bool NOT NULL,
	create_ts timestamptz NULL DEFAULT CURRENT_TIMESTAMP,
	update_ts timestamptz NULL DEFAULT CURRENT_TIMESTAMP
);

-- Permissions

ALTER TABLE public.ins_cx OWNER TO babylon;

-- public.ins_pri_list definition

-- Drop table

-- DROP TABLE public.ins_pri_list;

CREATE TABLE public.ins_pri_list (
	pri_ins_id int8 NOT NULL,
	ins_name varchar(256) NULL,
	carrier_code varchar(256) NULL,
	address_line1 varchar(256) NULL,
	address_line2 varchar(256) NULL,
	address_city varchar(256) NULL,
	address_state varchar(256) NULL,
	address_zipcode varchar(256) NULL,
	phone_number varchar(256) NULL,
	is_visible bool NULL,
	is_active bool NULL,
	create_ts timestamptz NULL DEFAULT CURRENT_TIMESTAMP,
	update_ts timestamptz NULL DEFAULT CURRENT_TIMESTAMP,
	CONSTRAINT ins_pri_list_pri_ins_id_key UNIQUE (pri_ins_id)
);

-- Permissions

ALTER TABLE public.ins_pri_list OWNER TO babylon;