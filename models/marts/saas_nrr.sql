-- Net and gross revenue retention for the cohort active at the start of the month.
-- NRR = (starting_mrr + expansion_mrr - contraction_mrr - churn_mrr) / starting_mrr
-- GRR = (starting_mrr - contraction_mrr - churn_mrr) / starting_mrr
-- New logos and reactivations are excluded. Values are ratios: 1.0 = 100%.
-- Null when starting MRR is 0 (nothing to retain).

with waterfall as (
    select * from {{ ref('saas_mrr_waterfall') }}
)

select
    month_start,
    currency_code,
    starting_mrr,
    expansion_mrr,
    contraction_mrr,
    churn_mrr,
    new_mrr,
    of_which_reactivation_mrr as reactivation_mrr,
    ending_mrr,
    (starting_mrr + expansion_mrr - contraction_mrr - churn_mrr) * 1.0
        / nullif(starting_mrr, 0) as nrr,
    (starting_mrr - contraction_mrr - churn_mrr) * 1.0
        / nullif(starting_mrr, 0) as grr,
    (
        (starting_mrr + expansion_mrr - contraction_mrr - churn_mrr) * 1.0
        / nullif(starting_mrr, 0)
    ) * 100 as nrr_pct,
    (
        (starting_mrr - contraction_mrr - churn_mrr) * 1.0
        / nullif(starting_mrr, 0)
    ) * 100 as grr_pct,
    starting_logos,
    churned_logos,
    ending_logos
from waterfall
