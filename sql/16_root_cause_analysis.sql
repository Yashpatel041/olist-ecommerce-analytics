-- ============================================================
-- PHASE 3.10: ROOT-CAUSE ANALYSIS
-- ============================================================


-- ============================================================
-- QUERY 1: Late Delivery vs Low Ratings
-- ============================================================

SELECT
    CASE
        WHEN delivered_on_time = TRUE THEN 'On Time'
        WHEN delivered_on_time = FALSE THEN 'Late'
        ELSE 'Unknown'
    END AS delivery_status,

    COUNT(*) AS reviewed_orders,

    ROUND(AVG(average_review_score), 2) AS avg_review_score,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN average_review_score <= 2 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS low_rating_rate

FROM orders_enriched

WHERE average_review_score IS NOT NULL

GROUP BY delivery_status

ORDER BY avg_review_score;


-- ============================================================
-- QUERY 2: Delay Severity vs Customer Satisfaction
-- ============================================================

SELECT
    CASE
        WHEN delivered_on_time = TRUE
            THEN 'On Time / Early'

        WHEN delivery_variance_days BETWEEN -999 AND 3
            THEN '1-3 Days Late'

        WHEN delivery_variance_days BETWEEN 4 AND 7
            THEN '4-7 Days Late'

        WHEN delivery_variance_days BETWEEN 8 AND 14
            THEN '8-14 Days Late'

        WHEN delivery_variance_days >= 15
            THEN '15+ Days Late'

        ELSE 'Unknown'
    END AS delay_group,

    COUNT(*) AS reviewed_orders,

    ROUND(AVG(average_review_score), 2) AS avg_review_score,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN average_review_score <= 2 THEN 1
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
        WHEN '1-3 Days Late' THEN 2
        WHEN '4-7 Days Late' THEN 3
        WHEN '8-14 Days Late' THEN 4
        WHEN '15+ Days Late' THEN 5
        ELSE 6
    END;


-- ============================================================
-- QUERY 3: Worst Categories by Customer Satisfaction
-- Minimum 100 reviewed orders
-- ============================================================

WITH category_reviews AS (

    SELECT
        oi.product_category_name_english AS category,

        o.order_id,

        o.average_review_score

    FROM orders_enriched o

    JOIN order_items_enriched oi
        ON o.order_id = oi.order_id

    WHERE o.average_review_score IS NOT NULL

    GROUP BY
        oi.product_category_name_english,
        o.order_id,
        o.average_review_score
)

SELECT
    category,

    COUNT(*) AS reviewed_orders,

    ROUND(AVG(average_review_score), 2) AS avg_review_score,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN average_review_score <= 2 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS low_rating_rate

FROM category_reviews

GROUP BY category

HAVING COUNT(*) >= 100

ORDER BY avg_review_score ASC
LIMIT 15;


-- ============================================================
-- QUERY 4: Category Delivery vs Satisfaction
-- ============================================================

SELECT
    oi.product_category_name_english AS category,

    COUNT(DISTINCT o.order_id) AS orders,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN o.delivered_on_time = FALSE THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS late_rate,

    ROUND(AVG(o.average_review_score), 2) AS avg_review_score

FROM orders_enriched o

JOIN order_items_enriched oi
    ON o.order_id = oi.order_id

WHERE
    o.delivered_on_time IS NOT NULL
    AND o.average_review_score IS NOT NULL

GROUP BY oi.product_category_name_english

HAVING COUNT(DISTINCT o.order_id) >= 100

ORDER BY late_rate DESC
LIMIT 20;


-- ============================================================
-- QUERY 5: Sellers with High Revenue + Poor Satisfaction
-- Minimum 100 reviewed orders
-- ============================================================

WITH seller_metrics AS (

    SELECT
        oi.seller_id,

        COUNT(DISTINCT oi.order_id) AS orders,

        SUM(oi.price) AS revenue,

        AVG(o.average_review_score) AS avg_review_score,

        100.0 *
        SUM(
            CASE
                WHEN o.average_review_score <= 2 THEN 1
                ELSE 0
            END
        ) / COUNT(*) AS low_rating_rate

    FROM order_items_enriched oi

    JOIN orders_enriched o
        ON oi.order_id = o.order_id

    WHERE o.average_review_score IS NOT NULL

    GROUP BY oi.seller_id
)

SELECT
    seller_id,

    orders,

    ROUND(revenue, 2) AS revenue,

    ROUND(avg_review_score, 2) AS avg_review_score,

    ROUND(low_rating_rate, 2) AS low_rating_rate

FROM seller_metrics

WHERE orders >= 100

ORDER BY
    avg_review_score ASC,
    revenue DESC

LIMIT 20;


-- ============================================================
-- QUERY 6: Sellers with Poor Delivery Performance
-- Minimum 100 delivered orders
-- ============================================================

SELECT
    oi.seller_id,

    COUNT(DISTINCT oi.order_id) AS delivered_orders,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN o.delivered_on_time = TRUE THEN 1
                ELSE 0
            END
        ) / COUNT(DISTINCT o.order_id),
        2
    ) AS on_time_rate,

    ROUND(
        AVG(
            CASE
                WHEN o.delivered_on_time = FALSE
                    THEN o.delivery_variance_days
                ELSE NULL
            END
        ),
        2
    ) AS avg_late_days

FROM order_items_enriched oi

JOIN orders_enriched o
    ON oi.order_id = o.order_id

WHERE o.delivered_on_time IS NOT NULL

GROUP BY oi.seller_id

HAVING COUNT(DISTINCT oi.order_id) >= 100

ORDER BY on_time_rate ASC

LIMIT 20;


-- ============================================================
-- QUERY 7: High-Risk Seller Identification
-- CORRECTED ORDER-LEVEL CALCULATION
-- ============================================================

WITH seller_metrics AS (

    SELECT
        oi.seller_id,

        COUNT(DISTINCT oi.order_id) AS orders,

        SUM(oi.price) AS revenue,

        AVG(o.average_review_score) AS avg_review_score,

        100.0 *
        COUNT(
            DISTINCT CASE
                WHEN o.average_review_score <= 2
                    THEN o.order_id
            END
        )
        / COUNT(DISTINCT o.order_id) AS low_rating_rate,

        100.0 *
        COUNT(
            DISTINCT CASE
                WHEN o.delivered_on_time = TRUE
                    THEN o.order_id
            END
        )
        / COUNT(DISTINCT o.order_id) AS on_time_rate

    FROM order_items_enriched oi

    JOIN orders_enriched o
        ON oi.order_id = o.order_id

    WHERE
        o.average_review_score IS NOT NULL
        AND o.delivered_on_time IS NOT NULL

    GROUP BY oi.seller_id
)

SELECT
    seller_id,

    orders,

    ROUND(revenue, 2) AS revenue,

    ROUND(avg_review_score, 2) AS avg_review_score,

    ROUND(low_rating_rate, 2) AS low_rating_rate,

    ROUND(on_time_rate, 2) AS on_time_rate,

    CASE
        WHEN avg_review_score < 3.0
             AND on_time_rate < 80
            THEN 'Critical'

        WHEN avg_review_score < 3.5
             OR on_time_rate < 85
            THEN 'High Risk'

        WHEN avg_review_score < 4.0
             OR on_time_rate < 90
            THEN 'Needs Attention'

        ELSE 'Healthy'
    END AS seller_risk

FROM seller_metrics

WHERE orders >= 50

ORDER BY
    CASE seller_risk
        WHEN 'Critical' THEN 1
        WHEN 'High Risk' THEN 2
        WHEN 'Needs Attention' THEN 3
        ELSE 4
    END,
    revenue DESC;


-- ============================================================
-- QUERY 8: Geographic Areas with Delivery + Rating Problems
-- ============================================================

SELECT
    customer_state,

    COUNT(*) AS orders,

    ROUND(AVG(average_review_score), 2) AS avg_review_score,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN delivered_on_time = FALSE THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS late_rate,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN average_review_score <= 2 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS low_rating_rate

FROM orders_enriched

WHERE
    average_review_score IS NOT NULL
    AND delivered_on_time IS NOT NULL

GROUP BY customer_state

HAVING COUNT(*) >= 100

ORDER BY low_rating_rate DESC;


-- ============================================================
-- QUERY 9: Order Status as Customer Experience Risk
-- ============================================================

SELECT
    order_status,

    COUNT(*) AS orders,

    ROUND(
        AVG(average_review_score),
        2
    ) AS avg_review_score,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN average_review_score <= 2 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS low_rating_rate

FROM orders_enriched

WHERE average_review_score IS NOT NULL

GROUP BY order_status

ORDER BY avg_review_score ASC;


-- ============================================================
-- QUERY 10: Root-Cause Summary
-- ============================================================

SELECT
    'Late Delivery' AS factor,

    COUNT(*) AS affected_orders,

    ROUND(
        AVG(average_review_score),
        2
    ) AS avg_review_score,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN average_review_score <= 2 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS low_rating_rate

FROM orders_enriched

WHERE
    delivered_on_time = FALSE
    AND average_review_score IS NOT NULL

UNION ALL

SELECT
    'On-Time Delivery' AS factor,

    COUNT(*) AS affected_orders,

    ROUND(
        AVG(average_review_score),
        2
    ) AS avg_review_score,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN average_review_score <= 2 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS low_rating_rate

FROM orders_enriched

WHERE
    delivered_on_time = TRUE
    AND average_review_score IS NOT NULL

UNION ALL

SELECT
    'Orders With Comments' AS factor,

    COUNT(*) AS affected_orders,

    ROUND(
        AVG(average_review_score),
        2
    ) AS avg_review_score,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN average_review_score <= 2 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS low_rating_rate

FROM orders_enriched

WHERE
    reviews_with_comments > 0
    AND average_review_score IS NOT NULL

UNION ALL

SELECT
    'Orders Without Comments' AS factor,

    COUNT(*) AS affected_orders,

    ROUND(
        AVG(average_review_score),
        2
    ) AS avg_review_score,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN average_review_score <= 2 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS low_rating_rate

FROM orders_enriched

WHERE
    reviews_with_comments = 0
    AND average_review_score IS NOT NULL;