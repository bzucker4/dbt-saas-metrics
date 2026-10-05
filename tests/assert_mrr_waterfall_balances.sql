-- The waterfall identity and the logo identity must hold on every month.

select
    month_start,
    starting_mrr,
    new_mrr,
    expansion_mrr,
    contraction_mrr,
    churn_mrr,
    ending_mrr,
    starting_logos,
    new_logos,
    reactivated_logos,
    churned_logos,
    ending_logos
from {{ ref('saas_mrr_waterfall') }}
where abs(
        ending_mrr
        - (starting_mrr + new_mrr + expansion_mrr - contraction_mrr - churn_mrr)
    ) > 0.01
    or ending_logos <> starting_logos + new_logos + reactivated_logos - churned_logos
    or of_which_reactivation_mrr > new_mrr
