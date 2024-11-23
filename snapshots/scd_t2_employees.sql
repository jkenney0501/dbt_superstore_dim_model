
-- creates type 2 slowly changing dimension for customers

{% snapshot scd_t2_employees %}


{{
    config(
        target_database='superstore',
        target_schema='dev_snapshots',
        unique_key='emp_id',
        strategy='timestamp',
        updated_at='updated_at',
        invalidate_hard_deletes=True
    )
}}

-- create employees dim, this is an scd type 2
with emps_dedupe_dim as(
    select 
        *,
        row_number() over(partition by emp_id, first_name, last_name, level, state, age, hire_date, job_title, status order by emp_id) as total_rows
    from {{ ref('stg_employees') }}
)
select 
    emp_id,
    first_name,
    last_name,
    level,
    state,
    age,
    hire_date,
    job_title,
    status,
    updated_at
from emps_dedupe_dim
where total_rows = 1

{% endsnapshot %}