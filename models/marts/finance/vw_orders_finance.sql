-- production fincnace view for specific BI purposes
-- this view queries the prod tables and joins the dimensions to the fact for ordeers while selecting only needed criteria as specified by the lob.
{{
    config(
        schema = 'vw_finance',
    )
}}

with finance as(
    select 
        fct.order_id,
        d.date_day as order_date,
        d.date_day as ship_date,
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
        {{ ref('fact_orders') }}  as fct
    join 
        {{ ref('dim_employees_current') }} as e 
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
)

select *
from finance