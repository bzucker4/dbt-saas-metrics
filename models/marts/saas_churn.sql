-- Grain: one account-month where an active account's MRR fell to zero.
-- churned_mrr is the MRR lost (the prior month's MRR).

with movements as (
    select * from {{ ref('int_saas_account_mrr_monthly') }}
),

accounts as (
    select * from {{ ref('int_saas_accounts') }}
)

select
    movements.account_month_key,
    movements.month_start,
    movements.account_id,
    accounts.account_name,
    movements.plan_name,
    movements.prior_mrr as churned_mrr,
    movements.currency_code,
    1 as churned_logo
from movements
left join accounts
    on movements.account_id = accounts.account_id
where movements.change_type = 'churn'
