
{% snapshot scd_t2_customers %}

{{
    config(
        target_schema = 'dev_snapshots',
        unique_key='customer_id',
        strategy='timestamp',
        updated_at='updated_at',
        invalidate_hard_deletes=True
    )
}}
-- this should be a type 2 scd
-- customers dimension deduped and ready for dbt load to internediate layer
-- this becomes int_customers_dim
-- add surrogaet key in final prod layer
with customers_dedupe_dim as (
select 
    *,
    row_number() over(partition by customer_id, customer_name, country_region, city, state, postal_code, region order by            customer_id ) as total_rows
from {{ ref('stg_orders') }}  -- source this in dbt
)

select 
    customer_id,
    customer_name,
    country_region, 
    city,
    state,
    postal_code,
    region,
    updated_at
from customers_dedupe_dim 
where total_rows = 1

{% endsnapshot %}