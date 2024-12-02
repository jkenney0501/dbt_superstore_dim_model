-- this isnt really needed other than to create a date table one time and derive the rest from that table and it will be ephemeral at file level
{{
    config(
        materialized="view"
    )
}}

{{ dbt_utils.date_spine(
    datepart="day",
    start_date="cast('2017-01-01' as date)",
    end_date="cast('2021-01-01' as date)"
   )
}}