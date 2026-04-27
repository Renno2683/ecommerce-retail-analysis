-- =============================================================
-- 05_product_performance.sql
-- E-Commerce Retail Analysis — Product Performance
-- =============================================================
-- Business questions answered:
--   1. Which products have the highest return rates?
--   2. Which categories have the best gross margin?
--   3. What is the revenue vs. volume relationship per product?
--   4. Which products are "high volume but low value"?
-- =============================================================


-- -------------------------------------------------------------
-- Q1: Product-level performance — revenue, volume, return rate
-- -------------------------------------------------------------

WITH product_stats AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        p.cost_price,

        -- Completed order metrics
        SUM(CASE WHEN o.order_status = 'completed'
                 THEN oi.quantity * oi.unit_price ELSE 0 END)  AS gross_revenue,

        SUM(CASE WHEN o.order_status = 'completed'
                 THEN oi.quantity ELSE 0 END)                  AS units_sold,

        COUNT(DISTINCT CASE WHEN o.order_status = 'completed'
                            THEN o.order_id END)               AS completed_orders,

        -- Return metrics
        COUNT(DISTINCT CASE WHEN o.order_status = 'returned'
                            THEN o.order_id END)               AS returned_orders,

        COUNT(DISTINCT o.order_id)                            AS total_orders

    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o       ON oi.order_id = o.order_id
    GROUP BY p.product_id, p.product_name, p.category, p.cost_price
)
SELECT
    product_id,
    product_name,
    category,
    gross_revenue,
    units_sold,
    completed_orders,
    returned_orders,
    total_orders,

    -- Return rate (as % of all orders placed)
    ROUND(
        100.0 * returned_orders / NULLIF(total_orders, 0),
        1
    )                                                AS return_rate_pct,

    -- Average selling price
    ROUND(gross_revenue / NULLIF(units_sold, 0), 2) AS avg_unit_price,

    -- Gross margin per unit (price - cost) / price
    ROUND(
        100.0 * (gross_revenue / NULLIF(units_sold, 0) - cost_price)
              / NULLIF(gross_revenue / NULLIF(units_sold, 0), 0),
        1
    )                                                AS gross_margin_pct

FROM product_stats
ORDER BY gross_revenue DESC;


-- -------------------------------------------------------------
-- Q2: Category-level return rate benchmarks
-- (Used to flag products with above-average return rates)
-- -------------------------------------------------------------

SELECT
    p.category,
    COUNT(DISTINCT CASE WHEN o.order_status = 'returned' THEN o.order_id END)  AS returns,
    COUNT(DISTINCT o.order_id)                                                  AS total_orders,
    ROUND(
        100.0
        * COUNT(DISTINCT CASE WHEN o.order_status = 'returned' THEN o.order_id END)
        / COUNT(DISTINCT o.order_id),
        1
    )                                                                           AS category_return_rate_pct,
    ROUND(
        SUM(CASE WHEN o.order_status = 'completed' THEN oi.quantity * oi.unit_price ELSE 0 END)
        / NULLIF(SUM(CASE WHEN o.order_status = 'completed' THEN oi.quantity ELSE 0 END), 0),
        2
    )                                                                           AS avg_unit_price,
    ROUND(
        AVG(p.cost_price),
        2
    )                                                                           AS avg_cost_price

FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o       ON oi.order_id = o.order_id
GROUP BY p.category
ORDER BY category_return_rate_pct DESC;


-- -------------------------------------------------------------
-- Q3: High-volume, low-margin products — risk flag
-- Products in top 50% of unit volume but bottom 25% of margin
-- -------------------------------------------------------------

WITH product_stats AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        SUM(CASE WHEN o.order_status = 'completed' THEN oi.quantity ELSE 0 END)             AS units_sold,
        SUM(CASE WHEN o.order_status = 'completed' THEN oi.quantity * oi.unit_price ELSE 0 END) AS revenue,
        AVG(p.cost_price) AS cost_price,
        AVG(oi.unit_price) AS avg_price
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o       ON oi.order_id = o.order_id
    GROUP BY p.product_id, p.product_name, p.category
),
ranked AS (
    SELECT *,
        ROUND(100.0 * (avg_price - cost_price) / NULLIF(avg_price, 0), 1) AS margin_pct,
        NTILE(4) OVER (ORDER BY units_sold)  AS volume_quartile,
        NTILE(4) OVER (ORDER BY
            (avg_price - cost_price) / NULLIF(avg_price, 0)
        )                                    AS margin_quartile
    FROM product_stats
)
SELECT
    product_id,
    product_name,
    category,
    units_sold,
    ROUND(revenue, 2)  AS revenue,
    margin_pct,
    '⚠️ High Volume / Low Margin' AS flag
FROM ranked
WHERE volume_quartile >= 3    -- top 50% by volume
  AND margin_quartile = 1     -- bottom 25% by margin
ORDER BY units_sold DESC;
