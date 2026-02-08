# KPI Methodology & Calculation Logic

## Overview

This document details the calculation methodology for all key performance indicators (KPIs) in the supply chain analytics platform. Each KPI includes business definition, calculation formula, SQL implementation, and interpretation guidelines.

---

## Core KPI Definitions

### 1. On-Time In-Full (OTIF) Rate

#### Business Definition
The percentage of orders that are delivered both on time AND with the complete ordered quantity. This is the gold standard metric for measuring fulfillment excellence.

#### Why It Matters
- Industry benchmark for operational performance
- Strong predictor of customer satisfaction and retention
- Directly impacts revenue and repeat business
- Below 65% typically indicates systemic operational issues

#### Calculation Components

**On-Time Criteria:**
- Delivery date ≤ Expected delivery date
- Expected delivery date = Order date + 2 business days (company standard SLA)

**In-Full Criteria:**
- Delivered quantity ≥ Ordered quantity
- Partial deliveries are considered failures

**OTIF Formula:**
```
OTIF Rate = (Orders meeting BOTH criteria / Total Orders) × 100
```

#### SQL Implementation

```sql
-- Calculate OTIF rate for overall performance
SELECT 
    ROUND(
        100.0 * COUNT(CASE WHEN on_time_flag = 1 AND in_full_flag = 1 THEN 1 END) 
        / COUNT(*),
        2
    ) AS otif_rate,
    COUNT(*) AS total_orders,
    COUNT(CASE WHEN on_time_flag = 1 AND in_full_flag = 1 THEN 1 END) AS otif_orders
FROM fact_orders
WHERE order_date >= CURRENT_DATE - INTERVAL '30 days';

-- Calculate OTIF by category
SELECT 
    p.category,
    ROUND(
        100.0 * COUNT(CASE WHEN o.on_time_flag = 1 AND o.in_full_flag = 1 THEN 1 END) 
        / COUNT(*),
        2
    ) AS otif_rate,
    COUNT(*) AS total_orders
FROM fact_orders o
JOIN dim_products p ON o.product_key = p.product_key
GROUP BY p.category
ORDER BY otif_rate ASC;

-- Calculate OTIF trend by month
SELECT 
    TO_CHAR(order_date, 'Mon YYYY') AS month,
    ROUND(
        100.0 * COUNT(CASE WHEN on_time_flag = 1 AND in_full_flag = 1 THEN 1 END) 
        / COUNT(*),
        2
    ) AS otif_rate
FROM fact_orders
GROUP BY TO_CHAR(order_date, 'Mon YYYY'), DATE_TRUNC('month', order_date)
ORDER BY DATE_TRUNC('month', order_date);
```

#### Flag Calculation Logic

```sql
-- On-time flag calculation
UPDATE fact_orders
SET on_time_flag = CASE
    WHEN delivery_date IS NULL THEN NULL  -- Not yet delivered
    WHEN delivery_date <= expected_delivery_date THEN 1
    ELSE 0
END;

-- In-full flag calculation
UPDATE fact_orders
SET in_full_flag = CASE
    WHEN delivered_qty IS NULL THEN NULL  -- Not yet delivered
    WHEN delivered_qty >= ordered_qty THEN 1
    ELSE 0
END;

-- Expected delivery date calculation (runs on order insertion)
UPDATE fact_orders
SET expected_delivery_date = order_date + INTERVAL '2 days'
WHERE expected_delivery_date IS NULL;
```

#### Interpretation Guidelines

| OTIF Rate | Performance Level | Action Required |
|-----------|-------------------|-----------------|
| **≥ 85%** | Excellent | Maintain current processes |
| **65-84%** | Good | Minor optimization opportunities |
| **50-64%** | Fair | Targeted improvements needed |
| **< 50%** | Poor | Immediate intervention required |

**Current Performance: 48.6% (Poor)**

---

### 2. Volume Fill Rate vs. In-Full Rate

#### Business Definition

**Volume Fill Rate:** The percentage of total ordered units that were delivered across all orders.

**In-Full Rate:** The percentage of orders where 100% of the ordered quantity was delivered.

#### Why This Distinction Matters

These two metrics together reveal the ROOT CAUSE of fulfillment issues:

- **High Volume Fill + Low In-Full** = Inventory allocation problem (have stock, but wrong distribution)
- **Low Volume Fill + Low In-Full** = Total inventory shortage

#### Calculation Formulas

```
Volume Fill Rate = (Total Delivered Quantity / Total Ordered Quantity) × 100

In-Full Rate = (Orders with 100% Delivered / Total Orders) × 100
```

#### SQL Implementation

```sql
-- Calculate both metrics
WITH metrics AS (
    SELECT 
        SUM(ordered_qty) AS total_ordered,
        SUM(delivered_qty) AS total_delivered,
        COUNT(*) AS total_orders,
        COUNT(CASE WHEN delivered_qty >= ordered_qty THEN 1 END) AS in_full_orders
    FROM fact_orders
    WHERE order_date >= CURRENT_DATE - INTERVAL '30 days'
)
SELECT 
    ROUND(100.0 * total_delivered / total_ordered, 2) AS volume_fill_rate,
    ROUND(100.0 * in_full_orders / total_orders, 2) AS in_full_rate,
    total_orders,
    total_ordered,
    total_delivered
FROM metrics;

-- Category-level analysis
SELECT 
    p.category,
    ROUND(100.0 * SUM(o.delivered_qty) / SUM(o.ordered_qty), 2) AS volume_fill_rate,
    ROUND(100.0 * COUNT(CASE WHEN o.delivered_qty >= o.ordered_qty THEN 1 END) / COUNT(*), 2) AS in_full_rate,
    COUNT(*) AS orders
FROM fact_orders o
JOIN dim_products p ON o.product_key = p.product_key
GROUP BY p.category;
```

#### Current Findings & Interpretation

**Observed Pattern:**
- Volume Fill Rate: **96.5%** (High)
- In-Full Rate: **66.8%** (Low)

**Root Cause Analysis:**
This pattern indicates the company has sufficient TOTAL inventory but struggles with:
1. Order consolidation and batching
2. Inventory allocation across warehouses
3. Partial shipment policies

**Recommended Actions:**
- Implement order batching by delivery route
- Review warehouse allocation algorithms
- Add safety stock buffers for high-velocity SKUs

---

### 3. Revenue Leakage

#### Business Definition
The monetary value of revenue lost due to unfulfilled order quantities. This represents the direct financial impact of supply chain inefficiencies.

#### Why It Matters
- Quantifies opportunity cost of operational failures
- Prioritizes improvement initiatives by financial impact
- Directly ties supply chain performance to P&L

#### Calculation Formula

```
Revenue Leakage = Σ [(Ordered Qty - Delivered Qty) × Unit Price]
                  for all orders where Delivered Qty < Ordered Qty
```

#### SQL Implementation

```sql
-- Total revenue leakage
SELECT 
    SUM((ordered_qty - COALESCE(delivered_qty, 0)) * unit_price) AS revenue_leakage,
    COUNT(CASE WHEN delivered_qty < ordered_qty THEN 1 END) AS affected_orders,
    ROUND(
        100.0 * SUM((ordered_qty - COALESCE(delivered_qty, 0)) * unit_price) 
        / SUM(ordered_qty * unit_price),
        2
    ) AS leakage_pct_of_revenue
FROM fact_orders
WHERE order_date >= CURRENT_DATE - INTERVAL '90 days';

-- Revenue leakage by category
SELECT 
    p.category,
    SUM((o.ordered_qty - COALESCE(o.delivered_qty, 0)) * o.unit_price) AS revenue_leakage,
    SUM(o.ordered_qty * o.unit_price) AS potential_revenue,
    ROUND(
        100.0 * SUM((o.ordered_qty - COALESCE(o.delivered_qty, 0)) * o.unit_price) 
        / SUM(o.ordered_qty * o.unit_price),
        2
    ) AS leakage_pct
FROM fact_orders o
JOIN dim_products p ON o.product_key = p.product_key
GROUP BY p.category
ORDER BY revenue_leakage DESC;

-- Top 10 products by revenue leakage
SELECT 
    p.product_name,
    p.category,
    SUM((o.ordered_qty - COALESCE(o.delivered_qty, 0)) * o.unit_price) AS revenue_leakage,
    COUNT(*) AS affected_orders
FROM fact_orders o
JOIN dim_products p ON o.product_key = p.product_key
WHERE o.delivered_qty < o.ordered_qty
GROUP BY p.product_name, p.category
ORDER BY revenue_leakage DESC
LIMIT 10;
```

#### Current Findings

**Total Revenue Leakage: $111,341**
- Represents **3.7%** of total revenue
- Affects **34%** of all orders

**Category Breakdown:**
- Dairy: $88,456 (79.5% of leakage)
- Food: $17,721 (15.9% of leakage)
- Beverages: $5,164 (4.6% of leakage)

**Interpretation:**
The concentration of revenue leakage in Dairy (which is also the largest revenue category) indicates this is the highest-priority area for operational improvement.

---

### 4. Late Delivery Rate

#### Business Definition
The percentage of orders delivered after the expected delivery date, regardless of quantity fulfillment.

#### Why It Matters
- Direct driver of customer dissatisfaction
- Leading indicator of logistics issues
- Impacts customer lifetime value and retention

#### Calculation Formula

```
Late Delivery Rate = (Orders Delivered Late / Total Delivered Orders) × 100

Late = Delivery Date > Expected Delivery Date
```

#### SQL Implementation

```sql
-- Overall late delivery rate
SELECT 
    ROUND(
        100.0 * COUNT(CASE WHEN on_time_flag = 0 THEN 1 END) 
        / COUNT(*),
        2
    ) AS late_delivery_rate,
    COUNT(CASE WHEN on_time_flag = 0 THEN 1 END) AS late_orders,
    COUNT(*) AS total_delivered_orders
FROM fact_orders
WHERE delivery_date IS NOT NULL;

-- Late delivery rate by category
SELECT 
    p.category,
    ROUND(
        100.0 * COUNT(CASE WHEN o.on_time_flag = 0 THEN 1 END) 
        / COUNT(*),
        2
    ) AS late_delivery_rate,
    AVG(o.delivery_date - o.expected_delivery_date) AS avg_days_late
FROM fact_orders o
JOIN dim_products p ON o.product_key = p.product_key
WHERE o.delivery_date IS NOT NULL
GROUP BY p.category;

-- Late delivery trend by week
SELECT 
    DATE_TRUNC('week', order_date) AS week,
    ROUND(
        100.0 * COUNT(CASE WHEN on_time_flag = 0 THEN 1 END) 
        / COUNT(*),
        2
    ) AS late_delivery_rate
FROM fact_orders
WHERE delivery_date IS NOT NULL
GROUP BY DATE_TRUNC('week', order_date)
ORDER BY week;
```

#### Current Findings

**Late Delivery Rate: 28.4%**

**Category Performance:**
- Dairy: 30.2% late delivery rate
- Food: 25.1% late delivery rate
- Beverages: 18.3% late delivery rate

**Average Delay:** 1.8 days beyond expected delivery date

---

### 5. Customer Lifetime Value (CLV)

#### Business Definition
The total revenue a customer generates over their entire relationship with the company.

#### Why It Matters
- Identifies most valuable customers for prioritization
- Informs customer retention strategies
- Guides resource allocation for customer service

#### Calculation Formula (Simplified)

```
CLV = Average Order Value × Number of Orders × Average Customer Lifespan
```

For this analysis, we use historical CLV (actual revenue to date):

```
Historical CLV = Σ (Order Revenue) for all orders by customer
```

#### SQL Implementation

```sql
-- Top customers by historical CLV
SELECT 
    c.customer_name,
    COUNT(*) AS total_orders,
    SUM(o.ordered_qty * o.unit_price) AS total_revenue,
    ROUND(AVG(o.ordered_qty * o.unit_price), 2) AS avg_order_value,
    MAX(o.order_date) AS last_order_date
FROM fact_orders o
JOIN dim_customers c ON o.customer_key = c.customer_key
GROUP BY c.customer_name
ORDER BY total_revenue DESC
LIMIT 20;

-- CLV distribution analysis
WITH customer_revenue AS (
    SELECT 
        customer_key,
        SUM(ordered_qty * unit_price) AS total_revenue
    FROM fact_orders
    GROUP BY customer_key
)
SELECT 
    CASE 
        WHEN total_revenue >= 100000 THEN 'High Value (≥$100K)'
        WHEN total_revenue >= 50000 THEN 'Medium Value ($50K-$100K)'
        WHEN total_revenue >= 25000 THEN 'Low Value ($25K-$50K)'
        ELSE 'Very Low Value (<$25K)'
    END AS customer_segment,
    COUNT(*) AS customer_count,
    SUM(total_revenue) AS total_revenue,
    ROUND(100.0 * SUM(total_revenue) / SUM(SUM(total_revenue)) OVER (), 2) AS revenue_pct
FROM customer_revenue
GROUP BY CASE 
    WHEN total_revenue >= 100000 THEN 'High Value (≥$100K)'
    WHEN total_revenue >= 50000 THEN 'Medium Value ($50K-$100K)'
    WHEN total_revenue >= 25000 THEN 'Low Value ($25K-$50K)'
    ELSE 'Very Low Value (<$25K)'
END
ORDER BY MIN(total_revenue) DESC;
```

---

### 6. Category Performance Index

#### Business Definition
A composite score measuring overall category health combining OTIF rate, revenue share, and growth trend.

#### Why It Matters
- Holistic view of category performance
- Prioritizes categories for operational focus
- Identifies expansion risks

#### Calculation Formula

```
Category Score = (OTIF Rate × 0.4) + (Revenue Share × 0.3) + (Growth Rate × 0.3)

Normalized to 0-100 scale
```

#### SQL Implementation

```sql
WITH category_metrics AS (
    SELECT 
        p.category,
        -- OTIF Rate (0-100)
        ROUND(
            100.0 * COUNT(CASE WHEN o.on_time_flag = 1 AND o.in_full_flag = 1 THEN 1 END) 
            / COUNT(*),
            2
        ) AS otif_rate,
        -- Revenue Share (0-100)
        ROUND(
            100.0 * SUM(o.ordered_qty * o.unit_price) 
            / SUM(SUM(o.ordered_qty * o.unit_price)) OVER (),
            2
        ) AS revenue_share,
        -- Month-over-month growth rate
        ROUND(
            100.0 * (
                SUM(CASE WHEN o.order_date >= CURRENT_DATE - INTERVAL '30 days' 
                    THEN o.ordered_qty * o.unit_price END) -
                SUM(CASE WHEN o.order_date BETWEEN CURRENT_DATE - INTERVAL '60 days' 
                    AND CURRENT_DATE - INTERVAL '30 days' 
                    THEN o.ordered_qty * o.unit_price END)
            ) / NULLIF(
                SUM(CASE WHEN o.order_date BETWEEN CURRENT_DATE - INTERVAL '60 days' 
                    AND CURRENT_DATE - INTERVAL '30 days' 
                    THEN o.ordered_qty * o.unit_price END),
                0
            ),
            2
        ) AS growth_rate
    FROM fact_orders o
    JOIN dim_products p ON o.product_key = p.product_key
    GROUP BY p.category
)
SELECT 
    category,
    otif_rate,
    revenue_share,
    growth_rate,
    ROUND(
        (otif_rate * 0.4) + (revenue_share * 0.3) + (COALESCE(growth_rate, 0) * 0.3),
        2
    ) AS category_score
FROM category_metrics
ORDER BY category_score DESC;
```

---

## Advanced Analytics Queries

### Trend Analysis

```sql
-- 7-day moving average of OTIF rate
WITH daily_otif AS (
    SELECT 
        order_date,
        ROUND(
            100.0 * COUNT(CASE WHEN on_time_flag = 1 AND in_full_flag = 1 THEN 1 END) 
            / COUNT(*),
            2
        ) AS daily_otif_rate
    FROM fact_orders
    WHERE order_date >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY order_date
)
SELECT 
    order_date,
    daily_otif_rate,
    ROUND(
        AVG(daily_otif_rate) OVER (
            ORDER BY order_date 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS otif_7day_ma
FROM daily_otif
ORDER BY order_date;
```

### Cohort Analysis

```sql
-- Customer cohort analysis by first order month
WITH first_orders AS (
    SELECT 
        customer_key,
        DATE_TRUNC('month', MIN(order_date)) AS cohort_month
    FROM fact_orders
    GROUP BY customer_key
),
cohort_revenue AS (
    SELECT 
        fo.cohort_month,
        DATE_TRUNC('month', o.order_date) AS order_month,
        COUNT(DISTINCT o.customer_key) AS active_customers,
        SUM(o.ordered_qty * o.unit_price) AS revenue
    FROM fact_orders o
    JOIN first_orders fo ON o.customer_key = fo.customer_key
    GROUP BY fo.cohort_month, DATE_TRUNC('month', o.order_date)
)
SELECT 
    cohort_month,
    order_month,
    active_customers,
    revenue,
    ROUND(revenue / active_customers, 2) AS revenue_per_customer
FROM cohort_revenue
ORDER BY cohort_month, order_month;
```

---

## Data Quality Checks

### KPI Validation Queries

```sql
-- Check for data anomalies
SELECT 
    'Negative Quantities' AS check_type,
    COUNT(*) AS issue_count
FROM fact_orders
WHERE ordered_qty < 0 OR delivered_qty < 0

UNION ALL

SELECT 
    'Delivery Before Order' AS check_type,
    COUNT(*) AS issue_count
FROM fact_orders
WHERE delivery_date < order_date

UNION ALL

SELECT 
    'Missing Expected Delivery Date' AS check_type,
    COUNT(*) AS issue_count
FROM fact_orders
WHERE expected_delivery_date IS NULL

UNION ALL

SELECT 
    'Zero Unit Price' AS check_type,
    COUNT(*) AS issue_count
FROM fact_orders
WHERE unit_price = 0 OR unit_price IS NULL;
```

---

## Appendix: Business Rules

### SLA Definitions
- **Expected Delivery Time:** Order Date + 2 business days
- **On-Time Threshold:** Delivered on or before expected delivery date
- **In-Full Threshold:** Delivered quantity ≥ Ordered quantity

### Category Definitions
- **Dairy:** Milk, cheese, yogurt, butter products
- **Food:** Grains, snacks, packaged foods
- **Beverages:** Juices, sodas, water, coffee

### Performance Thresholds
- **OTIF Rate:** Target ≥ 65%, Acceptable ≥ 50%
- **Late Delivery Rate:** Target < 15%, Acceptable < 25%
- **Volume Fill Rate:** Target ≥ 98%, Acceptable ≥ 95%

---

