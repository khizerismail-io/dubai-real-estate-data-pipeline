{{ config(materialized='table', schema='gold') }}

with tx as (
    select * from {{ ref('silver_transactions') }}
),

bridge as (
    select * from {{ ref('silver_transaction_brokers') }}
)

select
    t.transaction_id,
    t.transaction_number,
    t.transaction_date,
    t.transaction_year,
    t.transaction_group,
    t.procedure_type,
    t.property_usage,
    t.property_type,
    t.area_name,
    t.transaction_amount_aed,
    t.transaction_amount_usd,
    t.actual_area_sqft,
    t.price_tier,
    
    coalesce(b.broker_id, 'UNASSIGNED') as broker_id,
    coalesce(b.broker_name, 'UNASSIGNED') as broker_name,
    coalesce(b.broker_gender, 'UNKNOWN') as broker_gender

from tx t
left join bridge b
    on t.transaction_id = b.transaction_id