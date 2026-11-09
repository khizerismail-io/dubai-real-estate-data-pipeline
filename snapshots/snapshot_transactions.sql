{% snapshot snapshot_transactions %}

{{
    config(
        target_schema='snapshots',
        unique_key='transaction_id',
        strategy='check',
        check_cols=['transaction_amount_aed', 'actual_area_sqm', 'procedure_type', 'property_usage'],
        invalidate_hard_deletes=True
    )
}}

select
    transaction_id,
    transaction_number,
    transaction_date,
    transaction_group,
    procedure_type,
    deal_category,
    project_name,
    area_name,
    property_usage,
    property_type,
    property_subtype,
    transaction_amount_aed,
    transaction_amount_usd,
    actual_area_sqm,
    actual_area_sqft,
    price_per_sqm_aed,
    price_per_sqft_usd,
    price_tier,
    unit_size_segment
from {{ ref('silver_transactions') }}

{% endsnapshot %}