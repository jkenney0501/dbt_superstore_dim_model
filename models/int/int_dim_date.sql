
-- creates date table to ectract whatver you need for any date analysis, includes weekend day flag and holiday flag
-- created from ephemeral model that uses date spline package to create a range of dates.
with 
    dim_dates as(
        select 
        year(date_day) * 10000 + month(date_day) * 100 + day(date_day) as date_id,
        date_day,
        year(date_day) as yr,
        quarter(date_day) as quarter_of_yr,
        month(date_day) as mth,
        weekofyear(date_day) as wk_of_yr,
        dayofweek(date_day) as day_of_wk,
            case 
                when cast(dayofweek(date_day) as string ) = '0' then 'sunday' 
                when cast(dayofweek(date_day) as string ) = '1' then 'monday'
                when cast(dayofweek(date_day) as string ) = '2' then 'tuesday'
                when cast(dayofweek(date_day) as string ) = '3' then 'wednesday'
                when cast(dayofweek(date_day) as string ) = '4' then 'thursday'
                when cast(dayofweek(date_day) as string ) = '5' then 'friday'
            else 'saturday'
        end as day_name,
            case when dayofweek(date_day) in (0,6) then 1 else 0 end as weekend_flag,
            case 
                when month(date_day) in(1) and day(date_day) in(01) then 1 
                when month(date_day) in(1) and day(date_day) in(18) then 1
                when month(date_day) in(5) and day(date_day) in(31) then 1
                when month(date_day) in(6) and day(date_day) in(19) then 1
                when month(date_day) in(7) and day(date_day) in(4) then 1
                when month(date_day) in(9) and week(date_day) in (35) and dayofweek(date_day) in(0,1) then 1 -- labor day is always 1st monday in september, week 35
                when month(date_day) in(11) and day(date_day) in(11) then 1 
                when month(date_day) in(11) and week(date_day) in(48) and dayofweek(date_day) in (4) then 1 -- tg day is always last thursday of novemeberr, week 48
                when month(date_day) in(12) and day(date_day) in(25) then 1
                else 0
        end as holiday_flag,
        current_timestamp() as refreshed_at
        from {{ ref('stg_all_dates') }}
)

select * 
from dim_dates