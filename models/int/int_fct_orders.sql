-- create fact: this needs to be set up as incrmental
with orders_dedupe_fact as(
    select 
      {{ dbt_utils.generate_surrogate_key(['order_id', 'order_date', 'updated_at']) }} AS fct_primary_key,
        order_id,

        -- add cust surroigate
        -- add employee surriogate, join both tbales om natural key and use surrogate from dims
        -- add date id in place of dates
        order_date,
        ship_date,
        ship_mode,
        emp_id,
        sales,
        quantity,
        cost_percent,
        updated_at,
        row_number() over(partition by order_id, order_date, ship_date, ship_mode, sales, quantity, cost_percent order by order_id) as total_rows
    from {{ ref('stg_orders') }}
)
select 
    fct_primary_key,
    order_id,
    order_date,
    ship_date,
    ship_mode,
    emp_id,
    sales,
    quantity,
    cost_percent,
    updated_at
from orders_dedupe_fact
where total_rows = 1
