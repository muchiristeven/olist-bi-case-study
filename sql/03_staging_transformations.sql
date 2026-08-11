/*
============================================================
OLIST E-COMMERCE BUSINESS INTELLIGENCE CASE STUDY
03 - Staging Transformations
============================================================

Purpose:
Transform the raw Olist source tables into cleaned and
enriched staging tables for downstream dimensional modelling.

Key transformations include:
- customer and seller geographic standardisation
- order date preparation
- order status classification
- delivery performance calculations
- product category translation and enrichment
- item-level gross value calculation
- order-level payment aggregation

Database: PostgreSQL
============================================================
*/


-- =========================================================
-- 1. CUSTOMERS
-- Standardise geographic attributes while preserving both
-- order-level customer_id and persistent customer_unique_id.
-- =========================================================

DROP TABLE IF EXISTS staging.customers;

CREATE TABLE staging.customers AS
SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    LOWER(TRIM(customer_city)) AS customer_city,
    UPPER(TRIM(customer_state)) AS customer_state
FROM raw.customers;


-- =========================================================
-- 2. SELLERS
-- Standardise seller geographic attributes.
-- =========================================================

DROP TABLE IF EXISTS staging.sellers;

CREATE TABLE staging.sellers AS
SELECT
    seller_id,
    seller_zip_code_prefix,
    LOWER(TRIM(seller_city)) AS seller_city,
    UPPER(TRIM(seller_state)) AS seller_state
FROM raw.sellers;


-- =========================================================
-- 3. PRODUCTS
-- Enrich products with English category names and calculate
-- approximate product volume in cubic centimetres.
-- =========================================================

DROP TABLE IF EXISTS staging.products;

CREATE TABLE staging.products AS
SELECT
    p.product_id,
    p.product_category_name,
    ct.product_category_name_english,

    p.product_name_lenght,
    p.product_description_lenght,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,

    COALESCE(
        ct.product_category_name_english,
        'Unknown'
    )::VARCHAR(100) AS product_category,

    (
        p.product_length_cm
        * p.product_height_cm
        * p.product_width_cm
    )::NUMERIC AS product_volume_cm3

FROM raw.products p

LEFT JOIN raw.category_translation ct
    ON p.product_category_name = ct.product_category_name;


-- =========================================================
-- 4. ORDER ITEMS
-- Preserve order-item grain and calculate gross item value.
--
-- gross_item_value = item price + freight value
-- =========================================================

DROP TABLE IF EXISTS staging.order_items;

CREATE TABLE staging.order_items AS
SELECT
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value,

    (
        COALESCE(price, 0)
        + COALESCE(freight_value, 0)
    )::NUMERIC AS gross_item_value

FROM raw.order_items;


-- =========================================================
-- 5. ORDER PAYMENTS
-- Aggregate payment records to one row per order.
--
-- This prevents payment values from being duplicated when
-- payment data is later analysed alongside item-level sales.
-- =========================================================

DROP TABLE IF EXISTS staging.order_payments;

CREATE TABLE staging.order_payments AS
SELECT
    order_id,

    COUNT(*) AS payment_count,

    SUM(payment_value)::NUMERIC AS total_payment_value,

    MAX(payment_installments) AS max_installments,

    STRING_AGG(
        DISTINCT payment_type,
        ', '
        ORDER BY payment_type
    ) AS payment_methods

FROM raw.order_payments

GROUP BY order_id;


-- =========================================================
-- 6. ORDER REVIEWS
-- Preserve review-level information for downstream delivery
-- and customer-experience analysis.
-- =========================================================

DROP TABLE IF EXISTS staging.order_reviews;

CREATE TABLE staging.order_reviews AS
SELECT
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
FROM raw.order_reviews;


-- =========================================================
-- 7. ORDERS
-- Prepare reporting dates, status grouping and delivery
-- performance fields.
-- =========================================================

DROP TABLE IF EXISTS staging.orders;

CREATE TABLE staging.orders AS
SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,

    -- Reporting date
    order_purchase_timestamp::DATE AS purchase_date,

    -- Calendar attributes
    EXTRACT(
        YEAR FROM order_purchase_timestamp
    )::INTEGER AS purchase_year,

    EXTRACT(
        MONTH FROM order_purchase_timestamp
    )::INTEGER AS purchase_month_number,

    EXTRACT(
        QUARTER FROM order_purchase_timestamp
    )::INTEGER AS purchase_quarter,

    TO_CHAR(
        order_purchase_timestamp,
        'FMMonth'
    )::VARCHAR(20) AS purchase_month_name,

    -- Reporting-friendly order status
    CASE
        WHEN LOWER(order_status) = 'delivered'
            THEN 'Completed'
        ELSE 'Other'
    END::VARCHAR(20) AS order_status_group,

    -- Days from purchase to customer delivery
    CASE
        WHEN order_delivered_customer_date IS NOT NULL
        THEN (
            order_delivered_customer_date::DATE
            - order_purchase_timestamp::DATE
        )::NUMERIC(10,2)
        ELSE NULL
    END AS total_delivery_days,

    -- Delivery performance classification
    CASE
        WHEN order_delivered_customer_date IS NULL
            THEN NULL

        WHEN order_delivered_customer_date::DATE
             > order_estimated_delivery_date::DATE
            THEN 'Late'

        ELSE 'On time'
    END::VARCHAR(20) AS delivery_performance,

    -- Negative = delivered before estimate
    -- Positive = delivered after estimate
    CASE
        WHEN order_delivered_customer_date IS NOT NULL
        THEN (
            order_delivered_customer_date::DATE
            - order_estimated_delivery_date::DATE
        )
        ELSE NULL
    END::INTEGER AS days_vs_estimate,

    -- Binary late-delivery indicator
    CASE
        WHEN order_delivered_customer_date IS NULL
            THEN NULL

        WHEN order_delivered_customer_date::DATE
             > order_estimated_delivery_date::DATE
            THEN 1

        ELSE 0
    END::INTEGER AS is_late_delivery

FROM raw.orders;


-- =========================================================
-- 8. BASIC STAGING VALIDATION
-- =========================================================

SELECT
    'customers' AS table_name,
    COUNT(*) AS row_count
FROM staging.customers

UNION ALL

SELECT
    'sellers',
    COUNT(*)
FROM staging.sellers

UNION ALL

SELECT
    'products',
    COUNT(*)
FROM staging.products

UNION ALL

SELECT
    'order_items',
    COUNT(*)
FROM staging.order_items

UNION ALL

SELECT
    'order_payments',
    COUNT(*)
FROM staging.order_payments

UNION ALL

SELECT
    'order_reviews',
    COUNT(*)
FROM staging.order_reviews

UNION ALL

SELECT
    'orders',
    COUNT(*)
FROM staging.orders;
