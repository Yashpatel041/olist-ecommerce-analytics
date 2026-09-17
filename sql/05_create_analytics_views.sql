-- ============================================================
-- OLIST E-COMMERCE ANALYTICS
-- Phase 2: Analytics Layer
-- Step 2.7: Create Analytics Views
-- ============================================================


-- ============================================================
-- 1. CUSTOMER VIEW
-- ============================================================

CREATE OR REPLACE VIEW customer_clean AS
SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    TRIM(LOWER(customer_city)) AS customer_city,
    UPPER(TRIM(customer_state)) AS customer_state
FROM customers;


-- ============================================================
-- 2. PRODUCT VIEW WITH ENGLISH CATEGORY
-- ============================================================

CREATE OR REPLACE VIEW product_clean AS
SELECT
    p.product_id,
    p.product_category_name,

    CASE
        WHEN ct.product_category_name_english IS NOT NULL
            THEN ct.product_category_name_english

        WHEN p.product_category_name = 'pc_gamer'
            THEN 'PC Gamer'

        WHEN p.product_category_name =
             'portateis_cozinha_e_preparadores_de_alimentos'
            THEN 'Portable Kitchen & Food Preparers'

        ELSE 'Unknown Category'
    END AS product_category_name_english,

    p.product_name_lenght,
    p.product_description_lenght,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm

FROM products p

LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name;


-- ============================================================
-- 3. ORDER ITEM AGGREGATION
-- One row = one order
-- ============================================================

CREATE OR REPLACE VIEW order_item_summary AS
SELECT
    order_id,

    COUNT(*) AS total_items,

    COUNT(DISTINCT product_id) AS unique_products,

    COUNT(DISTINCT seller_id) AS unique_sellers,

    SUM(price) AS product_revenue,

    SUM(freight_value) AS total_freight,

    SUM(price + freight_value) AS item_total_value,

    AVG(price) AS average_item_price

FROM order_items

GROUP BY order_id;


-- ============================================================
-- 4. PAYMENT AGGREGATION
-- One row = one order
-- ============================================================

CREATE OR REPLACE VIEW order_payment_summary AS
SELECT
    order_id,

    SUM(payment_value) AS total_payment_value,

    COUNT(*) AS payment_record_count,

    MAX(payment_installments) AS max_installments,

    STRING_AGG(
        DISTINCT payment_type,
        ', '
        ORDER BY payment_type
    ) AS payment_types

FROM order_payments

GROUP BY order_id;


-- ============================================================
-- 5. REVIEW AGGREGATION
-- One row = one order
-- ============================================================

CREATE OR REPLACE VIEW order_review_summary AS
SELECT
    order_id,

    COUNT(*) AS review_count,

    AVG(review_score) AS average_review_score,

    MIN(review_score) AS minimum_review_score,

    MAX(review_score) AS maximum_review_score,

    COUNT(*) FILTER (
        WHERE review_comment_message IS NOT NULL
          AND TRIM(review_comment_message) <> ''
    ) AS reviews_with_comments

FROM order_reviews

GROUP BY order_id;


-- ============================================================
-- 6. ORDER ENRICHED VIEW
-- One row = one order
-- ============================================================

CREATE OR REPLACE VIEW orders_enriched AS

SELECT

    -- Order information
    o.order_id,
    o.customer_id,
    c.customer_unique_id,

    o.order_status,

    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    -- Customer information
    c.customer_city,
    c.customer_state,
    c.customer_zip_code_prefix,

    -- Item metrics
    COALESCE(oi.total_items, 0) AS total_items,
    COALESCE(oi.unique_products, 0) AS unique_products,
    COALESCE(oi.unique_sellers, 0) AS unique_sellers,

    COALESCE(oi.product_revenue, 0) AS product_revenue,
    COALESCE(oi.total_freight, 0) AS total_freight,
    COALESCE(oi.item_total_value, 0) AS item_total_value,
    COALESCE(oi.average_item_price, 0) AS average_item_price,

    -- Payment metrics
    COALESCE(op.total_payment_value, 0) AS total_payment_value,
    COALESCE(op.payment_record_count, 0) AS payment_record_count,
    COALESCE(op.max_installments, 0) AS max_installments,
    op.payment_types,

    -- Review metrics
    COALESCE(orv.review_count, 0) AS review_count,
    orv.average_review_score,
    orv.minimum_review_score,
    orv.maximum_review_score,
    COALESCE(orv.reviews_with_comments, 0) AS reviews_with_comments,

    -- Delivery metrics
    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
         AND o.order_purchase_timestamp IS NOT NULL
        THEN DATE_DIFF(
            'day',
            o.order_purchase_timestamp,
            o.order_delivered_customer_date
        )
    END AS delivery_days,

    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
        THEN DATE_DIFF(
            'day',
            o.order_estimated_delivery_date,
            o.order_delivered_customer_date
        )
    END AS delivery_variance_days,

    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
         AND o.order_delivered_customer_date
             <= o.order_estimated_delivery_date
        THEN TRUE

        WHEN o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
         AND o.order_delivered_customer_date
             > o.order_estimated_delivery_date
        THEN FALSE
    END AS delivered_on_time

FROM orders o

LEFT JOIN customer_clean c
    ON o.customer_id = c.customer_id

LEFT JOIN order_item_summary oi
    ON o.order_id = oi.order_id

LEFT JOIN order_payment_summary op
    ON o.order_id = op.order_id

LEFT JOIN order_review_summary orv
    ON o.order_id = orv.order_id;


-- ============================================================
-- 7. SELLER VIEW
-- ============================================================

CREATE OR REPLACE VIEW seller_clean AS
SELECT
    seller_id,
    seller_zip_code_prefix,
    TRIM(LOWER(seller_city)) AS seller_city,
    UPPER(TRIM(seller_state)) AS seller_state
FROM sellers;


-- ============================================================
-- 8. ORDER ITEM ENRICHED VIEW
-- One row = one order item
-- ============================================================

CREATE OR REPLACE VIEW order_items_enriched AS

SELECT

    oi.order_id,
    oi.order_item_id,

    oi.product_id,
    p.product_category_name,
    p.product_category_name_english,

    oi.seller_id,
    s.seller_city,
    s.seller_state,

    oi.shipping_limit_date,
    oi.price,
    oi.freight_value,

    oi.price + oi.freight_value AS item_total_value,

    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,
    p.product_photos_qty

FROM order_items oi

LEFT JOIN product_clean p
    ON oi.product_id = p.product_id

LEFT JOIN seller_clean s
    ON oi.seller_id = s.seller_id;