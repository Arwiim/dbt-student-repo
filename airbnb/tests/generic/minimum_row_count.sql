{% test minimum_row_count(model, min_row_count) %}
{{ config(severity = 'warn') }}
SELECT 
    COUNT(*) AS row_count
FROM
    {{ model }}
HAVING
    row_count < {{ min_row_count }}
{% endtest %}