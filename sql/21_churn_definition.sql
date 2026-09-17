CREATE OR REPLACE TABLE customer_churn_labels AS
SELECT
    customer_unique_id,
    last_order_date,

    DATE_DIFF(
        'day',
        CAST(last_order_date AS DATE),
        DATE '2018-08-31'
    ) AS days_since_last_order,

    CASE
        WHEN CAST(last_order_date AS DATE) <= DATE '2018-03-04'
            THEN 1
        ELSE 0
    END AS churned

FROM customer_features

WHERE CAST(last_order_date AS DATE) <= DATE '2018-08-31';