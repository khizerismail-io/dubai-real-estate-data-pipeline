with bronze as (
    select * from {{ ref('bronze_transactions') }}
),

deduped as (
    select
        *,
        row_number() over (
            partition by transaction_id 
            order by bronze_loaded_at desc
        ) as rn
    from bronze
),

silver as (
    select
        -- Identifiers
        transaction_id::varchar                             as transaction_id,
        transaction_number::varchar                         as transaction_number,
        
        -- Date & Temporal Dimensions
        instance_date::date                                 as transaction_date,
        extract(year from instance_date::date)              as transaction_year,
        to_char(instance_date::date, 'MMMM')                as transaction_month,
        to_char(instance_date::date, 'DY')                  as transaction_day_of_week,

        -- Transaction Classifications
        upper(trim(transaction_group))                      as transaction_group,
        upper(trim(procedure_type))                         as procedure_type,
        case 
            when lower(transaction_group) like '%sale%' or lower(procedure_type) like '%sale%' then 'Sales'
            when lower(transaction_group) like '%mortgage%' or lower(procedure_type) like '%mortgage%' then 'Mortgage'
            when lower(transaction_group) like '%gift%' or lower(procedure_type) like '%grant%' then 'Gift / Grant'
            else 'Other'
        end                                                 as deal_category,

        -- Property & Location Details
        initcap(trim(project_name))                         as project_name,
        initcap(trim(area_name))                            as area_name,
        upper(trim(property_usage))                         as property_usage,
        upper(trim(property_type))                          as property_type,
        upper(trim(property_subtype))                       as property_subtype,
        room_count::varchar                                 as room_count,
        parking_spaces_count::varchar                       as parking_spaces_count,
        
        -- Landmarks & Proximity
        initcap(trim(nearest_metro_station))                as nearest_metro_station,
        initcap(trim(nearest_shopping_mall))                as nearest_shopping_mall,
        initcap(trim(nearest_landmark))                     as nearest_landmark,

        -- Financial Metrics (AED & USD)
        transaction_amount_aed::number(18, 2)               as transaction_amount_aed,
        round(transaction_amount_aed / 3.6725, 2)           as transaction_amount_usd,

        -- Spatial Metrics (Using Actual Area)
        actual_area_sqm::float                              as actual_area_sqm,
        round(actual_area_sqm * 10.7639, 2)                 as actual_area_sqft,

        -- Price per Unit Area
        round(transaction_amount_aed / nullif(actual_area_sqm, 0), 2) as price_per_sqm_aed,
        round((transaction_amount_aed / 3.6725) / nullif(actual_area_sqm * 10.7639, 0), 2) as price_per_sqft_usd,

        -- Price Tier Classification
        case 
            when transaction_amount_aed < 1000000 then 'Budget (<1M AED)'
            when transaction_amount_aed between 1000000 and 3000000 then 'Mid-Market (1M-3M AED)'
            when transaction_amount_aed between 3000000 and 10000000 then 'Prime (3M-10M AED)'
            else 'Ultra-Luxury (>10M AED)'
        end                                                 as price_tier,

        -- Size Segment Classification
        case
            when actual_area_sqm < 50 then 'Micro / Studio (<50 SQM)'
            when actual_area_sqm between 50 and 100 then 'Compact (50-100 SQM)'
            when actual_area_sqm between 100 and 250 then 'Family Sized (100-250 SQM)'
            when actual_area_sqm between 250 and 500 then 'Spacious (250-500 SQM)'
            else 'Palatial / Villa Plot (>500 SQM)'
        end                                                 as unit_size_segment

    from deduped
    where rn = 1
      and transaction_id is not null
      and transaction_amount_aed > 0
)

select * 
from silver
order by transaction_date asc, transaction_id asc