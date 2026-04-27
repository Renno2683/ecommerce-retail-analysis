-- =============================================================
-- 04_rfm_segmentation.sql
-- E-Commerce Retail Analysis — RFM Customer Segmentation
-- =============================================================
-- RFM = Recency · Frequency · Monetary
--
-- Recency  : How recently did the customer order?
-- Frequency: How many orders have they placed?
-- Monetary : How much have they spent in total?
--
-- Each dimension is scored 1–4 (4 = best).
-- Combined score determines customer segment.
-- =============================================================


-- -------------------------------------------------------------
-- STEP 1: Calculate raw RFM values per customer
-- -------------------------------------------------------------
-- Adjust the snapshot date to your analysis period end.
-- Using 2024-01-01 as "today" for a dataset ending Dec 2023.

WITH rfm_raw AS (
    SELECT
        o.customer_id,
        MAX(o.order_date)                          AS last_order_date,
        DATE '2024-01-01' - MAX(o.order_date)      AS recency_days,   -- lower = better
        COUNT(DISTINCT o.order_id)                 AS frequency,
        SUM(oi.quantity * oi.unit_price)           AS monetary

    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'completed'
    GROUP BY o.customer_id
),

-- -------------------------------------------------------------
-- STEP 2: Assign quartile scores (1–4) using NTILE
-- Recency: REVERSED — lower days = higher score
-- -------------------------------------------------------------

rfm_scored AS (
    SELECT
        customer_id,
        last_order_date,
        recency_days,
        frequency,
        ROUND(monetary, 2)                         AS monetary,

        -- Recency score: fewer days since last order → higher score
        5 - NTILE(4) OVER (ORDER BY recency_days)  AS r_score,

        -- Frequency score: more orders → higher score
        NTILE(4) OVER (ORDER BY frequency)          AS f_score,

        -- Monetary score: higher spend → higher score
        NTILE(4) OVER (ORDER BY monetary)           AS m_score

    FROM rfm_raw
),

-- -------------------------------------------------------------
-- STEP 3: Combine scores and assign human-readable segments
-- -------------------------------------------------------------

rfm_segments AS (
    SELECT
        *,
        CONCAT(r_score, f_score, m_score)          AS rfm_score,
        (r_score + f_score + m_score)              AS rfm_total,

        CASE
            -- Champions: bought recently, buy often, spend most
            WHEN r_score = 4 AND f_score >= 3 AND m_score >= 3
                THEN 'Champions'

            -- Loyal Customers: buy often and spend well
            WHEN f_score >= 3 AND m_score >= 3
                THEN 'Loyal Customers'

            -- Potential Loyalists: recent, decent frequency
            WHEN r_score >= 3 AND f_score >= 2
                THEN 'Potential Loyalists'

            -- Recent Customers: bought recently but not much yet
            WHEN r_score = 4 AND f_score = 1
                THEN 'New Customers'

            -- At Risk: used to be good, haven't bought recently
            WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3
                THEN 'At Risk'

            -- Can't Lose Them: big spenders, haven't returned
            WHEN r_score = 1 AND m_score = 4
                THEN 'Cant Lose Them'

            -- Hibernating: low recency, low frequency, low spend
            WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2
                THEN 'Hibernating'

            ELSE 'Needs Attention'
        END                                        AS segment

    FROM rfm_scored
)

-- -------------------------------------------------------------
-- OUTPUT: Full RFM table (use for dashboards or Python import)
-- -------------------------------------------------------------

SELECT * FROM rfm_segments
ORDER BY rfm_total DESC;


-- =============================================================
-- SUMMARY: Segment-level aggregates for reporting
-- =============================================================

WITH rfm_raw AS (
    SELECT o.customer_id,
           DATE '2024-01-01' - MAX(o.order_date)  AS recency_days,
           COUNT(DISTINCT o.order_id)             AS frequency,
           SUM(oi.quantity * oi.unit_price)       AS monetary
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'completed'
    GROUP BY o.customer_id
),
rfm_scored AS (
    SELECT *,
           5 - NTILE(4) OVER (ORDER BY recency_days) AS r_score,
           NTILE(4)     OVER (ORDER BY frequency)    AS f_score,
           NTILE(4)     OVER (ORDER BY monetary)     AS m_score
    FROM rfm_raw
),
rfm_segments AS (
    SELECT *,
        CASE
            WHEN r_score = 4 AND f_score >= 3 AND m_score >= 3 THEN 'Champions'
            WHEN f_score >= 3 AND m_score >= 3                 THEN 'Loyal Customers'
            WHEN r_score >= 3 AND f_score >= 2                 THEN 'Potential Loyalists'
            WHEN r_score = 4 AND f_score = 1                   THEN 'New Customers'
            WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3 THEN 'At Risk'
            WHEN r_score = 1 AND m_score = 4                   THEN 'Cant Lose Them'
            WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'Hibernating'
            ELSE 'Needs Attention'
        END AS segment
    FROM rfm_scored
)
SELECT
    segment,
    COUNT(*)                           AS num_customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_base,
    ROUND(AVG(monetary), 2)            AS avg_spend,
    ROUND(SUM(monetary), 2)            AS total_revenue,
    ROUND(100.0 * SUM(monetary)
          / SUM(SUM(monetary)) OVER (), 1)            AS revenue_share_pct,
    ROUND(AVG(recency_days), 0)        AS avg_recency_days,
    ROUND(AVG(frequency), 1)           AS avg_orders

FROM rfm_segments
GROUP BY segment
ORDER BY total_revenue DESC;
