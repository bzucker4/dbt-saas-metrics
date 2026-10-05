-- Grain: one user who fired the signup event.
-- activated_within_window is true when the activation event happens
-- between signup and signup + saas_activation_window_days (default 14).

with signed_up_users as (
    select *
    from {{ ref('int_saas_user_first_touch') }}
    where signup_at is not null
),

activations as (
    select
        user_id,
        min(occurred_at) as activated_at
    from {{ ref('stg_saas_tracks') }}
    where event_name = {{ saas_event_literal('saas_activation_event', 'activated') }}
        and user_id is not null
    group by user_id
),

joined as (
    select
        signed_up_users.user_id,
        signed_up_users.account_id,
        signed_up_users.email,
        signed_up_users.signup_at,
        signed_up_users.first_seen_at,
        signed_up_users.first_page_at,
        activations.activated_at,
        cast({{ saas_date_trunc('month', 'signed_up_users.signup_at') }} as date) as cohort_month,
        case
            when activations.activated_at is null then null
            else {{ saas_datediff('day', 'signed_up_users.signup_at', 'activations.activated_at') }}
        end as days_to_activate
    from signed_up_users
    left join activations
        on signed_up_users.user_id = activations.user_id
)

select
    user_id,
    account_id,
    email,
    cohort_month,
    signup_at,
    first_seen_at,
    first_page_at,
    activated_at,
    days_to_activate,
    case
        when activated_at is not null and days_to_activate >= 0 then true
        else false
    end as activated_ever,
    case
        when activated_at is null then false
        when days_to_activate < 0 then false
        when days_to_activate <= {{ var('saas_activation_window_days', 14) }} then true
        else false
    end as activated_within_window,
    {{ var('saas_activation_window_days', 14) }} as activation_window_days
from joined
