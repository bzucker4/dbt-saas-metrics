-- Grain: one group call. group_id is the B2B account (workspace / customer).

with source_data as (
    select * from {{ source('segment', 'groups') }}
),

renamed as (
    select
        cast({{ saas_col('id') }} as varchar) as group_call_id,
        nullif(cast({{ saas_col(var('saas_group_id_column', 'group_id')) }} as varchar), '') as account_id,
        nullif(cast({{ saas_col('user_id') }} as varchar), '') as user_id,
        cast({{ saas_col('timestamp') }} as timestamp) as occurred_at,
        nullif(cast({{ saas_col(var('saas_group_name_column', 'name')) }} as varchar), '') as account_name,
        nullif(cast({{ saas_col(var('saas_group_plan_column', 'plan')) }} as varchar), '') as plan_name
    from source_data
)

select *
from renamed
where group_call_id is not null
    and occurred_at is not null
    and account_id is not null
