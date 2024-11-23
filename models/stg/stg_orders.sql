
-- imoprt raw orders to stage

with orders_stage as(
    select 
        *
    from 
        {{ source('raw', 'orders') }}
)

select 
    cast(row_id as int) as row_id,
    order_id,
    cast(order_date as date) as order_date,
    cast(ship_date as date) as ship_date,
    ship_mode,
    customer_id, 
    customer_name,
    sales_agent_id as emp_id,
    country_region,
    city,
    state,
    cast(postal_code as int) as postal_code,
    region,
    product_id,
    category,
    sub_category,
    product_name,
    cast( sales as decimal(20,2)) as sales,
    cast( quantity as integer) as quantity,
    cast( cost_percent as decimal(3,2)) as cost_percent,
    updated_at 
from orders_stage