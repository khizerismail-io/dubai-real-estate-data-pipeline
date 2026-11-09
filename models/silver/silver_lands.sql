with bronze as (
    select * from {{ ref('bronze_lands') }}
),

deduped as (
    select
        *,
        row_number() over (
            partition by land_id 
            order by bronze_loaded_at desc
        ) as rn
    from bronze
),

silver as (
    select
        -- Identifiers
        land_id::varchar                                    as land_id,
        pre_registration_number::varchar                    as pre_registration_number,
        project_number::varchar                             as project_number,

        -- Location & Classification
        initcap(trim(project_name))                         as project_name,
        initcap(trim(area_name))                            as area_name,
        initcap(trim(zone_name))                            as zone_name,
        trim(dm_zip_code)                                   as dm_zip_code,

        -- Land Attributes & Property Types
        upper(trim(land_type))                              as land_type,
        upper(trim(prop_sub_type))                          as property_subtype,

        -- Tenure & Market Flags
        case 
            when lower(trim(is_free_hold)) in ('yes', 'true', '1') then 'Freehold'
            when lower(trim(is_free_hold)) in ('no', 'false', '0') then 'Non-Freehold'
            else 'Unknown'
        end                                                 as tenure_type,

        case 
            when lower(trim(is_offplan)) in ('yes', 'true', '1') then 'Off-Plan'
            when lower(trim(is_offplan)) in ('no', 'false', '0') then 'Ready'
            else 'Unknown'
        end                                                 as market_segment,

        -- Spatial Metrics (SQM & SQFT)
        actual_area_sqm::float                              as actual_area_sqm,
        round(actual_area_sqm * 10.7639, 2)                 as actual_area_sqft,

        -- Land Size Classification
        case
            when actual_area_sqm < 500 then 'Small Plot (<500 SQM)'
            when actual_area_sqm between 500 and 1500 then 'Standard Residential (500-1,500 SQM)'
            when actual_area_sqm between 1500 and 5000 then 'Large Plot / Commercial (1,500-5,000 SQM)'
            else 'Mega Plot / Master Development (>5,000 SQM)'
        end                                                 as land_size_segment

    from deduped
    where rn = 1
      and land_id is not null
)

select * 
from silver
order by land_id asc