with emps_dim as(
    
    select 
        *
    from {{ ref('_int_dim_employees') }}
)

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
    updated_at,
from emps_dim
where is_current = 1