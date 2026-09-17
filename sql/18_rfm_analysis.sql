-- ============================================================
-- PHASE 4.2: RFM ANALYSIS
-- ============================================================
-- RFM = Recency, Frequency, Monetary
--
-- Grain:
-- 1 row = 1 customer_unique_id
--
-- Reference date:
-- 2018-10-17
-- ============================================================


CREATE OR REPLACE TABLE customer_rfm AS

SELECT

    customer_unique_id,

    -- --------------------------------------------------------
    -- RECENCY
    -- Number of days since the customer's last purchase
    -- --------------------------------------------------------

    DATE_DIFF(
        'day',
        CAST(last_order_date AS DATE),
        DATE '2018-10-17'
    ) AS recency_days,


    -- --------------------------------------------------------
    -- FREQUENCY
    -- Number of orders made by the customer
    -- --------------------------------------------------------

    total_orders AS frequency,


    -- --------------------------------------------------------
    -- MONETARY
    -- Total amount spent by the customer
    -- --------------------------------------------------------

    total_spent AS monetary


FROM customer_features;