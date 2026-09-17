CREATE OR REPLACE TABLE dashboard_trend_dataset AS

WITH order_customer_type AS (
    SELECT
        o.order_id,
        o.customer_unique_id,
        o.order_purchase_timestamp,
        o.total_payment_value,

        CASE
            WHEN o.order_purchase_timestamp =
                 MIN(o.order_purchase_timestamp)
                 OVER (PARTITION BY o.customer_unique_id)
            THEN 'New Customer Order'
            ELSE 'Repeat Customer Order'
        END AS order_customer_type

    FROM orders_enriched o

    WHERE o.customer_unique_id IS NOT NULL
),

monthly_summary AS (
    SELECT
        DATE_TRUNC(
            'month',
            order_purchase_timestamp
        ) AS order_month,

        COUNT(DISTINCT order_id) AS total_orders,

        COUNT(
            DISTINCT customer_unique_id
        ) AS active_customers,

        COUNT(
            DISTINCT CASE
                WHEN order_customer_type = 'New Customer Order'
                THEN customer_unique_id
            END
        ) AS new_customers,

        COUNT(
            DISTINCT CASE
                WHEN order_customer_type = 'Repeat Customer Order'
                THEN customer_unique_id
            END
        ) AS repeat_customers,

        SUM(total_payment_value) AS revenue,

        SUM(
            CASE
                WHEN order_customer_type = 'Repeat Customer Order'
                THEN 1
                ELSE 0
            END
        ) AS repeat_orders

    FROM order_customer_type

    GROUP BY
        DATE_TRUNC(
            'month',
            order_purchase_timestamp
        )
)

SELECT
    order_month,

    total_orders,

    active_customers,

    new_customers,

    repeat_customers,

    ROUND(revenue, 2) AS revenue,

    ROUND(
        revenue / NULLIF(total_orders, 0),
        2
    ) AS avg_order_value,

    repeat_orders,

    ROUND(
        100.0 * repeat_orders
        / NULLIF(total_orders, 0),
        2
    ) AS repeat_order_share_pct

FROM monthly_summary

ORDER BY order_month;