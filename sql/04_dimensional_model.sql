/*
============================================================
OLIST E-COMMERCE BUSINESS INTELLIGENCE CASE STUDY
04 - Dimensional Model
============================================================

Purpose:
Build analytics-ready dimension and fact tables from the
staging layer for downstream use in Power BI.

Model:
- dim_customer
- dim_product
- dim_seller
- dim_date
- fact_sales
- fact_order_payment
- fact_reviews

Modelling approach:
Fact constellation with shared dimensions.

Primary grains:
- fact_sales         : one row per order item
- fact_order_payment : one row per order
- fact_reviews       : one row per order/review record

Database: PostgreSQL
============================================================
*/


-- =========================================================
-- 1. CUSTOMER DIMENSION
--
-- customer_id represents the customer record associated
-- with an order.
--
-- customer_unique_id provides the persistent customer
-- identity used for repeat-purchase analysis.
-- =========================================================

DROP TABLE IF EXISTS analytics.dim_customer;

CREATE TABLE analytics.dim_customer AS
SELECT DISTINCT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM staging.customers;


-- =========================================================
-- 2. PRODUCT DIMENSION
--
-- Contains descriptive product attributes used to filter
-- and group sales measures.
-- =========================================================

DROP TABLE IF EXISTS analytics.dim_product;

CREATE TABLE analytics.dim_product AS
SELECT DISTINCT
    product_id,
    product_category,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,
    product_volume_cm3
FROM staging.products;


-- =========================================================
-- 3. SELLER DIMENSION
--
-- Provides seller geography for filtering and potential
-- seller-level analysis.
-- =========================================================

DROP TABLE IF EXISTS analytics.dim_seller;

CREATE TABLE analytics.dim_seller AS
SELECT DISTINCT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM staging.sellers;


-- =========================================================
-- 4. DATE DIMENSION
--
-- Generate a continuous calendar covering the full range
-- of purchase dates contained in the order data.
-- =========================================================

DROP TABLE IF EXISTS analytics.dim_date;

CREATE TABLE analytics.dim_date AS

WITH date_range AS (
    SELECT
        MIN(purchase_date) AS min_date,
        MAX(purchase_date) AS max_date
    FROM staging.orders
),

calendar AS (
    SELECT
        GENERATE_SERIES(
            min_date::TIMESTAMP,
            max_date::TIMESTAMP,
            INTERVAL '1 day'
        ) AS calendar_date
    FROM date_range
)

SELECT
    calendar_date::TIMESTAMPTZ AS calendar_date,

    EXTRACT(
        YEAR FROM calendar_date
    )::INTEGER AS year,

    EXTRACT(
        QUARTER FROM calendar_date
    )::INTEGER AS quarter_number,

    (
        'Q'
        || EXTRACT(
            QUARTER FROM calendar_date
        )::INTEGER
    ) AS quarter_name,

    EXTRACT(
        MONTH FROM calendar_date
    )::INTEGER AS month_number,

    TO_CHAR(
        calendar_date,
        'FMMonth'
    ) AS month_name,

    TO_CHAR(
        calendar_date,
        'Mon'
    ) AS month_short,

    TO_CHAR(
        calendar_date,
        'YYYY-MM'
    ) AS year_month,

    (
        EXTRACT(YEAR FROM calendar_date)::INTEGER * 100
        + EXTRACT(MONTH FROM calendar_date)::INTEGER
    ) AS year_month_number,

    EXTRACT(
        DAY FROM calendar_date
    )::INTEGER AS day_of_month,

    EXTRACT(
        ISODOW FROM calendar_date
    )::INTEGER AS day_of_week_number,

    TO_CHAR(
        calendar_date,
        'FMDay'
    ) AS day_name,

    EXTRACT(
        WEEK FROM calendar_date
    )::INTEGER AS week_number,

    CASE
        WHEN EXTRACT(
            ISODOW FROM calendar_date
        ) IN (6, 7)
        THEN TRUE
        ELSE FALSE
    END AS is_weekend

FROM calendar

ORDER BY calendar_date;


-- =========================================================
-- 5. SALES FACT
--
-- Grain:
-- One row per order item.
--
-- Combines item-level commercial data with order-level
-- status and delivery information.
--
-- Review information is reduced to one review score per
-- order before joining so that review records do not
-- multiply item-level sales rows.
-- =========================================================

DROP TABLE IF EXISTS analytics.fact_sales;

CREATE TABLE analytics.fact_sales AS

WITH review_per_order AS (

    SELECT DISTINCT ON (order_id)
        order_id,
        review_score
    FROM staging.order_reviews

    ORDER BY
        order_id,
        review_answer_timestamp DESC NULLS LAST
)

SELECT
    oi.order_id,
    oi.order_item_id,
    o.customer_id,
    oi.product_id,
    oi.seller_id,

    o.purchase_date,
    o.order_status,
    o.order_status_group,

    oi.price,
    oi.freight_value,
    oi.gross_item_value,

    o.total_delivery_days,
    o.days_vs_estimate,
    o.delivery_performance,
    o.is_late_delivery,

    r.review_score

FROM staging.order_items oi

INNER JOIN staging.orders o
    ON oi.order_id = o.order_id

LEFT JOIN review_per_order r
    ON oi.order_id = r.order_id;


-- =========================================================
-- 6. ORDER PAYMENT FACT
--
-- Grain:
-- One row per order.
--
-- Payment transactions have already been aggregated to
-- order grain in the staging layer. This prevents payment
-- values from being duplicated across multiple order items.
-- =========================================================

DROP TABLE IF EXISTS analytics.fact_order_payment;

CREATE TABLE analytics.fact_order_payment AS
SELECT
    o.order_id,
    o.customer_id,
    o.purchase_date,
    o.order_status,
    o.order_status_group,

    p.payment_count,
    p.total_payment_value,
    p.max_installments,
    p.payment_methods

FROM staging.orders o

INNER JOIN staging.order_payments p
    ON o.order_id = p.order_id;


-- =========================================================
-- 7. REVIEW / DELIVERY FACT
--
-- Grain:
-- One row per order-review record.
--
-- Keeps review activity separate from order-item sales so
-- delivery and review metrics are not multiplied by the
-- number of items within an order.
-- =========================================================

DROP TABLE IF EXISTS analytics.fact_reviews;

CREATE TABLE analytics.fact_reviews AS
SELECT
    r.review_id,
    o.order_id,
    o.customer_id,
    o.purchase_date,
    o.order_status,
    o.order_status_group,

    o.total_delivery_days,
    o.days_vs_estimate,
    o.delivery_performance,
    o.is_late_delivery,

    r.review_score,
    r.review_comment_title,
    r.review_comment_message,
    r.review_creation_date,
    r.review_answer_timestamp

FROM staging.orders o

INNER JOIN staging.order_reviews r
    ON o.order_id = r.order_id;


-- =========================================================
-- 8. BASIC MODEL VALIDATION
--
-- Confirm row counts for all dimensions and facts.
-- =========================================================

SELECT
    'dim_customer' AS table_name,
    COUNT(*) AS row_count
FROM analytics.dim_customer

UNION ALL

SELECT
    'dim_product',
    COUNT(*)
FROM analytics.dim_product

UNION ALL

SELECT
    'dim_seller',
    COUNT(*)
FROM analytics.dim_seller

UNION ALL

SELECT
    'dim_date',
    COUNT(*)
FROM analytics.dim_date

UNION ALL

SELECT
    'fact_sales',
    COUNT(*)
FROM analytics.fact_sales

UNION ALL

SELECT
    'fact_order_payment',
    COUNT(*)
FROM analytics.fact_order_payment

UNION ALL

SELECT
    'fact_reviews',
    COUNT(*)
FROM analytics.fact_reviews;
