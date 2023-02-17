-- DROP TABLE public.wave_benefit_estimation;

CREATE TABLE public.wave_benefit_estimation (
	benefit_type varchar(256) NULL,
	request_type varchar(256) NULL,
	benefit_amount numeric(10, 2) NULL,
	benefit_time_per_hour decimal(10, 4) NULL,
	is_active bool NULL,
	effective_date date default current_date,
	end_date date default NULL,
	create_ts timestamp default current_timestamp,
	update_ts timestamp default current_timestamp
);

-- Permissions

ALTER TABLE public.wave_benefit_estimation OWNER TO babylon;
GRANT SELECT ON TABLE public.wave_queue_cost_reporting TO group readonly_access;  


---fill table 
-- 5 minutes estimated benefit for billing team (5/60) = 0.0833 hourly savings
-- $70 revenue estimated per request
-- $20 per hour per biller
INSERT INTO public.wave_benefit_estimation
(benefit_type, request_type, benefit_amount, benefit_time_per_hour, is_active)
VALUES('wave_disco_benefit', 'DISCO', 20, 0.1667, true),
('wave_eligibilty_benefit', 'ELIG', 20, 0.0833, true)
;
