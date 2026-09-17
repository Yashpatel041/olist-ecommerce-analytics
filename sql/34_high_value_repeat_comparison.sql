CREATE OR REPLACE TABLE high_value_repeat_comparison AS

WITH high_value_customers AS (
    SELECT
        customer_unique_id,
        total_orders,
        total_spent,
        avg_order_value,
        total_items,
        unique_sellers,
        late_rate,
        avg_delivery_days,
        avg_delivery_delay,
        avg_review_score,
        low_rating_orders,

        CASE
            WHEN total_orders = 1
                THEN 'High-Value One-Time'
            ELSE 'High-Value Repeat'
        END AS customer_segment

    FROM customer_features
    WHERE customer_unique_id IS NOT NULL
      AND total_spent >= 250
)

SELECT
    customer_segment,

    COUNT(*) AS customer_count,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_share_pct,

    ROUND(AVG(total_orders), 2) AS avg_orders,

    ROUND(AVG(total_spent), 2) AS avg_customer_spend,

    ROUND(AVG(avg_order_value), 2) AS avg_order_value,

    ROUND(AVG(total_items), 2) AS avg_items,

    ROUND(AVG(unique_sellers), 2) AS avg_sellers,

    ROUND(AVG(late_rate), 2) AS avg_late_rate_pct,

    ROUND(AVG(avg_delivery_days), 2) AS avg_delivery_days,

    ROUND(AVG(avg_delivery_delay), 2) AS avg_delivery_delay,

    ROUND(AVG(avg_review_score), 2) AS avg_review_score,

    ROUND(
        100.0 * SUM(low_rating_orders)
        / NULLIF(
            SUM(
                CASE
                    WHEN avg_review_score IS NOT NULL
                    THEN total_orders
                    ELSE 0
                END
            ),
            0
        ),
        2
    ) AS low_rating_rate_pct

FROM high_value_customers

GROUP BY customer_segment

ORDER BY
    CASE customer_segment
        WHEN 'High-Value One-Time' THEN 1
        WHEN 'High-Value Repeat' THEN 2
    END;