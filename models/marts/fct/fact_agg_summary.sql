{{
    config(
        materialized = 'table'
    )
}}

with finance_summary as(
    select 
        year(d.date_day) as order_year,
        month(d.date_day) as order_month,
        p.category,
        p.sub_category,
        count(fct.order_id) as total_orders,
        sum(fct.quantity) as total_quantity,
        round(avg(fct.quantity),1) as avg_quantity_per_order,
        sum(fct.sales) as total_sales,
        round(avg(fct.sales),2) as average_sales_per_order
    from 
        {{ ref('fact_orders') }}  as fct
    join 
        {{ ref('dim_products_current') }}  as p 
            using(prod_surr_id)
    join 
        {{ ref('dim_date') }} as d 
            on fct.order_date_id = d.date_id 
    group by rollup(1,2,3,4)
    order by 1,2,3,4

)

select *,
    sum(total_sales) over(partition by order_year order by order_year, order_month ) as running_total_by_category_by_month_year,
    round(avg(total_sales) over(partition by order_year, category order by order_year, order_month),2) as avg_sales_by_category,
    sum(total_sales) over(partition by order_year, sub_category order by order_year, order_month) as total_sales_by_sub_category_by_year,
    round(avg(total_sales) over(partition by order_year, sub_category order by order_year, order_month),2) as avg_sales_by_sub_category
from finance_summary

