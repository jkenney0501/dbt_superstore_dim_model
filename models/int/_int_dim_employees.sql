{{
    config(
        materialized='ephemeral'
    )
}}


with emps as(
    select 
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
        case 
            when dbt_valid_to is null then 1 else 0 
        end as is_current,
        case 
            when dbt_valid_to is null then '2099-12-31' 
            else dbt_valid_to
        end as valid_to,
        updated_at,

    from {{ ref('scd_t2_employees') }}
)

SELECT *
FROM emps