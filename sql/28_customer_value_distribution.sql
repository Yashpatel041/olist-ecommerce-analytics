CREATE OR REPLACE TABLE customer_value_distribution AS

WITH customer_stats AS (
    SELECT
        customer_unique_id,
        total_spent
    FROM customer_features
    WHERE customer_unique_id IS NOT NULL
),

spending_stats AS (
    SELECT
        COUNT(*) AS customer_count,
        MIN(total_spent) AS min_spend,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_spent) AS q1_spend,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY total_spent) AS median_spend,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_spent) AS q3_spend,
        AVG(total_spent) AS avg_spend,
        MAX(total_spent) AS max_spend
    FROM customer_stats
),

total_revenue AS (
    SELECT
        SUM(total_spent) AS total_customer_revenue
    FROM customer_stats
),

tier_summary AS (
    SELECT
        CASE
            WHEN total_spent < 100 THEN 'Low Value'
            WHEN total_spent < 250 THEN 'Medium Value'
            WHEN total_spent < 500 THEN 'High Value'
            ELSE 'Very High Value'
        END AS value_tier,
        COUNT(*) AS customer_count,
        ROUND(SUM(total_spent), 2) AS revenue,
        ROUND(AVG(total_spent), 2) AS avg_customer_spend
    FROM customer_stats
    GROUP BY
        CASE
            WHEN total_spent < 100 THEN 'Low Value'
            WHEN total_spent < 250 THEN 'Medium Value'
            WHEN total_spent < 500 THEN 'High Value'
            ELSE 'Very High Value'
        END
)

SELECT
    'Overall Distribution' AS analysis_type,
    NULL AS value_tier,
    customer_count,
    ROUND(min_spend, 2) AS min_spend,
    ROUND(q1_spend, 2) AS q1_spend,
    ROUND(median_spend, 2) AS median_spend,
    ROUND(q3_spend, 2) AS q3_spend,
    ROUND(avg_spend, 2) AS avg_spend,
    ROUND(max_spend, 2) AS max_spend,
    NULL AS revenue,
    NULL AS revenue_share_pct,
    NULL AS avg_customer_spend
FROM spending_stats

UNION ALL

SELECT
    'Value Tier' AS analysis_type,
    ts.value_tier,
    ts.customer_count,
    NULL AS min_spend,
    NULL AS q1_spend,
    NULL AS median_spend,
    NULL AS q3_spend,
    NULL AS avg_spend,
    NULL AS max_spend,
    ts.revenue,
    ROUND(
        100.0 * ts.revenue / tr.total_customer_revenue,
        2
    ) AS revenue_share_pct,
    ts.avg_customer_spend
FROM tier_summary ts
CROSS JOIN total_revenue tr;