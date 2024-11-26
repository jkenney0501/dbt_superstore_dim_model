
{{
    config(
        materialized='ephemeral'
    )
}}


with int_location as(
    select 
    {{ dbt_utils.generate_surrogate_key(['country_region', 'state', 'city', 'postal_code', 'region']) }} as location_surr_id,
    *
    from 
        {{ ref('stg_location') }}
)

select *
from int_location