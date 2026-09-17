CREATE OR REPLACE TABLE customer_90day_repeat_analysis AS

WITH first_orders AS (
    SELECT
        customer_unique_id,
        CAST(first_order_date AS DATE) AS first_order_date,
        DATE_TRUNC('month', first_order_date) AS acquisition_month
    FROM customer_retention_analysis
),

repeat_within_90_days AS (
    SELECT DISTINCT
        f.customer_unique_id
    FROM first_orders f

    JOIN orders_enriched o
        ON o.customer_unique_id = f.customer_unique_id

    WHERE
        CAST(o.order_purchase_timestamp AS DATE)
            > f.first_order_date

        AND CAST(o.order_purchase_timestamp AS DATE)
            <= f.first_order_date + INTERVAL 90 DAY
)

SELECT
    f.acquisition_month,

    COUNT(*) AS customers,

    COUNT(r.customer_unique_id) AS repeat_customers_90d,

    ROUND(
        100.0 * COUNT(r.customer_unique_id) / COUNT(*),
        2
    ) AS repeat_rate_90d

FROM first_orders f

LEFT JOIN repeat_within_90_days r
    ON f.customer_unique_id = r.customer_unique_id

GROUP BY f.acquisition_month

ORDER BY f.acquisition_month;