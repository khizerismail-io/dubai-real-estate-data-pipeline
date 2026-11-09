{{ config(materialized='table', schema='gold') }}

with area_metrics as (
    select
        area_name,
        property_usage,
        property_type,
        broker_gender,
        count(distinct transaction_id)                          as deal_count,
        sum(transaction_amount_aed)                             as total_volume_aed,
        sum(actual_area_sqft)                                   as total_sqft
    from {{ ref('fct_property_sales') }}
    where broker_gender in ('MALE', 'FEMALE')
      and area_name is not null
    group by 1, 2, 3, 4
)

select
    area_name,
    property_usage,
    property_type,
    broker_gender,
    deal_count,
    round(total_volume_aed, 2)                                  as total_volume_aed,
    round(total_volume_aed / nullif(total_sqft, 0), 2)          as realized_price_per_sqft_aed,
    round((total_volume_aed / 3.6725) / nullif(total_sqft, 0), 2) as realized_price_per_sqft_usd,
    round(
        100.0 * total_volume_aed / 
        nullif(sum(total_volume_aed) over (partition by area_name), 0), 
        2
    )                                                           as gender_area_market_share_pct
from area_metrics