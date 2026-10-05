-- Sequential funnel counts cannot increase at a later stage.

select
    cohort_month,
    visitors,
    signups,
    activations,
    paid_conversions
from {{ ref('saas_plg_funnel') }}
where signups > visitors
    or activations > signups
    or paid_conversions > activations
    or visitors < 0
    or signups < 0
