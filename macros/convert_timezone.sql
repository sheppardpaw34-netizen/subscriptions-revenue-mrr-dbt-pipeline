{% macro convert_timezone(column_name) %}
    safe_cast({{ column_name }} as timestamp)
{% endmacro %}