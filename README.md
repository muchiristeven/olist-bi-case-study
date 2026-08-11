# Olist E-Commerce Business Intelligence Case Study

> End-to-end Business Intelligence solution using PostgreSQL, dimensional modelling, Power BI and DAX to transform Brazilian e-commerce data into decision-ready business insights.

## Executive Summary

This project develops an end-to-end Business Intelligence solution for the Olist Brazilian e-commerce dataset.

The objective was not simply to create dashboards, but to design a structured analytical solution capable of answering key business questions across sales, products, customers, delivery performance and payments.

The solution covers the complete BI workflow:

- Data preparation and transformation using PostgreSQL and SQL
- Separation of raw, staging and analytics data layers
- Dimensional modelling using fact and dimension tables
- Business metric development using DAX
- Interactive dashboard development in Power BI
- Data quality and reconciliation checks
- Business analysis and recommendation development

The resulting solution provides management with a consolidated view of commercial performance, customer behaviour, product concentration, delivery performance and payment patterns.

---

## Business Problem

Olist's transactional data spans multiple business processes, including orders, order items, customers, products, sellers, payments and reviews.

These datasets operate at different levels of granularity. Directly combining them into a single analytical table could therefore produce duplicated revenue, incorrect order counts and distorted payment metrics.

The project was designed to answer questions such as:

- How are revenue and order volumes changing over time?
- Which product categories contribute most to revenue?
- How concentrated is revenue across product categories?
- Where are customers geographically concentrated?
- How strong is customer retention and repeat purchasing?
- Which regions experience the highest delivery delays?
- How does delivery performance relate to customer experience?
- Which payment methods dominate transaction value?
- How frequently are instalments and multiple payment methods used?

---

## Solution Architecture

The analytical pipeline follows a layered architecture:

```text
Olist Source Data
       │
       ▼
┌─────────────┐
│ RAW LAYER   │
│ PostgreSQL  │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ STAGING     │
│ SQL Cleaning│
│ & Transform │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ ANALYTICS   │
│ Dimensional │
│ Model       │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ POWER BI    │
│ DAX Metrics │
│ Dashboards  │
└─────────────┘
```

Three PostgreSQL schemas were used to separate responsibilities:

- **`raw`** — source-aligned imported data
- **`staging`** — cleaned and transformed analytical preparation layer
- **`analytics`** — dimensional tables consumed by Power BI

This separation improves traceability, maintainability and validation throughout the analytical pipeline.

---

## Dimensional Data Model

The Power BI semantic model was designed around multiple fact tables rather than flattening all business processes into one table.

### Fact Tables

- **FactSales** — order-item grain for sales, product and seller analysis
- **FactOrderPayment** — order grain for payment analysis
- **FactReviews** — order/review-level delivery and customer experience analysis

### Dimension Tables

- **DimCustomer**
- **DimProduct**
- **DimSeller**
- **DimDate**

This structure protects the analytical model from many-to-many duplication and allows measures to be calculated at the appropriate business grain.

---

## Dashboard Overview

The Power BI report contains five analytical areas:

### 1. Executive Overview
High-level monitoring of completed revenue, orders, items sold and average order value, including monthly performance trends and geographic revenue distribution.

### 2. Product Category Performance
Analysis of category revenue, items sold, average selling price, revenue contribution and cumulative revenue concentration.

### 3. Customer Performance
Analysis of customer distribution, revenue per customer, repeat customers, repeat customer rate and geographic customer concentration.

### 4. Delivery Performance
Monitoring of on-time delivery, average delivery duration, performance against estimated delivery dates, review scores and regional late-delivery rates.

### 5. Payment Analysis
Analysis of completed payment value, average payment per order, instalment behaviour, payment methods and multi-payment orders.

---

## Key Business Findings

The analysis identified several important patterns:

- Revenue and order activity expanded strongly during the main operating period.
- Revenue was concentrated within a relatively small subset of product categories.
- São Paulo represented the dominant customer and revenue market.
- Customer repeat purchasing remained very low, indicating limited customer retention.
- Overall delivery performance was strong, but substantial regional differences remained.
- Late-delivery rates increased during selected periods of higher operational pressure.
- Credit cards dominated payment value.
- Instalment payments were an important component of customer purchasing behaviour.
- Orders using multiple payment methods represented only a small proportion of total transactions.

---

## Business Recommendations

Based on the analysis, the following actions are recommended:

1. **Strengthen customer retention initiatives**  
   Develop post-purchase engagement, targeted promotions and repeat-purchase incentives.

2. **Prioritise high-value product categories**  
   Focus commercial planning on categories responsible for the majority of revenue while monitoring concentration risk.

3. **Investigate regional delivery bottlenecks**  
   Analyse states with persistently high late-delivery rates and identify logistics or seller-related causes.

4. **Prepare operational capacity for demand peaks**  
   Use historical monthly patterns to anticipate periods associated with increased order volumes and delivery pressure.

5. **Maintain payment flexibility**  
   Continue supporting credit-card instalments while monitoring payment behaviour and transaction economics.

---

## Technical Implementation

### SQL & PostgreSQL

SQL was used to:

- Create raw, staging and analytics schemas
- Define source-aligned tables
- Standardise data types and fields
- Create derived business attributes
- Aggregate payment records to order grain
- Build dimensional tables
- Construct analytical fact tables
- Perform data-quality and reconciliation checks

The complete SQL pipeline is available in the [`sql/`](sql/) directory.

### DAX & Power BI

DAX measures were developed for:

- Revenue and order KPIs
- Product revenue contribution
- Customer repeat behaviour
- Revenue per customer
- Delivery performance
- Review scores
- Payment value
- Instalment behaviour
- Multi-payment order analysis

The documented measures are available in [`dax/measures.md`](dax/measures.md).

---

## Repository Structure

```text
olist-bi-case-study/
│
├── README.md
│
├── sql/
│   ├── 01_create_schemas.sql
│   ├── 02_raw_tables.sql
│   ├── 03_staging_transformations.sql
│   ├── 04_dimensional_model.sql
│   └── 05_data_quality_checks.sql
│
└── dax/
    └── measures.md
```

---

## Tools & Technical Skills Demonstrated

**Database & SQL**
- PostgreSQL
- SQL
- Data transformation
- Data validation
- Data-quality testing

**Data Modelling**
- Dimensional modelling
- Fact and dimension design
- Grain definition
- Star-schema principles
- Multi-fact semantic modelling

**Business Intelligence**
- Power BI
- DAX
- Power Query
- KPI development
- Interactive dashboards
- Data visualisation

**Business Analysis**
- Revenue analysis
- Product performance analysis
- Customer analysis
- Delivery performance analysis
- Payment analysis
- Business recommendation development

---

## Project Status

**Completed**

The project demonstrates an end-to-end BI workflow from source data preparation through dimensional modelling, analytical measure development, dashboard creation and business insight generation.
