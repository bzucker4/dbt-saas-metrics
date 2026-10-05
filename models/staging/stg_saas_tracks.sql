-- Grain: one track call. event_name is the product event (signed_up, activated, ...).

with source_data as (
    select * from {{ source('segment', 'tracks') }}
),

renamed as (
    select
        cast({{ saas_col('id') }} as varchar) as track_id,
        cast({{ saas_col('anonymous_id') }} as varchar) as anonymous_id,
        nullif(cast({{ saas_col('user_id') }} as varchar), '') as user_id,
        nullif(cast({{ saas_col(var('saas_event_column', 'event')) }} as varchar), '') as event_name,
        cast({{ saas_col('timestamp') }} as timestamp) as occurred_at,
        nullif(cast({{ saas_col(var('saas_account_id_column', 'context_group_id')) }} as varchar), '') as account_id
    from source_data
)

select *
from renamed
where track_id is not null
    and occurred_at is not null
    and event_name is not null
