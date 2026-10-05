-- Point-in-time account health as of saas_as_of_date (or current_timestamp).
-- Score is 0-100 from usage recency, event volume, payment status, and MRR trend.
--   recency  <=7d 40, <=14d 30, <=30d 20, <=60d 10, else 0  (max 40)
--   volume   >=8 events 16, >=3 events 12, >=1 event 6, else 0  (max 16)
--   payment  active MRR 30, past_due MRR 12, else 0  (max 30)
--   growth   expansion 10, flat/new/reactivation 6, contraction 3, else 0  (max 10)
-- Tiers: healthy >= 75, watch >= 45, otherwise at_risk.
-- Lookback for volume is saas_health_lookback_days (default 30).

with params as (
    select {{ saas_as_of_timestamp() }} as as_of_at
),

accounts as (
    select * from {{ ref('int_saas_accounts') }}
),

movements as (
    select * from {{ ref('int_saas_account_mrr_monthly') }}
),

latest_mrr as (
    select
        movements.account_id,
        movements.month_start,
        movements.mrr,
        movements.prior_mrr,
        movements.change_type,
        movements.status,
        movements.plan_name,
        movements.currency_code,
        row_number() over (
            partition by movements.account_id
            order by movements.month_start desc
        ) as row_num
    from movements
    cross join params
    where movements.month_start <= cast({{ saas_date_trunc('month', 'params.as_of_at') }} as date)
),

current_mrr as (
    select *
    from latest_mrr
    where row_num = 1
),

usage as (
    select
        tracks.account_id,
        count(*) as events_lookback,
        count(distinct tracks.user_id) as active_users_lookback
    from {{ ref('stg_saas_tracks') }} as tracks
    cross join params
    where tracks.account_id is not null
        and cast(tracks.occurred_at as date) <= cast(params.as_of_at as date)
        and cast(tracks.occurred_at as date) > cast(
            {{ saas_dateadd('day', -var('saas_health_lookback_days', 30), 'params.as_of_at') }} as date
        )
    group by tracks.account_id
),

last_seen as (
    select
        tracks.account_id,
        max(tracks.occurred_at) as last_seen_at
    from {{ ref('stg_saas_tracks') }} as tracks
    cross join params
    where tracks.account_id is not null
        and tracks.occurred_at <= params.as_of_at
    group by tracks.account_id
),

scored as (
    select
        accounts.account_id,
        accounts.account_name,
        accounts.known_users,
        cast(params.as_of_at as date) as as_of_date,
        coalesce(current_mrr.mrr, cast(0 as decimal(18, 2))) as current_mrr,
        current_mrr.prior_mrr,
        coalesce(current_mrr.currency_code, {{ saas_currency_literal() }}) as currency_code,
        current_mrr.plan_name,
        current_mrr.change_type,
        case
            when coalesce(current_mrr.mrr, 0) > 0 and current_mrr.status = 'past_due' then 'past_due'
            when coalesce(current_mrr.mrr, 0) > 0 then 'active'
            when current_mrr.account_id is not null then 'canceled'
            else 'none'
        end as payment_status,
        last_seen.last_seen_at,
        case
            when last_seen.last_seen_at is null then null
            else {{ saas_datediff('day', 'last_seen.last_seen_at', 'params.as_of_at') }}
        end as days_since_last_seen,
        coalesce(usage.events_lookback, 0) as events_lookback,
        coalesce(usage.active_users_lookback, 0) as active_users_lookback,
        {{ var('saas_health_lookback_days', 30) }} as lookback_days,
        case
            when last_seen.last_seen_at is null then 0
            when {{ saas_datediff('day', 'last_seen.last_seen_at', 'params.as_of_at') }} <= 7 then 40
            when {{ saas_datediff('day', 'last_seen.last_seen_at', 'params.as_of_at') }} <= 14 then 30
            when {{ saas_datediff('day', 'last_seen.last_seen_at', 'params.as_of_at') }} <= 30 then 20
            when {{ saas_datediff('day', 'last_seen.last_seen_at', 'params.as_of_at') }} <= 60 then 10
            else 0
        end as recency_points,
        case
            when coalesce(usage.events_lookback, 0) >= 8 then 16
            when coalesce(usage.events_lookback, 0) >= 3 then 12
            when coalesce(usage.events_lookback, 0) >= 1 then 6
            else 0
        end as volume_points,
        case
            when coalesce(current_mrr.mrr, 0) > 0 and current_mrr.status = 'past_due' then 12
            when coalesce(current_mrr.mrr, 0) > 0 then 30
            else 0
        end as payment_points,
        case
            when current_mrr.change_type = 'expansion' then 10
            when current_mrr.change_type = 'contraction' then 3
            when current_mrr.change_type in ('retained', 'new', 'reactivation') then 6
            else 0
        end as growth_points
    from accounts
    cross join params
    left join current_mrr
        on accounts.account_id = current_mrr.account_id
    left join usage
        on accounts.account_id = usage.account_id
    left join last_seen
        on accounts.account_id = last_seen.account_id
)

select
    account_id,
    account_name,
    as_of_date,
    current_mrr,
    prior_mrr,
    currency_code,
    plan_name,
    payment_status,
    change_type,
    known_users,
    last_seen_at,
    days_since_last_seen,
    events_lookback,
    active_users_lookback,
    lookback_days,
    recency_points,
    volume_points,
    payment_points,
    growth_points,
    least(
        recency_points + volume_points + payment_points + growth_points,
        100
    ) as health_score,
    case
        when least(recency_points + volume_points + payment_points + growth_points, 100) >= 75 then 'healthy'
        when least(recency_points + volume_points + payment_points + growth_points, 100) >= 45 then 'watch'
        else 'at_risk'
    end as health_tier
from scored
