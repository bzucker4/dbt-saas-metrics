{# Snapshot clock for customer health. Unset var means the warehouse clock. #}
{% macro saas_as_of_timestamp() %}
    {%- set raw = var('saas_as_of_date', none) -%}
    {%- if raw is not none and (raw | string | trim) != '' -%}
        cast('{{ raw | string | replace("'", "") }}' as timestamp)
    {%- else -%}
        current_timestamp
    {%- endif -%}
{% endmacro %}
