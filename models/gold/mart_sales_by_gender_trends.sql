{{ config(materialized='table', schema='gold') }}

select
    transaction_year,
    area_name,
    property_type,
    broker_gender,
    count(distinct transaction_id)        as total_deals,
    round(sum(transaction_amount_aed), 2) as total_volume_aed,
    round(avg(transaction_amount_aed), 2) as avg_deal_size_aed
from {{ ref('fct_property_sales') }}
where broker_gender in ('MALE', 'FEMALE')
group by 1, 2, 3, 4