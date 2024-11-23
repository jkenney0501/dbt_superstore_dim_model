WITH prod_scd AS(
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['product_id', 'category', 'sub_category', 'product_name']) }} as prod_surr_id,
        product_id,
        category,
        sub_category,
        product_name,
        dbt_updated_at as valid_from,
        CASE WHEN dbt_valid_to IS NULL THEN 1 ELSE 0 END AS is_current,
        CASE WHEN dbt_valid_to IS NULL THEN '2099-12-31' 
        ELSE dbt_valid_to
        END AS valid_to,
        updated_at
    FROM {{ ref('scd_t2_products') }}
)

SELECT * 
FROM prod_scd