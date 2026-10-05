-- Grain: one person. Known users use user_id. Unidentified visitors use anonymous_id.
-- Stage flags are sequential: paid implies activation implies signup implies visit.
-- A signup with no page view still counts as a visit so the funnel stays monotonic.
-- Activation here means the activation event ever fired. The time-boxed rate
-- lives on saas_activation (var saas_activation_window_days).

with first_touch as (
    select * from {{ ref('int_saas_user_first_touch') }}
),

activation as (
    select * from {{ ref('int_saas_user_activation') }}
),

pages as (
    select * from {{ ref('stg_saas_pages') }}
),

identifies as (
    select * from {{ ref('stg_saas_identifies') }}
),

paid_accounts as (
    select account_id
    from {{ ref('stg_saas_subscriptions') }}
    where mrr > 0
    group by account_id
),

paid_events as (
    select distinct user_id
    from {{ ref('stg_saas_tracks') }}
    where event_name = {{ saas_event_literal('saas_paid_event', 'subscription_started') }}
        and user_id is not null
),

identity_map as (
    select
        anonymous_id,
        user_id
    from (
        select
            anonymous_id,
            user_id,
            row_number() over (
                partition by anonymous_id
                order by identified_at, identify_id
            ) as row_num
        from identifies
        where anonymous_id is not null
            and user_id is not null
    ) ranked
    where row_num = 1
),

anonymous_visitors as (
    select
        pages.anonymous_id as person_id,
        min(pages.occurred_at) as first_visit_at
    from pages
    left join identity_map
        on pages.anonymous_id = identity_map.anonymous_id
    where pages.user_id is null
        and identity_map.user_id is null
        and pages.anonymous_id is not null
    group by pages.anonymous_id
),

known_people as (
    select
        first_touch.user_id as person_id,
        first_touch.account_id,
        first_touch.first_page_at as first_visit_at,
        first_touch.signup_at,
        activation.activated_at,
        activation.days_to_activate,
        coalesce(activation.activated_within_window, false) as activated_within_window,
        coalesce(activation.activated_ever, false) as activated_ever,
        case
            when paid_accounts.account_id is not null or paid_events.user_id is not null then true
            else false
        end as is_paid_account
    from first_touch
    left join activation
        on first_touch.user_id = activation.user_id
    left join paid_accounts
        on first_touch.account_id = paid_accounts.account_id
    left join paid_events
        on first_touch.user_id = paid_events.user_id
    where first_touch.signup_at is not null
        or first_touch.first_page_at is not null
),

people as (
    select
        person_id,
        account_id,
        first_visit_at,
        signup_at,
        activated_at,
        days_to_activate,
        activated_within_window,
        activated_ever,
        is_paid_account
    from known_people

    union all

    select
        person_id,
        cast(null as varchar) as account_id,
        first_visit_at,
        cast(null as timestamp) as signup_at,
        cast(null as timestamp) as activated_at,
        cast(null as integer) as days_to_activate,
        false as activated_within_window,
        false as activated_ever,
        false as is_paid_account
    from anonymous_visitors
),

flagged as (
    select
        person_id,
        account_id,
        first_visit_at,
        signup_at,
        activated_at,
        days_to_activate,
        activated_within_window,
        is_paid_account,
        cast(
            {{ saas_date_trunc('month', 'coalesce(first_visit_at, signup_at)') }} as date
        ) as cohort_month,
        case
            when first_visit_at is not null or signup_at is not null then true
            else false
        end as has_visit,
        case
            when signup_at is not null then true
            else false
        end as has_signup,
        case
            when signup_at is not null and activated_ever then true
            else false
        end as has_activation,
        case
            when signup_at is not null and activated_ever and is_paid_account then true
            else false
        end as has_paid
    from people
)

select
    person_id,
    cohort_month,
    account_id,
    first_visit_at,
    signup_at,
    activated_at,
    days_to_activate,
    activated_within_window,
    has_visit,
    has_signup,
    has_activation,
    is_paid_account,
    has_paid
from flagged
where cohort_month is not null
