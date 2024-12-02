-- prod table for fact orders
-- this is tested in the intermediate stage before being built or incrmented here.
with fact_orders as(
    select *
    from {{ ref('int_fct_orders') }} -- <-- this table is testes, no need to test thsi fact
)
select *
from fact_orders