{{ config(materialized='table', schema='silver') }}

with sales_tx as (
    select 
        transaction_id,
        row_number() over (order by transaction_id) as tx_seq
    from {{ ref('silver_transactions') }}
    where upper(trim(transaction_group)) = 'SALES'
),

active_brokers as (
    select 
        broker_id,
        broker_name,
        gender,
        row_number() over (order by broker_id) as broker_seq,
        count(*) over () as total_brokers
    from {{ ref('silver_brokers') }}
    where gender in ('MALE', 'FEMALE')
)

select
    t.transaction_id,
    b.broker_id,
    b.broker_name,
    b.gender as broker_gender
from sales_tx t
join active_brokers b
    on mod(t.tx_seq, b.total_brokers) + 1 = b.broker_seq