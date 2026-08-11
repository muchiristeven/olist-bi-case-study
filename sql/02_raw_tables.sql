/*
============================================================
OLIST E-COMMERCE BUSINESS INTELLIGENCE CASE STUDY
02 - Raw Table Definitions
============================================================

Purpose:
Create the raw PostgreSQL tables used to store the original
Olist e-commerce source datasets before transformation.

The raw layer preserves the source structure as closely as
possible and acts as the foundation for the staging and
analytics layers.

Database: PostgreSQL
============================================================
*/


-- =========================================================
-- 1. PRODUCT CATEGORY TRANSLATION
-- Source: product_category_name_translation.csv
-- =========================================================

CREATE TABLE IF NOT EXISTS raw.category_translation (
    product_category_name         VARCHAR,
    product_category_name_english VARCHAR
);


-- =========================================================
-- 2. CUSTOMERS
-- Source: olist_customers_dataset.csv
-- =========================================================

CREATE TABLE IF NOT EXISTS raw.customers (
    customer_id              VARCHAR(32),
    customer_unique_id       VARCHAR(32),
    customer_zip_code_prefix INTEGER,
    customer_city            VARCHAR(100),
    customer_state           CHAR(2)
);


-- =========================================================
-- 3. ORDER ITEMS
-- Source: olist_order_items_dataset.csv
-- Grain: one row per item within an order
-- =========================================================

CREATE TABLE IF NOT EXISTS raw.order_items (
    order_id            VARCHAR(32),
    order_item_id       INTEGER,
    product_id          VARCHAR(32),
    seller_id           VARCHAR(32),
    shipping_limit_date TIMESTAMP,
    price               NUMERIC(10,2),
    freight_value       NUMERIC(10,2)
);


-- =========================================================
-- 4. ORDER PAYMENTS
-- Source: olist_order_payments_dataset.csv
-- Grain: one row per payment transaction
-- =========================================================

CREATE TABLE IF NOT EXISTS raw.order_payments (
    order_id             VARCHAR(32),
    payment_sequential   INTEGER,
    payment_type         VARCHAR(20),
    payment_installments INTEGER,
    payment_value        NUMERIC(10,2)
);


-- =========================================================
-- 5. ORDER REVIEWS
-- Source: olist_order_reviews_dataset.csv
-- =========================================================

CREATE TABLE IF NOT EXISTS raw.order_reviews (
    review_id               VARCHAR,
    order_id                VARCHAR,
    review_score            INTEGER,
    review_comment_title    VARCHAR,
    review_comment_message  VARCHAR,
    review_creation_date    DATE,
    review_answer_timestamp TIMESTAMP
);


-- =========================================================
-- 6. ORDERS
-- Source: olist_orders_dataset.csv
-- Grain: one row per order
-- =========================================================

CREATE TABLE IF NOT EXISTS raw.orders (
    order_id                      VARCHAR(32),
    customer_id                   VARCHAR(32),
    order_status                  VARCHAR(20),
    order_purchase_timestamp      TIMESTAMP,
    order_approved_at             TIMESTAMP,
    order_delivered_carrier_date  TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);


-- =========================================================
-- 7. PRODUCTS
-- Source: olist_products_dataset.csv
-- =========================================================

CREATE TABLE IF NOT EXISTS raw.products (
    product_id                 VARCHAR,
    product_category_name      VARCHAR,
    product_name_lenght        INTEGER,
    product_description_lenght INTEGER,
    product_photos_qty         INTEGER,
    product_weight_g           INTEGER,
    product_length_cm          INTEGER,
    product_height_cm          INTEGER,
    product_width_cm           INTEGER
);


-- =========================================================
-- 8. SELLERS
-- Source: olist_sellers_dataset.csv
-- =========================================================

CREATE TABLE IF NOT EXISTS raw.sellers (
    seller_id              VARCHAR,
    seller_zip_code_prefix INTEGER,
    seller_city            VARCHAR,
    seller_state           VARCHAR
);
