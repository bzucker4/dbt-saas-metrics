-- Activation rate by signup month.
-- Numerator: users who fire saas_activation_event within saas_activation_window_days.
-- Denominator: users who fire saas_signup_event.
-- median_days_to_activate is the median among users who activated inside the window.

with users as (
    select * from {{ ref('int_saas_user_activation') }}
),

cohorts as (
    select
        cohort_month,
        count(distinct user_id) as new_users,
        count(distinct case when activated_within_window then user_id end) as activated_users,
        count(distinct case
            when activated_ever and not activated_within_window then user_id
        end) as activated_after_window,
        count(distinct case when not activated_ever then user_id end) as not_activated_users
    from users
    group by cohort_month
),

windowed as (
    select
        cohort_month,
        user_id,
        days_to_activate
    from users
    where activated_within_window
        and days_to_activate is not null
),

ranked as (
    select
        cohort_month,
        user_id,
        days_to_activate,
        row_number() over (
            partition by cohort_month
            order by days_to_activate, user_id
        ) as row_num,
        count(*) over (partition by cohort_month) as cohort_size
    from windowed
),

medians as (
    select
        cohort_month,
        avg(days_to_activate) as median_days_to_activate
    from ranked
    where row_num = floor((cohort_size + 1) / 2.0)
        or row_num = ceil((cohort_size + 1) / 2.0)
    group by cohort_month
)

select
    cohorts.cohort_month,
    {{ saas_event_literal('saas_signup_event', 'signed_up') }} as signup_event,
    {{ saas_event_literal('saas_activation_event', 'activated') }} as activation_event,
    {{ var('saas_activation_window_days', 14) }} as activation_window_days,
    cohorts.new_users,
    cohorts.activated_users,
    cohorts.activated_after_window,
    cohorts.not_activated_users,
    cohorts.activated_users * 1.0 / nullif(cohorts.new_users, 0) as activation_rate,
    medians.median_days_to_activate
from cohorts
left join medians
    on cohorts.cohort_month = medians.cohort_month
