-- Monthly MRR waterfall.
-- ending_mrr = starting_mrr + new_mrr + expansion_mrr - contraction_mrr - churn_mrr
-- new_mrr includes first-time logos and reactivations (both were absent from starting MRR).
-- of_which_reactivation_mrr is the reactivation portion of new_mrr, not an extra term.

with movements as (
    select * from {{ ref('int_saas_account_mrr_monthly') }}
)

select
    month_start,
    max(currency_code) as currency_code,
    sum(case when prior_mrr > 0 then prior_mrr else 0 end) as starting_mrr,
    sum(new_mrr + reactivation_mrr) as new_mrr,
    sum(reactivation_mrr) as of_which_reactivation_mrr,
    sum(expansion_mrr) as expansion_mrr,
    sum(contraction_mrr) as contraction_mrr,
    sum(churn_mrr) as churn_mrr,
    sum(mrr) as ending_mrr,
    sum(mrr) - sum(case when prior_mrr > 0 then prior_mrr else 0 end) as net_new_mrr,
    count(distinct case when prior_mrr > 0 then account_id end) as starting_logos,
    count(distinct case when change_type = 'new' then account_id end) as new_logos,
    count(distinct case when change_type = 'reactivation' then account_id end) as reactivated_logos,
    count(distinct case when change_type = 'churn' then account_id end) as churned_logos,
    count(distinct case when mrr > 0 then account_id end) as ending_logos
from movements
group by month_start
