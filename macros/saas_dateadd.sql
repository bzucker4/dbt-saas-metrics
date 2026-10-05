{% macro saas_dateadd(datepart, interval, from_expr) %}
    {{ return(adapter.dispatch('saas_dateadd', 'dbt_saas_metrics')(datepart, interval, from_expr)) }}
{% endmacro %}

{% macro default__saas_dateadd(datepart, interval, from_expr) %}
    {{ return(dbt_utils.dateadd(datepart, interval, from_expr)) }}
{% endmacro %}

{% macro duckdb__saas_dateadd(datepart, interval, from_expr) %}
    {{ from_expr }} + ({{ interval }}) * interval 1 {{ datepart }}
{% endmacro %}

{% macro snowflake__saas_dateadd(datepart, interval, from_expr) %}
    dateadd({{ datepart }}, {{ interval }}, {{ from_expr }})
{% endmacro %}

{% macro bigquery__saas_dateadd(datepart, interval, from_expr) %}
    date_add(cast({{ from_expr }} as date), interval ({{ interval }}) {{ datepart }})
{% endmacro %}

{% macro redshift__saas_dateadd(datepart, interval, from_expr) %}
    dateadd({{ datepart }}, {{ interval }}, {{ from_expr }})
{% endmacro %}
