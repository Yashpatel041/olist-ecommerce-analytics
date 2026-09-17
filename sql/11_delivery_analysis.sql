-- ============================================================
-- OLIST E-COMMERCE ANALYTICS
-- Phase 3: Exploratory Data Analysis
-- Step 3.5: Delivery Analysis
-- ============================================================


-- ============================================================
-- 1. OVERALL DELIVERY PERFORMANCE
-- ============================================================

SELECT
    COUNT(*) FILTER (
        WHERE delivery_days IS NOT NULL
    ) AS delivered_orders,

    ROUND(
        AVG(delivery_days),
        2
    ) AS average_delivery_days,

    ROUND(
        MEDIAN(delivery_days),
        2
    ) AS median_delivery_days,

    ROUND(
        MIN(delivery_days),
        2
    ) AS minimum_delivery_days,

    ROUND(
        MAX(delivery_days),
        2
    ) AS maximum_delivery_days

FROM orders_enriched

WHERE order_status = 'delivered';


-- ============================================================
-- 2. ON-TIME VS LATE ORDERS
-- ============================================================

SELECT
    CASE
        WHEN delivered_on_time = TRUE
            THEN 'On Time'
        WHEN delivered_on_time = FALSE
            THEN 'Late'
        ELSE 'Unknown'
    END AS delivery_status,

    COUNT(*) AS order_count,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_orders

FROM orders_enriched

WHERE order_status = 'delivered'

GROUP BY delivery_status

ORDER BY order_count DESC;


-- ============================================================
-- 3. DELIVERY DELAY DISTRIBUTION
-- ============================================================

SELECT
    CASE
        WHEN delivery_variance_days <= 0
            THEN 'On Time / Early'

        WHEN delivery_variance_days BETWEEN 1 AND 3
            THEN '1-3 Days Late'

        WHEN delivery_variance_days BETWEEN 4 AND 7
            THEN '4-7 Days Late'

        WHEN delivery_variance_days BETWEEN 8 AND 14
            THEN '8-14 Days Late'

        ELSE '15+ Days Late'
    END AS delay_segment,

    COUNT(*) AS order_count,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_orders

FROM orders_enriched

WHERE
    order_status = 'delivered'
    AND delivery_variance_days IS NOT NULL

GROUP BY delay_segment

ORDER BY
    CASE delay_segment
        WHEN 'On Time / Early' THEN 1
        WHEN '1-3 Days Late' THEN 2
        WHEN '4-7 Days Late' THEN 3
        WHEN '8-14 Days Late' THEN 4
        WHEN '15+ Days Late' THEN 5
    END;


-- ============================================================
-- 4. AVERAGE DELAY
-- ============================================================

SELECT
    ROUND(
        AVG(delivery_variance_days),
        2
    ) AS average_delivery_variance_days,

    ROUND(
        MEDIAN(delivery_variance_days),
        2
    ) AS median_delivery_variance_days,

    ROUND(
        AVG(delivery_variance_days)
        FILTER (
            WHERE delivery_variance_days > 0
        ),
        2
    ) AS average_delay_when_late

FROM orders_enriched

WHERE
    order_status = 'delivered'
    AND delivery_variance_days IS NOT NULL;


-- ============================================================
-- 5. MONTHLY DELIVERY PERFORMANCE
-- ============================================================

SELECT
    DATE_TRUNC(
        'month',
        order_purchase_timestamp
    ) AS month,

    COUNT(*) AS delivered_orders,

    ROUND(
        AVG(delivery_days),
        2
    ) AS average_delivery_days,

    ROUND(
        AVG(delivery_variance_days),
        2
    ) AS average_delivery_variance_days,

    COUNT(*) FILTER (
        WHERE delivered_on_time = TRUE
    ) AS on_time_orders,

    COUNT(*) FILTER (
        WHERE delivered_on_time = FALSE
    ) AS late_orders,

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
    ) AS on_time_rate

FROM orders_enriched

WHERE order_status = 'delivered'

GROUP BY month

ORDER BY month;


-- ============================================================
-- 6. WORST 10 MONTHS BY ON-TIME DELIVERY RATE
-- ============================================================

SELECT
    DATE_TRUNC(
        'month',
        order_purchase_timestamp
    ) AS month,

    COUNT(*) AS delivered_orders,

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
    ) AS on_time_rate,

    ROUND(
        AVG(delivery_variance_days),
        2
    ) AS average_delivery_variance_days

FROM orders_enriched

WHERE
    order_status = 'delivered'
    AND delivered_on_time IS NOT NULL

GROUP BY month

HAVING COUNT(*) >= 100

ORDER BY on_time_rate ASC

LIMIT 10;


-- ============================================================
-- 7. DELIVERY PERFORMANCE BY CATEGORY
-- ============================================================

SELECT
    COALESCE(
        oi.product_category_name_english,
        'Unknown Category'
    ) AS category,

    COUNT(DISTINCT oe.order_id) AS delivered_orders,

    ROUND(
        AVG(oe.delivery_days),
        2
    ) AS average_delivery_days,

    ROUND(
        AVG(oe.delivery_variance_days),
        2
    ) AS average_delivery_variance_days,

    ROUND(
        COUNT(DISTINCT oe.order_id)
        FILTER (
            WHERE oe.delivered_on_time = TRUE
        ) * 100.0
        /
        NULLIF(
            COUNT(DISTINCT oe.order_id)
            FILTER (
                WHERE oe.delivered_on_time IS NOT NULL
            ),
            0
        ),
        2
    ) AS on_time_rate

FROM orders_enriched oe

JOIN order_items_enriched oi
    ON oe.order_id = oi.order_id

WHERE
    oe.order_status = 'delivered'
    AND oe.delivery_days IS NOT NULL

GROUP BY category

HAVING COUNT(DISTINCT oe.order_id) >= 100

ORDER BY on_time_rate ASC

LIMIT 15;


-- ============================================================
-- 8. DELIVERY STATUS VS REVIEW SCORE
-- ============================================================

SELECT
    CASE
        WHEN oe.delivered_on_time = TRUE
            THEN 'On Time'
        WHEN oe.delivered_on_time = FALSE
            THEN 'Late'
        ELSE 'Unknown'
    END AS delivery_status,

    COUNT(DISTINCT oe.order_id) AS orders,

    ROUND(
        AVG(ors.average_review_score),
        2
    ) AS average_review_score

FROM orders_enriched oe

LEFT JOIN order_review_summary ors
    ON oe.order_id = ors.order_id

WHERE
    oe.order_status = 'delivered'
    AND oe.delivered_on_time IS NOT NULL
    AND ors.average_review_score IS NOT NULL

GROUP BY delivery_status

ORDER BY delivery_status;