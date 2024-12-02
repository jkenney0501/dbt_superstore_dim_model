
with customers_current as(

    select *
    from 
        {{ ref('_int_dim_customers') }}
)

select 
    cust_surr_id,
    customer_id,
    customer_name,
    valid_from,
    valid_to,
    updated_at
from customers_current
where is_current = 1


