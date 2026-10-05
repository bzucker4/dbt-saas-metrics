{# Quote a raw source column, folding case for the active warehouse.
   Snowflake Segment loads are uppercase. BigQuery, Redshift, and DuckDB
   are lowercase. Override with var saas_column_casing: lower | upper | auto. #}
{% macro saas_col(column_name) -%}
    {%- set casing = var('saas_column_casing', 'auto') | lower -%}
    {%- if casing == 'upper' -%}
        {%- set resolved = column_name | upper -%}
    {%- elif casing == 'lower' -%}
        {%- set resolved = column_name | lower -%}
    {%- elif target.type == 'snowflake' -%}
        {%- set resolved = column_name | upper -%}
    {%- else -%}
        {%- set resolved = column_name | lower -%}
    {%- endif -%}
    {{ adapter.quote(resolved) }}
{%- endmacro %}

{# Event names are interpolated into SQL string literals. Strip quotes. #}
{% macro saas_event_literal(var_name, default_value) -%}
    '{{ var(var_name, default_value) | replace("'", "") }}'
{%- endmacro %}

{% macro saas_currency_literal() -%}
    '{{ var("saas_currency_code", "USD") | replace("'", "") }}'
{%- endmacro %}
