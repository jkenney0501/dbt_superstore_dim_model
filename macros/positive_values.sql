-- applies to all numeric cols with a count, date math or a dolar amount

{% test positive_value(model, column_name) %}
    WITH gte_zero AS(
        SELECT  *
        FROM {{ model }}
        WHERE {{ column_name}} <= 0
)

SELECT * FROM gte_zero

{% endtest %}