-- ============================================================
-- OLIST E-COMMERCE ANALYTICS
-- Phase 3: Exploratory Data Analysis
-- Step 3.4: Customer Analysis
-- ============================================================


-- ============================================================
-- 1. CUSTOMER ORDER FREQUENCY
-- ============================================================

WITH customer_orders AS (
    SELECT
        customer_unique_id,
        COUNT(DISTINCT order_id) AS total_orders
    FROM orders_enriched
    GROUP BY customer_unique_id
)

SELECT
    total_orders,
    COUNT(*) AS customer_count,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_customers
FROM customer_orders
GROUP BY total_orders
ORDER BY total_orders;


-- ============================================================
-- 2. ONE-TIME VS REPEAT CUSTOMERS
-- ============================================================

WITH customer_orders AS (
    SELECT
        customer_unique_id,
        COUNT(DISTINCT order_id) AS total_orders
    FROM orders_enriched
    GROUP BY customer_unique_id
)

SELECT
    CASE
        WHEN total_orders = 1 THEN 'One-time Customer'
        ELSE 'Repeat Customer'
    END AS customer_type,

    COUNT(*) AS customer_count,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_customers

FROM customer_orders

GROUP BY customer_type

ORDER BY customer_count DESC;


-- ============================================================
-- 3. REVENUE: ONE-TIME VS REPEAT CUSTOMERS
-- ============================================================

WITH customer_orders AS (
    SELECT
        customer_unique_id,
        COUNT(DISTINCT order_id) AS total_orders
    FROM orders_enriched
    GROUP BY customer_unique_id
),

customer_revenue AS (
    SELECT
        oe.customer_unique_id,
        co.total_orders,
        SUM(oe.item_total_value) AS total_spend
    FROM orders_enriched oe
    JOIN customer_orders co
        ON oe.customer_unique_id = co.customer_unique_id
    GROUP BY
        oe.customer_unique_id,
        co.total_orders
)

SELECT
    CASE
        WHEN total_orders = 1 THEN 'One-time Customer'
        ELSE 'Repeat Customer'
    END AS customer_type,

    COUNT(*) AS customer_count,

    ROUND(SUM(total_spend), 2) AS total_revenue,

    ROUND(AVG(total_spend), 2) AS average_customer_spend,

    ROUND(
        SUM(total_spend) * 100.0 /
        SUM(SUM(total_spend)) OVER (),
        2
    ) AS percentage_of_revenue

FROM customer_revenue

GROUP BY customer_type

ORDER BY total_revenue DESC;


-- ============================================================
-- 4. CUSTOMER VALUE DISTRIBUTION
-- ============================================================

WITH customer_value AS (
    SELECT
        customer_unique_id,
        COUNT(DISTINCT order_id) AS total_orders,
        ROUND(SUM(item_total_value), 2) AS total_spend
    FROM orders_enriched
    GROUP BY customer_unique_id
)

SELECT
    CASE
        WHEN total_spend < 100 THEN 'Under 100'
        WHEN total_spend < 250 THEN '100 - 249'
        WHEN total_spend < 500 THEN '250 - 499'
        WHEN total_spend < 1000 THEN '500 - 999'
        ELSE '1000+'
    END AS spending_segment,

    COUNT(*) AS customer_count,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_customers

FROM customer_value

GROUP BY spending_segment

ORDER BY
    CASE spending_segment
        WHEN 'Under 100' THEN 1
        WHEN '100 - 249' THEN 2
        WHEN '250 - 499' THEN 3
        WHEN '500 - 999' THEN 4
        WHEN '1000+' THEN 5
    END;


-- ============================================================
-- 5. TOP 20 CUSTOMERS BY TOTAL SPEND
-- ============================================================

SELECT
    customer_unique_id,

    COUNT(DISTINCT order_id) AS total_orders,

    ROUND(SUM(item_total_value), 2) AS total_spend,

    ROUND(
        AVG(item_total_value),
        2
    ) AS average_order_value

FROM orders_enriched

GROUP BY customer_unique_id

ORDER BY total_spend DESC

LIMIT 20;


-- ============================================================
-- 6. TOP 20 CUSTOMERS BY NUMBER OF ORDERS
-- ============================================================

SELECT
    customer_unique_id,

    COUNT(DISTINCT order_id) AS total_orders,

    ROUND(SUM(item_total_value), 2) AS total_spend,

    ROUND(
        AVG(item_total_value),
        2
    ) AS average_order_value

FROM orders_enriched

GROUP BY customer_unique_id

ORDER BY total_orders DESC, total_spend DESC

LIMIT 20;


-- ============================================================
-- 7. CUSTOMER FIRST AND LAST PURCHASE
-- ============================================================

SELECT
    customer_unique_id,

    MIN(order_purchase_timestamp) AS first_purchase,

    MAX(order_purchase_timestamp) AS last_purchase,

    COUNT(DISTINCT order_id) AS total_orders,

    ROUND(SUM(item_total_value), 2) AS total_spend

FROM orders_enriched

GROUP BY customer_unique_id

ORDER BY last_purchase DESC

LIMIT 20;


-- ============================================================
-- 8. REPEAT PURCHASE INTERVAL
-- ============================================================

WITH customer_purchases AS (
    SELECT
        customer_unique_id,
        order_purchase_timestamp,

        LAG(order_purchase_timestamp) OVER (
            PARTITION BY customer_unique_id
            ORDER BY order_purchase_timestamp
        ) AS previous_purchase

    FROM orders_enriched
)

SELECT
    COUNT(*) AS repeat_purchase_events,

    ROUND(
        AVG(
            DATE_DIFF(
                'day',
                previous_purchase,
                order_purchase_timestamp
            )
        ),
        2
    ) AS average_days_between_purchases,

    ROUND(
        MEDIAN(
            DATE_DIFF(
                'day',
                previous_purchase,
                order_purchase_timestamp
            )
        ),
        2
    ) AS median_days_between_purchases

FROM customer_purchases

WHERE previous_purchase IS NOT NULL;