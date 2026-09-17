CREATE OR REPLACE TABLE revenue_vs_satisfaction AS

WITH customer_value AS (
    SELECT
        customer_unique_id,
        total_spent,
        total_orders,
        late_orders,
        late_rate,
        avg_delivery_days,
        avg_review_score,
        low_rating_orders,

        CASE
            WHEN total_spent < 100 THEN 'Low Value'
            WHEN total_spent < 250 THEN 'Medium Value'
            WHEN total_spent < 500 THEN 'High Value'
            ELSE 'Very High Value'
        END AS value_tier

    FROM customer_features
    WHERE customer_unique_id IS NOT NULL
)

SELECT
    value_tier,

    COUNT(*) AS customer_count,

    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_share_pct,

    ROUND(AVG(total_spent), 2) AS avg_customer_spend,

    ROUND(AVG(total_orders), 2) AS avg_orders,

    ROUND(AVG(late_rate), 2) AS avg_late_rate_pct,

    ROUND(AVG(avg_delivery_days), 2) AS avg_delivery_days,

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

FROM customer_value

GROUP BY value_tier

ORDER BY
    CASE value_tier
        WHEN 'Low Value' THEN 1
        WHEN 'Medium Value' THEN 2
        WHEN 'High Value' THEN 3
        WHEN 'Very High Value' THEN 4
    END;