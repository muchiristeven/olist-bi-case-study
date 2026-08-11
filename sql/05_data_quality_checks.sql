/*
============================================================
OLIST E-COMMERCE BUSINESS INTELLIGENCE CASE STUDY
05 - Data Quality & Validation Checks
============================================================

Purpose:
Validate the integrity of the staging and analytics layers
before consumption in Power BI.

Checks include:
- row counts
- duplicate keys
- fact-table grain validation
- missing dimension relationships
- source-to-model reconciliation
- payment aggregation validation
- delivery field consistency
- date coverage
- null and completeness checks

Database: PostgreSQL
============================================================
*/


-- =========================================================
-- 1. RAW SOURCE ROW COUNTS
-- =========================================================

SELECT 'raw.customers' AS table_name, COUNT(*) AS row_count
FROM raw.customers

UNION ALL
SELECT 'raw.orders', COUNT(*)
FROM raw.orders

UNION ALL
SELECT 'raw.order_items', COUNT(*)
FROM raw.order_items

UNION ALL
SELECT 'raw.order_payments', COUNT(*)
FROM raw.order_payments

UNION ALL
SELECT 'raw.order_reviews', COUNT(*)
FROM raw.order_reviews

UNION ALL
SELECT 'raw.products', COUNT(*)
FROM raw.products

UNION ALL
SELECT 'raw.sellers', COUNT(*)
FROM raw.sellers;


-- =========================================================
-- 2. STAGING ROW COUNTS
-- =========================================================

SELECT 'staging.customers' AS table_name, COUNT(*) AS row_count
FROM staging.customers

UNION ALL
SELECT 'staging.orders', COUNT(*)
FROM staging.orders

UNION ALL
SELECT 'staging.order_items', COUNT(*)
FROM staging.order_items

UNION ALL
SELECT 'staging.order_payments', COUNT(*)
FROM staging.order_payments

UNION ALL
SELECT 'staging.order_reviews', COUNT(*)
FROM staging.order_reviews

UNION ALL
SELECT 'staging.products', COUNT(*)
FROM staging.products

UNION ALL
SELECT 'staging.sellers', COUNT(*)
FROM staging.sellers;


-- =========================================================
-- 3. ANALYTICS ROW COUNTS
-- =========================================================

SELECT 'analytics.dim_customer' AS table_name, COUNT(*) AS row_count
FROM analytics.dim_customer

UNION ALL
SELECT 'analytics.dim_product', COUNT(*)
FROM analytics.dim_product

UNION ALL
SELECT 'analytics.dim_seller', COUNT(*)
FROM analytics.dim_seller

UNION ALL
SELECT 'analytics.dim_date', COUNT(*)
FROM analytics.dim_date

UNION ALL
SELECT 'analytics.fact_sales', COUNT(*)
FROM analytics.fact_sales

UNION ALL
SELECT 'analytics.fact_order_payment', COUNT(*)
FROM analytics.fact_order_payment

UNION ALL
SELECT 'analytics.fact_reviews', COUNT(*)
FROM analytics.fact_reviews;


-- =========================================================
-- 4. DIMENSION KEY DUPLICATE CHECKS
-- Expected result: zero rows returned
-- =========================================================

SELECT
    customer_id,
    COUNT(*) AS duplicate_count
FROM analytics.dim_customer
GROUP BY customer_id
HAVING COUNT(*) > 1;


SELECT
    product_id,
    COUNT(*) AS duplicate_count
FROM analytics.dim_product
GROUP BY product_id
HAVING COUNT(*) > 1;


SELECT
    seller_id,
    COUNT(*) AS duplicate_count
FROM analytics.dim_seller
GROUP BY seller_id
HAVING COUNT(*) > 1;


SELECT
    calendar_date,
    COUNT(*) AS duplicate_count
FROM analytics.dim_date
GROUP BY calendar_date
HAVING COUNT(*) > 1;


-- =========================================================
-- 5. FACT SALES GRAIN CHECK
--
-- Grain should be:
-- one row per order_id + order_item_id
--
-- Expected result: zero rows returned
-- =========================================================

SELECT
    order_id,
    order_item_id,
    COUNT(*) AS duplicate_count
FROM analytics.fact_sales
GROUP BY
    order_id,
    order_item_id
HAVING COUNT(*) > 1;


-- =========================================================
-- 6. PAYMENT FACT GRAIN CHECK
--
-- Grain should be:
-- one row per order
--
-- Expected result: zero rows returned
-- =========================================================

SELECT
    order_id,
    COUNT(*) AS duplicate_count
FROM analytics.fact_order_payment
GROUP BY order_id
HAVING COUNT(*) > 1;


-- =========================================================
-- 7. REVIEW FACT GRAIN CHECK
--
-- Review data may contain multiple review records, therefore
-- validate the intended order/review combination.
--
-- Expected result: zero rows returned
-- =========================================================

SELECT
    order_id,
    review_id,
    COUNT(*) AS duplicate_count
FROM analytics.fact_reviews
GROUP BY
    order_id,
    review_id
HAVING COUNT(*) > 1;


-- =========================================================
-- 8. MISSING CUSTOMER DIMENSION RELATIONSHIPS
-- Expected result: zero
-- =========================================================

SELECT
    COUNT(*) AS sales_rows_without_customer
FROM analytics.fact_sales f

LEFT JOIN analytics.dim_customer d
    ON f.customer_id = d.customer_id

WHERE d.customer_id IS NULL;


SELECT
    COUNT(*) AS payment_rows_without_customer
FROM analytics.fact_order_payment f

LEFT JOIN analytics.dim_customer d
    ON f.customer_id = d.customer_id

WHERE d.customer_id IS NULL;


SELECT
    COUNT(*) AS review_rows_without_customer
FROM analytics.fact_reviews f

LEFT JOIN analytics.dim_customer d
    ON f.customer_id = d.customer_id

WHERE d.customer_id IS NULL;


-- =========================================================
-- 9. MISSING PRODUCT DIMENSION RELATIONSHIPS
-- Expected result: zero
-- =========================================================

SELECT
    COUNT(*) AS sales_rows_without_product
FROM analytics.fact_sales f

LEFT JOIN analytics.dim_product d
    ON f.product_id = d.product_id

WHERE d.product_id IS NULL;


-- =========================================================
-- 10. MISSING SELLER DIMENSION RELATIONSHIPS
-- Expected result: zero
-- =========================================================

SELECT
    COUNT(*) AS sales_rows_without_seller
FROM analytics.fact_sales f

LEFT JOIN analytics.dim_seller d
    ON f.seller_id = d.seller_id

WHERE d.seller_id IS NULL;


-- =========================================================
-- 11. MISSING DATE DIMENSION RELATIONSHIPS
-- Expected result: zero
-- =========================================================

SELECT
    COUNT(*) AS sales_rows_without_date
FROM analytics.fact_sales f

LEFT JOIN analytics.dim_date d
    ON f.purchase_date = d.calendar_date::DATE

WHERE d.calendar_date IS NULL;


SELECT
    COUNT(*) AS payment_rows_without_date
FROM analytics.fact_order_payment f

LEFT JOIN analytics.dim_date d
    ON f.purchase_date = d.calendar_date::DATE

WHERE d.calendar_date IS NULL;


SELECT
    COUNT(*) AS review_rows_without_date
FROM analytics.fact_reviews f

LEFT JOIN analytics.dim_date d
    ON f.purchase_date = d.calendar_date::DATE

WHERE d.calendar_date IS NULL;


-- =========================================================
-- 12. RAW VS STAGING ORDER ITEM RECONCILIATION
--
-- Order-item counts should remain unchanged.
-- =========================================================

SELECT
    (SELECT COUNT(*) FROM raw.order_items) AS raw_order_items,
    (SELECT COUNT(*) FROM staging.order_items) AS staging_order_items,
    (
        (SELECT COUNT(*) FROM staging.order_items)
        -
        (SELECT COUNT(*) FROM raw.order_items)
    ) AS difference;


-- =========================================================
-- 13. STAGING VS FACT SALES RECONCILIATION
--
-- Fact sales should preserve order-item grain.
-- =========================================================

SELECT
    (SELECT COUNT(*) FROM staging.order_items) AS staging_order_items,
    (SELECT COUNT(*) FROM analytics.fact_sales) AS fact_sales_rows,
    (
        (SELECT COUNT(*) FROM analytics.fact_sales)
        -
        (SELECT COUNT(*) FROM staging.order_items)
    ) AS difference;


-- =========================================================
-- 14. RAW PAYMENT VALUE VS STAGING PAYMENT VALUE
--
-- Aggregating payment records should not change the total
-- payment value.
--
-- Expected difference: approximately zero
-- =========================================================

SELECT
    ROUND(
        (SELECT SUM(payment_value)
         FROM raw.order_payments),
        2
    ) AS raw_payment_value,

    ROUND(
        (SELECT SUM(total_payment_value)
         FROM staging.order_payments),
        2
    ) AS staging_payment_value,

    ROUND(
        (
            (SELECT SUM(total_payment_value)
             FROM staging.order_payments)
            -
            (SELECT SUM(payment_value)
             FROM raw.order_payments)
        ),
        2
    ) AS difference;


-- =========================================================
-- 15. STAGING PAYMENT VS PAYMENT FACT RECONCILIATION
-- =========================================================

SELECT
    ROUND(
        (SELECT SUM(total_payment_value)
         FROM staging.order_payments),
        2
    ) AS staging_payment_value,

    ROUND(
        (SELECT SUM(total_payment_value)
         FROM analytics.fact_order_payment),
        2
    ) AS fact_payment_value,

    ROUND(
        (
            (SELECT SUM(total_payment_value)
             FROM analytics.fact_order_payment)
            -
            (SELECT SUM(total_payment_value)
             FROM staging.order_payments)
        ),
        2
    ) AS difference;


-- =========================================================
-- 16. SALES PRICE RECONCILIATION
--
-- Confirm that item price totals are preserved from staging
-- into the sales fact.
-- =========================================================

SELECT
    ROUND(
        (SELECT SUM(price)
         FROM staging.order_items),
        2
    ) AS staging_item_revenue,

    ROUND(
        (SELECT SUM(price)
         FROM analytics.fact_sales),
        2
    ) AS fact_item_revenue,

    ROUND(
        (
            (SELECT SUM(price)
             FROM analytics.fact_sales)
            -
            (SELECT SUM(price)
             FROM staging.order_items)
        ),
        2
    ) AS difference;


-- =========================================================
-- 17. GROSS ITEM VALUE CONSISTENCY
--
-- gross_item_value should equal:
-- price + freight_value
--
-- Expected result: zero
-- =========================================================

SELECT
    COUNT(*) AS inconsistent_gross_item_rows
FROM staging.order_items

WHERE gross_item_value
      <> COALESCE(price, 0) + COALESCE(freight_value, 0);


-- =========================================================
-- 18. DELIVERY FLAG CONSISTENCY
--
-- Late flag should agree with days_vs_estimate.
--
-- Expected result: zero
-- =========================================================

SELECT
    COUNT(*) AS inconsistent_late_delivery_rows
FROM staging.orders

WHERE
    (
        days_vs_estimate > 0
        AND is_late_delivery <> 1
    )

    OR

    (
        days_vs_estimate <= 0
        AND is_late_delivery <> 0
    );


-- =========================================================
-- 19. DELIVERY CLASSIFICATION CONSISTENCY
--
-- Expected result: zero
-- =========================================================

SELECT
    COUNT(*) AS inconsistent_delivery_classification
FROM staging.orders

WHERE
    (
        is_late_delivery = 1
        AND delivery_performance <> 'Late'
    )

    OR

    (
        is_late_delivery = 0
        AND delivery_performance <> 'On time'
    );


-- =========================================================
-- 20. DATE RANGE VALIDATION
-- =========================================================

SELECT
    MIN(purchase_date) AS first_purchase_date,
    MAX(purchase_date) AS last_purchase_date
FROM staging.orders;


SELECT
    MIN(calendar_date) AS first_calendar_date,
    MAX(calendar_date) AS last_calendar_date
FROM analytics.dim_date;


-- =========================================================
-- 21. ORDER STATUS DISTRIBUTION
--
-- Useful for confirming the completed vs non-completed
-- reporting classification.
-- =========================================================

SELECT
    order_status,
    order_status_group,
    COUNT(*) AS order_count
FROM staging.orders
GROUP BY
    order_status,
    order_status_group
ORDER BY
    order_status_group,
    order_status;


-- =========================================================
-- 22. NULL CHECKS FOR CORE FACT KEYS
-- =========================================================

SELECT
    COUNT(*) AS fact_sales_missing_keys
FROM analytics.fact_sales
WHERE
       order_id IS NULL
    OR order_item_id IS NULL
    OR customer_id IS NULL
    OR product_id IS NULL
    OR seller_id IS NULL;


SELECT
    COUNT(*) AS payment_fact_missing_keys
FROM analytics.fact_order_payment
WHERE
       order_id IS NULL
    OR customer_id IS NULL;


SELECT
    COUNT(*) AS review_fact_missing_keys
FROM analytics.fact_reviews
WHERE
       order_id IS NULL
    OR customer_id IS NULL;


-- =========================================================
-- 23. COMPLETED ORDER RECONCILIATION
--
-- Because fact_sales operates at item grain, order counts
-- must use DISTINCT order_id.
-- =========================================================

SELECT
    COUNT(DISTINCT order_id) AS completed_orders
FROM analytics.fact_sales
WHERE order_status_group = 'Completed';


-- =========================================================
-- 24. COMPLETED PAYMENT ORDER RECONCILIATION
-- =========================================================

SELECT
    COUNT(DISTINCT order_id) AS completed_payment_orders
FROM analytics.fact_order_payment
WHERE order_status_group = 'Completed';


-- =========================================================
-- 25. CUSTOMER IDENTITY CHECK
--
-- Compare order-level customer IDs with persistent customer
-- identities used for repeat-purchase analysis.
-- =========================================================

SELECT
    COUNT(DISTINCT customer_id) AS customer_records,
    COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM analytics.dim_customer;


-- =========================================================
-- 26. FINAL HIGH-LEVEL MODEL SUMMARY
-- =========================================================

SELECT
    COUNT(DISTINCT order_id) AS orders,
    COUNT(*) AS item_rows,
    COUNT(DISTINCT customer_id) AS customer_records,
    COUNT(DISTINCT product_id) AS products,
    COUNT(DISTINCT seller_id) AS sellers,
    ROUND(SUM(price), 2) AS item_revenue
FROM analytics.fact_sales;
