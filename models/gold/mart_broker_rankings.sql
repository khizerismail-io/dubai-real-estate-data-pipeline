{{ config(materialized='table', schema='gold') }}

with broker_sales as (
    select
        broker_id,
        broker_name,
        broker_gender,
        count(distinct transaction_id)              as total_deals,
        sum(transaction_amount_aed)                 as total_volume_aed,
        avg(transaction_amount_aed)                 as avg_deal_size_aed,
        min(transaction_date)                       as first_deal_date,
        max(transaction_date)                       as last_deal_date
    from {{ ref('fct_property_sales') }}
    where broker_gender in ('MALE', 'FEMALE')
    group by 1, 2, 3
),

ranked_brokers as (
    select
        *,
        -- Overall ranking
        dense_rank() over (order by total_volume_aed desc)             as rank_overall,
        -- Within-gender ranking
        dense_rank() over (partition by broker_gender 
                           order by total_volume_aed desc)             as rank_within_gender,
        -- Percentile contribution
        percent_rank() over (order by total_volume_aed desc)           as volume_percentile
    from broker_sales
)

select
    broker_id,
    broker_name,
    broker_gender,
    total_deals,
    round(total_volume_aed, 2)                      as total_volume_aed,
    round(avg_deal_size_aed, 2)                     as avg_deal_size_aed,
    rank_overall,
    rank_within_gender,
    case
        when volume_percentile >= 0.90 then 'Tier 1 - Elite Top 10%'
        when volume_percentile >= 0.70 then 'Tier 2 - High Performer'
        when volume_percentile >= 0.40 then 'Tier 3 - Mid Tier'
        else 'Tier 4 - Long Tail'
    end                                             as performance_tier,
    first_deal_date,
    last_deal_date
from ranked_brokers