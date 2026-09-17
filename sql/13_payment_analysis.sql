-- ============================================================
-- PHASE 3.7: PAYMENT ANALYSIS
-- ============================================================


-- ============================================================
-- QUERY 1: Payment Type Distribution
-- ============================================================

SELECT
    payment_type,
    COUNT(*) AS payment_records,
    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage,
    ROUND(
        SUM(payment_value),
        2
    ) AS total_payment_value,
    ROUND(
        AVG(payment_value),
        2
    ) AS average_payment_value

FROM order_payments

GROUP BY payment_type

ORDER BY total_payment_value DESC;


-- ============================================================
-- QUERY 2: Payment Type by Order
-- ============================================================

SELECT
    payment_types,
    COUNT(*) AS orders,
    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage

FROM orders_enriched

WHERE payment_types IS NOT NULL

GROUP BY payment_types

ORDER BY orders DESC;


-- ============================================================
-- QUERY 3: Average Payment Value
-- ============================================================

SELECT
    ROUND(
        AVG(total_payment_value),
        2
    ) AS average_payment_per_order,

    ROUND(
        MEDIAN(total_payment_value),
        2
    ) AS median_payment_per_order,

    ROUND(
        MIN(total_payment_value),
        2
    ) AS minimum_payment,

    ROUND(
        MAX(total_payment_value),
        2
    ) AS maximum_payment

FROM orders_enriched

WHERE total_payment_value IS NOT NULL;


-- ============================================================
-- QUERY 4: Payment Installments
-- ============================================================

SELECT
    max_installments AS installments,

    COUNT(*) AS orders,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage

FROM orders_enriched

WHERE max_installments IS NOT NULL

GROUP BY max_installments

ORDER BY installments;


-- ============================================================
-- QUERY 5: Payment Type vs Average Order Value
-- ============================================================

WITH order_payment_type AS (

    SELECT
        order_id,
        payment_type,
        SUM(payment_value) AS payment_value

    FROM order_payments

    GROUP BY
        order_id,
        payment_type
)

SELECT
    payment_type,

    COUNT(DISTINCT order_id) AS orders,

    ROUND(
        SUM(payment_value),
        2
    ) AS total_payment_value,

    ROUND(
        AVG(payment_value),
        2
    ) AS average_payment_value

FROM order_payment_type

GROUP BY payment_type

ORDER BY total_payment_value DESC;


-- ============================================================
-- QUERY 6: Payment Type vs Review Score
-- ============================================================

WITH order_payment_type AS (

    SELECT
        order_id,
        STRING_AGG(
            DISTINCT payment_type,
            ', '
        ) AS payment_type

    FROM order_payments

    GROUP BY order_id
)

SELECT
    p.payment_type,

    COUNT(*) AS reviewed_orders,

    ROUND(
        AVG(o.average_review_score),
        2
    ) AS avg_review_score

FROM order_payment_type p

JOIN orders_enriched o
    ON p.order_id = o.order_id

WHERE o.average_review_score IS NOT NULL

GROUP BY p.payment_type

ORDER BY avg_review_score DESC;


-- ============================================================
-- QUERY 7: Payment Type vs Order Status
-- ============================================================

WITH order_payment_type AS (

    SELECT
        order_id,
        STRING_AGG(
            DISTINCT payment_type,
            ', '
        ) AS payment_type

    FROM order_payments

    GROUP BY order_id
)

SELECT
    o.order_status,

    p.payment_type,

    COUNT(*) AS orders

FROM order_payment_type p

JOIN orders_enriched o
    ON p.order_id = o.order_id

GROUP BY
    o.order_status,
    p.payment_type

ORDER BY
    o.order_status,
    orders DESC;


-- ============================================================
-- QUERY 8: Orders with Multiple Payment Methods
-- ============================================================

SELECT
    COUNT(*) AS multi_payment_orders,

    ROUND(
        100.0 * COUNT(*) /
        (SELECT COUNT(*) FROM orders_enriched),
        2
    ) AS percentage_of_orders

FROM orders_enriched

WHERE payment_record_count > 1;


-- ============================================================
-- QUERY 9: Payment Value vs Order Value Difference
-- ============================================================

SELECT
    ROUND(
        SUM(total_payment_value),
        2
    ) AS total_payment_value,

    ROUND(
        SUM(item_total_value),
        2
    ) AS total_order_value,

    ROUND(
        SUM(total_payment_value - item_total_value),
        2
    ) AS total_difference,

    ROUND(
        AVG(total_payment_value - item_total_value),
        2
    ) AS average_difference

FROM orders_enriched;


-- ============================================================
-- QUERY 10: Zero-Value Payment Orders
-- ============================================================

SELECT
    order_status,

    COUNT(*) AS orders_with_zero_payment

FROM orders_enriched

WHERE
    total_payment_value = 0

GROUP BY order_status

ORDER BY orders_with_zero_payment DESC;


-- ============================================================
-- QUERY 11: Undefined Payment Type
-- ============================================================

SELECT
    payment_type,

    COUNT(*) AS payment_records,

    ROUND(
        SUM(payment_value),
        2
    ) AS total_payment_value

FROM order_payments

WHERE payment_type = 'not_defined'

GROUP BY payment_type;


-- ============================================================
-- QUERY 12: Payment Value Distribution
-- ============================================================

SELECT
    CASE
        WHEN total_payment_value < 50
            THEN 'Under 50'
        WHEN total_payment_value < 100
            THEN '50-99'
        WHEN total_payment_value < 250
            THEN '100-249'
        WHEN total_payment_value < 500
            THEN '250-499'
        WHEN total_payment_value < 1000
            THEN '500-999'
        ELSE '1000+'
    END AS payment_bucket,

    COUNT(*) AS orders,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage

FROM orders_enriched

WHERE total_payment_value IS NOT NULL

GROUP BY payment_bucket

ORDER BY
    CASE payment_bucket
        WHEN 'Under 50' THEN 1
        WHEN '50-99' THEN 2
        WHEN '100-249' THEN 3
        WHEN '250-499' THEN 4
        WHEN '500-999' THEN 5
        WHEN '1000+' THEN 6
    END;