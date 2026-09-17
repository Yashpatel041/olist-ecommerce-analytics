CREATE OR REPLACE TABLE temporal_churn_population AS

WITH eligible_customers AS (
    SELECT DISTINCT
        customer_unique_id
    FROM orders_enriched
    WHERE
        customer_unique_id IS NOT NULL
        AND CAST(order_purchase_timestamp AS DATE)
            <= DATE '2018-02-28'
),

future_activity AS (
    SELECT DISTINCT
        customer_unique_id
    FROM orders_enriched
    WHERE
        customer_unique_id IS NOT NULL
        AND CAST(order_purchase_timestamp AS DATE)
            > DATE '2018-02-28'
        AND CAST(order_purchase_timestamp AS DATE)
            <= DATE '2018-08-29'
)

SELECT
    e.customer_unique_id,

    CASE
        WHEN f.customer_unique_id IS NULL THEN 1
        ELSE 0
    END AS churned

FROM eligible_customers e

LEFT JOIN future_activity f
    ON e.customer_unique_id = f.customer_unique_id;