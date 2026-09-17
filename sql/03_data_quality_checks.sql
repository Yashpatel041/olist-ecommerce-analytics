-- ============================================================
-- OLIST E-COMMERCE ANALYTICS
-- Phase 2: Data Quality Checks
-- ============================================================


-- ============================================================
-- 1. NULL CHECKS
-- ============================================================


-- CUSTOMERS
SELECT
    'customers' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS customer_id_nulls,
    COUNT(*) FILTER (WHERE customer_unique_id IS NULL) AS customer_unique_id_nulls,
    COUNT(*) FILTER (WHERE customer_zip_code_prefix IS NULL) AS zip_code_nulls,
    COUNT(*) FILTER (WHERE customer_city IS NULL) AS city_nulls,
    COUNT(*) FILTER (WHERE customer_state IS NULL) AS state_nulls
FROM customers;


-- ORDERS
SELECT
    'orders' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS order_id_nulls,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS customer_id_nulls,
    COUNT(*) FILTER (WHERE order_status IS NULL) AS status_nulls,
    COUNT(*) FILTER (WHERE order_purchase_timestamp IS NULL) AS purchase_date_nulls,
    COUNT(*) FILTER (WHERE order_approved_at IS NULL) AS approved_date_nulls,
    COUNT(*) FILTER (WHERE order_delivered_carrier_date IS NULL) AS carrier_date_nulls,
    COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS delivered_date_nulls,
    COUNT(*) FILTER (WHERE order_estimated_delivery_date IS NULL) AS estimated_date_nulls
FROM orders;


-- ORDER ITEMS
SELECT
    'order_items' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS order_id_nulls,
    COUNT(*) FILTER (WHERE order_item_id IS NULL) AS item_id_nulls,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS product_id_nulls,
    COUNT(*) FILTER (WHERE seller_id IS NULL) AS seller_id_nulls,
    COUNT(*) FILTER (WHERE shipping_limit_date IS NULL) AS shipping_date_nulls,
    COUNT(*) FILTER (WHERE price IS NULL) AS price_nulls,
    COUNT(*) FILTER (WHERE freight_value IS NULL) AS freight_nulls
FROM order_items;


-- ORDER PAYMENTS
SELECT
    'order_payments' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS order_id_nulls,
    COUNT(*) FILTER (WHERE payment_sequential IS NULL) AS sequential_nulls,
    COUNT(*) FILTER (WHERE payment_type IS NULL) AS payment_type_nulls,
    COUNT(*) FILTER (WHERE payment_installments IS NULL) AS installment_nulls,
    COUNT(*) FILTER (WHERE payment_value IS NULL) AS payment_value_nulls
FROM order_payments;


-- ORDER REVIEWS
SELECT
    'order_reviews' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE review_id IS NULL) AS review_id_nulls,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS order_id_nulls,
    COUNT(*) FILTER (WHERE review_score IS NULL) AS review_score_nulls,
    COUNT(*) FILTER (WHERE review_comment_title IS NULL) AS title_nulls,
    COUNT(*) FILTER (WHERE review_comment_message IS NULL) AS message_nulls,
    COUNT(*) FILTER (WHERE review_creation_date IS NULL) AS creation_date_nulls,
    COUNT(*) FILTER (WHERE review_answer_timestamp IS NULL) AS answer_date_nulls
FROM order_reviews;


-- PRODUCTS
SELECT
    'products' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS product_id_nulls,
    COUNT(*) FILTER (WHERE product_category_name IS NULL) AS category_nulls,
    COUNT(*) FILTER (WHERE product_name_lenght IS NULL) AS name_length_nulls,
    COUNT(*) FILTER (WHERE product_description_lenght IS NULL) AS description_length_nulls,
    COUNT(*) FILTER (WHERE product_photos_qty IS NULL) AS photos_nulls,
    COUNT(*) FILTER (WHERE product_weight_g IS NULL) AS weight_nulls,
    COUNT(*) FILTER (WHERE product_length_cm IS NULL) AS length_nulls,
    COUNT(*) FILTER (WHERE product_height_cm IS NULL) AS height_nulls,
    COUNT(*) FILTER (WHERE product_width_cm IS NULL) AS width_nulls
FROM products;


-- SELLERS
SELECT
    'sellers' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE seller_id IS NULL) AS seller_id_nulls,
    COUNT(*) FILTER (WHERE seller_zip_code_prefix IS NULL) AS zip_code_nulls,
    COUNT(*) FILTER (WHERE seller_city IS NULL) AS city_nulls,
    COUNT(*) FILTER (WHERE seller_state IS NULL) AS state_nulls
FROM sellers;


-- GEOLOCATION
SELECT
    'geolocation' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE geolocation_zip_code_prefix IS NULL) AS zip_code_nulls,
    COUNT(*) FILTER (WHERE geolocation_lat IS NULL) AS latitude_nulls,
    COUNT(*) FILTER (WHERE geolocation_lng IS NULL) AS longitude_nulls,
    COUNT(*) FILTER (WHERE geolocation_city IS NULL) AS city_nulls,
    COUNT(*) FILTER (WHERE geolocation_state IS NULL) AS state_nulls
FROM geolocation;


-- CATEGORY TRANSLATION
SELECT
    'category_translation' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE product_category_name IS NULL) AS category_nulls,
    COUNT(*) FILTER (WHERE product_category_name_english IS NULL) AS english_category_nulls
FROM category_translation;


-- ============================================================
-- 2. DUPLICATE ID CHECKS
-- ============================================================


-- Customers
SELECT
    'customers.customer_id' AS identifier,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT customer_id
    FROM customers
    GROUP BY customer_id
    HAVING COUNT(*) > 1
);


-- Customer unique IDs
SELECT
    'customers.customer_unique_id' AS identifier,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT customer_unique_id
    FROM customers
    GROUP BY customer_unique_id
    HAVING COUNT(*) > 1
);


-- Orders
SELECT
    'orders.order_id' AS identifier,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT order_id
    FROM orders
    GROUP BY order_id
    HAVING COUNT(*) > 1
);


-- Products
SELECT
    'products.product_id' AS identifier,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT product_id
    FROM products
    GROUP BY product_id
    HAVING COUNT(*) > 1
);


-- Sellers
SELECT
    'sellers.seller_id' AS identifier,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT seller_id
    FROM sellers
    GROUP BY seller_id
    HAVING COUNT(*) > 1
);


-- ============================================================
-- 3. ORDER ITEM DUPLICATE CHECK
-- ============================================================

SELECT
    COUNT(*) AS duplicate_order_item_groups
FROM (
    SELECT
        order_id,
        order_item_id
    FROM order_items
    GROUP BY
        order_id,
        order_item_id
    HAVING COUNT(*) > 1
);


-- ============================================================
-- 4. REVIEW ID DUPLICATES
-- ============================================================

SELECT
    COUNT(*) AS duplicate_review_id_groups
FROM (
    SELECT review_id
    FROM order_reviews
    GROUP BY review_id
    HAVING COUNT(*) > 1
);


-- ============================================================
-- 5. PAYMENT SEQUENCE DUPLICATES WITHIN ORDER
-- ============================================================

SELECT
    COUNT(*) AS duplicate_payment_sequence_groups
FROM (
    SELECT
        order_id,
        payment_sequential
    FROM order_payments
    GROUP BY
        order_id,
        payment_sequential
    HAVING COUNT(*) > 1
);


-- ============================================================
-- 6. BASIC VALUE VALIDATION
-- ============================================================


-- Negative / zero product prices
SELECT
    COUNT(*) FILTER (WHERE price < 0) AS negative_prices,
    COUNT(*) FILTER (WHERE price = 0) AS zero_prices,
    MIN(price) AS minimum_price,
    MAX(price) AS maximum_price
FROM order_items;


-- Negative / zero freight values
SELECT
    COUNT(*) FILTER (WHERE freight_value < 0) AS negative_freight,
    COUNT(*) FILTER (WHERE freight_value = 0) AS zero_freight,
    MIN(freight_value) AS minimum_freight,
    MAX(freight_value) AS maximum_freight
FROM order_items;


-- Payment values
SELECT
    COUNT(*) FILTER (WHERE payment_value < 0) AS negative_payments,
    COUNT(*) FILTER (WHERE payment_value = 0) AS zero_payments,
    MIN(payment_value) AS minimum_payment,
    MAX(payment_value) AS maximum_payment
FROM order_payments;


-- Review scores
SELECT
    COUNT(*) FILTER (WHERE review_score < 1) AS scores_below_1,
    COUNT(*) FILTER (WHERE review_score > 5) AS scores_above_5,
    MIN(review_score) AS minimum_score,
    MAX(review_score) AS maximum_score
FROM order_reviews;


-- ============================================================
-- 7. ORDER STATUS DISTRIBUTION
-- ============================================================

SELECT
    order_status,
    COUNT(*) AS order_count
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;


-- ============================================================
-- 8. PAYMENT TYPE DISTRIBUTION
-- ============================================================

SELECT
    payment_type,
    COUNT(*) AS payment_count
FROM order_payments
GROUP BY payment_type
ORDER BY payment_count DESC;