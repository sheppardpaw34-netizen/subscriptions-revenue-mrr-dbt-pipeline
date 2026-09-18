{% macro safe_cast(field, type) %}
    {{ return(adapter.dispatch('safe_cast')(field, type)) }}
{% endmacro %}

{% macro default__safe_cast(field, type) %}
    -- DuckDB / MotherDuck target
    try_cast({{ field }} as {{ type }})
{% endmacro %}

{% macro bigquery__safe_cast(field, type) %}
    -- BigQuery target
    safe_cast({{ field }} as {{ type }})
{% endmacro %}