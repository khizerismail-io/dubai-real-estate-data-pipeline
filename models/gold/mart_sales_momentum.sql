{{ config(materialized='table', schema='gold') }}

with monthly_base as (
    select
        date_trunc('month', transaction_date::date)             as period_start_date,
        extract(year from transaction_date::date)               as transaction_year,
        extract(month from transaction_date::date)              as transaction_month,
        broker_gender,
        count(distinct transaction_id)                          as deals_this_month,
        sum(transaction_amount_aed)                             as volume_this_month_aed
    from {{ ref('fct_property_sales') }}
    where broker_gender in ('MALE', 'FEMALE')
      and transaction_date is not null
    group by 1, 2, 3, 4
)

select
    period_start_date,
    transaction_year,
    transaction_month,
    broker_gender,
    deals_this_month,
    round(volume_this_month_aed, 2)                             as volume_this_month_aed,

    -- Running Cumulative Volume by Gender over time
    round(
        sum(volume_this_month_aed) over (
            partition by broker_gender 
            order by period_start_date 
            rows between unbounded preceding and current row
        ), 2
    )                                                           as cumulative_volume_aed,

    -- Month-over-Month Growth %
    round(
        (volume_this_month_aed - lag(volume_this_month_aed) over (
            partition by broker_gender order by period_start_date
        )) / nullif(lag(volume_this_month_aed) over (
            partition by broker_gender order by period_start_date
        ), 0) * 100, 2
    )                                                           as mom_volume_growth_pct

from monthly_base
order by period_start_date asc, broker_gender