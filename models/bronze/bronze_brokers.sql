with source as (
    select * from {{ source('dubai_source', 'BROKERS') }}
)

select
    *,
    current_timestamp() as bronze_loaded_at
from source