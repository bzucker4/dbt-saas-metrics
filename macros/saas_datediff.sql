{% macro saas_datediff(datepart, start_date, end_date) %}
    {{ return(adapter.dispatch('saas_datediff', 'dbt_saas_metrics')(datepart, start_date, end_date)) }}
{% endmacro %}

{% macro default__saas_datediff(datepart, start_date, end_date) %}
    {{ return(dbt_utils.datediff(start_date, end_date, datepart)) }}
{% endmacro %}

{% macro duckdb__saas_datediff(datepart, start_date, end_date) %}
    date_diff('{{ datepart }}', cast({{ start_date }} as date), cast({{ end_date }} as date))
{% endmacro %}

{% macro snowflake__saas_datediff(datepart, start_date, end_date) %}
    datediff({{ datepart }}, cast({{ start_date }} as date), cast({{ end_date }} as date))
{% endmacro %}

{% macro bigquery__saas_datediff(datepart, start_date, end_date) %}
    date_diff(cast({{ end_date }} as date), cast({{ start_date }} as date), {{ datepart }})
{% endmacro %}

{% macro redshift__saas_datediff(datepart, start_date, end_date) %}
    datediff({{ datepart }}, cast({{ start_date }} as date), cast({{ end_date }} as date))
{% endmacro %}
