-- prod customer history table
with customers_hist as(

    select 
        cust_surr_id,
        customer_id,
        customer_name,
        valid_from,
        valid_to,
        is_current,
        updated_at
    from 
        {{ ref('_int_dim_customers') }}
)

select *
from customers_hist