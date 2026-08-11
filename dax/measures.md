# DAX Measures

This file contains the key Power BI measures used in the Olist Business Intelligence case study.

The measures are grouped by analytical area and reflect the semantic layer used across the Executive Overview, Product, Customer, Delivery and Payment dashboards.

---

## Executive Overview Measures

```DAX
Total Orders =
DISTINCTCOUNT(
    'analytics fact_sales'[order_id]
)

Item Revenue =
SUM(
    'analytics fact_sales'[price]
)

Items Sold =
COUNTROWS(
    'analytics fact_sales'
)

Completed Orders =
CALCULATE(
    [Total Orders],
    'analytics fact_sales'[order_status_group] = "Completed"
)
Completed Item Revenue =
CALCULATE(
    [Item Revenue],
    'analytics fact_sales'[order_status_group] = "Completed"
)

Completed Items Sold =
CALCULATE(
    [Items Sold],
    'analytics fact_sales'[order_status_group] = "Completed"
)

Average Selling Price =
DIVIDE(
    [Item Revenue],
    [Items Sold]
)

```
## Product Category Performance Measures
```
DAX
Revenue Contribution % =
DIVIDE(
    [Completed Item Revenue],
    CALCULATE(
        [Completed Item Revenue],
        REMOVEFILTERS(
            'analytics dim_product'
        )
    )
)
```
## Customer Performance Measures
```
DAX
Completed Unique Customers =
CALCULATE(
    DISTINCTCOUNT(
        'analytics fact_sales'[Customer Unique ID]
    ),
    'analytics fact_sales'[order_status_group] = "Completed"
)

Repeat Customers =
COUNTROWS(
    FILTER(
        VALUES(
            'analytics fact_sales'[Customer Unique ID]
        ),
        CALCULATE(
            [Completed Orders]
        ) > 1
    )
)

Repeat Customer Rate =
DIVIDE(
    [Repeat Customers],
    [Completed Unique Customers]
)

Revenue per Customer =
DIVIDE(
    [Completed Item Revenue],
    [Completed Unique Customers]
)

Customer Contribution % =
DIVIDE(
    [Completed Unique Customers],
    CALCULATE(
        [Completed Unique Customers],
        REMOVEFILTERS(
            'analytics dim_customer'[customer_state]
        )
    )
)
```
## Delivery Performance Measures
```
DAX
Reviewed Orders =
DISTINCTCOUNT(
    'analytics fact_reviews'[order_id]
)

Delivered Reviewed Orders =
CALCULATE(
    [Reviewed Orders],
    NOT ISBLANK(
        'analytics fact_reviews'[is_late_delivery]
    )
)

Late Delivered Orders =
CALCULATE(
    [Reviewed Orders],
    'analytics fact_reviews'[is_late_delivery] = 1
)

Late Delivery % =
DIVIDE(
    [Late Delivered Orders],
    [Delivered Reviewed Orders]
)

On-Time Delivery % =
1 - [Late Delivery %]

Average Delivery Days =
AVERAGE(
    'analytics fact_reviews'[total_delivery_days]
)

Average Days vs Estimate =
AVERAGE(
    'analytics fact_reviews'[days_vs_estimate]
)

Average Review Score =
AVERAGE(
    'analytics fact_reviews'[review_score]
)

Late Delivery % (Min. 100 Orders) =
IF(
    [Delivered Reviewed Orders] >= 100,
    [Late Delivery %],
    BLANK()
)
```
## Payment Analysis Measures
```
DAX
Paid Orders =
DISTINCTCOUNT(
    'analytics fact_order_payment'[order_id]
)

Total Payment Value =
SUM(
    'analytics fact_order_payment'[total_payment_value]
)

Completed Payment Orders =
CALCULATE(
    DISTINCTCOUNT(
        'analytics fact_order_payment'[order_id]
    ),
    'analytics fact_order_payment'[order_status_group] = "Completed"
)

Completed Payment Value =
CALCULATE(
    [Total Payment Value],
    'analytics fact_order_payment'[order_status_group] = "Completed"
)

Completed Average Payment per Order =
DIVIDE(
    [Completed Payment Value],
    [Completed Payment Orders]
)

Average Installments =
AVERAGE(
    'analytics fact_order_payment'[max_installments]
)

Multi Payment Orders =
CALCULATE(
    COUNTROWS(
        'analytics fact_order_payment'
    ),
    'analytics fact_order_payment'[payment_count] > 1
)

Multi-Payment Order % =
DIVIDE(
    [Multi Payment Orders],
    [Completed Payment Orders]
)
```



