-- Grain: one known user.
-- Stitches anonymous page views to user_id via the earliest identify call.

with identifies as (
    select * from {{ ref('stg_saas_identifies') }}
),

tracks as (
    select * from {{ ref('stg_saas_tracks') }}
),

pages as (
    select * from {{ ref('stg_saas_pages') }}
),

groups as (
    select * from {{ ref('stg_saas_groups') }}
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

known_users as (
    select user_id from identifies where user_id is not null
    union
    select user_id from tracks where user_id is not null
    union
    select user_id from groups where user_id is not null
),

stitched_pages as (
    select
        coalesce(pages.user_id, identity_map.user_id) as user_id,
        pages.anonymous_id,
        pages.occurred_at,
        pages.path
    from pages
    left join identity_map
        on pages.anonymous_id = identity_map.anonymous_id
),

first_page as (
    select
        user_id,
        anonymous_id as first_anonymous_id,
        occurred_at as first_page_at,
        path as landing_path
    from (
        select
            user_id,
            anonymous_id,
            occurred_at,
            path,
            row_number() over (
                partition by user_id
                order by occurred_at, anonymous_id
            ) as row_num
        from stitched_pages
        where user_id is not null
    ) ranked
    where row_num = 1
),

signups as (
    select
        user_id,
        min(occurred_at) as signup_at
    from tracks
    where event_name = {{ saas_event_literal('saas_signup_event', 'signed_up') }}
        and user_id is not null
    group by user_id
),

signup_account as (
    select
        user_id,
        account_id
    from (
        select
            user_id,
            account_id,
            row_number() over (
                partition by user_id
                order by occurred_at, track_id
            ) as row_num
        from tracks
        where event_name = {{ saas_event_literal('saas_signup_event', 'signed_up') }}
            and user_id is not null
            and account_id is not null
    ) ranked
    where row_num = 1
),

first_identify as (
    select
        user_id,
        identified_at as first_identify_at,
        email,
        account_id as identify_account_id
    from (
        select
            user_id,
            identified_at,
            email,
            account_id,
            row_number() over (
                partition by user_id
                order by identified_at, identify_id
            ) as row_num
        from identifies
        where user_id is not null
    ) ranked
    where row_num = 1
),

latest_group_account as (
    select
        user_id,
        account_id
    from (
        select
            user_id,
            account_id,
            row_number() over (
                partition by user_id
                order by occurred_at desc, group_call_id desc
            ) as row_num
        from groups
        where user_id is not null
            and account_id is not null
    ) ranked
    where row_num = 1
)

select
    known_users.user_id,
    first_page.first_anonymous_id,
    coalesce(
        latest_group_account.account_id,
        signup_account.account_id,
        first_identify.identify_account_id
    ) as account_id,
    first_identify.email,
    first_page.first_page_at,
    first_page.landing_path,
    first_identify.first_identify_at,
    signups.signup_at,
    nullif(
        least(
            coalesce(first_page.first_page_at, cast('2999-01-01' as timestamp)),
            coalesce(first_identify.first_identify_at, cast('2999-01-01' as timestamp)),
            coalesce(signups.signup_at, cast('2999-01-01' as timestamp))
        ),
        cast('2999-01-01' as timestamp)
    ) as first_seen_at
from known_users
left join first_page
    on known_users.user_id = first_page.user_id
left join signups
    on known_users.user_id = signups.user_id
left join signup_account
    on known_users.user_id = signup_account.user_id
left join first_identify
    on known_users.user_id = first_identify.user_id
left join latest_group_account
    on known_users.user_id = latest_group_account.user_id
