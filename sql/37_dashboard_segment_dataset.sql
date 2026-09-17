CREATE OR REPLACE TABLE dashboard_segment_dataset AS

SELECT
    business_segment,

    customer_count,

    customer_share_pct,

    total_revenue,

    revenue_share_pct,

    avg_orders,

    avg_customer_spend,

    avg_order_value,

    avg_items,

    avg_sellers,

    avg_late_rate_pct,

    avg_delivery_days,

    avg_review_score,

    low_rating_rate_pct

FROM customer_business_segments

ORDER BY
    CASE business_segment
        WHEN 'High-Value Repeat' THEN 1
        WHEN 'High-Value One-Time' THEN 2
        WHEN 'Low-Value Repeat' THEN 3
        WHEN 'Low-Value One-Time' THEN 4
    END;