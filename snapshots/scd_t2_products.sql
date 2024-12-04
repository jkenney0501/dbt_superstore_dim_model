-- using check stratgey given the product id has a many to many rerlationship with category/subcategory and can repeat.

{% snapshot scd_t2_products %}

{{
    config(
        target_schema='dev_snapshots',
        unique_key= ['product_id', 'product_name'], 
        strategy='check',
        check_cols = ['product_id', 'category', 'sub_category', 'product_name'],
        invalidate_hard_deletes=True
    )
}}

-- create product dimension, this is an scd type 2
with products_dedupe_dim as (
    select 
        product_id  as product_id,
        category,
        sub_category,
        product_name,
        updated_at,
        row_number() over(partition by product_id, category, sub_category, product_name order by product_id) as total_rows
    from {{ ref('stg_products') }}
)

select 
    product_id,
    category,
    sub_category,
    product_name,
    updated_at,
    total_rows
from products_dedupe_dim
where total_rows = 1

{% endsnapshot %}