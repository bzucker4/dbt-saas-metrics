-- Grain: one account-month billing snapshot.
-- Buyers point source('billing', 'subscriptions') at a view with this shape.
-- mrr is the ending recurring revenue for that month in major currency units.
-- A churned month is mrr = 0 with status canceled. Missing months are treated
-- as zero after the account's first snapshot (see int_saas_account_mrr_monthly).

with source_data as (
    select * from {{ source('billing', 'subscriptions') }}
),

renamed as (
    select
        cast({{ saas_col('subscription_id') }} as varchar) as subscription_id,
        nullif(cast({{ saas_col('account_id') }} as varchar), '') as account_id,
        cast({{ saas_col('month_start') }} as date) as month_start,
        cast({{ saas_col('mrr') }} as decimal(18, 2)) as mrr,
        nullif(lower(cast({{ saas_col('status') }} as varchar)), '') as status,
        nullif(cast({{ saas_col('plan_name') }} as varchar), '') as plan_name,
        cast({{ saas_col('seats') }} as integer) as seats
    from source_data
)

select *
from renamed
where account_id is not null
    and month_start is not null
    and mrr is not null
