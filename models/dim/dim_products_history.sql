-- product history table

with prod_hist as(
    select *
        
    from 
        {{ ref('_int_dim_products') }}
)

select * 
from prod_hist