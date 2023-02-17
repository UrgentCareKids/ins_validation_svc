--drop view if exists public.wave_queue_cost_reporting;

CREATE OR REPLACE VIEW public.wave_queue_cost_reporting
as


with wave_stats_detail as (
	select
	wpj.queue_id,
	wpj.insurance_name,
	wpj.coveragestatus,
	wpj.confidencelevel,
	wpj.payercode,
	wpj.hierarchy_level,
	wpj.create_ts,
	coalesce(iq.request_type , riq.request_type) request_type,
	row_number() over (partition by wpj.queue_id order by hierarchy_level asc) as dedupe_queue_id
	from
	wave_parsed_json wpj
	left join rdshft_insval_queue riq on wpj.queue_id = riq.queue_id
	left join insval_queue iq on wpj.queue_id = iq.queue_id
	where wpj.queue_id is not null
),

wave_monthly_vol as (
	select (date_trunc('month', create_ts) + interval '1 month' - interval '1 day')::date as eomonth, request_type, count(queue_id) as volume,
	sum(case when ((payercode <> 'DISCO'::text or payercode is not null) AND request_type = 'DISCO' and coveragestatus = 'ACTIVE' and confidencelevel = 1 ) then 1 else 0 end )  AS disco_success_count,
	sum(case when (request_type = 'ELIG' and coveragestatus = 'ACTIVE' and confidencelevel = 1 ) then 1 else 0 end )  AS elig_success_count	
    from wave_stats_detail
	where dedupe_queue_id = 1
	group by 1,2
),

wave_costs as (
	select wmv.*,
	lvl_1.request_cost lvl1_rate,
	case when volume > lvl_1.request_amount then lvl_1.request_amount*lvl_1.request_cost else volume*lvl_1.request_cost end lvl1_cost,
	lvl_2.request_cost lvl2_rate,
	--when the voumes are between level 1 and level 2 then sum the excess volumes and multiply by level 2 rate
	case when (volume > lvl_1.request_amount and volume < lvl_2.request_amount) then (volume - lvl_1.request_amount)*lvl_2.request_cost
	-- if my volume is greater then level 2, then charge max lvl 2 cost
	when volume > lvl_2.request_amount then (lvl_2.request_amount-lvl_1.request_amount)*lvl_2.request_cost
	else 0 end lvl2_cost,
	
	lvl_3.request_cost lvl3_rate,
	--when the voumes are between level 2 and level 3 then sum the excess volumes and multiply by level 3 rate
	case when (volume > lvl_2.request_amount and volume < lvl_3.request_amount) then (volume - lvl_2.request_amount)*lvl_3.request_cost
	-- if my volume is greater then level 3, then charge max lvl 3 cost
	when volume > lvl_3.request_amount then (lvl_3.request_amount-lvl_2.request_amount)*lvl_3.request_cost
	else 0 end lvl3_cost,
	
	lvl_4.request_cost lvl4_rate,
		--when the voumes are between level 3 and level 4 then sum the excess volumes and multiply by level 4 rate
	case when (volume > lvl_3.request_amount and volume < lvl_4.request_amount) then (volume - lvl_3.request_amount)*lvl_4.request_cost
	-- if my volume is greater then level 4, then charge max lvl 4 cost
	when volume > lvl_4.request_amount then (lvl_4.request_amount-lvl_3.request_amount)*lvl_4.request_cost
	else 0 end lvl4_cost,
	
	lvl_5.request_cost lvl5_rate,
		--when the voumes are between level 4 and level 5 then sum the excess volumes and multiply by level 5 rate
	case when (volume > lvl_4.request_amount and volume < lvl_5.request_amount) then (volume - lvl_4.request_amount)*lvl_5.request_cost
	-- if my volume is greater then level 5, then charge max lvl 5 cost
	when volume > lvl_5.request_amount then (lvl_5.request_amount-lvl_4.request_amount)*lvl_5.request_cost
	else 0 end lvl5_cost,
	
	lvl_6.request_cost lvl6_rate,
		--when the voumes are between level 5 and level 6 then sum the excess volumes and multiply by level 6 rate
	case when (volume > lvl_5.request_amount and volume < lvl_6.request_amount) then (volume - lvl_5.request_amount)*lvl_6.request_cost
	-- if my volume is greater then level 6, then charge max lvl 6 cost
	when volume > lvl_6.request_amount then (lvl_6.request_amount-lvl_5.request_amount)*lvl_6.request_cost
	else 0 end lvl6_cost
	
	from wave_monthly_vol wmv
	left join wave_cost lvl_1 on wmv.request_type = lvl_1.request_type and lvl_1.request_rank = 1 and lvl_1.is_active is true
	left join wave_cost lvl_2 on wmv.request_type = lvl_2.request_type and lvl_2.request_rank = 2 and lvl_2.is_active is true
	left join wave_cost lvl_3 on wmv.request_type = lvl_3.request_type and lvl_3.request_rank = 3 and lvl_3.is_active is true
	left join wave_cost lvl_4 on wmv.request_type = lvl_4.request_type and lvl_4.request_rank = 4 and lvl_4.is_active is true
	left join wave_cost lvl_5 on wmv.request_type = lvl_5.request_type and lvl_5.request_rank = 5 and lvl_5.is_active is true
	left join wave_cost lvl_6 on wmv.request_type = lvl_6.request_type and lvl_6.request_rank = 6 and lvl_6.is_active is true
),

wave_benefit as (
	select  eomonth, wmv.request_type, 
		 (disco_success_count* disco_benefit.benefit_time_per_hour)::numeric  as disco_time_saved,
		 (disco_success_count * (disco_benefit.benefit_time_per_hour * disco_benefit.benefit_amount ))::numeric as disco_revenue,
		 (elig_success_count * elig_benefit.benefit_time_per_hour)::numeric  as elig_time_saved,
		 (elig_success_count * (elig_benefit.benefit_time_per_hour * elig_benefit.benefit_amount ))::numeric as elig_revenue
	from wave_monthly_vol wmv
	left join wave_benefit_estimation disco_benefit on wmv.request_type = disco_benefit.request_type and disco_benefit.benefit_type = 'wave_disco_benefit'
	left join wave_benefit_estimation elig_benefit on wmv.request_type = elig_benefit.request_type and elig_benefit.benefit_type = 'wave_eligibilty_benefit'
)

select 
	wc.eomonth, 
	wc.request_type, 
	wc.volume, 
	wc.disco_success_count, 
	wc.elig_success_count,
	wb.disco_revenue , 
	wb.elig_time_saved, 
	wb.elig_revenue, 
	 COALESCE(lvl1_cost,0) + COALESCE(lvl2_cost,0) + COALESCE(lvl3_cost,0) + COALESCE(lvl4_cost,0) + COALESCE(lvl5_cost,0) + COALESCE(lvl6_cost,0) as sum_cost,
	 --return on investment = revenue - cost
 	COALESCE (elig_revenue, disco_revenue) - (COALESCE(lvl1_cost,0) + COALESCE(lvl2_cost,0) + COALESCE(lvl3_cost,0) + COALESCE(lvl4_cost,0) + COALESCE(lvl5_cost,0) + COALESCE(lvl6_cost,0) ) as wave_roi
from wave_costs wc
left join wave_benefit wb on wc.eomonth = wb.eomonth and wc.request_type = wb.request_type
;

----permissions to looker
 GRANT SELECT ON TABLE public.wave_queue_cost_reporting TO group readonly_access;  



  
 GRANT SELECT ON TABLE public.wave_queue_cost_reporting TO group readonly_access;  