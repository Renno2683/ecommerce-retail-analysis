-- =============================================================
-- 02_revenue_analysis.sql
-- E-Commerce Retail Analysis — Revenue Trends
-- =============================================================
-- Business questions answered:
--   1. What is our monthly revenue trend?
--   2. Which product categories drive the most revenue?
--   3. How does month-over-month growth vary by category?
--   4. Which acquisition channels bring in the highest-value customers?
-- =============================================================


-- -------------------------------------------------------------
-- Q1: Monthly revenue trend (completed orders only)
-- -------------------------------------------------------------
-- We exclude 'returned' and 'cancelled' orders from revenue.
-- Using DATE_TRUNC for PostgreSQL; replace with strftime('%Y-%m', order_date) for SQLite.

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_date)        AS order_month,
        SUM(oi.quantity * oi.unit_price)          AS revenue,
        COUNT(DISTINCT o.order_id)                AS num_orders,
        COUNT(DISTINCT o.customer_id)             AS unique_customers
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'completed'
    GROUP BY 1
)
SELECT
    order_month,
    revenue,
    num_orders,
    unique_customers,
    ROUND(revenue / num_orders, 2)                AS avg_order_value,

    -- Month-over-month revenue growth %
    LAG(revenue) OVER (ORDER BY order_month)      AS prev_month_revenue,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (ORDER BY order_month))
              / NULLIF(LAG(revenue) OVER (ORDER BY order_month), 0),
        1
    )                                             AS mom_growth_pct

FROM monthly_revenue
ORDER BY order_month;


-- -------------------------------------------------------------
-- Q2: Revenue by product category (full period)
-- -------------------------------------------------------------

SELECT
    p.category,
    SUM(oi.quantity * oi.unit_price)              AS total_revenue,
    COUNT(DISTINCT o.order_id)                    AS num_orders,
    ROUND(
        100.0 * SUM(oi.quantity * oi.unit_price)
              / SUM(SUM(oi.quantity * oi.unit_price)) OVER (),
        1
    )                                             AS revenue_share_pct,
    ROUND(SUM(oi.quantity * oi.unit_price)
          / COUNT(DISTINCT o.order_id), 2)        AS avg_order_value

FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p     ON oi.product_id = p.product_id
WHERE o.order_status = 'completed'
GROUP BY p.category
ORDER BY total_revenue DESC;


-- -------------------------------------------------------------
-- Q3: Monthly revenue by category (pivot-ready output)
-- -------------------------------------------------------------

SELECT
    DATE_TRUNC('month', o.order_date)            AS order_month,
    p.category,
    SUM(oi.quantity * oi.unit_price)             AS revenue

FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p     ON oi.product_id = p.product_id
WHERE o.order_status = 'completed'
GROUP BY 1, 2
ORDER BY 1, 3 DESC;


-- -------------------------------------------------------------
-- Q4: Revenue by acquisition channel
-- Higher avg_order_value = more valuable acquisition source
-- -------------------------------------------------------------

SELECT
    c.channel,
    COUNT(DISTINCT c.customer_id)                AS customers,
    COUNT(DISTINCT o.order_id)                   AS orders,
    SUM(oi.quantity * oi.unit_price)             AS total_revenue,
    ROUND(
        SUM(oi.quantity * oi.unit_price)
        / COUNT(DISTINCT c.customer_id), 2
    )                                            AS revenue_per_customer,
    ROUND(
        SUM(oi.quantity * oi.unit_price)
        / COUNT(DISTINCT o.order_id), 2
    )                                            AS avg_order_value

FROM customers c
JOIN orders o       ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'completed'
GROUP BY c.channel
ORDER BY revenue_per_customer DESC;
