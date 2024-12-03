-- product currenty table

with prod_hist as(
    select 
        *
    from {{ ref('_int_dim_products') }}
)

select 
    prod_surr_id,
    product_id,
    category,
    sub_category,
    product_name,
    valid_from,
    valid_to,
    updated_at
from prod_hist
where is_current = 1