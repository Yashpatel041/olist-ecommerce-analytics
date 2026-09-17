CREATE OR REPLACE TABLE customer_rfm_segmented AS
SELECT
    customer_unique_id,
    recency_days,
    frequency,
    monetary,
    recency_score,
    monetary_score,
    customer_type,

    CASE
        WHEN customer_type = 'Repeat Customer'
             AND recency_score >= 4
             AND monetary_score >= 4
            THEN 'High-Value Active'

        WHEN customer_type = 'Repeat Customer'
             AND recency_score >= 4
            THEN 'Active Repeat'

        WHEN customer_type = 'Repeat Customer'
             AND recency_score <= 2
            THEN 'At-Risk Repeat'

        WHEN customer_type = 'One-Time Customer'
             AND recency_score >= 4
             AND monetary_score >= 4
            THEN 'Recent High-Value One-Time'

        WHEN customer_type = 'One-Time Customer'
             AND recency_score <= 2
            THEN 'Inactive One-Time'

        ELSE 'Other'
    END AS customer_segment

FROM customer_rfm_scored;