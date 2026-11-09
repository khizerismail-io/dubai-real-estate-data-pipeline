{% macro deduplicate_by(model_ref, partition_col, order_col='bronze_loaded_at') %}
    with ranked as (
        select
            *,
            row_number() over (
                partition by {{ partition_col }}
                order by {{ order_col }} desc
            ) as _dedupe_rn
        from {{ model_ref }}
    )
    select * exclude (_dedupe_rn)
    from ranked
    where _dedupe_rn = 1
{% endmacro %}