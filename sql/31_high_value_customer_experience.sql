CREATE OR REPLACE TABLE high_value_customer_experience AS

WITH customer_tiers AS (
    SELECT
        customer_unique_id,
        CASE
            WHEN total_spent < 100 THEN 'Low Value'
            WHEN total_spent < 250 THEN 'Medium Value'
            WHEN total_spent < 500 THEN 'High Value'
            ELSE 'Very High Value'
        END AS value_tier
    FROM customer_features
    WHERE customer_unique_id IS NOT NULL
),

order_experience AS (
    SELECT
        o.customer_unique_id,
        o.order_id,
        o.delivered_on_time,
        o.average_review_score,
        o.delivery_variance_days
    FROM orders_enriched o
    INNER JOIN customer_tiers c
        ON o.customer_unique_id = c.customer_unique_id
    WHERE o.customer_unique_id IS NOT NULL
),

experience_summary AS (
    SELECT
        c.value_tier,

        CASE
            WHEN o.delivered_on_time = TRUE THEN 'On-Time'
            WHEN o.delivered_on_time = FALSE THEN 'Late'
            ELSE 'Unknown'
        END AS delivery_status,

        COUNT(*) AS order_count,

        ROUND(
            AVG(o.average_review_score),
            2
        ) AS avg_review_score,

        ROUND(
            100.0 * SUM(
                CASE
                    WHEN o.average_review_score <= 2 THEN 1
                    ELSE 0
                END
            )
            / NULLIF(
                SUM(
                    CASE
                        WHEN o.average_review_score IS NOT NULL THEN 1
                        ELSE 0
                    END
                ),
                0
            ),
            2
        ) AS low_rating_rate_pct,

        ROUND(
            AVG(
                CASE
                    WHEN o.delivered_on_time = FALSE
                    THEN o.delivery_variance_days
                    ELSE NULL
                END
            ),
            2
        ) AS avg_delay_days

    FROM order_experience o
    INNER JOIN customer_tiers c
        ON o.customer_unique_id = c.customer_unique_id

    GROUP BY
        c.value_tier,
        CASE
            WHEN o.delivered_on_time = TRUE THEN 'On-Time'
            WHEN o.delivered_on_time = FALSE THEN 'Late'
            ELSE 'Unknown'
        END
)

SELECT
    value_tier,
    delivery_status,
    order_count,

    ROUND(
        100.0 * order_count
        / SUM(order_count) OVER (
            PARTITION BY value_tier
        ),
        2
    ) AS order_share_pct,

    avg_review_score,
    low_rating_rate_pct,
    avg_delay_days

FROM experience_summary

ORDER BY
    CASE value_tier
        WHEN 'Low Value' THEN 1
        WHEN 'Medium Value' THEN 2
        WHEN 'High Value' THEN 3
        WHEN 'Very High Value' THEN 4
        ELSE 5
    END,

    CASE delivery_status
        WHEN 'On-Time' THEN 1
        WHEN 'Late' THEN 2
        ELSE 3
    END;