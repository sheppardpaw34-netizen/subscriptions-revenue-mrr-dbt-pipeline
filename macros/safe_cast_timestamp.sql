{% macro safe_cast_timestamp(column_name) %}
    {{ dbt_date.from_unixtimestamp("case when " ~ column_name ~ " > 10000000000 then cast(" ~ column_name ~ " / 1000 as bigint) else cast(" ~ column_name ~ " as bigint) end") }}
{% endmacro %}