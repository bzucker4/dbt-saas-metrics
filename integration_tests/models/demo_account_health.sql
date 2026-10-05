-- Current health snapshot from the package, for the demo as-of date.

select
    account_id,
    account_name,
    as_of_date,
    current_mrr,
    payment_status,
    plan_name,
    health_score,
    health_tier,
    days_since_last_seen,
    events_lookback,
    active_users_lookback,
    recency_points,
    volume_points,
    payment_points,
    growth_points
from {{ ref('saas_customer_health') }}
