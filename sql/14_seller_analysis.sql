-- ============================================================
-- PHASE 3.8: SELLER ANALYSIS
-- ============================================================


-- ============================================================
-- QUERY 1: Overall Seller Performance
-- ============================================================

SELECT
    COUNT(DISTINCT seller_id) AS total_sellers,

    COUNT(DISTINCT order_id) AS total_orders,

    ROUND(
        SUM(price),
        2
    ) AS total_product_revenue,

    ROUND(
        AVG(price),
        2
    ) AS average_item_price

FROM order_items_enriched;


-- ============================================================
-- QUERY 2: Top 20 Sellers by Revenue
-- ============================================================

SELECT
    seller_id,

    COUNT(DISTINCT order_id) AS orders,

    COUNT(*) AS items_sold,

    ROUND(
        SUM(price),
        2
    ) AS product_revenue,

    ROUND(
        SUM(freight_value),
        2
    ) AS freight_revenue,

    ROUND(
        SUM(price + freight_value),
        2
    ) AS total_order_value

FROM order_items_enriched

GROUP BY seller_id

ORDER BY product_revenue DESC

LIMIT 20;


-- ============================================================
-- QUERY 3: Top 20 Sellers by Order Volume
-- ============================================================

SELECT
    seller_id,

    COUNT(DISTINCT order_id) AS orders,

    COUNT(*) AS items_sold,

    ROUND(
        SUM(price),
        2
    ) AS product_revenue,

    ROUND(
        AVG(price),
        2
    ) AS average_item_price

FROM order_items_enriched

GROUP BY seller_id

ORDER BY orders DESC

LIMIT 20;


-- ============================================================
-- QUERY 4: Seller Revenue Distribution
-- ============================================================

WITH seller_revenue AS (

    SELECT
        seller_id,

        SUM(price) AS revenue

    FROM order_items_enriched

    GROUP BY seller_id
)

SELECT
    CASE
        WHEN revenue < 1000
            THEN 'Under 1K'
        WHEN revenue < 5000
            THEN '1K-4.9K'
        WHEN revenue < 10000
            THEN '5K-9.9K'
        WHEN revenue < 25000
            THEN '10K-24.9K'
        WHEN revenue < 50000
            THEN '25K-49.9K'
        ELSE '50K+'
    END AS revenue_bucket,

    COUNT(*) AS sellers,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage

FROM seller_revenue

GROUP BY revenue_bucket

ORDER BY
    CASE revenue_bucket
        WHEN 'Under 1K' THEN 1
        WHEN '1K-4.9K' THEN 2
        WHEN '5K-9.9K' THEN 3
        WHEN '10K-24.9K' THEN 4
        WHEN '25K-49.9K' THEN 5
        WHEN '50K+' THEN 6
    END;


-- ============================================================
-- QUERY 5: Seller Revenue Concentration
-- ============================================================

WITH seller_revenue AS (

    SELECT
        seller_id,
        SUM(price) AS revenue

    FROM order_items_enriched

    GROUP BY seller_id
),

ranked_sellers AS (

    SELECT
        seller_id,
        revenue,

        ROW_NUMBER() OVER (
            ORDER BY revenue DESC
        ) AS seller_rank,

        COUNT(*) OVER () AS total_sellers

    FROM seller_revenue
)

SELECT
    CASE
        WHEN seller_rank <= 10
            THEN 'Top 10'
        WHEN seller_rank <= 50
            THEN 'Top 50'
        WHEN seller_rank <= 100
            THEN 'Top 100'
        WHEN seller_rank <= 500
            THEN 'Top 500'
        ELSE 'Remaining'
    END AS seller_group,

    COUNT(*) AS sellers,

    ROUND(
        SUM(revenue),
        2
    ) AS revenue,

    ROUND(
        100.0 * SUM(revenue) /
        SUM(SUM(revenue)) OVER (),
        2
    ) AS revenue_share

FROM ranked_sellers

GROUP BY seller_group

ORDER BY
    CASE seller_group
        WHEN 'Top 10' THEN 1
        WHEN 'Top 50' THEN 2
        WHEN 'Top 100' THEN 3
        WHEN 'Top 500' THEN 4
        ELSE 5
    END;


-- ============================================================
-- QUERY 6: Seller AOV
-- Minimum 50 orders
-- ============================================================

SELECT
    seller_id,

    COUNT(DISTINCT order_id) AS orders,

    ROUND(
        SUM(price + freight_value) /
        COUNT(DISTINCT order_id),
        2
    ) AS average_order_value,

    ROUND(
        SUM(price),
        2
    ) AS product_revenue

FROM order_items_enriched

GROUP BY seller_id

HAVING COUNT(DISTINCT order_id) >= 50

ORDER BY average_order_value DESC

LIMIT 20;


-- ============================================================
-- QUERY 7: Seller Review Performance
-- Minimum 50 reviewed orders
-- ============================================================

WITH seller_orders AS (

    SELECT DISTINCT
        seller_id,
        order_id

    FROM order_items_enriched
),

seller_reviews AS (

    SELECT
        so.seller_id,
        so.order_id,
        o.average_review_score

    FROM seller_orders so

    JOIN orders_enriched o
        ON so.order_id = o.order_id

    WHERE o.average_review_score IS NOT NULL
)

SELECT
    seller_id,

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

FROM seller_reviews

GROUP BY seller_id

HAVING COUNT(*) >= 50

ORDER BY avg_review_score ASC

LIMIT 20;


-- ============================================================
-- QUERY 8: Seller Delivery Performance
-- Minimum 50 delivered orders
-- ============================================================

WITH seller_orders AS (

    SELECT DISTINCT
        seller_id,
        order_id

    FROM order_items_enriched
),

seller_delivery AS (

    SELECT
        so.seller_id,
        so.order_id,
        o.delivered_on_time

    FROM seller_orders so

    JOIN orders_enriched o
        ON so.order_id = o.order_id

    WHERE o.delivered_on_time IS NOT NULL
)

SELECT
    seller_id,

    COUNT(*) AS delivered_orders,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN delivered_on_time = TRUE
                    THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS on_time_rate

FROM seller_delivery

GROUP BY seller_id

HAVING COUNT(*) >= 50

ORDER BY on_time_rate ASC

LIMIT 20;


-- ============================================================
-- QUERY 9: High Revenue + Poor Reviews
-- Minimum 100 reviewed orders
-- ============================================================

WITH seller_orders AS (

    SELECT DISTINCT
        seller_id,
        order_id

    FROM order_items_enriched
),

seller_metrics AS (

    SELECT
        so.seller_id,

        COUNT(*) AS reviewed_orders,

        ROUND(
            AVG(o.average_review_score),
            2
        ) AS avg_review_score,

        ROUND(
            SUM(
                CASE
                    WHEN o.average_review_score <= 2
                        THEN 1
                    ELSE 0
                END
            ) * 100.0 / COUNT(*),
            2
        ) AS low_rating_rate

    FROM seller_orders so

    JOIN orders_enriched o
        ON so.order_id = o.order_id

    WHERE o.average_review_score IS NOT NULL

    GROUP BY so.seller_id

    HAVING COUNT(*) >= 100
),

seller_revenue AS (

    SELECT
        seller_id,

        SUM(price) AS revenue

    FROM order_items_enriched

    GROUP BY seller_id
)

SELECT
    sm.seller_id,

    ROUND(sr.revenue, 2) AS revenue,

    sm.reviewed_orders,

    sm.avg_review_score,

    sm.low_rating_rate

FROM seller_metrics sm

JOIN seller_revenue sr
    ON sm.seller_id = sr.seller_id

ORDER BY
    sr.revenue DESC;


-- ============================================================
-- QUERY 10: Seller Performance Summary
-- ============================================================

WITH seller_orders AS (

    SELECT DISTINCT
        seller_id,
        order_id

    FROM order_items_enriched
),

seller_metrics AS (

    SELECT
        so.seller_id,

        COUNT(*) AS orders,

        ROUND(
            AVG(o.average_review_score),
            2
        ) AS avg_review_score,

        ROUND(
            100.0 *
            SUM(
                CASE
                    WHEN o.delivered_on_time = TRUE
                        THEN 1
                    ELSE 0
                END
            ) /
            NULLIF(
                SUM(
                    CASE
                        WHEN o.delivered_on_time IS NOT NULL
                            THEN 1
                        ELSE 0
                    END
                ),
                0
            ),
            2
        ) AS on_time_rate

    FROM seller_orders so

    JOIN orders_enriched o
        ON so.order_id = o.order_id

    GROUP BY so.seller_id
),

seller_revenue AS (

    SELECT
        seller_id,

        SUM(price) AS revenue

    FROM order_items_enriched

    GROUP BY seller_id
)

SELECT
    sm.seller_id,

    sm.orders,

    ROUND(sr.revenue, 2) AS revenue,

    sm.avg_review_score,

    sm.on_time_rate,

    CASE
        WHEN sm.avg_review_score >= 4.5
             AND sm.on_time_rate >= 95
            THEN 'Excellent'

        WHEN sm.avg_review_score >= 4.0
             AND sm.on_time_rate >= 90
            THEN 'Good'

        WHEN sm.avg_review_score < 3.0
             OR sm.on_time_rate < 80
            THEN 'Needs Attention'

        ELSE 'Average'
    END AS performance_segment

FROM seller_metrics sm

JOIN seller_revenue sr
    ON sm.seller_id = sr.seller_id

ORDER BY revenue DESC;


-- ============================================================
-- QUERY 11: Seller State Performance
-- ============================================================

SELECT
    seller_state,

    COUNT(DISTINCT seller_id) AS sellers,

    COUNT(DISTINCT order_id) AS orders,

    ROUND(
        SUM(price),
        2
    ) AS revenue,

    ROUND(
        AVG(price),
        2
    ) AS average_item_price

FROM order_items_enriched

GROUP BY seller_state

ORDER BY revenue DESC;


-- ============================================================
-- QUERY 12: Seller Activity Distribution
-- ============================================================

WITH seller_orders AS (

    SELECT
        seller_id,

        COUNT(DISTINCT order_id) AS orders

    FROM order_items_enriched

    GROUP BY seller_id
)

SELECT
    CASE
        WHEN orders = 1
            THEN '1 Order'
        WHEN orders BETWEEN 2 AND 10
            THEN '2-10 Orders'
        WHEN orders BETWEEN 11 AND 50
            THEN '11-50 Orders'
        WHEN orders BETWEEN 51 AND 100
            THEN '51-100 Orders'
        ELSE '100+ Orders'
    END AS seller_activity,

    COUNT(*) AS sellers,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage

FROM seller_orders

GROUP BY seller_activity

ORDER BY
    CASE seller_activity
        WHEN '1 Order' THEN 1
        WHEN '2-10 Orders' THEN 2
        WHEN '11-50 Orders' THEN 3
        WHEN '51-100 Orders' THEN 4
        WHEN '100+ Orders' THEN 5
    END;