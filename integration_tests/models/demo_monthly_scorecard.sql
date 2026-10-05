-- Buyer-facing monthly rollup of the package marts. Safe to copy into a BI model.

select
    waterfall.month_start,
    waterfall.currency_code,
    waterfall.starting_mrr,
    waterfall.new_mrr,
    waterfall.expansion_mrr,
    waterfall.contraction_mrr,
    waterfall.churn_mrr,
    waterfall.ending_mrr,
    waterfall.ending_logos,
    nrr.nrr,
    nrr.grr,
    activation.new_users,
    activation.activated_users,
    activation.activation_rate,
    activation.median_days_to_activate,
    funnel.visitors,
    funnel.signups,
    funnel.activations,
    funnel.paid_conversions,
    funnel.visit_to_paid_rate
from {{ ref('saas_mrr_waterfall') }} as waterfall
left join {{ ref('saas_nrr') }} as nrr
    on waterfall.month_start = nrr.month_start
left join {{ ref('saas_activation') }} as activation
    on waterfall.month_start = activation.cohort_month
left join {{ ref('saas_plg_funnel') }} as funnel
    on waterfall.month_start = funnel.cohort_month
