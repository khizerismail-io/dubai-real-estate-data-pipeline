WITH annual_summary AS (
    SELECT
        transaction_year,
        broker_gender,
        ROUND(SUM(transaction_amount_aed), 2) AS total_sales_aed
    FROM {{ ref('fct_property_sales') }}
    WHERE broker_gender IN ('MALE', 'FEMALE')
      AND transaction_year IS NOT NULL
    GROUP BY transaction_year, broker_gender
)
SELECT
    transaction_year,
    broker_gender,
    total_sales_aed,
    ROUND(
        (total_sales_aed - LAG(total_sales_aed) OVER (PARTITION BY broker_gender ORDER BY transaction_year))
        / NULLIF(LAG(total_sales_aed) OVER (PARTITION BY broker_gender ORDER BY transaction_year), 0) * 100,
        2
    ) AS yoy_growth_pct
FROM annual_summary
ORDER BY transaction_year ASC, broker_gender;