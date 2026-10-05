{% macro saas_date_trunc(datepart, date_expr) %}
    {{ return(adapter.dispatch('saas_date_trunc', 'dbt_saas_metrics')(datepart, date_expr)) }}
{% endmacro %}

{% macro default__saas_date_trunc(datepart, date_expr) %}
    {{ return(dbt_utils.date_trunc(datepart, date_expr)) }}
{% endmacro %}

{% macro duckdb__saas_date_trunc(datepart, date_expr) %}
    date_trunc('{{ datepart }}', {{ date_expr }})
{% endmacro %}

{% macro snowflake__saas_date_trunc(datepart, date_expr) %}
    date_trunc({{ datepart }}, {{ date_expr }})
{% endmacro %}

{% macro bigquery__saas_date_trunc(datepart, date_expr) %}
    date_trunc(cast({{ date_expr }} as date), {{ datepart }})
{% endmacro %}

{% macro redshift__saas_date_trunc(datepart, date_expr) %}
    date_trunc('{{ datepart }}', {{ date_expr }})
{% endmacro %}
