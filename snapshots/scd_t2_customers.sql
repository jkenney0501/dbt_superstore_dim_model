
{% snapshot scd_t2_customers %}

{{
    config(
        target_schema = 'dev_snapshots',
        unique_key='customer_id',
        strategy='check',
        check_cols = ['customer_name'],
        invalidate_hard_deletes=True
    )
}}

with customers_dedupe_dim as (
    select 
        customer_id,
        customer_name,
        updated_at,
        row_number() over(partition by customer_id, customer_name order by customer_id ) as total_rows
    from {{ ref('stg_orders') }}  -- source this in dbt
)

select 
    customer_id,
    customer_name,
    updated_at
from customers_dedupe_dim 
where total_rows = 1

{% endsnapshot %}