-- =============================================================
-- 01_schema.sql
-- E-Commerce Retail Analysis — Table Definitions
-- =============================================================
-- Compatible with: PostgreSQL, SQLite, BigQuery (minor tweaks)
-- Run this first to establish the schema before running other scripts.
-- =============================================================


-- -------------------------------------------------------------
-- CUSTOMERS
-- One row per registered customer.
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS customers (
    customer_id  INTEGER      PRIMARY KEY,
    signup_date  DATE         NOT NULL,
    region       VARCHAR(50)  NOT NULL,   -- e.g. 'NSW', 'VIC', 'QLD'
    channel      VARCHAR(50)  NOT NULL    -- acquisition channel
);


-- -------------------------------------------------------------
-- PRODUCTS
-- Product catalogue with category and cost info.
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS products (
    product_id   INTEGER       PRIMARY KEY,
    product_name VARCHAR(200)  NOT NULL,
    category     VARCHAR(100)  NOT NULL,
    cost_price   DECIMAL(10,2) NOT NULL   -- internal cost for margin calc
);


-- -------------------------------------------------------------
-- ORDERS
-- One row per order (header level).
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS orders (
    order_id      INTEGER       PRIMARY KEY,
    customer_id   INTEGER       NOT NULL REFERENCES customers(customer_id),
    order_date    DATE          NOT NULL,
    order_status  VARCHAR(20)   NOT NULL   -- 'completed' | 'returned' | 'cancelled'
    -- total_amount is derived from order_items to avoid denormalisation,
    -- but can be stored here as a cache if needed.
);


-- -------------------------------------------------------------
-- ORDER_ITEMS
-- One row per product line within an order.
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS order_items (
    item_id     INTEGER       PRIMARY KEY,
    order_id    INTEGER       NOT NULL REFERENCES orders(order_id),
    product_id  INTEGER       NOT NULL REFERENCES products(product_id),
    quantity    INTEGER       NOT NULL CHECK (quantity > 0),
    unit_price  DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0)
);


-- -------------------------------------------------------------
-- Useful indexes for query performance
-- -------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_orders_customer   ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_date       ON orders(order_date);
CREATE INDEX IF NOT EXISTS idx_items_order       ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_items_product     ON order_items(product_id);
