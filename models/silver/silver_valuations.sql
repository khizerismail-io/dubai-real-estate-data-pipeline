with bronze as (
    select * from {{ ref('bronze_valuations') }}
),

deduped as (
    select
        *,
        row_number() over (
            partition by valuation_id 
            order by bronze_loaded_at desc
        ) as rn
    from bronze
),

cleaned as (
    select
        -- Identifiers
        valuation_id::varchar                                                 as valuation_id,
        procedure_number::varchar                                             as procedure_number,

        -- Date & Temporal Dimensions
        instance_date::date                                                   as valuation_date,
        procedure_year::integer                                               as procedure_year,
        to_char(instance_date::date, 'MMMM')                                  as valuation_month,
        to_char(instance_date::date, 'DY')                                    as valuation_day_of_week,

        -- Location & Subtypes
        initcap(trim(area_name))                                              as area_name,
        upper(trim(property_type))                                            as property_type,
        upper(trim(property_subtype))                                         as property_subtype,

        -- Financial & Spatial Metrics
        coalesce(actual_worth_aed, valuation_total_value_aed, 0)::number(18, 2) as valuation_amount_aed,
        actual_area_sqm::float                                                as actual_area_sqm

    from deduped
    where rn = 1
      and valuation_id is not null
      and coalesce(actual_worth_aed, valuation_total_value_aed, 0) > 0
),

silver as (
    select
        valuation_id,
        procedure_number,
        valuation_date,
        procedure_year,
        valuation_month,
        valuation_day_of_week,
        area_name,
        property_type,
        property_subtype,

        -- Financial Metrics (AED & USD)
        valuation_amount_aed,
        round(valuation_amount_aed / 3.6725, 2)                               as valuation_amount_usd,

        -- Spatial Metrics (SQM & SQFT)
        actual_area_sqm,
        round(actual_area_sqm * 10.7639, 2)                                   as actual_area_sqft,

        -- Rates per Unit Area
        round(valuation_amount_aed / nullif(actual_area_sqm, 0), 2)           as valuation_rate_per_sqm_aed,
        round((valuation_amount_aed / 3.6725) / nullif(actual_area_sqm * 10.7639, 0), 2) as valuation_rate_per_sqft_usd,

        -- Valuation Tiers
        case 
            when valuation_amount_aed < 1000000 then 'Budget (<1M AED)'
            when valuation_amount_aed between 1000000 and 3000000 then 'Mid-Market (1M-3M AED)'
            when valuation_amount_aed between 3000000 and 10000000 then 'Prime (3M-10M AED)'
            else 'Ultra-Luxury (>10M AED)'
        end                                                                   as valuation_tier,

        -- Size Segments
        case
            when actual_area_sqm < 50 then 'Micro / Studio (<50 SQM)'
            when actual_area_sqm between 50 and 100 then 'Compact (50-100 SQM)'
            when actual_area_sqm between 100 and 250 then 'Family Sized (100-250 SQM)'
            when actual_area_sqm between 250 and 500 then 'Spacious (250-500 SQM)'
            else 'Palatial / Large Plot (>500 SQM)'
        end                                                                   as unit_size_segment

    from cleaned
)

select * 
from silver
order by valuation_id asc