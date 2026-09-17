CREATE OR REPLACE TABLE customer_churn_dataset AS
SELECT
    f.customer_unique_id,

    -- Customer behavior
    f.total_orders,
    f.customer_lifetime_days,
    f.total_spent,
    f.total_freight,
    f.avg_order_value,
    f.total_items,
    f.unique_products,
    f.unique_sellers,

    -- Delivery behavior
    f.late_orders,
    f.late_rate,
    f.avg_delivery_days,
    f.avg_delivery_delay,

    -- Review behavior
    f.avg_review_score,
    f.low_rating_orders,
    f.low_rating_rate,

    -- RFM
    r.recency_days,
    r.frequency,
    r.monetary,
    r.recency_score,
    r.monetary_score,
    r.customer_type,

    -- Target
    c.churned

FROM customer_churn_features f

INNER JOIN customer_rfm_scored r
    ON f.customer_unique_id = r.customer_unique_id

INNER JOIN customer_churn_labels c
    ON f.customer_unique_id = c.customer_unique_id;