{% macro convert_timezone(column_name) %}
    {{ return(adapter.dispatch('convert_timezone')(column_name)) }}
{% endmacro %}

{% macro default__convert_timezone(column_name) %}
    -- DuckDB / MotherDuck target
    try_cast({{ column_name }} as timestamp)
{% endmacro %}

{% macro bigquery__convert_timezone(column_name) %}
    -- BigQuery target
    safe_cast({{ column_name }} as timestamp)
{% endmacro %}