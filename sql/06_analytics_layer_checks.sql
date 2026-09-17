-- ============================================================
-- OLIST E-COMMERCE ANALYTICS
-- Phase 2: Analytics Layer Validation
-- Step 2.8
-- ============================================================


-- ============================================================
-- 1. ROW COUNTS
-- ============================================================

SELECT
    'customers' AS table_name,
    COUNT(*) AS row_count
FROM customers

UNION ALL

SELECT
    'customer_clean',
    COUNT(*)
FROM customer_clean

UNION ALL

SELECT
    'products',
    COUNT(*)
FROM products

UNION ALL

SELECT
    'product_clean',
    COUNT(*)
FROM product_clean

UNION ALL

SELECT
    'orders',
    COUNT(*)
FROM orders

UNION ALL

SELECT
    'orders_enriched',
    COUNT(*)
FROM orders_enriched

UNION ALL

SELECT
    'order_items',
    COUNT(*)
FROM order_items

UNION ALL

SELECT
    'order_items_enriched',
    COUNT(*)
FROM order_items_enriched;


-- ============================================================
-- 2. ORDERS_ENRICHED MUST BE ONE ROW PER ORDER
-- ============================================================

SELECT
    COUNT(*) AS duplicate_order_groups
FROM (
    SELECT
        order_id
    FROM orders_enriched
    GROUP BY order_id
    HAVING COUNT(*) > 1
);


-- ============================================================
-- 3. CHECK FOR MISSING ORDER IDs
-- ============================================================

SELECT
    COUNT(*) AS missing_order_ids
FROM orders_enriched
WHERE order_id IS NULL;


-- ============================================================
-- 4. COMPARE ORDER COUNTS
-- ============================================================

SELECT
    (SELECT COUNT(*) FROM orders) AS raw_orders,
    (SELECT COUNT(*) FROM orders_enriched) AS enriched_orders,
    (SELECT COUNT(*) FROM orders)
      -
    (SELECT COUNT(*) FROM orders_enriched) AS difference;


-- ============================================================
-- 5. CHECK ORDER ITEM SUMMARY GRAIN
-- ============================================================

SELECT
    COUNT(*) AS duplicate_order_groups
FROM (
    SELECT
        order_id
    FROM order_item_summary
    GROUP BY order_id
    HAVING COUNT(*) > 1
);


-- ============================================================
-- 6. CHECK PAYMENT SUMMARY GRAIN
-- ============================================================

SELECT
    COUNT(*) AS duplicate_order_groups
FROM (
    SELECT
        order_id
    FROM order_payment_summary
    GROUP BY order_id
    HAVING COUNT(*) > 1
);


-- ============================================================
-- 7. CHECK REVIEW SUMMARY GRAIN
-- ============================================================

SELECT
    COUNT(*) AS duplicate_order_groups
FROM (
    SELECT
        order_id
    FROM order_review_summary
    GROUP BY order_id
    HAVING COUNT(*) > 1
);


-- ============================================================
-- 8. REVENUE RECONCILIATION
-- ============================================================

SELECT
    ROUND(SUM(price), 2) AS raw_product_revenue,
    ROUND(
        (
            SELECT SUM(product_revenue)
            FROM order_item_summary
        ),
        2
    ) AS summarized_product_revenue
FROM order_items;


-- ============================================================
-- 9. FREIGHT RECONCILIATION
-- ============================================================

SELECT
    ROUND(SUM(freight_value), 2) AS raw_freight,
    ROUND(
        (
            SELECT SUM(total_freight)
            FROM order_item_summary
        ),
        2
    ) AS summarized_freight
FROM order_items;


-- ============================================================
-- 10. PAYMENT RECONCILIATION
-- ============================================================

SELECT
    ROUND(SUM(payment_value), 2) AS raw_payment_value,
    ROUND(
        (
            SELECT SUM(total_payment_value)
            FROM order_payment_summary
        ),
        2
    ) AS summarized_payment_value
FROM order_payments;


-- ============================================================
-- 11. CHECK CATEGORY FALLBACK
-- ============================================================

SELECT
    product_category_name,
    product_category_name_english,
    COUNT(*) AS product_count
FROM product_clean
WHERE product_category_name IN (
    'pc_gamer',
    'portateis_cozinha_e_preparadores_de_alimentos'
)
GROUP BY
    product_category_name,
    product_category_name_english
ORDER BY product_category_name;


-- ============================================================
-- 12. SAMPLE ORDERS_ENRICHED
-- ============================================================

SELECT *
FROM orders_enriched
ORDER BY order_purchase_timestamp
LIMIT 10;