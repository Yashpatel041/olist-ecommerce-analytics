-- ============================================================
-- PHASE 3.9: GEOGRAPHIC ANALYSIS
-- ============================================================


-- ============================================================
-- QUERY 1: Customer Distribution by State
-- ============================================================

SELECT
    customer_state,

    COUNT(DISTINCT customer_unique_id) AS customers,

    COUNT(DISTINCT customer_id) AS customer_accounts,

    COUNT(DISTINCT order_id) AS orders

FROM orders_enriched

GROUP BY customer_state

ORDER BY customers DESC;


-- ============================================================
-- QUERY 2: Customer Revenue by State
-- ============================================================

SELECT
    customer_state,

    COUNT(DISTINCT customer_unique_id) AS customers,

    COUNT(DISTINCT order_id) AS orders,

    ROUND(
        SUM(item_total_value),
        2
    ) AS total_order_value,

    ROUND(
        SUM(item_total_value) /
        COUNT(DISTINCT customer_unique_id),
        2
    ) AS revenue_per_customer

FROM orders_enriched

GROUP BY customer_state

ORDER BY total_order_value DESC;


-- ============================================================
-- QUERY 3: Customer AOV by State
-- ============================================================

SELECT
    customer_state,

    COUNT(DISTINCT order_id) AS orders,

    ROUND(
        SUM(item_total_value) /
        COUNT(DISTINCT order_id),
        2
    ) AS average_order_value

FROM orders_enriched

GROUP BY customer_state

HAVING COUNT(DISTINCT order_id) >= 100

ORDER BY average_order_value DESC;


-- ============================================================
-- QUERY 4: Customer State Revenue Share
-- ============================================================

WITH state_revenue AS (

    SELECT
        customer_state,

        SUM(item_total_value) AS revenue

    FROM orders_enriched

    GROUP BY customer_state
)

SELECT
    customer_state,

    ROUND(revenue, 2) AS revenue,

    ROUND(
        100.0 * revenue /
        SUM(revenue) OVER (),
        2
    ) AS revenue_share

FROM state_revenue

ORDER BY revenue DESC;


-- ============================================================
-- QUERY 5: Customer State Review Performance
-- Minimum 100 reviewed orders
-- ============================================================

SELECT
    customer_state,

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

GROUP BY customer_state

HAVING COUNT(*) >= 100

ORDER BY avg_review_score ASC;


-- ============================================================
-- QUERY 6: Customer State Delivery Performance
-- Minimum 100 delivered orders
-- ============================================================

SELECT
    customer_state,

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
    ) AS on_time_rate,

    ROUND(
        AVG(
            CASE
                WHEN delivered_on_time = FALSE
                    THEN delivery_variance_days
                ELSE NULL
            END
        ),
        2
    ) AS avg_late_days

FROM orders_enriched

WHERE delivered_on_time IS NOT NULL

GROUP BY customer_state

HAVING COUNT(*) >= 100

ORDER BY on_time_rate ASC;


-- ============================================================
-- QUERY 7: Seller Distribution by State
-- ============================================================

SELECT
    seller_state,

    COUNT(DISTINCT seller_id) AS sellers,

    COUNT(DISTINCT order_id) AS orders,

    ROUND(
        SUM(price),
        2
    ) AS product_revenue

FROM order_items_enriched

GROUP BY seller_state

ORDER BY sellers DESC;


-- ============================================================
-- QUERY 8: Seller State Revenue Share
-- ============================================================

WITH seller_state_revenue AS (

    SELECT
        seller_state,

        SUM(price) AS revenue

    FROM order_items_enriched

    GROUP BY seller_state
)

SELECT
    seller_state,

    ROUND(revenue, 2) AS revenue,

    ROUND(
        100.0 * revenue /
        SUM(revenue) OVER (),
        2
    ) AS revenue_share

FROM seller_state_revenue

ORDER BY revenue DESC;


-- ============================================================
-- QUERY 9: Customer State vs Seller State
-- ============================================================

SELECT
    o.customer_state,

    oi.seller_state,

    COUNT(DISTINCT o.order_id) AS orders,

    ROUND(
        SUM(oi.price + oi.freight_value),
        2
    ) AS order_value

FROM orders_enriched o

JOIN order_items_enriched oi
    ON o.order_id = oi.order_id

GROUP BY
    o.customer_state,
    oi.seller_state

ORDER BY order_value DESC

LIMIT 30;


-- ============================================================
-- QUERY 10: Same-State vs Cross-State Orders
-- ============================================================

WITH order_geography AS (

    SELECT
        o.order_id,

        o.customer_state,

        STRING_AGG(
            DISTINCT oi.seller_state,
            ', '
        ) AS seller_states

    FROM orders_enriched o

    JOIN order_items_enriched oi
        ON o.order_id = oi.order_id

    GROUP BY
        o.order_id,
        o.customer_state
)

SELECT
    CASE
        WHEN seller_states = customer_state
            THEN 'Same State'
        ELSE 'Cross State'
    END AS geographic_type,

    COUNT(*) AS orders,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage

FROM order_geography

GROUP BY geographic_type;


-- ============================================================
-- QUERY 11: Cross-State Delivery Performance
-- ============================================================

WITH order_geography AS (

    SELECT
        o.order_id,

        o.customer_state,

        STRING_AGG(
            DISTINCT oi.seller_state,
            ', '
        ) AS seller_states,

        MAX(o.delivered_on_time::INTEGER) AS delivered_on_time

    FROM orders_enriched o

    JOIN order_items_enriched oi
        ON o.order_id = oi.order_id

    WHERE o.delivered_on_time IS NOT NULL

    GROUP BY
        o.order_id,
        o.customer_state
)

SELECT
    CASE
        WHEN seller_states = customer_state
            THEN 'Same State'
        ELSE 'Cross State'
    END AS geographic_type,

    COUNT(*) AS delivered_orders,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN delivered_on_time = 1
                    THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS on_time_rate

FROM order_geography

GROUP BY geographic_type;


-- ============================================================
-- QUERY 12: Cross-State vs Same-State Customer Satisfaction
-- ============================================================

WITH order_geography AS (

    SELECT
        o.order_id,

        o.customer_state,

        STRING_AGG(
            DISTINCT oi.seller_state,
            ', '
        ) AS seller_states,

        o.average_review_score

    FROM orders_enriched o

    JOIN order_items_enriched oi
        ON o.order_id = oi.order_id

    WHERE o.average_review_score IS NOT NULL

    GROUP BY
        o.order_id,
        o.customer_state,
        o.average_review_score
)

SELECT
    CASE
        WHEN seller_states = customer_state
            THEN 'Same State'
        ELSE 'Cross State'
    END AS geographic_type,

    COUNT(*) AS reviewed_orders,

    ROUND(
        AVG(average_review_score),
        2
    ) AS avg_review_score

FROM order_geography

GROUP BY geographic_type;


-- ============================================================
-- QUERY 13: Top Customer Cities by Order Volume
-- ============================================================

SELECT
    customer_city,

    customer_state,

    COUNT(DISTINCT customer_unique_id) AS customers,

    COUNT(DISTINCT order_id) AS orders,

    ROUND(
        SUM(item_total_value),
        2
    ) AS revenue

FROM orders_enriched

GROUP BY
    customer_city,
    customer_state

HAVING COUNT(DISTINCT order_id) >= 100

ORDER BY orders DESC

LIMIT 20;


-- ============================================================
-- QUERY 14: Top Customer Cities by Revenue
-- Minimum 100 orders
-- ============================================================

SELECT
    customer_city,

    customer_state,

    COUNT(DISTINCT order_id) AS orders,

    ROUND(
        SUM(item_total_value),
        2
    ) AS revenue

FROM orders_enriched

GROUP BY
    customer_city,
    customer_state

HAVING COUNT(DISTINCT order_id) >= 100

ORDER BY revenue DESC

LIMIT 20;