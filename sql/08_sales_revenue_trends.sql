-- ============================================================
-- OLIST E-COMMERCE ANALYTICS
-- Phase 3: Exploratory Data Analysis
-- Step 3.2: Sales & Revenue Trends
-- ============================================================


-- ============================================================
-- 1. MONTHLY SALES PERFORMANCE
-- ============================================================

SELECT
    DATE_TRUNC('month', order_purchase_timestamp) AS month,
    COUNT(*) AS total_orders,
    ROUND(SUM(product_revenue), 2) AS product_revenue,
    ROUND(SUM(total_freight), 2) AS freight,
    ROUND(SUM(item_total_value), 2) AS total_order_value,
    ROUND(AVG(item_total_value), 2) AS average_order_value
FROM orders_enriched
GROUP BY month
ORDER BY month;


-- ============================================================
-- 2. MONTHLY ORDER GROWTH
-- ============================================================

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', order_purchase_timestamp) AS month,
        COUNT(*) AS total_orders
    FROM orders_enriched
    GROUP BY month
)

SELECT
    month,
    total_orders,
    LAG(total_orders) OVER (
        ORDER BY month
    ) AS previous_month_orders,

    ROUND(
        (
            total_orders
            -
            LAG(total_orders) OVER (
                ORDER BY month
            )
        ) * 100.0
        /
        NULLIF(
            LAG(total_orders) OVER (
                ORDER BY month
            ),
            0
        ),
        2
    ) AS month_over_month_growth_pct

FROM monthly_sales
ORDER BY month;


-- ============================================================
-- 3. MONTHLY REVENUE GROWTH
-- ============================================================

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', order_purchase_timestamp) AS month,
        SUM(product_revenue) AS revenue
    FROM orders_enriched
    GROUP BY month
)

SELECT
    month,
    ROUND(revenue, 2) AS revenue,

    ROUND(
        LAG(revenue) OVER (
            ORDER BY month
        ),
        2
    ) AS previous_month_revenue,

    ROUND(
        (
            revenue
            -
            LAG(revenue) OVER (
                ORDER BY month
            )
        ) * 100.0
        /
        NULLIF(
            LAG(revenue) OVER (
                ORDER BY month
            ),
            0
        ),
        2
    ) AS month_over_month_growth_pct

FROM monthly_sales
ORDER BY month;


-- ============================================================
-- 4. TOP 5 MONTHS BY REVENUE
-- ============================================================

SELECT
    DATE_TRUNC('month', order_purchase_timestamp) AS month,
    ROUND(SUM(product_revenue), 2) AS revenue,
    COUNT(*) AS total_orders
FROM orders_enriched
GROUP BY month
ORDER BY revenue DESC
LIMIT 5;


-- ============================================================
-- 5. TOP 5 MONTHS BY ORDER VOLUME
-- ============================================================

SELECT
    DATE_TRUNC('month', order_purchase_timestamp) AS month,
    COUNT(*) AS total_orders,
    ROUND(SUM(product_revenue), 2) AS revenue
FROM orders_enriched
GROUP BY month
ORDER BY total_orders DESC
LIMIT 5;