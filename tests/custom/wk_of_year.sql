-- test the internmediate model to get the week of the year.
--  not inlcuded in unit tests becasue the unit was calling jan 1st 2024 the first week but it is still the 52nd week of 2023.
with week_test as (

    select
        date_day,
        week(date_day) as calculated_wk_of_yr
    from 
        {{ ref('int_dim_date') }}
    where wk_of_yr != week(date_day)

)

select * from week_test