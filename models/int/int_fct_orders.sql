-- create fact: this needs to be set up as incrmental

{{ 
    config(
        materialized = 'incremental', 
        unique_key = 'fct_primary_key',
        on_schema_change ='fail'
    ) 
}}

-- adds dupe check
with orders_dedupe_fact as(
    select 
        *,
        row_number() over(partition by order_id, order_date, ship_date, ship_mode, sales, quantity, cost_percent order by order_id) as total_rows
    from {{ ref('stg_orders') }}
),

-- gets only unique rows from dedupe fact
de_duped as(
    select *
    from orders_dedupe_fact
    where total_rows = 1
),

-- adds increment step after deduped so it is readay for testing before prod
increment_fct as (
    select 
        {{ dbt_utils.generate_surrogate_key(['order_id', 'order_date', 'updated_at']) }} AS fct_primary_key,
        {{ dbt_utils.generate_surrogate_key(['customer_id', 'customer_name']) }} as cust_surr_id,
        order_id,
        YEAR(order_date) * 10000 + MONTH(order_date) * 100 + DAY(order_date) AS order_date_id,
        YEAR(ship_date) * 10000 + MONTH(ship_date) * 100 + DAY(ship_date) AS ship_date_id,
        ship_mode,
        emp_id,
        {{ dbt_utils.generate_surrogate_key(['country_region', 'state', 'city', 'postal_code', 'region']) }} as location_surr_id,
        {{ dbt_utils.generate_surrogate_key(['product_id', 'category', 'sub_category', 'product_name']) }} as prod_surr_id,
        sales,
        quantity,
        cost_percent,
        updated_at
    from de_duped

     {% if is_incremental() %}

            WHERE updated_at >= (SELECT MAX(updated_at) FROM {{ this }} )

     {% endif %}
)

-- final query
select *
from increment_fct 
