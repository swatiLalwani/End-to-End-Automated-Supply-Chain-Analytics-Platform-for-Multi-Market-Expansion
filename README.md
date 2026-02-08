# 📦 End-to-End Automated Supply Chain Analytics Platform

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=flat&logo=postgresql&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=flat&logo=python&logoColor=white)
![n8n](https://img.shields.io/badge/n8n-EA4B71?style=flat&logo=n8n&logoColor=white)
![Quadratic](https://img.shields.io/badge/Quadratic-Analytics-blue)
![SQL](https://img.shields.io/badge/SQL-Advanced-orange)
![ETL](https://img.shields.io/badge/ETL-Automated-green)

> **Automated data ingestion to eliminate 15+ hours/week of manual reporting while identifying $111K in revenue leakage**

An automated analytics platform that transforms raw operational Excel files into real-time executive dashboards, enabling data-driven supply chain decisions during multi-market expansion.

---

## 📊 Quick Impact

| Metric | Value | Impact |
|--------|-------|--------|
| **Revenue Leakage Identified** | $111K | 3.7% of total revenue at risk |
| **OTIF Improvement** | +3.8pp | Tracked over 3-month period |
| **Reporting Time** | Manual → Real-time | Previously took days, now automated |
| **High-Risk Category Flagged** | Dairy (79.5% revenue) | Lowest OTIF at 47.7% |

---

## 🎯 Project Overview

This project simulates a real-world analytics engagement for a rapidly growing food manufacturer expanding from Dallas to New Jersey and beyond. Following expansion, the company experienced:

- Rising customer complaints
- Inventory stockouts and inconsistent fulfillment
- Revenue leakage from unfulfilled orders
- No centralized visibility into operational performance

**The Challenge:** Leadership needed a single source of truth to assess operational readiness before scaling into additional markets.

**The Solution:** An automated analytics platform providing real-time visibility into inventory health, fulfillment performance, and revenue leakage.

---

## 🏗️ Solution Architecture

```
┌─────────────────┐
│  Raw Excel Data │
│  (Orders, Inv)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐      ┌──────────────────┐
│   n8n Workflow  │─────▶│   PostgreSQL     │
│  (Scheduled ETL)│      │  (Data Modeling) │
└─────────────────┘      └────────┬─────────┘
                                  │
                                  ▼
                         ┌─────────────────┐
                         │    Quadratic    │
                         │  (Dashboards &  │
                         │   KPI Analysis) │
                         └─────────────────┘
```

### Pipeline Flow

1. **Google Drive Trigger**: n8n monitors designated folder for new Excel files
2. **Automated Download**: Files downloaded when detected
3. **CSV Extraction**: Excel files parsed into structured CSV format
4. **Database Insert**: Data loaded into PostgreSQL staging tables
5. **Transformation**: SQL queries calculate KPIs and aggregate metrics
6. **Dashboard Refresh**: Quadratic connects to PostgreSQL for real-time visualization

**Automation Frequency:** Daily scheduled runs + event-triggered updates

---

## 🛠️ Technology Stack

| Tool | Purpose | Why This Tool? |
|------|---------|----------------|
| **n8n** | Workflow automation | No-code ETL pipeline with built-in scheduling and error handling |
| **PostgreSQL** | Database & data modeling | Robust relational database for complex KPI calculations and historical tracking |
| **Python** | Advanced analytics | Custom scripts for complex calculations, data transformations, and business logic |
| **Quadratic** | Analytics & dashboards | Python-enabled spreadsheet with interactive visualizations and live database connections |
| **Google Drive** | Data source | Centralized storage for operational Excel files |
```

---

## 📈 Key Performance Indicators (KPIs)

### 1. **On-Time In-Full (OTIF) Rate**
- **Definition:** % of orders delivered on time with complete quantities
- **Current Performance:** 48.6% (Target: >65%)
- **Business Impact:** Primary measure of fulfillment excellence; below 50% indicates systemic issues

-- Calculate OTIF rate for last 30 days
SELECT 
    COUNT(*) as total_orders,
    COUNT(CASE WHEN on_time_flag = 1 AND in_full_flag = 1 THEN 1 END) as otif_orders,
    ROUND(
        100.0 * COUNT(CASE WHEN on_time_flag = 1 AND in_full_flag = 1 THEN 1 END) 
        / COUNT(*), 
    2) AS otif_rate
FROM fact_orders
WHERE order_date >= CURRENT_DATE - INTERVAL '30 days';

-- See full query logic: sql/kpi_calculations.sql
```

### 2. **Volume Fill Rate vs. In-Full Rate**
- **Volume Fill Rate:** % of total ordered quantity delivered
- **In-Full Rate:** % of orders with 100% quantity fulfilled
- **Key Insight:** High volume fill (96.5%) + Low in-full (66.8%) = Inventory allocation issues, not capacity constraints

### 3. **Revenue Leakage**
- **Definition:** Revenue lost from unfulfilled order quantities
- **Current Impact:** $111K (3.7% of total revenue)
- **Calculation:** `(Ordered Qty - Delivered Qty) × Unit Price`

### 4. **Late Delivery Rate**
- **Current Performance:** 28% of orders delivered late
- **Impact:** Direct driver of customer dissatisfaction and repeat order risk

### 5. **Category-Level Risk**
- **Dairy:** 79.5% of revenue, 47.7% OTIF (worst performing)
- **Food:** 15.9% of revenue, 49.8% OTIF
- **Beverages:** 4.6% of revenue, 65.8% OTIF (best performing)

---

## 🖼️ Dashboard Gallery

### Executive Dashboard
Strategic overview for COO-level decision making with monthly trends and category breakdowns.


**Screenshot:** 

<img src="dashboards/Executive dashboard.png" width="900">

**Key Features:**
- Monthly OTIF and revenue trends
- Category performance comparison
- Top customer analysis
- Revenue concentration risk visualization

---

### Supply Chain Dashboard
Operational metrics for logistics and fulfillment teams.

**Screenshot:**

<img src="dashboards/supplychain dashboard.png" width="900">

**Key Features:**
- Daily delivery metrics and delay analysis
- OTIF rates by category
- Shortfall tracking by product
- Late delivery trend analysis

---

### Product Dashboard
Product-level performance and revenue analysis.

**Screenshot:** 

<img src="dashboards/product dashboard.png" width="900">

**Key Features:**
- Top 10 products by revenue
- OTIF performance by product
- Category revenue share and delivery performance
- Quantity shortfall analysis by SKU

---

### Operations Dashboard
Daily operational insights and activity patterns.

**Screenshot:** 

<img src="dashboards/Operations Dashboard.png" width="900">

**Key Features:**
- Daily order volume and revenue trends
- Weekday performance analysis
- Peak day identification
- Customer order frequency analysis

---

### Finance Dashboard
Revenue analysis and customer lifetime value metrics.

**Screenshot:**

<img src="dashboards/finance dashboard.png" width="900">

**Key Features:**
- Monthly revenue trends by category
- Top customers by revenue
- CLV analysis and forecast accuracy
- Revenue loss quantification

---

## 💡 Critical Business Insights

### Finding #1: Inventory Allocation, Not Capacity
**Evidence:** 96.5% volume fill rate but only 66.8% in-full rate

**Interpretation:** Company has sufficient total inventory but struggles with order consolidation and allocation

**Recommendation:** Implement order batching logic and safety stock buffers for high-velocity SKUs

### Finding #2: Category Risk Concentration
**Evidence:** Dairy represents 79.5% of revenue but has lowest OTIF (47.7%)

**Interpretation:** Core revenue stream is at highest operational risk, blocking expansion readiness

**Recommendation:** Immediate focus on Dairy category logistics optimization and inventory management

### Finding #3: Late Delivery Cascade Effect
**Evidence:** 28% late delivery rate correlates with lowest OTIF categories

**Interpretation:** Logistics delays compound with inventory shortfalls to create compound failures

**Recommendation:** Targeted route optimization and carrier performance tracking for Dairy-heavy deliveries

---

## 📋 Project Structure

```
supply-chain-analytics/
├── README.md                          # This file
├── datasets/                          # Source data files
│   ├── dim_customers.csv
│   ├── dim_date.csv
│   ├── dim_products.csv
│   ├── dim_target_orders.csv
│   ├── fact_order_online.csv
│   ├── fact_orders_aggregate.csv
│   └── fact_summary.csv
├── sql/                               # Database queries
│   ├── 01_schema_setup.sql           # Database schema creation
│   ├── 02_kpi_calculations.sql       # Core KPI queries
│   ├── 03_category_analysis.sql      # Category performance queries
│   └── 04_trend_analysis.sql         # Time-based trend queries
├── scripts/                           # Python analytics scripts
│   ├── Category_Summary.py           # Category-level performance metrics
│   ├── Customer_Activity.py          # Customer ordering patterns
│   ├── Customer_LTV2.py              # Customer lifetime value analysis
│   ├── Customer_OTIF_Discrepancy.py  # Customer performance gaps
│   ├── Daily_Operations_Summary.py   # Daily operational KPIs
│   ├── Exec_Performance_Overview.py  # Executive summary metrics
│   ├── Executive_KPI_Table.py        # High-level KPI calculations
│   ├── KPI_Summary_supply_chain.py   # Supply chain KPI aggregation
│   ├── Late_Delivery_Analysis.py     # Delivery delay root cause analysis
│   ├── Monthly_Performance.py        # Month-over-month trend analysis
│   ├── Product_Performance.py        # Product-level analytics
│   ├── Revenue_Loss_Chart.py         # Revenue leakage visualization
│   ├── Revenue_Summary.py            # Revenue breakdown by category
│   └── Weekday_Performance.py        # Day-of-week performance patterns
├── n8n/                               # Workflow automation
│   └── My_workflow_4__1_.json        # Complete n8n workflow configuration
├── documents/                         # Documentation
│   ├── architecture.md               # Detailed architecture documentation
│   ├── kpi_methodology.md            # KPI calculation details
│   ├── Data_Dictionary.csv           # Field definitions and sources
│   ├── Executive_Summary.csv         # Executive summary table
│   └── Impact_Summary.csv            # Business impact metrics
├── dashboards/                        # Dashboard screenshots
│   ├── Executive_dashboard.png
│   ├── supplychain_dashboard.png
│   ├── product_dashboard.png
│   ├── Operations_Dashboard.png
│   └── finance_dashboard.png
└── images/                            # Architecture diagrams
    ├── Architecture_diagram.png
    └── workflow.png
```
---
## 🔄 Automated Workflow

The n8n workflow automates the entire data pipeline from ingestion to database loading:

**Screenshot:**

<img src="images/workflow (1).png" width="900">

**Workflow Steps:**
1. Monitor Google Drive folder for new Excel files
2. Download files when detected
3. Extract CSV data from Excel sheets
4. Validate data quality
5. Load into PostgreSQL staging tables
6. Execute transformation queries
7. Send completion notification

[View Complete Workflow JSON](n8n workflow automation/My workflow 4 (1).json)

---

## 🚀 Strategic Recommendations & 90-Day Roadmap

### Immediate Actions (Days 1-30)
1. **Dairy Category Sprint**
   - Audit current inventory levels for top 10 Dairy SKUs
   - Implement dynamic safety stock calculations
   - Priority logistics routing for Dairy orders

2. **Order Consolidation Logic**
   - Batch orders by delivery route and product category
   - Reduce partial shipments by 50%

### Mid-Term Actions (Days 31-60)
3. **Logistics Partner Performance Review**
   - Track carrier-level on-time performance
   - Renegotiate SLAs with bottom 25% performers

4. **Inventory Allocation Algorithm**
   - Implement demand forecasting for top 20 products
   - Automated reorder point calculations

### Long-Term Actions (Days 61-90)
5. **Expand Analytics Coverage**
   - Add demand forecasting dashboard
   - Implement inventory turnover tracking
   - Build customer churn risk model

**Target Outcome:** Increase OTIF from 48.6% to 60%, enabling confident expansion into 2 additional markets

---

## 🎯 Business Impact Summary

This platform enabled leadership to:

✅ **Quantify Revenue Loss**: Identified specific $111K opportunity from fulfillment improvements

✅ **Identify Expansion Blockers**: Flagged Dairy category as high-risk area requiring immediate action

✅ **Track Performance Trends**: Documented +3.8pp OTIF improvement over 3 months

✅ **Prioritize Interventions**: Data-backed decision making on logistics and inventory investments

✅ **Eliminate Manual Reporting**: Automated pipeline reduced reporting time from days to real-time

---

## 🔧 Technical Implementation Details

### Data Model
The PostgreSQL database implements a star schema with:

- **Fact Tables**: `fact_orders`, `fact_deliveries`
- **Dimension Tables**: `dim_products`, `dim_customers`, `dim_dates`
- **KPI Tables**: `kpi_summary`, `category_performance`

### n8n Workflow Components
1. **Google Drive Trigger Node**: Watches folder for new files
2. **Download File Node**: Retrieves Excel files
3. **CSV Parser Node**: Extracts data from Excel sheets
4. **PostgreSQL Insert Nodes**: Loads data into staging tables
5. **Error Handling**: Retry logic + Slack notifications on failure

### Key SQL Techniques Used
- Window functions for trend analysis
- CTEs for complex KPI calculations
- Date dimension tables for time-based aggregation
- Category-level performance tracking with ROLLUP

---

---

## 🐍 Python Analytics Scripts

The project includes **14 custom Python scripts** that power advanced analytics and visualization in the Quadratic dashboards. These scripts connect directly to PostgreSQL to perform real-time calculations and generate executive insights.

### Core Libraries Used
- **pandas**: Data manipulation and aggregation
- **psycopg2**: PostgreSQL database connectivity
- **numpy**: Numerical computations
- **datetime**: Time-based calculations

### Script Categories

#### 📊 Executive Analytics
| Script | Purpose | Key Metrics |
|--------|---------|-------------|
| **Executive_KPI_Table.py** | High-level dashboard KPIs | OTIF, revenue, order volume |
| **Exec_Performance_Overview.py** | Executive summary metrics | Monthly trends, category breakdown |
| **Monthly_Performance.py** | Month-over-month analysis | Growth rates, performance trends |

#### 🚚 Supply Chain Analytics
| Script | Purpose | Key Metrics |
|--------|---------|-------------|
| **KPI_Summary_supply_chain.py** | Supply chain KPI aggregation | Fill rates, delivery performance |
| **Late_Delivery_Analysis.py** | Root cause analysis of delays | Delay frequency, patterns, carriers |
| **Daily_Operations_Summary.py** | Daily operational insights | Order volume, peak times, throughput |
| **Weekday_Performance.py** | Day-of-week patterns | Weekday vs weekend analysis |

#### 💰 Revenue & Financial Analytics
| Script | Purpose | Key Metrics |
|--------|---------|-------------|
| **Revenue_Summary.py** | Revenue breakdown by category | Category revenue share, trends |
| **Revenue_Loss_Chart.py** | Revenue leakage visualization | Shortfall by product/category |

#### 👥 Customer Analytics
| Script | Purpose | Key Metrics |
|--------|---------|-------------|
| **Customer_Activity.py** | Customer ordering patterns | Order frequency, recency |
| **Customer_LTV2.py** | Customer lifetime value | CLV calculation, segmentation |
| **Customer_OTIF_Discrepancy.py** | Customer-level OTIF gaps | Performance variations by customer |

#### 📦 Product Analytics
| Script | Purpose | Key Metrics |
|--------|---------|-------------|
| **Product_Performance.py** | Product-level performance | Revenue, OTIF, shortfall by SKU |
| **Category_Summary.py** | Category-level aggregation | Category performance comparison |

### How Scripts Are Used

1. **Quadratic Integration**: Scripts run directly in Quadratic cells using Python engine
2. **Real-Time Execution**: Connect to PostgreSQL on-demand for live data
3. **Dashboard Generation**: Output feeds directly into dashboard visualizations
4. **Modular Design**: Each script focuses on specific analytics domain


## 📚 Additional Documentation

- **[Architecture Documentation](documents/architecture.md)**: Detailed system design and data flow
- **[KPI Methodology](documents/kpi_methodology.md)**: Complete calculation logic for all metrics
- **[KPI Queries](sql/kpi_calculations.sql)**: SQL code for all dashboard metrics
- **[n8n Workflow](n8n workflow automation/My workflow 4 (1).json)**: Complete automation workflow configuration
```

---

## 🤝 Skills Demonstrated

### Technical Skills
- **Workflow Automation**: n8n pipeline design with scheduling and error handling
- **Database Design**: PostgreSQL schema modeling for analytics workloads
- **SQL Analytics**: Complex aggregations, window functions, and KPI calculations
- **Python Programming**: Custom analytics scripts using pandas, psycopg2, and numpy
- **Data Engineering**: ETL pipeline development and data quality management
- **Data Visualization**: Executive-ready dashboard design in Quadratic with Python integration

### Business Skills
- **KPI Definition**: Translated business requirements into measurable metrics
- **Stakeholder Communication**: Executive-level insights from operational data
- **Strategic Planning**: 90-day improvement roadmap aligned with expansion goals
- **Problem Solving**: Root cause analysis of operational inefficiencies
```

---

