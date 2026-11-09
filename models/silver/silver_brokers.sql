with bronze as (
    select * from {{ ref('bronze_brokers') }}
),

deduped as (
    select
        *,
        row_number() over (
            partition by broker_id 
            order by bronze_loaded_at desc
        ) as rn
    from bronze
),

silver as (
    select
        -- Identifiers
        broker_id::varchar                                          as broker_id,
        broker_number::varchar                                      as broker_number,
        real_estate_company_number::varchar                         as real_estate_company_number,

        -- Personal & Company Details
        initcap(trim(broker_name))                                  as broker_name,
        upper(trim(gender))                                         as gender,
        initcap(trim(real_estate_company_name))                     as real_estate_company_name,
        trim(phone)                                                 as phone_number,

        -- Licensing Dates & Lifecycle
        license_start_date::date                                    as license_start_date,
        license_end_date::date                                      as license_end_date,
        datediff('day', current_date(), license_end_date::date)     as days_until_license_expiry,

        -- Operational License Status
        case 
            when license_end_date::date >= current_date() then 'Active'
            when license_end_date::date < current_date() then 'Expired'
            else 'Unknown'
        end                                                         as license_status

    from deduped
    where rn = 1
      and broker_id is not null
      and broker_number is not null
      and broker_name is not null
      and real_estate_company_name is not null
      and license_start_date is not null
      and license_end_date is not null
      and phone is not null
      and gender is not null
)

select * 
from silver
order by try_to_number(broker_id) asc