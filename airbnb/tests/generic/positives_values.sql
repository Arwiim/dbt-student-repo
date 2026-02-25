{% test positive_values(model, column_name, values) %}
    select *
    from {{ model }}
    where {{ column_name }} <= 0
{% endtest %}
