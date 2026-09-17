CREATE OR REPLACE TABLE revenue_concentration AS
WITH ranked_customers AS (
    SELECT
        customer_unique_id,
        total_spent,
        NTILE(100) OVER (ORDER BY total_spent DESC) AS percentile_group
    FROM customer_features
    WHERE customer_unique_id IS NOT NULL
),
total_revenue AS (
    SELECT
        SUM(total_spent) AS total_customer_revenue
    FROM ranked_customers
),
concentration AS (

    SELECT
        'Top 1%' AS customer_group,
        1 AS sort_order,
        COUNT(*) AS customer_count,
        ROUND(SUM(total_spent), 2) AS revenue,
        ROUND(
            100.0 * SUM(total_spent) / MAX(total_customer_revenue),
            2
        ) AS revenue_share_pct
    FROM ranked_customers, total_revenue
    WHERE percentile_group = 1

    UNION ALL

    SELECT
        'Top 5%',
        2,
        COUNT(*),
        ROUND(SUM(total_spent), 2),
        ROUND(
            100.0 * SUM(total_spent) / MAX(total_customer_revenue),
            2
        )
    FROM ranked_customers, total_revenue
    WHERE percentile_group <= 5

    UNION ALL

    SELECT
        'Top 10%',
        3,
        COUNT(*),
        ROUND(SUM(total_spent), 2),
        ROUND(
            100.0 * SUM(total_spent) / MAX(total_customer_revenue),
            2
        )
    FROM ranked_customers, total_revenue
    WHERE percentile_group <= 10

    UNION ALL

    SELECT
        'Top 20%',
        4,
        COUNT(*),
        ROUND(SUM(total_spent), 2),
        ROUND(
            100.0 * SUM(total_spent) / MAX(total_customer_revenue),
            2
        )
    FROM ranked_customers, total_revenue
    WHERE percentile_group <= 20

    UNION ALL

    SELECT
        'Remaining 80%',
        5,
        COUNT(*),
        ROUND(SUM(total_spent), 2),
        ROUND(
            100.0 * SUM(total_spent) / MAX(total_customer_revenue),
            2
        )
    FROM ranked_customers, total_revenue
    WHERE percentile_group > 20
)

SELECT
    customer_group,
    customer_count,
    revenue,
    revenue_share_pct
FROM concentration
ORDER BY sort_order;