-- ============================================================
-- OLIST E-COMMERCE ANALYTICS
-- Phase 3: Exploratory Data Analysis
-- Step 3.1: Overall Business KPIs
-- ============================================================


-- ============================================================
-- 1. OVERALL BUSINESS KPIs
-- ============================================================

SELECT
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_unique_id) AS total_customers,

    (
        SELECT COUNT(DISTINCT product_id)
        FROM order_items_enriched
    ) AS total_products,

    (
        SELECT COUNT(DISTINCT seller_id)
        FROM order_items_enriched
    ) AS total_sellers,

    ROUND(SUM(product_revenue), 2) AS total_product_revenue,
    ROUND(SUM(total_freight), 2) AS total_freight,
    ROUND(SUM(item_total_value), 2) AS total_order_value
FROM orders_enriched;


-- ============================================================
-- 2. AVERAGE ORDER VALUE
-- ============================================================

SELECT
    ROUND(AVG(item_total_value), 2) AS average_order_value
FROM orders_enriched
WHERE item_total_value IS NOT NULL;


-- ============================================================
-- 3. AVERAGE ITEMS PER ORDER
-- ============================================================

SELECT
    ROUND(AVG(total_items), 2) AS average_items_per_order
FROM orders_enriched
WHERE total_items IS NOT NULL;


-- ============================================================
-- 4. ORDER STATUS DISTRIBUTION
-- ============================================================

SELECT
    order_status,
    COUNT(*) AS order_count,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_orders
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;


-- ============================================================
-- 5. DELIVERED ORDER RATE
-- ============================================================

SELECT
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
    ) AS delivered_orders,
    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
        ) * 100.0 / COUNT(*),
        2
    ) AS delivered_rate
FROM orders;


-- ============================================================
-- 6. AVERAGE REVIEW SCORE
-- ============================================================

SELECT
    ROUND(AVG(average_review_score), 2) AS average_review_score
FROM orders_enriched
WHERE average_review_score IS NOT NULL;


-- ============================================================
-- 7. ON-TIME DELIVERY RATE
-- ============================================================

SELECT
    COUNT(*) FILTER (
        WHERE delivered_on_time IS NOT NULL
    ) AS orders_with_delivery_result,

    COUNT(*) FILTER (
        WHERE delivered_on_time = TRUE
    ) AS on_time_orders,

    ROUND(
        COUNT(*) FILTER (
            WHERE delivered_on_time = TRUE
        ) * 100.0
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE delivered_on_time IS NOT NULL
            ),
            0
        ),
        2
    ) AS on_time_delivery_rate
FROM orders_enriched;


-- ============================================================
-- 8. PAYMENT VALUE VS PRODUCT + FREIGHT
-- ============================================================

SELECT
    ROUND(SUM(product_revenue), 2) AS product_revenue,
    ROUND(SUM(total_freight), 2) AS freight,
    ROUND(SUM(item_total_value), 2) AS item_plus_freight,
    ROUND(
        (
            SELECT SUM(total_payment_value)
            FROM order_payment_summary
        ),
        2
    ) AS total_payment_value
FROM orders_enriched;