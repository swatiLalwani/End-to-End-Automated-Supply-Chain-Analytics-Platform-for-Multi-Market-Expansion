# System Architecture Documentation

## Overview

This document provides detailed technical architecture for the automated supply chain analytics platform.

---

## High-Level Architecture

```
┌───────────────────────────────────────────────────────────────────┐
│                          Data Sources                             │
│                                                                   │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │   Orders     │    │  Inventory   │    │  Deliveries  │      │
│  │   Excel      │    │    Excel     │    │    Excel     │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
│           │                   │                   │              │
│           └───────────────────┴───────────────────┘              │
│                               │                                  │
│                    Stored in Google Drive                        │
└───────────────────────────────┬───────────────────────────────────┘
                                │
                                ▼
┌───────────────────────────────────────────────────────────────────┐
│                     Orchestration Layer                           │
│                                                                   │
│                        ┌───────────────┐                         │
│                        │  n8n Workflow  │                         │
│                        │   Automation   │                         │
│                        └───────┬───────┘                         │
│                                │                                  │
│   ┌────────────────────────────┼────────────────────────────┐   │
│   │                            │                            │   │
│   ▼                            ▼                            ▼   │
│ Watch      ──────▶      Download    ──────▶         Extract     │
│ Folder                   Files                       CSV Data    │
│                                                                   │
└───────────────────────────────┬───────────────────────────────────┘
                                │
                                ▼
┌───────────────────────────────────────────────────────────────────┐
│                       Data Storage Layer                          │
│                                                                   │
│                      ┌─────────────────┐                         │
│                      │   PostgreSQL    │                         │
│                      │     Database    │                         │
│                      └────────┬────────┘                         │
│                               │                                  │
│   ┌───────────────────────────┼───────────────────────────┐     │
│   │                           │                           │     │
│   ▼                           ▼                           ▼     │
│ Staging     ──────▶     Fact Tables   ──────▶      KPI Tables   │
│ Tables                   (Normalized)              (Aggregated)  │
│                                                                   │
└───────────────────────────────┬───────────────────────────────────┘
                                │
                                ▼
┌───────────────────────────────────────────────────────────────────┐
│                    Analytics & Presentation                       │
│                                                                   │
│                      ┌─────────────────┐                         │
│                      │    Quadratic    │                         │
│                      │   Spreadsheet   │                         │
│                      └────────┬────────┘                         │
│                               │                                  │
│   ┌───────────────────────────┼───────────────────────────┐     │
│   │                           │                           │     │
│   ▼                           ▼                           ▼     │
│ Executive   ──────     Operations    ──────      Supply Chain   │
│ Dashboard             Dashboard                   Dashboard      │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

---

## Component Details

### 1. Data Ingestion Layer (n8n)

#### Workflow Components

**Trigger Node: Google Drive Folder Watch**
- **Type:** Event-driven + Scheduled polling
- **Configuration:** 
  - Folder ID: Monitored Google Drive folder
  - Polling Interval: Every 1 hour
  - File Type Filter: `.xlsx` files only
- **Output:** File metadata (name, ID, timestamp)

**Download Node**
- **Action:** Downloads Excel files to temporary storage
- **Error Handling:** Retry up to 3 times with exponential backoff
- **Storage:** `/tmp/n8n-downloads/` (cleared after processing)

**CSV Extraction Node**
- **Library:** `xlsx` (SheetJS)
- **Processing:**
  - Reads all sheets from Excel workbook
  - Converts to CSV format
  - Validates required columns exist
  - Handles missing values (NULL for empty cells)

**Data Validation Node**
- **Checks:**
  - Required fields present
  - Date format validation
  - Numeric field type verification
  - Duplicate order ID detection
- **Action on Failure:** Log error + send alert

**PostgreSQL Insert Node**
- **Mode:** Bulk insert (batch size: 1000 rows)
- **Strategy:** 
  - Insert into staging tables first
  - Run validation queries
  - Merge into production tables
  - Update last_updated timestamps

#### Error Handling Strategy

```javascript
// Pseudo-code for error handling flow
try {
  downloadFile()
  extractCSV()
  validateData()
  insertToDatabase()
} catch (error) {
  if (retries < 3) {
    wait(exponentialBackoff(retries))
    retry()
  } else {
    logError()
    sendSlackAlert()
    moveFileToErrorFolder()
  }
}
```

---

### 2. Database Layer (PostgreSQL)

#### Schema Design

**Staging Tables** (Temporary storage for raw data)
```sql
-- Orders staging
CREATE TABLE stg_orders (
    order_id VARCHAR(50),
    order_date DATE,
    customer_id VARCHAR(50),
    product_id VARCHAR(50),
    ordered_qty INTEGER,
    unit_price DECIMAL(10,2),
    loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Similar structure for deliveries and inventory staging
```

**Fact Tables** (Normalized operational data)
```sql
-- Main orders fact table
CREATE TABLE fact_orders (
    order_key SERIAL PRIMARY KEY,
    order_id VARCHAR(50) UNIQUE NOT NULL,
    order_date DATE NOT NULL,
    customer_key INTEGER REFERENCES dim_customers(customer_key),
    product_key INTEGER REFERENCES dim_products(product_key),
    ordered_qty INTEGER NOT NULL,
    delivered_qty INTEGER,
    unit_price DECIMAL(10,2) NOT NULL,
    delivery_date DATE,
    expected_delivery_date DATE,
    on_time_flag INTEGER,  -- 1 if delivered on time, 0 otherwise
    in_full_flag INTEGER,  -- 1 if full quantity delivered, 0 otherwise
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Performance indexes
CREATE INDEX idx_order_date ON fact_orders(order_date);
CREATE INDEX idx_customer ON fact_orders(customer_key);
CREATE INDEX idx_product ON fact_orders(product_key);
```

**Dimension Tables**
```sql
-- Products dimension
CREATE TABLE dim_products (
    product_key SERIAL PRIMARY KEY,
    product_id VARCHAR(50) UNIQUE NOT NULL,
    product_name VARCHAR(200),
    category VARCHAR(100),
    subcategory VARCHAR(100)
);

-- Customers dimension
CREATE TABLE dim_customers (
    customer_key SERIAL PRIMARY KEY,
    customer_id VARCHAR(50) UNIQUE NOT NULL,
    customer_name VARCHAR(200),
    city VARCHAR(100),
    state VARCHAR(50)
);

-- Date dimension (for time-based analysis)
CREATE TABLE dim_date (
    date_key INTEGER PRIMARY KEY,
    full_date DATE UNIQUE NOT NULL,
    year INTEGER,
    quarter INTEGER,
    month INTEGER,
    month_name VARCHAR(20),
    week_of_year INTEGER,
    day_of_week INTEGER,
    day_name VARCHAR(20),
    is_weekend BOOLEAN
);
```

**KPI Summary Tables** (Pre-aggregated metrics)
```sql
-- Category-level daily KPIs
CREATE TABLE kpi_category_daily (
    summary_key SERIAL PRIMARY KEY,
    calc_date DATE NOT NULL,
    category VARCHAR(100),
    total_orders INTEGER,
    total_revenue DECIMAL(15,2),
    otif_orders INTEGER,
    otif_rate DECIMAL(5,2),
    avg_fill_rate DECIMAL(5,2),
    revenue_leakage DECIMAL(15,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Monthly executive summary
CREATE TABLE kpi_executive_monthly (
    summary_key SERIAL PRIMARY KEY,
    month_year DATE NOT NULL,
    total_orders INTEGER,
    total_revenue DECIMAL(15,2),
    otif_rate DECIMAL(5,2),
    late_delivery_rate DECIMAL(5,2),
    revenue_leakage DECIMAL(15,2),
    top_customer VARCHAR(200),
    worst_category VARCHAR(100)
);
```

#### Data Transformation Pipeline

```sql
-- Example: ETL from staging to fact table
INSERT INTO fact_orders (
    order_id,
    order_date,
    customer_key,
    product_key,
    ordered_qty,
    delivered_qty,
    unit_price,
    delivery_date,
    expected_delivery_date,
    on_time_flag,
    in_full_flag
)
SELECT 
    so.order_id,
    so.order_date,
    dc.customer_key,
    dp.product_key,
    so.ordered_qty,
    COALESCE(sd.delivered_qty, 0) AS delivered_qty,
    so.unit_price,
    sd.delivery_date,
    so.order_date + INTERVAL '2 days' AS expected_delivery_date,
    CASE 
        WHEN sd.delivery_date <= (so.order_date + INTERVAL '2 days') 
        THEN 1 ELSE 0 
    END AS on_time_flag,
    CASE 
        WHEN sd.delivered_qty >= so.ordered_qty 
        THEN 1 ELSE 0 
    END AS in_full_flag
FROM stg_orders so
LEFT JOIN stg_deliveries sd ON so.order_id = sd.order_id
JOIN dim_customers dc ON so.customer_id = dc.customer_id
JOIN dim_products dp ON so.product_id = dp.product_id
ON CONFLICT (order_id) 
DO UPDATE SET
    delivered_qty = EXCLUDED.delivered_qty,
    delivery_date = EXCLUDED.delivery_date,
    on_time_flag = EXCLUDED.on_time_flag,
    in_full_flag = EXCLUDED.in_full_flag,
    updated_at = CURRENT_TIMESTAMP;
```

---

### 3. Analytics Layer (Quadratic)

#### Connection Configuration

**Database Connection**
- **Type:** PostgreSQL
- **Connection String:** `postgresql://username@host:5432/supply_chain_db`
- **SSL Mode:** Required
- **Connection Pooling:** Max 5 concurrent connections

#### Dashboard Queries

Each dashboard sheet connects directly to PostgreSQL views or tables:

**Executive Dashboard Queries:**
```python
# Python cell in Quadratic for dynamic KPI calculation
import pandas as pd
from quadratic import get_sql_connection

conn = get_sql_connection('postgres_supply_chain')

# Monthly trend query
monthly_kpis = pd.read_sql("""
    SELECT 
        TO_CHAR(order_date, 'Mon YY') as month,
        COUNT(*) as total_orders,
        SUM(ordered_qty * unit_price) as revenue,
        ROUND(AVG(CASE WHEN on_time_flag = 1 AND in_full_flag = 1 THEN 100.0 ELSE 0 END), 2) as otif_rate
    FROM fact_orders
    GROUP BY TO_CHAR(order_date, 'Mon YY'), DATE_TRUNC('month', order_date)
    ORDER BY DATE_TRUNC('month', order_date)
""", conn)

# Category breakdown
category_performance = pd.read_sql("""
    SELECT 
        p.category,
        COUNT(*) as orders,
        SUM(o.ordered_qty * o.unit_price) as revenue,
        ROUND(100.0 * SUM(CASE WHEN on_time_flag = 1 AND in_full_flag = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) as otif_rate
    FROM fact_orders o
    JOIN dim_products p ON o.product_key = p.product_key
    GROUP BY p.category
    ORDER BY revenue DESC
""", conn)
```

#### Refresh Strategy

- **Manual Refresh:** User-triggered via Quadratic refresh button
- **Scheduled Refresh:** Not currently implemented (future enhancement)
- **Incremental Load:** Only new/updated records loaded via `WHERE updated_at > last_refresh`

---

## Data Flow Sequence

### Daily Automated Flow

```
Time: 2:00 AM (Scheduled)
┌─────────────────────────────────────────┐
│ 1. n8n Workflow Triggered (Schedule)    │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ 2. Check Google Drive for New Files     │
│    - Files modified in last 24 hours    │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ 3. Download Files (If Found)            │
│    - Orders_YYYYMMDD.xlsx                │
│    - Deliveries_YYYYMMDD.xlsx            │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ 4. Extract & Validate Data              │
│    - Parse Excel sheets                  │
│    - Data quality checks                 │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ 5. Load to PostgreSQL Staging           │
│    - Bulk insert (1000 rows/batch)      │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ 6. Run ETL Transformations               │
│    - Merge staging → fact tables         │
│    - Update dimension tables             │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ 7. Calculate KPIs                        │
│    - Aggregate metrics                   │
│    - Update summary tables               │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ 8. Send Completion Notification          │
│    - Slack message with summary          │
│    - Email to stakeholders (optional)    │
└─────────────────────────────────────────┘
```

---

## Performance Considerations

### Database Optimization

**Indexing Strategy:**
- B-tree indexes on date columns for time-based queries
- Composite indexes on frequently filtered column combinations
- Covering indexes for common dashboard queries

**Query Optimization:**
- Materialized views for expensive aggregations
- Partitioning of fact tables by month (future enhancement)
- Regular VACUUM and ANALYZE maintenance

**Estimated Query Performance:**
- Executive dashboard load: < 2 seconds
- Category analysis: < 1 second
- Full data refresh: ~5 minutes (for 10K+ orders)

### Scalability Plan

**Current Capacity:**
- Up to 50K orders/month
- 500 products
- 200 customers

**Scale-Up Path:**
- Database connection pooling (pgBouncer)
- Read replicas for analytics queries
- Incremental data loading strategy
- Partition large fact tables by date range

---

## Security & Access Control

### Database Security

**User Roles:**
```sql
-- Read-only analytics user
CREATE ROLE analytics_readonly WITH LOGIN PASSWORD 'secure_password';
GRANT CONNECT ON DATABASE supply_chain_db TO analytics_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO analytics_readonly;

-- ETL process user (read/write to staging, read-only to prod)
CREATE ROLE etl_process WITH LOGIN PASSWORD 'secure_password';
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA staging TO etl_process;
GRANT SELECT, INSERT, UPDATE ON fact_orders, fact_deliveries TO etl_process;
```

### n8n Security

- **Credentials:** Stored in n8n encrypted credentials store
- **API Keys:** Google Drive API with restricted scope (read-only)
- **Network:** n8n runs in private subnet, no public internet access

### Data Privacy

- **Customer PII:** Customer names hashed in non-production environments
- **Audit Trail:** All data modifications logged with timestamp and user
- **Backup Strategy:** Daily automated backups with 30-day retention

---

## Monitoring & Alerting

### Key Metrics Tracked

1. **Pipeline Health:**
   - Workflow execution success rate
   - Average execution time
   - Data quality validation failures

2. **Data Quality:**
   - Missing/null value rates
   - Duplicate record detection
   - Schema validation errors

3. **System Performance:**
   - Database query execution times
   - Dashboard load times
   - Storage usage trends

### Alert Thresholds

```yaml
alerts:
  - name: "Workflow Failure"
    condition: "Execution status = 'error'"
    action: "Send Slack alert immediately"
    
  - name: "Data Quality Issue"
    condition: "Null rate > 5%"
    action: "Email data team + pause next run"
    
  - name: "Performance Degradation"
    condition: "Dashboard load time > 10 seconds"
    action: "Log warning + investigate"
```

---

## Disaster Recovery

### Backup Strategy

**Database Backups:**
- Full backup: Daily at 3:00 AM
- Incremental backup: Every 6 hours
- Retention: 30 days rolling

**n8n Workflow Backups:**
- JSON export: Weekly
- Version control: Git repository
- Configuration backup: Daily

### Recovery Procedures

**Scenario 1: Database Corruption**
1. Stop ETL pipeline
2. Restore from most recent full backup
3. Apply incremental backups since full backup
4. Validate data integrity
5. Resume pipeline

**Scenario 2: n8n Workflow Failure**
1. Identify failed node in workflow
2. Check error logs for root cause
3. Fix configuration or code issue
4. Manually re-run failed executions
5. Verify data completeness

**Recovery Time Objective (RTO):** 4 hours  
**Recovery Point Objective (RPO):** 6 hours

---

## Future Enhancements

### Phase 2 Roadmap

1. **Real-Time Streaming**
   - Replace batch processing with event-driven architecture
   - Kafka for message queue
   - Real-time dashboard updates

2. **Predictive Analytics**
   - Demand forecasting ML model
   - Inventory optimization recommendations
   - Customer churn prediction

3. **Advanced Visualizations**
   - Interactive dashboards in Power BI or Tableau
   - Mobile app for on-the-go monitoring
   - Custom alerting based on KPI thresholds

4. **Data Warehouse Migration**
   - Move to Snowflake or BigQuery for better scalability
   - Implement dbt for transformation layer
   - Add data lineage tracking

---

## Appendix

### Technologies Used

| Component | Technology | Version |
|-----------|-----------|---------|
| Workflow Automation | n8n | 1.19.0 |
| Database | PostgreSQL | 15.3 |
| Analytics Platform | Quadratic | 2024.1 |
| Cloud Storage | Google Drive | API v3 |
| Programming | Python | 3.11 |
| SQL | PostgreSQL | 15 |

### External Dependencies

- Google Drive API credentials
- PostgreSQL JDBC driver
- Python libraries: pandas, psycopg2, openpyxl

---

*Last Updated: February 2026*
