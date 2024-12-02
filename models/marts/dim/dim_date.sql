
-- prod date table

with dim_dates as(

    select *
    from 
        {{ ref('int_dim_date') }}
)

select * 
from dim_dates