-- =============================================================
-- 03_cohort_analysis.sql
-- E-Commerce Retail Analysis — Monthly Cohort Retention
-- =============================================================
-- Business questions answered:
--   1. How well do we retain customers across monthly cohorts?
--   2. Which cohorts show the strongest long-term retention?
--   3. What % of cohort revenue is generated in subsequent months?
-- =============================================================
-- NOTE: Cohort = the month a customer placed their FIRST order.
-- =============================================================


-- -------------------------------------------------------------
-- STEP 1: Identify each customer's first-order month (cohort)
-- -------------------------------------------------------------

WITH customer_cohorts AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(order_date)) AS cohort_month
    FROM orders
    WHERE order_status = 'completed'
    GROUP BY customer_id
),

-- -------------------------------------------------------------
-- STEP 2: Tag every completed order with the customer's cohort
--         and calculate months-since-first-order (period_number)
-- -------------------------------------------------------------

order_cohort_map AS (
    SELECT
        o.customer_id,
        cc.cohort_month,
        DATE_TRUNC('month', o.order_date)   AS order_month,

        -- How many months after cohort month did this order occur?
        -- Period 0 = acquisition month
        (EXTRACT(YEAR  FROM DATE_TRUNC('month', o.order_date))
         - EXTRACT(YEAR  FROM cc.cohort_month)) * 12
        + (EXTRACT(MONTH FROM DATE_TRUNC('month', o.order_date))
           - EXTRACT(MONTH FROM cc.cohort_month))   AS period_number

    FROM orders o
    JOIN customer_cohorts cc ON o.customer_id = cc.customer_id
    WHERE o.order_status = 'completed'
),

-- -------------------------------------------------------------
-- STEP 3: Count distinct active customers per cohort per period
-- -------------------------------------------------------------

cohort_activity AS (
    SELECT
        cohort_month,
        period_number,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM order_cohort_map
    GROUP BY 1, 2
),

-- -------------------------------------------------------------
-- STEP 4: Get the cohort starting size (period 0)
-- -------------------------------------------------------------

cohort_sizes AS (
    SELECT
        cohort_month,
        active_customers AS cohort_size
    FROM cohort_activity
    WHERE period_number = 0
)

-- -------------------------------------------------------------
-- FINAL: Retention table — each row is cohort × period
-- -------------------------------------------------------------

SELECT
    ca.cohort_month,
    cs.cohort_size,
    ca.period_number,
    ca.active_customers,
    ROUND(
        100.0 * ca.active_customers / cs.cohort_size,
        1
    )                     AS retention_pct

FROM cohort_activity ca
JOIN cohort_sizes cs ON ca.cohort_month = cs.cohort_month
ORDER BY ca.cohort_month, ca.period_number;


-- =============================================================
-- BONUS: Revenue cohort analysis
-- Same structure but tracks revenue instead of customer count
-- =============================================================

WITH customer_cohorts AS (
    SELECT customer_id,
           DATE_TRUNC('month', MIN(order_date)) AS cohort_month
    FROM orders WHERE order_status = 'completed'
    GROUP BY customer_id
),
cohort_revenue AS (
    SELECT
        cc.cohort_month,
        (EXTRACT(YEAR  FROM DATE_TRUNC('month', o.order_date))
         - EXTRACT(YEAR  FROM cc.cohort_month)) * 12
        + (EXTRACT(MONTH FROM DATE_TRUNC('month', o.order_date))
           - EXTRACT(MONTH FROM cc.cohort_month))         AS period_number,
        SUM(oi.quantity * oi.unit_price)                  AS period_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN customer_cohorts cc ON o.customer_id = cc.customer_id
    WHERE o.order_status = 'completed'
    GROUP BY 1, 2
),
cohort_initial_revenue AS (
    SELECT cohort_month, period_revenue AS initial_revenue
    FROM cohort_revenue WHERE period_number = 0
)
SELECT
    cr.cohort_month,
    cr.period_number,
    cr.period_revenue,
    ROUND(
        100.0 * cr.period_revenue / cir.initial_revenue,
        1
    )                     AS revenue_retention_pct
FROM cohort_revenue cr
JOIN cohort_initial_revenue cir ON cr.cohort_month = cir.cohort_month
ORDER BY cr.cohort_month, cr.period_number;
