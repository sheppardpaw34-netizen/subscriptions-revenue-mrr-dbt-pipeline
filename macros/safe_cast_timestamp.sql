{% macro safe_cast_timestamp(column_name) %}
    {% set int_type = 'INT64' if target.type == 'bigquery' else 'bigint' %}
    {{ dbt_date.from_unixtimestamp("case when " ~ column_name ~ " > 10000000000 then cast(" ~ column_name ~ " / 1000 as " ~ int_type ~ ") else cast(" ~ column_name ~ " as " ~ int_type ~ ") end") }}
{% endmacro %}