CREATE OR REPLACE TABLE dashboard_rfm_dataset AS

SELECT
    customer_segment,

    COUNT(*) AS customer_count,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_share_pct,

    ROUND(AVG(recency_days), 2) AS avg_recency_days,

    ROUND(AVG(frequency), 2) AS avg_frequency,

    ROUND(AVG(monetary), 2) AS avg_monetary_value,

    ROUND(AVG(recency_score), 2) AS avg_recency_score,

    ROUND(AVG(monetary_score), 2) AS avg_monetary_score

FROM customer_rfm_segmented

GROUP BY customer_segment

ORDER BY
    CASE customer_segment
        WHEN 'High-Value Active' THEN 1
        WHEN 'Active Repeat' THEN 2
        WHEN 'Recent High-Value One-Time' THEN 3
        WHEN 'At-Risk Repeat' THEN 4
        WHEN 'Inactive One-Time' THEN 5
        WHEN 'Other' THEN 6
        ELSE 7
    END;