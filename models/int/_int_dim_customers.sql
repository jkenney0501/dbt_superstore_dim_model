WITH customers AS(
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['customer_id', 'customer_name']) }} as cust_surr_id,
        customer_id,
        customer_name,
        --dbt_updated_at as updated_at,
        dbt_valid_from as valid_from,
        CASE WHEN dbt_valid_to IS NULL THEN 1 ELSE 0 END AS is_current,
        CASE WHEN dbt_valid_to IS NULL THEN '2099-12-31' 
        ELSE dbt_valid_to
        END AS valid_to,
        updated_at
    FROM {{ ref('scd_t2_customers') }}
)

SELECT *
FROM customers