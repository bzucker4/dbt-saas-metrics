{% macro get_segment_schema() %}
    {{ return(var('saas_segment_schema', 'segment')) }}
{% endmacro %}

{% macro get_segment_database() %}
    {{ return(var('saas_segment_database', target.database)) }}
{% endmacro %}

{% macro get_billing_schema() %}
    {{ return(var('saas_billing_schema', var('saas_segment_schema', 'segment'))) }}
{% endmacro %}

{% macro get_billing_database() %}
    {{ return(var('saas_billing_database', var('saas_segment_database', target.database))) }}
{% endmacro %}
