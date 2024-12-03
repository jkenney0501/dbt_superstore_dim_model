-- applies to all numeric cols with a count, date math or a dolar amount
{% test positive_value(model, column_name) %}
    with gte_zero as(
        select  *
        from {{ model }}
        where {{ column_name}} <= 0
)

select * from gte_zero

{% endtest %}