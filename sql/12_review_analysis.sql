-- ============================================================
-- PHASE 3.6: REVIEW ANALYSIS
-- ============================================================


-- ============================================================
-- QUERY 1: Review Score Distribution
-- ============================================================

SELECT
    average_review_score,
    COUNT(*) AS order_count,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM orders_enriched
WHERE average_review_score IS NOT NULL
GROUP BY average_review_score
ORDER BY average_review_score;


-- ============================================================
-- QUERY 2: Review Score Distribution by Score
-- ============================================================

SELECT
    review_score,
    COUNT(*) AS reviewed_orders,
    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM (
    SELECT
        order_id,
        average_review_score::INTEGER AS review_score
    FROM orders_enriched
    WHERE average_review_score IS NOT NULL
)
GROUP BY review_score
ORDER BY review_score;


-- ============================================================
-- QUERY 3: Average Review Score
-- ============================================================

SELECT
    ROUND(AVG(average_review_score), 2) AS average_review_score,
    COUNT(*) AS reviewed_orders
FROM orders_enriched
WHERE average_review_score IS NOT NULL;


-- ============================================================
-- QUERY 4: Review Score vs Delivery Performance
-- ============================================================

SELECT
    CASE
        WHEN delivered_on_time = TRUE THEN 'On Time'
        WHEN delivered_on_time = FALSE THEN 'Late'
        ELSE 'Unknown'
    END AS delivery_status,
    COUNT(*) AS reviewed_orders,
    ROUND(AVG(average_review_score), 2) AS avg_review_score
FROM orders_enriched
WHERE average_review_score IS NOT NULL
GROUP BY delivery_status
ORDER BY avg_review_score DESC;


-- ============================================================
-- QUERY 5: Review Score by Delay Severity
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
        WHEN delivery_variance_days >= 15
            THEN '15+ Days Late'
        ELSE 'Unknown'
    END AS delay_category,

    COUNT(*) AS reviewed_orders,

    ROUND(
        AVG(average_review_score),
        2
    ) AS avg_review_score

FROM orders_enriched
WHERE average_review_score IS NOT NULL

GROUP BY delay_category

ORDER BY
    CASE delay_category
        WHEN 'On Time / Early' THEN 1
        WHEN '1-3 Days Late' THEN 2
        WHEN '4-7 Days Late' THEN 3
        WHEN '8-14 Days Late' THEN 4
        WHEN '15+ Days Late' THEN 5
        ELSE 6
    END;


-- ============================================================
-- QUERY 6: Review Comments Availability
-- ============================================================

SELECT
    CASE
        WHEN reviews_with_comments > 0
            THEN 'Has Comment'
        ELSE 'No Comment'
    END AS comment_status,

    COUNT(*) AS reviewed_orders,

    ROUND(
        AVG(average_review_score),
        2
    ) AS avg_review_score

FROM orders_enriched
WHERE average_review_score IS NOT NULL

GROUP BY comment_status
ORDER BY comment_status;


-- ============================================================
-- QUERY 7: Low-Rated Orders
-- ============================================================

SELECT
    average_review_score,
    COUNT(*) AS reviewed_orders,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage

FROM orders_enriched

WHERE average_review_score <= 2

GROUP BY average_review_score

ORDER BY average_review_score;


-- ============================================================
-- QUERY 8: Review Score by Order Status
-- ============================================================

SELECT
    order_status,
    COUNT(*) AS reviewed_orders,

    ROUND(
        AVG(average_review_score),
        2
    ) AS avg_review_score

FROM orders_enriched

WHERE average_review_score IS NOT NULL

GROUP BY order_status

ORDER BY avg_review_score;


-- ============================================================
-- QUERY 9: Monthly Review Performance
-- ============================================================

SELECT
    DATE_TRUNC(
        'month',
        order_purchase_timestamp
    ) AS month,

    COUNT(*) AS reviewed_orders,

    ROUND(
        AVG(average_review_score),
        2
    ) AS avg_review_score,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN average_review_score <= 2
                    THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS low_rating_rate

FROM orders_enriched

WHERE average_review_score IS NOT NULL

GROUP BY month

ORDER BY month;


-- ============================================================
-- QUERY 10: Review Performance by Category
-- Minimum 100 reviewed orders
-- ============================================================

WITH category_review AS (

    SELECT
        product_category_name_english AS category,
        oi.order_id AS order_id,

        AVG(average_review_score) AS review_score

    FROM order_items_enriched oi

    JOIN orders_enriched o
        ON oi.order_id = o.order_id

    WHERE o.average_review_score IS NOT NULL

    GROUP BY
        category,
        oi.order_id
)

SELECT
    category,

    COUNT(*) AS reviewed_orders,

    ROUND(
        AVG(review_score),
        2
    ) AS avg_review_score,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN review_score <= 2
                    THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS low_rating_rate

FROM category_review

GROUP BY category

HAVING COUNT(*) >= 100

ORDER BY avg_review_score ASC;

-- ============================================================
-- QUERY 11: Review Score by Delivery Status
-- Focus on reviewed orders only
-- ============================================================

SELECT
    delivered_on_time,

    COUNT(*) AS reviewed_orders,

    ROUND(
        AVG(average_review_score),
        2
    ) AS avg_review_score,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN average_review_score <= 2
                    THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS low_rating_rate

FROM orders_enriched

WHERE
    average_review_score IS NOT NULL
    AND delivered_on_time IS NOT NULL

GROUP BY delivered_on_time

ORDER BY delivered_on_time DESC;


-- ============================================================
-- QUERY 12: Severe Delay and Low Review Relationship
-- ============================================================

SELECT
    CASE
        WHEN delivery_variance_days <= 0
            THEN 'On Time / Early'
        WHEN delivery_variance_days BETWEEN 1 AND 7
            THEN '1-7 Days Late'
        WHEN delivery_variance_days BETWEEN 8 AND 14
            THEN '8-14 Days Late'
        WHEN delivery_variance_days >= 15
            THEN '15+ Days Late'
        ELSE 'Unknown'
    END AS delay_group,

    COUNT(*) AS reviewed_orders,

    ROUND(
        AVG(average_review_score),
        2
    ) AS avg_review_score,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN average_review_score <= 2
                    THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS low_rating_rate

FROM orders_enriched

WHERE average_review_score IS NOT NULL

GROUP BY delay_group

ORDER BY
    CASE delay_group
        WHEN 'On Time / Early' THEN 1
        WHEN '1-7 Days Late' THEN 2
        WHEN '8-14 Days Late' THEN 3
        WHEN '15+ Days Late' THEN 4
        ELSE 5
    END;