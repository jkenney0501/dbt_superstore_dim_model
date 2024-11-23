
-- import employees file to stage layer
with employees_stage as(
    select 
        *
    from 
        {{ source('raw', 'employees') }}
)

select 
    cast(emp_id as int) as emp_id,
    name as first_name,
    surname as last_name,
    level,
    state,
    cast(age as int) as age,
    cast(hire_date as date) as hire_date,
    job_title,
    status,
    updated_at
from employees_stage