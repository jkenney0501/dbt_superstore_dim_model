{{
    config(
        materialized='ephemeral'
    )
}}


with prod_scd as(
    select 
        {{ dbt_utils.generate_surrogate_key(['product_id', 'category', 'sub_category', 'product_name']) }} as prod_surr_id,
        product_id,
        category,
        sub_category,
        product_name,
        dbt_updated_at as valid_from,
        case 
            when dbt_valid_to is null then 1 
          else 0 
        end as is_current,
        case 
            when dbt_valid_to is null then '2099-12-31' 
          else dbt_valid_to
        end as valid_to,
        updated_at
    from {{ ref('scd_t2_products') }}
)

select * 
from prod_scd