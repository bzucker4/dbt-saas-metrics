{% macro saas_generate_surrogate_key(field_list) %}
    {{ return(adapter.dispatch('saas_generate_surrogate_key', 'dbt_saas_metrics')(field_list)) }}
{% endmacro %}

{% macro default__saas_generate_surrogate_key(field_list) %}
    {{ return(dbt_utils.generate_surrogate_key(field_list)) }}
{% endmacro %}
