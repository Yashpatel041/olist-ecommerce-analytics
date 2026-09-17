-- ============================================
-- Phase 5.4.5
-- Dashboard Validation
-- ============================================

-- 1. Base customer count
SELECT
    'Base Customer Count' AS validation_check,
    COUNT(*) AS expected_value,
    (SELECT total_customers
     FROM customer_dashboard_kpis) AS dashboard_value,
    CASE
        WHEN COUNT(*) =
             (SELECT total_customers
              FROM customer_dashboard_kpis)
        THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM customer_features;


-- 2. Revenue reconciliation
SELECT
    'Revenue Reconciliation' AS validation_check,
    ROUND(SUM(total_spent), 2) AS expected_value,
    (
        SELECT total_revenue
        FROM customer_dashboard_kpis
    ) AS dashboard_value,
    CASE
        WHEN ROUND(SUM(total_spent), 2) =
             (
                 SELECT total_revenue
                 FROM customer_dashboard_kpis
             )
        THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM customer_features;


-- 3. Business segment customer count
SELECT
    'Business Segment Customers' AS validation_check,
    SUM(customer_count) AS expected_value,
    (
        SELECT total_customers
        FROM customer_dashboard_kpis
    ) AS dashboard_value,
    CASE
        WHEN SUM(customer_count) =
             (
                 SELECT total_customers
                 FROM customer_dashboard_kpis
             )
        THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM customer_business_segments;


-- 4. Business segment revenue
SELECT
    'Business Segment Revenue' AS validation_check,
    ROUND(SUM(total_revenue), 2) AS expected_value,
    (
        SELECT total_revenue
        FROM customer_dashboard_kpis
    ) AS dashboard_value,
    CASE
        WHEN ROUND(SUM(total_revenue), 2) =
             (
                 SELECT total_revenue
                 FROM customer_dashboard_kpis
             )
        THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM customer_business_segments;


-- 5. RFM customer count
SELECT
    'RFM Customer Count' AS validation_check,
    SUM(customer_count) AS expected_value,
    (
        SELECT total_customers
        FROM customer_dashboard_kpis
    ) AS dashboard_value,
    CASE
        WHEN SUM(customer_count) =
             (
                 SELECT total_customers
                 FROM customer_dashboard_kpis
             )
        THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM dashboard_rfm_dataset;