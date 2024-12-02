with emps_dim as(
    
    select 
        emp_surr_id,
        emp_id,
        first_name,
        last_name,
        level,
        state,
        age,
        hire_date,
        job_title,
        status,
        valid_from,
        valid_to,
        is_current,
        updated_at,

    from {{ ref('_int_dim_employees') }}
)

select *
from emps_dim
