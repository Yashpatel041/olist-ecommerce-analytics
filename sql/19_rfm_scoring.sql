-- ============================================================
-- PHASE 4.2.3: RFM SCORING
-- ============================================================
-- Recency:
--   5 = most recent
--   1 = least recent
--
-- Monetary:
--   5 = highest spending
--   1 = lowest spending
--
-- Frequency:
--   Kept as raw frequency because 96.88% of customers
--   have exactly one order.
-- ============================================================

CREATE OR REPLACE TABLE customer_rfm_scored AS

SELECT
    customer_unique_id,

    recency_days,

    frequency,

    monetary,

    -- --------------------------------------------------------
    -- RECENCY SCORE
    -- Lower recency is better
    -- --------------------------------------------------------

    NTILE(5) OVER (
        ORDER BY recency_days DESC
    ) AS recency_score,


    -- --------------------------------------------------------
    -- MONETARY SCORE
    -- Higher monetary value is better
    -- --------------------------------------------------------

    NTILE(5) OVER (
        ORDER BY monetary
    ) AS monetary_score,


    -- --------------------------------------------------------
    -- CUSTOMER TYPE
    -- --------------------------------------------------------

    CASE
        WHEN frequency = 1
            THEN 'One-Time Customer'
        ELSE 'Repeat Customer'
    END AS customer_type

FROM customer_rfm;