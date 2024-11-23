WITH emps AS(
    SELECT 
        -- add surrogate key
        {{ dbt_utils.generate_surrogate_key(['emp_id', 'first_name', 'last_name']) }} as emp_surr_id,
        emp_id,
        first_name,
        last_name,
        level,
        state,
        age,
        hire_date,
        job_title,
        status,
        --dbt_updated_at as updated_at,
        dbt_valid_from as valid_from,
        CASE WHEN dbt_valid_to IS NULL THEN 1 ELSE 0 END AS is_current,
        CASE 
            WHEN dbt_valid_to IS NULL THEN '2099-12-31' 
            ELSE dbt_valid_to
        END AS valid_to,
        updated_at,

    FROM {{ ref('scd_t2_employees') }}
)

SELECT *
FROM emps