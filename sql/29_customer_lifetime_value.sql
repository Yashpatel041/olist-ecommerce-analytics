CREATE OR REPLACE TABLE customer_lifetime_value AS

WITH customer_clv AS (
    SELECT
        customer_unique_id,
        total_orders,
        first_order_date,
        last_order_date,
        customer_lifetime_days,
        total_spent,
        avg_order_value
    FROM customer_features
    WHERE customer_unique_id IS NOT NULL
),

clv_summary AS (
    SELECT
        CASE
            WHEN total_orders = 1 THEN '1 Order'
            WHEN total_orders = 2 THEN '2 Orders'
            WHEN total_orders = 3 THEN '3 Orders'
            WHEN total_orders >= 4 THEN '4+ Orders'
        END AS purchase_frequency_group,

        COUNT(*) AS customer_count,

        ROUND(AVG(total_spent), 2) AS avg_clv,

        ROUND(
            PERCENTILE_CONT(0.50)
            WITHIN GROUP (ORDER BY total_spent),
            2
        ) AS median_clv,

        ROUND(SUM(total_spent), 2) AS total_revenue,

        ROUND(AVG(customer_lifetime_days), 2) AS avg_lifetime_days,

        ROUND(AVG(avg_order_value), 2) AS avg_order_value

    FROM customer_clv

    GROUP BY
        CASE
            WHEN total_orders = 1 THEN '1 Order'
            WHEN total_orders = 2 THEN '2 Orders'
            WHEN total_orders = 3 THEN '3 Orders'
            WHEN total_orders >= 4 THEN '4+ Orders'
        END
),

total_revenue AS (
    SELECT
        SUM(total_spent) AS overall_revenue
    FROM customer_clv
)

SELECT
    purchase_frequency_group,
    customer_count,
    ROUND(
        100.0 * customer_count
        / SUM(customer_count) OVER (),
        2
    ) AS customer_share_pct,
    avg_clv,
    median_clv,
    total_revenue,
    ROUND(
        100.0 * total_revenue / overall_revenue,
        2
    ) AS revenue_share_pct,
    avg_lifetime_days,
    avg_order_value
FROM clv_summary
CROSS JOIN total_revenue

ORDER BY
    CASE purchase_frequency_group
        WHEN '1 Order' THEN 1
        WHEN '2 Orders' THEN 2
        WHEN '3 Orders' THEN 3
        WHEN '4+ Orders' THEN 4
    END;