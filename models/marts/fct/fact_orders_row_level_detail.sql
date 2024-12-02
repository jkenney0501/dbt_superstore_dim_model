-- row level detail for whole report
{{
    config(
        materialized = 'view'
    )
}}
with finance_row_level as(
    select 
        fct.order_id,
        c.customer_id,
        c.customer_name,
        d.yr,
        d.mth,
        d.date_day as order_date,
        d.date_day as ship_date,
        d.day_name,
        d.weekend_flag as order_placed_on_weekend,
        d.holiday_flag as order_placed_on_holiday,
        fct.ship_mode,
        e.emp_id,
        e.first_name,
        e.last_name,
        e.job_title,
        p.product_name,
        p.category,
        p.sub_category,
        fct.sales,
        fct.quantity,
        fct.cost_percent,
        fct.updated_at
    from 
        {{ ref('fact_orders') }} as fct
    join 
        {{ ref('dim_employees_current') }}  as e 
            using(emp_id)
    join 
        {{ ref('dim_products_current') }}  as p 
            using(prod_surr_id)
    join 
        {{ ref('dim_date') }} as d 
            on fct.order_date_id = d.date_id 
    join 
        {{ ref('dim_date') }} as d2 
            on fct.ship_date_id = d2.date_id

    join {{ ref('dim_customers_current') }} as c
            on fct.cust_surr_id = c.cust_surr_id
        
)

select *
from finance_row_level