{{
    config(
        materialized='ephemeral'
    )
}}

with customers as(
    select 
        {{ dbt_utils.generate_surrogate_key(['customer_id', 'customer_name']) }} as cust_surr_id,
        customer_id,
        customer_name,
        dbt_valid_from as valid_from,
            case when dbt_valid_to is null then 1 else 0 end as is_current,
            case when dbt_valid_to is null then '2099-12-31' 
        else dbt_valid_to
        end as valid_to,
        updated_at
    from {{ ref('scd_t2_customers') }}
)

select *
from customers