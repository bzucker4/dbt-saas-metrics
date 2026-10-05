-- Grain: one account-month where MRR decreased but the account stayed above zero.
-- Lost revenue from accounts that went to zero is churn, not contraction.

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
    movements.prior_mrr,
    movements.mrr as current_mrr,
    movements.contraction_mrr,
    movements.currency_code
from movements
left join accounts
    on movements.account_id = accounts.account_id
where movements.change_type = 'contraction'
