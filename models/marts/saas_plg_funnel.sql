-- PLG funnel by the month of first visit (or signup, if no page view was captured).
-- Counts are sequential: each stage requires every earlier stage.
-- visit -> signup -> activation (ever) -> paid account.
-- Time-boxed activation is saas_activation, not this model.

with people as (
    select * from {{ ref('int_saas_plg_funnel_events') }}
),

rolled as (
    select
        cohort_month,
        count(distinct case when has_visit then person_id end) as visitors,
        count(distinct case when has_signup then person_id end) as signups,
        count(distinct case when has_activation then person_id end) as activations,
        count(distinct case when has_paid then person_id end) as paid_conversions
    from people
    group by cohort_month
)

select
    cohort_month,
    visitors,
    signups,
    activations,
    paid_conversions,
    signups * 1.0 / nullif(visitors, 0) as visit_to_signup_rate,
    activations * 1.0 / nullif(signups, 0) as signup_to_activation_rate,
    paid_conversions * 1.0 / nullif(activations, 0) as activation_to_paid_rate,
    paid_conversions * 1.0 / nullif(visitors, 0) as visit_to_paid_rate
from rolled
