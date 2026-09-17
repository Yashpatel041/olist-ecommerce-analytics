-- ============================================================
-- OLIST E-COMMERCE ANALYTICS
-- Phase 2: Anomaly Investigation
-- ============================================================


-- ============================================================
-- 1. DUPLICATE REVIEW IDs
-- ============================================================

-- Find review IDs that occur more than once
SELECT
    review_id,
    COUNT(*) AS review_count
FROM order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY review_count DESC;


-- Inspect the actual rows for duplicate review IDs
SELECT
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
FROM order_reviews
WHERE review_id IN (
    SELECT review_id
    FROM order_reviews
    GROUP BY review_id
    HAVING COUNT(*) > 1
)
ORDER BY review_id, order_id;


-- Summary: are duplicate review IDs associated with
-- the same order or different orders?
SELECT
    review_id,
    COUNT(*) AS review_rows,
    COUNT(DISTINCT order_id) AS distinct_orders
FROM order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY review_rows DESC;


-- ============================================================
-- 2. ZERO-VALUE PAYMENTS
-- ============================================================

-- Inspect all zero-value payment records
SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
FROM order_payments
WHERE payment_value = 0
ORDER BY order_id, payment_sequential;


-- Check whether zero-value payments are the only
-- payment records for their orders
SELECT
    op.order_id,
    COUNT(*) AS payment_records,
    SUM(op.payment_value) AS total_payment_value
FROM order_payments op
WHERE op.order_id IN (
    SELECT order_id
    FROM order_payments
    WHERE payment_value = 0
)
GROUP BY op.order_id
ORDER BY op.order_id;


-- Check the order status of zero-payment orders
SELECT
    o.order_status,
    COUNT(DISTINCT op.order_id) AS zero_payment_orders
FROM order_payments op
JOIN orders o
    ON op.order_id = o.order_id
WHERE op.payment_value = 0
GROUP BY o.order_status
ORDER BY zero_payment_orders DESC;


-- ============================================================
-- 3. UNTRANSLATED PRODUCT CATEGORIES
-- ============================================================

-- List the 13 product categories without an English translation
SELECT DISTINCT
    p.product_category_name
FROM products p
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND ct.product_category_name IS NULL
ORDER BY p.product_category_name;


-- Count products in each untranslated category
SELECT
    p.product_category_name,
    COUNT(*) AS product_count
FROM products p
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND ct.product_category_name IS NULL
GROUP BY p.product_category_name
ORDER BY product_count DESC;


-- Check whether these untranslated categories actually
-- appear in order_items
SELECT
    p.product_category_name,
    COUNT(DISTINCT oi.order_id) AS orders,
    COUNT(*) AS order_items
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND ct.product_category_name IS NULL
GROUP BY p.product_category_name
ORDER BY order_items DESC;


-- ============================================================
-- 4. ADDITIONAL PAYMENT CHECK
-- ============================================================

-- Investigate the 3 'not_defined' payment records
SELECT
    op.order_id,
    op.payment_sequential,
    op.payment_type,
    op.payment_installments,
    op.payment_value,
    o.order_status
FROM order_payments op
JOIN orders o
    ON op.order_id = o.order_id
WHERE op.payment_type = 'not_defined'
ORDER BY op.order_id;