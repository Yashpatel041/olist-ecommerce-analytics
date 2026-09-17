-- ============================================================
-- OLIST E-COMMERCE ANALYTICS
-- Phase 2: Relationship & Data Quality Checks
-- ============================================================


-- ============================================================
-- 1. Orders with missing customer records
-- ============================================================

SELECT COUNT(*) AS orders_without_customer
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- ============================================================
-- 2. Order items with missing orders
-- ============================================================

SELECT COUNT(*) AS items_without_order
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;


-- ============================================================
-- 3. Order items with missing products
-- ============================================================

SELECT COUNT(*) AS items_without_product
FROM order_items oi
LEFT JOIN products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;


-- ============================================================
-- 4. Order items with missing sellers
-- ============================================================

SELECT COUNT(*) AS items_without_seller
FROM order_items oi
LEFT JOIN sellers s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;


-- ============================================================
-- 5. Payments with missing orders
-- ============================================================

SELECT COUNT(*) AS payments_without_order
FROM order_payments op
LEFT JOIN orders o
    ON op.order_id = o.order_id
WHERE o.order_id IS NULL;


-- ============================================================
-- 6. Reviews with missing orders
-- ============================================================

SELECT COUNT(*) AS reviews_without_order
FROM order_reviews r
LEFT JOIN orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;


-- ============================================================
-- 7. Products without category translation
-- ============================================================

SELECT COUNT(*) AS products_without_translation
FROM products p
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND ct.product_category_name IS NULL;


-- ============================================================
-- 8. Orders with multiple items
-- ============================================================

SELECT
    COUNT(*) AS multi_item_orders
FROM (
    SELECT order_id
    FROM order_items
    GROUP BY order_id
    HAVING COUNT(*) > 1
);


-- ============================================================
-- 9. Orders with multiple payment records
-- ============================================================

SELECT
    COUNT(*) AS multi_payment_orders
FROM (
    SELECT order_id
    FROM order_payments
    GROUP BY order_id
    HAVING COUNT(*) > 1
);


-- ============================================================
-- 10. Orders with multiple reviews
-- ============================================================

SELECT
    COUNT(*) AS multi_review_orders
FROM (
    SELECT order_id
    FROM order_reviews
    GROUP BY order_id
    HAVING COUNT(*) > 1
);