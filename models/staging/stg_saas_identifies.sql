-- Grain: one Segment/Rudderstack identify call.
-- Links anonymous_id to user_id and carries the account trait when present.

with source_data as (
    select * from {{ source('segment', 'identifies') }}
),

renamed as (
    select
        cast({{ saas_col('id') }} as varchar) as identify_id,
        cast({{ saas_col('anonymous_id') }} as varchar) as anonymous_id,
        nullif(cast({{ saas_col('user_id') }} as varchar), '') as user_id,
        cast({{ saas_col('timestamp') }} as timestamp) as identified_at,
        nullif(cast({{ saas_col('email') }} as varchar), '') as email,
        nullif(cast({{ saas_col(var('saas_account_id_column', 'context_group_id')) }} as varchar), '') as account_id
    from source_data
)

select *
from renamed
where identify_id is not null
    and identified_at is not null
