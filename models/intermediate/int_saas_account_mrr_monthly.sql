-- Grain: one account per calendar month from the first billed month through
-- the latest month present in billing snapshots.
-- Missing months after the first snapshot are filled with MRR 0 so a
-- disappeared customer is classified as churn in the first empty month.
--
-- change_type:
--   new           first month with MRR, no prior MRR
--   reactivation  MRR returns after a zero month (not the first month)
--   expansion     MRR increased vs the prior calendar month
--   contraction   MRR decreased but stayed above zero
--   churn         prior MRR > 0 and current MRR = 0
--   retained      MRR unchanged and above zero
--   inactive      both months are zero

with snapshots as (
    select
        account_id,
        cast({{ saas_date_trunc('month', 'month_start') }} as date) as month_start,
        mrr,
        status,
        plan_name,
        seats
    from {{ ref('stg_saas_subscriptions') }}
),

monthly as (
    select
        account_id,
        month_start,
        sum(mrr) as mrr,
        max(status) as status,
        max(plan_name) as plan_name,
        sum(seats) as seats
    from snapshots
    group by account_id, month_start
),

bounds as (
    select
        min(month_start) as min_month,
        max(month_start) as max_month
    from monthly
),

-- 0..299 covers 25 years of monthly history without recursive CTEs.
month_numbers as (
    select ones.n + tens.n * 10 + hundreds.n * 100 as n
    from (
        select 0 as n
        union all select 1
        union all select 2
        union all select 3
        union all select 4
        union all select 5
        union all select 6
        union all select 7
        union all select 8
        union all select 9
    ) as ones
    cross join (
        select 0 as n
        union all select 1
        union all select 2
        union all select 3
        union all select 4
        union all select 5
        union all select 6
        union all select 7
        union all select 8
        union all select 9
    ) as tens
    cross join (
        select 0 as n
        union all select 1
        union all select 2
    ) as hundreds
),

month_spine as (
    select
        cast({{ saas_dateadd('month', 'month_numbers.n', 'bounds.min_month') }} as date) as month_start
    from bounds
    cross join month_numbers
    where bounds.min_month is not null
        and month_numbers.n <= {{ saas_datediff('month', 'bounds.min_month', 'bounds.max_month') }}
),

account_bounds as (
    select
        account_id,
        min(month_start) as first_month
    from monthly
    group by account_id
),

filled as (
    select
        account_bounds.account_id,
        month_spine.month_start,
        account_bounds.first_month,
        coalesce(monthly.mrr, cast(0 as decimal(18, 2))) as mrr,
        monthly.status,
        monthly.plan_name,
        monthly.seats
    from account_bounds
    inner join month_spine
        on month_spine.month_start >= account_bounds.first_month
    left join monthly
        on account_bounds.account_id = monthly.account_id
        and month_spine.month_start = monthly.month_start
),

with_prior as (
    select
        account_id,
        month_start,
        first_month,
        mrr,
        status,
        plan_name,
        seats,
        coalesce(
            lag(mrr) over (partition by account_id order by month_start),
            cast(0 as decimal(18, 2))
        ) as prior_mrr
    from filled
),

classified as (
    select
        account_id,
        month_start,
        first_month,
        mrr,
        prior_mrr,
        mrr - prior_mrr as mrr_delta,
        status,
        plan_name,
        seats,
        case
            when prior_mrr = 0 and mrr > 0 and month_start = first_month then 'new'
            when prior_mrr = 0 and mrr > 0 and month_start > first_month then 'reactivation'
            when prior_mrr > 0 and mrr > prior_mrr then 'expansion'
            when prior_mrr > 0 and mrr > 0 and mrr < prior_mrr then 'contraction'
            when prior_mrr > 0 and mrr = 0 then 'churn'
            when prior_mrr > 0 and mrr = prior_mrr then 'retained'
            else 'inactive'
        end as change_type,
        case
            when prior_mrr = 0 and mrr > 0 and month_start = first_month then mrr
            else cast(0 as decimal(18, 2))
        end as new_mrr,
        case
            when prior_mrr = 0 and mrr > 0 and month_start > first_month then mrr
            else cast(0 as decimal(18, 2))
        end as reactivation_mrr,
        case
            when prior_mrr > 0 and mrr > prior_mrr then mrr - prior_mrr
            else cast(0 as decimal(18, 2))
        end as expansion_mrr,
        case
            when prior_mrr > 0 and mrr > 0 and mrr < prior_mrr then prior_mrr - mrr
            else cast(0 as decimal(18, 2))
        end as contraction_mrr,
        case
            when prior_mrr > 0 and mrr = 0 then prior_mrr
            else cast(0 as decimal(18, 2))
        end as churn_mrr
    from with_prior
)

select
    {{ saas_generate_surrogate_key(['account_id', 'month_start']) }} as account_month_key,
    account_id,
    month_start,
    first_month,
    mrr,
    prior_mrr,
    mrr_delta,
    change_type,
    new_mrr,
    reactivation_mrr,
    expansion_mrr,
    contraction_mrr,
    churn_mrr,
    status,
    plan_name,
    seats,
    {{ saas_currency_literal() }} as currency_code
from classified
