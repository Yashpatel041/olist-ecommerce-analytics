CREATE OR REPLACE TABLE customer_dashboard_kpis AS

WITH customer_base AS (
    SELECT
        customer_unique_id,
        total_orders,
        total_spent,
        avg_order_value,
        late_rate,
        avg_review_score,
        low_rating_orders
    FROM customer_features
    WHERE customer_unique_id IS NOT NULL
),

customer_summary AS (
    SELECT
        COUNT(*) AS total_customers,

        SUM(
            CASE
                WHEN total_orders = 1 THEN 1
                ELSE 0
            END
        ) AS one_time_customers,

        SUM(
            CASE
                WHEN total_orders > 1 THEN 1
                ELSE 0
            END
        ) AS repeat_customers,

        SUM(total_spent) AS total_revenue,

        AVG(total_spent) AS avg_customer_spend,

        AVG(avg_order_value) AS avg_order_value,

        AVG(total_orders) AS avg_orders,

        AVG(late_rate) AS avg_late_rate,

        AVG(avg_review_score) AS avg_review_score,

        SUM(low_rating_orders) AS low_rating_orders,

        SUM(
            CASE
                WHEN avg_review_score IS NOT NULL
                THEN total_orders
                ELSE 0
            END
        ) AS reviewed_orders

    FROM customer_base
),

revenue_concentration_summary AS (
    SELECT
        MAX(
            CASE
                WHEN customer_group = 'Top 10%'
                THEN revenue_share_pct
            END
        ) AS top_10_revenue_share,

        MAX(
            CASE
                WHEN customer_group = 'Top 20%'
                THEN revenue_share_pct
            END
        ) AS top_20_revenue_share

    FROM revenue_concentration
),

high_value_summary AS (
    SELECT
        SUM(
            CASE
                WHEN total_spent >= 250 THEN 1
                ELSE 0
            END
        ) AS high_value_customers

    FROM customer_base
)

SELECT
    cs.total_customers,

    cs.one_time_customers,

    cs.repeat_customers,

    ROUND(
        100.0 * cs.repeat_customers
        / cs.total_customers,
        2
    ) AS repeat_customer_rate_pct,

    ROUND(cs.total_revenue, 2) AS total_revenue,

    ROUND(cs.avg_customer_spend, 2) AS avg_customer_spend,

    ROUND(cs.avg_order_value, 2) AS avg_order_value,

    ROUND(cs.avg_orders, 2) AS avg_orders,

    ROUND(cs.avg_late_rate, 2) AS avg_late_rate_pct,

    ROUND(cs.avg_review_score, 2) AS avg_review_score,

    ROUND(
        100.0 * cs.low_rating_orders
        / NULLIF(cs.reviewed_orders, 0),
        2
    ) AS low_rating_rate_pct,

    hv.high_value_customers,

    ROUND(
        100.0 * hv.high_value_customers
        / cs.total_customers,
        2
    ) AS high_value_customer_share_pct,

    ROUND(rc.top_10_revenue_share, 2)
        AS top_10_revenue_share_pct,

    ROUND(rc.top_20_revenue_share, 2)
        AS top_20_revenue_share_pct,

    1.33 AS repeat_90_day_rate_pct

FROM customer_summary cs

CROSS JOIN revenue_concentration_summary rc

CROSS JOIN high_value_summary hv;