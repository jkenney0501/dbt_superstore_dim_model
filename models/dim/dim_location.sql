
-- prod location table

with dim_location as(
    select 
    *
    from 
        {{ ref('_int_dim_location') }}
)

select *
from dim_location