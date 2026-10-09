{% macro convert_to_local_tz(timestamp_column, target_tz='America/New_York') %}
    {% if target.type == 'bigquery' %}
        datetime({{ timestamp_column }}, '{{ target_tz }}')
    {% else %}
        timezone('{{ target_tz }}', {{ timestamp_column }})
    {% endif %}
{% endmacro %}