-- ============================================================
-- PHASE 4.1: CUSTOMER-LEVEL FEATURE ENGINEERING
-- ============================================================
-- Purpose:
-- Convert order-level data into one row per customer.
--
-- Grain:
-- 1 row = 1 customer_unique_id
-- ============================================================


-- ============================================================
-- CUSTOMER-LEVEL FEATURE TABLE
-- ============================================================

CREATE OR REPLACE TABLE customer_features AS

SELECT
    customer_unique_id,

    -- --------------------------------------------------------
    -- CUSTOMER ACTIVITY
    -- --------------------------------------------------------

    COUNT(DISTINCT order_id) AS total_orders,

    MIN(order_purchase_timestamp) AS first_order_date,

    MAX(order_purchase_timestamp) AS last_order_date,

    DATE_DIFF(
        'day',
        MIN(order_purchase_timestamp),
        MAX(order_purchase_timestamp)
    ) AS customer_lifetime_days,


    -- --------------------------------------------------------
    -- SPENDING BEHAVIOR
    -- --------------------------------------------------------

    ROUND(
        SUM(total_payment_value),
        2
    ) AS total_spent,

    ROUND(
        SUM(total_freight),
        2
    ) AS total_freight,

    ROUND(
        AVG(total_payment_value),
        2
    ) AS avg_order_value,


    -- --------------------------------------------------------
    -- PRODUCT / ORDER BEHAVIOR
    -- --------------------------------------------------------

    SUM(total_items) AS total_items,

    SUM(unique_products) AS unique_products,

    SUM(unique_sellers) AS unique_sellers,


    -- --------------------------------------------------------
    -- DELIVERY BEHAVIOR
    -- --------------------------------------------------------

    SUM(
        CASE
            WHEN delivered_on_time = FALSE
            THEN 1
            ELSE 0
        END
    ) AS late_orders,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN delivered_on_time = FALSE
                THEN 1
                ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN delivered_on_time IS NOT NULL
                    THEN 1
                    ELSE 0
                END
            ),
            0
        ),
        2
    ) AS late_rate,

    ROUND(
        AVG(delivery_days),
        2
    ) AS avg_delivery_days,

    ROUND(
        AVG(
            CASE
                WHEN delivered_on_time = FALSE
                THEN delivery_variance_days
                ELSE NULL
            END
        ),
        2
    ) AS avg_delivery_delay,


    -- --------------------------------------------------------
    -- CUSTOMER SATISFACTION
    -- --------------------------------------------------------

    ROUND(
        AVG(average_review_score),
        2
    ) AS avg_review_score,

    SUM(
        CASE
            WHEN average_review_score <= 2
            THEN 1
            ELSE 0
        END
    ) AS low_rating_orders,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN average_review_score <= 2
                THEN 1
                ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN average_review_score IS NOT NULL
                    THEN 1
                    ELSE 0
                END
            ),
            0
        ),
        2
    ) AS low_rating_rate

FROM orders_enriched

WHERE customer_unique_id IS NOT NULL

GROUP BY customer_unique_id;