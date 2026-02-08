-- ============================================================================
-- Core KPI Calculation Queries
-- ============================================================================
-- Purpose: Calculate primary supply chain KPIs
-- Author: Swati Lalwani
-- ============================================================================

-- ============================================================================
-- 1. OTIF (On-Time In-Full) RATE CALCULATION
-- ============================================================================

-- Overall OTIF Rate (Last 30 Days)
SELECT 
    COUNT(*) AS total_orders,
    COUNT(CASE WHEN on_time_flag = 1 AND in_full_flag = 1 THEN 1 END) AS otif_orders,
    ROUND(
        100.0 * COUNT(CASE WHEN on_time_flag = 1 AND in_full_flag = 1 THEN 1 END) 
        / COUNT(*),
        2
    ) AS otif_rate,
    -- Breakdown
    COUNT(CASE WHEN on_time_flag = 1 THEN 1 END) AS on_time_orders,
    ROUND(100.0 * COUNT(CASE WHEN on_time_flag = 1 THEN 1 END) / COUNT(*), 2) AS on_time_rate,
    COUNT(CASE WHEN in_full_flag = 1 THEN 1 END) AS in_full_orders,
    ROUND(100.0 * COUNT(CASE WHEN in_full_flag = 1 THEN 1 END) / COUNT(*), 2) AS in_full_rate
FROM fact_orders
WHERE order_date >= CURRENT_DATE - INTERVAL '30 days'
    AND delivery_date IS NOT NULL;

-- OTIF Rate by Category
SELECT 
    p.category,
    COUNT(*) AS total_orders,
    SUM(o.order_revenue) AS total_revenue,
    ROUND(100.0 * SUM(o.order_revenue) / SUM(SUM(o.order_revenue)) OVER (), 2) AS revenue_share_pct,
    COUNT(CASE WHEN o.on_time_flag = 1 AND o.in_full_flag = 1 THEN 1 END) AS otif_orders,
    ROUND(
        100.0 * COUNT(CASE WHEN o.on_time_flag = 1 AND o.in_full_flag = 1 THEN 1 END) 
        / COUNT(*),
        2
    ) AS otif_rate,
    ROUND(100.0 * COUNT(CASE WHEN o.on_time_flag = 1 THEN 1 END) / COUNT(*), 2) AS on_time_rate,
    ROUND(100.0 * COUNT(CASE WHEN o.in_full_flag = 1 THEN 1 END) / COUNT(*), 2) AS in_full_rate
FROM fact_orders o
JOIN dim_products p ON o.product_key = p.product_key
WHERE o.delivery_date IS NOT NULL
GROUP BY p.category
ORDER BY otif_rate ASC;

-- OTIF Rate by Month (Trend Analysis)
SELECT 
    TO_CHAR(order_date, 'Mon YYYY') AS month,
    DATE_TRUNC('month', order_date) AS month_date,
    COUNT(*) AS total_orders,
    ROUND(
        100.0 * COUNT(CASE WHEN on_time_flag = 1 AND in_full_flag = 1 THEN 1 END) 
        / COUNT(*),
        2
    ) AS otif_rate,
    -- Month-over-month change
    ROUND(
        100.0 * COUNT(CASE WHEN on_time_flag = 1 AND in_full_flag = 1 THEN 1 END) 
        / COUNT(*),
        2
    ) - LAG(ROUND(
        100.0 * COUNT(CASE WHEN on_time_flag = 1 AND in_full_flag = 1 THEN 1 END) 
        / COUNT(*),
        2
    )) OVER (ORDER BY DATE_TRUNC('month', order_date)) AS otif_change_pp
FROM fact_orders
WHERE delivery_date IS NOT NULL
    AND order_date >= CURRENT_DATE - INTERVAL '6 months'
GROUP BY TO_CHAR(order_date, 'Mon YYYY'), DATE_TRUNC('month', order_date)
ORDER BY month_date;

-- OTIF Rate by City
SELECT 
    c.city,
    c.state,
    COUNT(*) AS total_orders,
    ROUND(
        100.0 * COUNT(CASE WHEN o.on_time_flag = 1 AND o.in_full_flag = 1 THEN 1 END) 
        / COUNT(*),
        2
    ) AS otif_rate
FROM fact_orders o
JOIN dim_customers c ON o.customer_key = c.customer_key
WHERE o.delivery_date IS NOT NULL
    AND o.order_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY c.city, c.state
HAVING COUNT(*) >= 10  -- Minimum 10 orders for statistical relevance
ORDER BY otif_rate ASC
LIMIT 10;

-- ============================================================================
-- 2. FILL RATE ANALYSIS
-- ============================================================================

-- Volume Fill Rate vs In-Full Rate
SELECT 
    -- Volume fill rate (overall quantity fulfillment)
    SUM(ordered_qty) AS total_ordered_qty,
    SUM(delivered_qty) AS total_delivered_qty,
    ROUND(100.0 * SUM(delivered_qty) / SUM(ordered_qty), 2) AS volume_fill_rate,
    
    -- In-full rate (percentage of orders completely fulfilled)
    COUNT(*) AS total_orders,
    COUNT(CASE WHEN in_full_flag = 1 THEN 1 END) AS in_full_orders,
    ROUND(100.0 * COUNT(CASE WHEN in_full_flag = 1 THEN 1 END) / COUNT(*), 2) AS in_full_rate,
    
    -- Gap analysis
    ROUND(
        100.0 * SUM(delivered_qty) / SUM(ordered_qty), 2
    ) - ROUND(
        100.0 * COUNT(CASE WHEN in_full_flag = 1 THEN 1 END) / COUNT(*), 2
    ) AS fill_rate_gap
FROM fact_orders
WHERE order_date >= CURRENT_DATE - INTERVAL '30 days';

-- Fill Rate by Category
SELECT 
    p.category,
    SUM(o.ordered_qty) AS total_ordered_qty,
    SUM(o.delivered_qty) AS total_delivered_qty,
    ROUND(100.0 * SUM(o.delivered_qty) / SUM(o.ordered_qty), 2) AS volume_fill_rate,
    COUNT(*) AS total_orders,
    ROUND(100.0 * COUNT(CASE WHEN o.in_full_flag = 1 THEN 1 END) / COUNT(*), 2) AS in_full_rate,
    -- Quantity shortfall
    SUM(o.ordered_qty - o.delivered_qty) AS total_shortfall_qty
FROM fact_orders o
JOIN dim_products p ON o.product_key = p.product_key
GROUP BY p.category
ORDER BY volume_fill_rate ASC;

-- ============================================================================
-- 3. REVENUE LEAKAGE CALCULATION
-- ============================================================================

-- Total Revenue Leakage
SELECT 
    SUM(order_revenue) AS potential_revenue,
    SUM(delivered_revenue) AS actual_revenue,
    SUM(revenue_leakage) AS total_revenue_leakage,
    ROUND(100.0 * SUM(revenue_leakage) / SUM(order_revenue), 2) AS leakage_pct,
    COUNT(CASE WHEN delivered_qty < ordered_qty THEN 1 END) AS orders_with_shortfall,
    ROUND(100.0 * COUNT(CASE WHEN delivered_qty < ordered_qty THEN 1 END) / COUNT(*), 2) AS shortfall_order_pct
FROM fact_orders
WHERE order_date >= CURRENT_DATE - INTERVAL '90 days';

-- Revenue Leakage by Category
SELECT 
    p.category,
    SUM(o.order_revenue) AS potential_revenue,
    SUM(o.revenue_leakage) AS revenue_leakage,
    ROUND(100.0 * SUM(o.revenue_leakage) / SUM(o.order_revenue), 2) AS leakage_pct,
    COUNT(CASE WHEN o.delivered_qty < o.ordered_qty THEN 1 END) AS orders_with_shortfall
FROM fact_orders o
JOIN dim_products p ON o.product_key = p.product_key
WHERE o.order_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY p.category
ORDER BY revenue_leakage DESC;

-- Top 10 Products by Revenue Leakage
SELECT 
    p.product_name,
    p.category,
    COUNT(*) AS affected_orders,
    SUM(o.ordered_qty - o.delivered_qty) AS quantity_shortfall,
    SUM(o.revenue_leakage) AS revenue_leakage,
    ROUND(AVG(o.unit_price), 2) AS avg_unit_price
FROM fact_orders o
JOIN dim_products p ON o.product_key = p.product_key
WHERE o.delivered_qty < o.ordered_qty
    AND o.order_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY p.product_name, p.category
ORDER BY revenue_leakage DESC
LIMIT 10;

-- Revenue Leakage Trend by Month
SELECT 
    TO_CHAR(order_date, 'Mon YYYY') AS month,
    SUM(revenue_leakage) AS revenue_leakage,
    SUM(order_revenue) AS potential_revenue,
    ROUND(100.0 * SUM(revenue_leakage) / SUM(order_revenue), 2) AS leakage_pct
FROM fact_orders
WHERE order_date >= CURRENT_DATE - INTERVAL '6 months'
GROUP BY TO_CHAR(order_date, 'Mon YYYY'), DATE_TRUNC('month', order_date)
ORDER BY DATE_TRUNC('month', order_date);

-- ============================================================================
-- 4. LATE DELIVERY ANALYSIS
-- ============================================================================

-- Overall Late Delivery Rate
SELECT 
    COUNT(*) AS total_delivered_orders,
    COUNT(CASE WHEN on_time_flag = 0 THEN 1 END) AS late_orders,
    ROUND(100.0 * COUNT(CASE WHEN on_time_flag = 0 THEN 1 END) / COUNT(*), 2) AS late_delivery_rate,
    ROUND(AVG(CASE WHEN on_time_flag = 0 THEN delivery_date - expected_delivery_date END), 1) AS avg_days_late
FROM fact_orders
WHERE delivery_date IS NOT NULL
    AND order_date >= CURRENT_DATE - INTERVAL '30 days';

-- Late Delivery by Category
SELECT 
    p.category,
    COUNT(*) AS total_orders,
    COUNT(CASE WHEN o.on_time_flag = 0 THEN 1 END) AS late_orders,
    ROUND(100.0 * COUNT(CASE WHEN o.on_time_flag = 0 THEN 1 END) / COUNT(*), 2) AS late_delivery_rate,
    ROUND(AVG(CASE WHEN o.on_time_flag = 0 THEN o.delivery_date - o.expected_delivery_date END), 1) AS avg_days_late
FROM fact_orders o
JOIN dim_products p ON o.product_key = p.product_key
WHERE o.delivery_date IS NOT NULL
GROUP BY p.category
ORDER BY late_delivery_rate DESC;

-- Late Delivery Trend by Week
SELECT 
    DATE_TRUNC('week', order_date) AS week_start,
    COUNT(*) AS total_orders,
    ROUND(100.0 * COUNT(CASE WHEN on_time_flag = 0 THEN 1 END) / COUNT(*), 2) AS late_delivery_rate
FROM fact_orders
WHERE delivery_date IS NOT NULL
    AND order_date >= CURRENT_DATE - INTERVAL '12 weeks'
GROUP BY DATE_TRUNC('week', order_date)
ORDER BY week_start;

-- ============================================================================
-- 5. CUSTOMER LIFETIME VALUE (CLV)
-- ============================================================================

-- Top 20 Customers by Revenue
SELECT 
    c.customer_name,
    c.city,
    c.state,
    COUNT(*) AS total_orders,
    SUM(o.order_revenue) AS total_revenue,
    ROUND(AVG(o.order_revenue), 2) AS avg_order_value,
    MIN(o.order_date) AS first_order_date,
    MAX(o.order_date) AS last_order_date,
    -- OTIF rate for this customer
    ROUND(
        100.0 * COUNT(CASE WHEN o.on_time_flag = 1 AND o.in_full_flag = 1 THEN 1 END) 
        / COUNT(*),
        2
    ) AS customer_otif_rate
FROM fact_orders o
JOIN dim_customers c ON o.customer_key = c.customer_key
GROUP BY c.customer_name, c.city, c.state
ORDER BY total_revenue DESC
LIMIT 20;

-- Customer Segmentation by Revenue
WITH customer_revenue AS (
    SELECT 
        customer_key,
        SUM(order_revenue) AS total_revenue,
        COUNT(*) AS order_count
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
    SUM(total_revenue) AS segment_revenue,
    ROUND(100.0 * SUM(total_revenue) / SUM(SUM(total_revenue)) OVER (), 2) AS revenue_pct,
    ROUND(AVG(total_revenue), 2) AS avg_revenue_per_customer,
    ROUND(AVG(order_count), 1) AS avg_orders_per_customer
FROM customer_revenue
GROUP BY CASE 
    WHEN total_revenue >= 100000 THEN 'High Value (≥$100K)'
    WHEN total_revenue >= 50000 THEN 'Medium Value ($50K-$100K)'
    WHEN total_revenue >= 25000 THEN 'Low Value ($25K-$50K)'
    ELSE 'Very Low Value (<$25K)'
END
ORDER BY MIN(total_revenue) DESC;

-- ============================================================================
-- 6. EXECUTIVE SUMMARY KPIs (Single Query)
-- ============================================================================

WITH kpi_metrics AS (
    SELECT 
        -- Time period
        MIN(order_date) AS period_start,
        MAX(order_date) AS period_end,
        
        -- Volume metrics
        COUNT(*) AS total_orders,
        COUNT(DISTINCT customer_key) AS unique_customers,
        
        -- Revenue metrics
        SUM(order_revenue) AS total_revenue,
        SUM(revenue_leakage) AS revenue_leakage,
        
        -- OTIF metrics
        COUNT(CASE WHEN on_time_flag = 1 AND in_full_flag = 1 THEN 1 END) AS otif_orders,
        COUNT(CASE WHEN on_time_flag = 1 THEN 1 END) AS on_time_orders,
        COUNT(CASE WHEN in_full_flag = 1 THEN 1 END) AS in_full_orders,
        
        -- Fill rate metrics
        SUM(ordered_qty) AS total_ordered_qty,
        SUM(delivered_qty) AS total_delivered_qty
    FROM fact_orders
    WHERE order_date >= CURRENT_DATE - INTERVAL '30 days'
        AND delivery_date IS NOT NULL
)
SELECT 
    period_start,
    period_end,
    total_orders,
    unique_customers,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(revenue_leakage, 2) AS revenue_leakage,
    ROUND(100.0 * revenue_leakage / total_revenue, 2) AS revenue_leakage_pct,
    
    -- OTIF metrics
    ROUND(100.0 * otif_orders / total_orders, 2) AS otif_rate,
    ROUND(100.0 * on_time_orders / total_orders, 2) AS on_time_rate,
    ROUND(100.0 * in_full_orders / total_orders, 2) AS in_full_rate,
    
    -- Fill rates
    ROUND(100.0 * total_delivered_qty / total_ordered_qty, 2) AS volume_fill_rate,
    
    -- Average order value
    ROUND(total_revenue / total_orders, 2) AS avg_order_value
FROM kpi_metrics;

-- ============================================================================
-- 7. UPDATE FLAGS IN FACT TABLE (Run after data load)
-- ============================================================================

-- Update expected delivery date (if not already set)
UPDATE fact_orders
SET expected_delivery_date = order_date + INTERVAL '2 days'
WHERE expected_delivery_date IS NULL;

-- Update on_time_flag
UPDATE fact_orders
SET on_time_flag = CASE
    WHEN delivery_date IS NULL THEN NULL
    WHEN delivery_date <= expected_delivery_date THEN 1
    ELSE 0
END
WHERE on_time_flag IS NULL OR delivery_date IS NOT NULL;

-- Update in_full_flag
UPDATE fact_orders
SET in_full_flag = CASE
    WHEN delivered_qty IS NULL THEN NULL
    WHEN delivered_qty >= ordered_qty THEN 1
    ELSE 0
END
WHERE in_full_flag IS NULL OR delivered_qty IS NOT NULL;

-- Update OTIF flag (composite)
UPDATE fact_orders
SET otif_flag = CASE
    WHEN on_time_flag = 1 AND in_full_flag = 1 THEN 1
    ELSE 0
END
WHERE delivery_date IS NOT NULL;

-- ============================================================================
-- END OF KPI CALCULATIONS
-- ============================================================================
