-- Grain: one page call. Anonymous visitors are kept; user_id may be null.

with source_data as (
    select * from {{ source('segment', 'pages') }}
),

renamed as (
    select
        cast({{ saas_col('id') }} as varchar) as page_id,
        cast({{ saas_col('anonymous_id') }} as varchar) as anonymous_id,
        nullif(cast({{ saas_col('user_id') }} as varchar), '') as user_id,
        cast({{ saas_col('timestamp') }} as timestamp) as occurred_at,
        nullif(cast({{ saas_col('url') }} as varchar), '') as url,
        nullif(cast({{ saas_col('path') }} as varchar), '') as path,
        nullif(cast({{ saas_col(var('saas_account_id_column', 'context_group_id')) }} as varchar), '') as account_id
    from source_data
)

select *
from renamed
where page_id is not null
    and occurred_at is not null
