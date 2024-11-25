with stg_location as(
    select 
        country_region,
        state,
        city,
        postal_code,
        region,
        row_number() over(partition by country_region, state, city, postal_code, region order by 2) as total_rows
    from 
        {{ source('raw', 'orders') }}
)

select 
    country_region,
    state,
    city,
    postal_code,
    region,
from stg_location
where total_rows = 1
order by 2