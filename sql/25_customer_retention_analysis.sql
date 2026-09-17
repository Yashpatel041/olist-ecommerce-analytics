CREATE OR REPLACE TABLE customer_retention_analysis AS

SELECT
    customer_unique_id,

    COUNT(DISTINCT order_id) AS total_orders,

    MIN(order_purchase_timestamp) AS first_order_date,

    MAX(order_purchase_timestamp) AS last_order_date,

    ROUND(SUM(total_payment_value), 2) AS total_spent,

    ROUND(AVG(total_payment_value), 2) AS avg_order_value,

    SUM(total_items) AS total_items,

    SUM(unique_sellers) AS total_sellers,

    ROUND(AVG(average_review_score), 2) AS avg_review_score,

    CASE
        WHEN COUNT(DISTINCT order_id) = 1
            THEN 'One-Time Customer'
        ELSE 'Repeat Customer'
    END AS customer_type

FROM orders_enriched

WHERE customer_unique_id IS NOT NULL

GROUP BY customer_unique_id;