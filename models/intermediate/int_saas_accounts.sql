-- Grain: one B2B account, from group calls and billing snapshots.

with groups as (
    select * from {{ ref('stg_saas_groups') }}
),

subscriptions as (
    select distinct account_id
    from {{ ref('stg_saas_subscriptions') }}
),

ranked_groups as (
    select
        account_id,
        account_name,
        plan_name,
        occurred_at,
        user_id,
        row_number() over (
            partition by account_id
            order by occurred_at desc, group_call_id desc
        ) as row_num
    from groups
),

latest_group as (
    select
        account_id,
        account_name,
        plan_name as group_plan_name,
        occurred_at as last_group_at
    from ranked_groups
    where row_num = 1
),

user_counts as (
    select
        account_id,
        count(distinct user_id) as known_users
    from groups
    where user_id is not null
    group by account_id
),

account_ids as (
    select account_id from latest_group
    union
    select account_id from subscriptions
)

select
    ids.account_id,
    latest_group.account_name,
    latest_group.group_plan_name,
    latest_group.last_group_at,
    coalesce(user_counts.known_users, 0) as known_users
from account_ids as ids
left join latest_group
    on ids.account_id = latest_group.account_id
left join user_counts
    on ids.account_id = user_counts.account_id
