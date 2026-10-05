-- Locks the synthetic book of business so a buyer can trust the quick start.
-- Figures are ratios and major currency units, not percents, except where named.

with failures as (
    select 'february nrr should be 1' as check_name
    from {{ ref('saas_nrr') }}
    where month_start = cast('2025-02-01' as date)
        and abs(nrr - 1.0) > 0.000001

    union all

    select 'april contraction and ending mrr'
    from {{ ref('saas_mrr_waterfall') }}
    where month_start = cast('2025-04-01' as date)
        and (
            abs(contraction_mrr - 100) > 0.01
            or abs(ending_mrr - 2850) > 0.01
            or abs(new_mrr - 250) > 0.01
        )

    union all

    select 'may churn, new logos, and reactivation'
    from {{ ref('saas_mrr_waterfall') }}
    where month_start = cast('2025-05-01' as date)
        and (
            abs(churn_mrr - 300) > 0.01
            or abs(new_mrr - 750) > 0.01
            or abs(of_which_reactivation_mrr - 150) > 0.01
            or abs(ending_mrr - 3300) > 0.01
        )

    union all

    select 'june expansion to 3800 ending mrr'
    from {{ ref('saas_mrr_waterfall') }}
    where month_start = cast('2025-06-01' as date)
        and (
            abs(starting_mrr - 3300) > 0.01
            or abs(expansion_mrr - 500) > 0.01
            or abs(ending_mrr - 3800) > 0.01
        )

    union all

    select 'june nrr about 115 percent'
    from {{ ref('saas_nrr') }}
    where month_start = cast('2025-06-01' as date)
        and abs(nrr - (3800.0 / 3300.0)) > 0.000001

    union all

    select 'january activation 5 of 6, median 2 days'
    from {{ ref('saas_activation') }}
    where cohort_month = cast('2025-01-01' as date)
        and (
            new_users <> 6
            or activated_users <> 5
            or abs(median_days_to_activate - 2) > 0.001
        )

    union all

    select 'january funnel'
    from {{ ref('saas_plg_funnel') }}
    where cohort_month = cast('2025-01-01' as date)
        and (visitors <> 7 or signups <> 6 or activations <> 5 or paid_conversions <> 5)

    union all

    select 'february funnel includes late activator as activated but unpaid'
    from {{ ref('saas_plg_funnel') }}
    where cohort_month = cast('2025-02-01' as date)
        and (visitors <> 2 or signups <> 2 or activations <> 2 or paid_conversions <> 1)

    union all

    select 'acme should be healthy and gamma at risk'
    from {{ ref('saas_customer_health') }}
    where (account_id = 'acct_acme' and health_tier <> 'healthy')
        or (account_id = 'acct_gamma' and health_tier <> 'at_risk')
        or (account_id = 'acct_echo' and health_tier <> 'watch')
)

select * from failures
