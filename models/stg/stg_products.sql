with stg_products as(
    
    select distinct
        product_id,
        category,
        sub_category,
        product_name,
        updated_at,
    from  
        {{ source('raw', 'orders') }} 
)

select *
from stg_products
