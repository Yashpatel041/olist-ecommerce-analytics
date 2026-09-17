-- ============================================================
-- OLIST E-COMMERCE ANALYTICS
-- Phase 3: Exploratory Data Analysis
-- Step 3.3: Product & Category Analysis
-- ============================================================


-- ============================================================
-- 1. CATEGORY PERFORMANCE OVERVIEW
-- ============================================================

SELECT
    COALESCE(
        product_category_name_english,
        'Unknown Category'
    ) AS category,

    COUNT(DISTINCT order_id) AS total_orders,

    COUNT(*) AS units_sold,

    COUNT(DISTINCT product_id) AS unique_products,

    ROUND(SUM(price), 2) AS product_revenue,

    ROUND(SUM(freight_value), 2) AS freight,

    ROUND(SUM(price + freight_value), 2) AS total_value,

    ROUND(AVG(price), 2) AS average_item_price

FROM order_items_enriched

GROUP BY category

ORDER BY product_revenue DESC;


-- ============================================================
-- 2. TOP 10 CATEGORIES BY REVENUE
-- ============================================================

SELECT
    COALESCE(
        product_category_name_english,
        'Unknown Category'
    ) AS category,

    ROUND(SUM(price), 2) AS revenue,

    COUNT(*) AS units_sold,

    COUNT(DISTINCT order_id) AS total_orders

FROM order_items_enriched

GROUP BY category

ORDER BY revenue DESC

LIMIT 10;


-- ============================================================
-- 3. TOP 10 CATEGORIES BY UNITS SOLD
-- ============================================================

SELECT
    COALESCE(
        product_category_name_english,
        'Unknown Category'
    ) AS category,

    COUNT(*) AS units_sold,

    COUNT(DISTINCT order_id) AS total_orders,

    ROUND(SUM(price), 2) AS revenue

FROM order_items_enriched

GROUP BY category

ORDER BY units_sold DESC

LIMIT 10;


-- ============================================================
-- 4. TOP 10 CATEGORIES BY NUMBER OF ORDERS
-- ============================================================

SELECT
    COALESCE(
        product_category_name_english,
        'Unknown Category'
    ) AS category,

    COUNT(DISTINCT order_id) AS total_orders,

    COUNT(*) AS units_sold,

    ROUND(SUM(price), 2) AS revenue

FROM order_items_enriched

GROUP BY category

ORDER BY total_orders DESC

LIMIT 10;


-- ============================================================
-- 5. CATEGORY AVERAGE ITEM PRICE
-- ============================================================

SELECT
    COALESCE(
        product_category_name_english,
        'Unknown Category'
    ) AS category,

    COUNT(*) AS units_sold,

    ROUND(AVG(price), 2) AS average_item_price,

    ROUND(
        SUM(price) / NULLIF(COUNT(*), 0),
        2
    ) AS revenue_per_unit

FROM order_items_enriched

GROUP BY category

HAVING COUNT(*) >= 100

ORDER BY average_item_price DESC

LIMIT 10;


-- ============================================================
-- 6. CATEGORY REVIEW PERFORMANCE
-- ============================================================

SELECT
    COALESCE(
        oi.product_category_name_english,
        'Unknown Category'
    ) AS category,

    COUNT(DISTINCT oi.order_id) AS reviewed_orders,

    ROUND(
        AVG(orv.average_review_score),
        2
    ) AS average_review_score,

    ROUND(
        AVG(oi.price),
        2
    ) AS average_item_price

FROM order_items_enriched oi

JOIN order_review_summary orv
    ON oi.order_id = orv.order_id

WHERE orv.average_review_score IS NOT NULL

GROUP BY category

HAVING COUNT(DISTINCT oi.order_id) >= 100

ORDER BY average_review_score ASC

LIMIT 10;


-- ============================================================
-- 7. HIGH-REVENUE CATEGORIES WITH CUSTOMER RATINGS
-- ============================================================

WITH category_sales AS (

    SELECT
        COALESCE(
            product_category_name_english,
            'Unknown Category'
        ) AS category,

        COUNT(DISTINCT order_id) AS total_orders,

        COUNT(*) AS units_sold,

        ROUND(SUM(price), 2) AS revenue

    FROM order_items_enriched

    GROUP BY category

)

SELECT
    cs.category,
    cs.total_orders,
    cs.units_sold,
    cs.revenue,

    ROUND(
        AVG(ors.average_review_score),
        2
    ) AS average_review_score

FROM category_sales cs

LEFT JOIN order_items_enriched oi
    ON cs.category =
       COALESCE(
           oi.product_category_name_english,
           'Unknown Category'
       )

LEFT JOIN order_review_summary ors
    ON oi.order_id = ors.order_id

GROUP BY
    cs.category,
    cs.total_orders,
    cs.units_sold,
    cs.revenue

HAVING cs.total_orders >= 100

ORDER BY cs.revenue DESC

LIMIT 15;