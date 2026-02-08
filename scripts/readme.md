# Python Analytics Scripts

This directory contains 14 custom Python scripts that power the analytics engine for the supply chain platform. Each script connects to PostgreSQL to perform specific analytical tasks and generate insights for the Quadratic dashboards.

---

## 📊 Script Inventory

### Executive & Strategic Analytics

#### 1. **Executive_KPI_Table.py**
**Purpose:** Generates high-level KPI summary for executive dashboard

**Key Metrics:**
- Total orders and revenue
- OTIF rate (current and trend)
- Late delivery rate
- Revenue leakage amount and percentage
- Top performing and underperforming categories

**Output:** Single-row KPI summary table

**Used In:** Executive Dashboard (top KPI cards)

---

#### 2. **Exec_Performance_Overview.py**
**Purpose:** Comprehensive executive performance snapshot

**Key Metrics:**
- Month-over-month performance comparison
- Category-level OTIF breakdown
- Top 5 customers by revenue
- Year-to-date performance vs targets

**Output:** Multi-section performance report

**Used In:** Executive Dashboard (main performance section)

---

#### 3. **Monthly_Performance.py**
**Purpose:** Month-over-month trend analysis

**Key Metrics:**
- Monthly OTIF rate trend (last 6 months)
- Revenue growth rate by month
- Order volume trends
- Performance velocity (rate of improvement)

**Output:** Time series data for trend charts

**Used In:** Executive Dashboard (trend line charts)

---

### Supply Chain Operations

#### 4. **KPI_Summary_supply_chain.py**
**Purpose:** Core supply chain performance metrics

**Key Metrics:**
- Volume fill rate vs In-full rate
- Category-level OTIF performance
- Inventory shortfall by product
- Delivery performance by city

**Output:** Supply chain KPI table

**Used In:** Supply Chain Dashboard

---

#### 5. **Late_Delivery_Analysis.py**
**Purpose:** Root cause analysis for delivery delays

**Key Metrics:**
- Late delivery rate by category
- Average days late by product
- Peak delay times (day of week, time of month)
- Late delivery correlation with order volume

**Output:** Delay analysis table with root cause flags

**Used In:** Supply Chain Dashboard (delay analysis section)

---

#### 6. **Daily_Operations_Summary.py**
**Purpose:** Daily operational metrics and patterns

**Key Metrics:**
- Orders per day (last 30 days)
- Revenue per day
- Daily OTIF rate
- Peak order days

**Output:** Daily aggregated metrics

**Used In:** Operations Dashboard

---

#### 7. **Weekday_Performance.py**
**Purpose:** Day-of-week performance patterns

**Key Metrics:**
- OTIF rate by day of week
- Order volume by weekday vs weekend
- Revenue patterns across week
- Best/worst performing days

**Output:** Weekday comparison table

**Used In:** Operations Dashboard (weekday analysis chart)

---

### Revenue & Financial Analytics

#### 8. **Revenue_Summary.py**
**Purpose:** Revenue breakdown and analysis

**Key Metrics:**
- Revenue by category
- Revenue by city/region
- Month-over-month revenue change
- Revenue concentration (top 20% of customers)

**Output:** Revenue breakdown table

**Used In:** Finance Dashboard

---

#### 9. **Revenue_Loss_Chart.py**
**Purpose:** Revenue leakage visualization data

**Key Metrics:**
- Revenue leakage by category
- Top 10 products by revenue lost
- Revenue leakage trend over time
- Potential recovery amount

**Output:** Chart-ready data for revenue loss visualization

**Used In:** Finance Dashboard (revenue leakage chart)

---

### Customer Analytics

#### 10. **Customer_Activity.py**
**Purpose:** Customer ordering behavior analysis

**Key Metrics:**
- Order frequency per customer
- Days since last order
- Average order value by customer
- Customer activity segmentation (active, at-risk, churned)

**Output:** Customer activity profile table

**Used In:** Operations Dashboard (customer section)

---

#### 11. **Customer_LTV2.py**
**Purpose:** Customer lifetime value calculation

**Key Metrics:**
- Historical CLV (total revenue to date)
- Average order value
- Order frequency
- Customer tenure
- CLV segmentation (high/medium/low value)

**Output:** Customer LTV ranking table

**Used In:** Finance Dashboard (customer value section)

---

#### 12. **Customer_OTIF_Discrepancy.py**
**Purpose:** Customer-level OTIF performance gaps

**Key Metrics:**
- OTIF rate by customer
- Customers with significant OTIF discrepancy vs average
- Customer-specific delivery issues
- At-risk customers (low OTIF + high revenue)

**Output:** Customer OTIF comparison table

**Used In:** Operations Dashboard (customer OTIF analysis)

---

### Product Analytics

#### 13. **Product_Performance.py**
**Purpose:** Product-level performance metrics

**Key Metrics:**
- Revenue by product
- OTIF rate by product
- Quantity shortfall by SKU
- Product velocity (units per day)
- Underperforming products (high revenue + low OTIF)

**Output:** Product performance table

**Used In:** Product Dashboard

---

#### 14. **Category_Summary.py**
**Purpose:** Category-level aggregation and comparison

**Key Metrics:**
- Category revenue share
- Category OTIF performance
- Category-level fill rates
- Category risk score (revenue × (1 - OTIF))

**Output:** Category comparison table

**Used In:** Executive Dashboard & Product Dashboard (category sections)

---

## 🔧 Common Script Structure

All scripts follow this consistent pattern:

```python
"""
Script Name: [Script_Name].py
Purpose: [Brief description]
Output: [What the script returns]
"""

import psycopg2
import pandas as pd
from datetime import datetime, timedelta

# Database connection configuration
DB_CONFIG = {
    'host': 'your_host',
    'database': 'supply_chain_db',
    'user': 'analytics_user',
    'password': 'password'  # Use environment variables in production
}

def get_connection():
    """Establish database connection"""
    return psycopg2.connect(**DB_CONFIG)

def calculate_metrics():
    """Main calculation logic"""
    conn = get_connection()
    
    query = """
        -- SQL query to retrieve data
    """
    
    df = pd.read_sql(query, conn)
    
    # Data transformations
    # ... calculation logic ...
    
    conn.close()
    return df

if __name__ == "__main__":
    # Main execution
    result = calculate_metrics()
    print(result)
```

---

## 🚀 Usage

### In Quadratic (Primary Use Case)

```python
# Import and run script in Quadratic Python cell
import sys
sys.path.append('/path/to/scripts')

from Executive_KPI_Table import calculate_metrics
kpis = calculate_metrics()

# Display in sheet
kpis
```

### Standalone Execution

```bash
# Run individual script
python scripts/Revenue_Summary.py

# Run with custom date range
python scripts/Monthly_Performance.py --start-date 2024-01-01 --end-date 2024-12-31
```

---

## 📦 Dependencies

Install required packages:

```bash
pip install -r requirements.txt
```

Required libraries:
- `pandas` - Data manipulation
- `psycopg2-binary` - PostgreSQL connection
- `numpy` - Numerical operations
- `python-dotenv` - Environment variable management

---

## 🔐 Configuration

### Database Credentials

**Best Practice:** Use environment variables instead of hardcoding credentials

Create a `.env` file:
```
DB_HOST=your_database_host
DB_NAME=supply_chain_db
DB_USER=analytics_user
DB_PASSWORD=your_password
DB_PORT=5432
```

Update scripts to use:
```python
import os
from dotenv import load_dotenv

load_dotenv()

DB_CONFIG = {
    'host': os.getenv('DB_HOST'),
    'database': os.getenv('DB_NAME'),
    'user': os.getenv('DB_USER'),
    'password': os.getenv('DB_PASSWORD')
}
```

---

## 🧪 Testing

Each script can be tested independently:

```bash
# Test database connection
python -c "from scripts.Executive_KPI_Table import get_connection; conn = get_connection(); print('Connection successful')"

# Run and validate output
python scripts/Revenue_Summary.py | head -10
```

---

## 📈 Performance Considerations

### Query Optimization
- All scripts use optimized SQL queries with proper indexes
- Date range filtering applied at database level
- Aggregations performed in SQL before loading to pandas

### Caching
- Consider implementing result caching for frequently run scripts
- Use `@lru_cache` decorator for repeated calculations

### Execution Time
- Most scripts execute in < 2 seconds
- Large aggregations (Monthly_Performance) may take 3-5 seconds

---

## 🛠️ Maintenance

### Adding New Scripts

1. Follow the common structure template
2. Add clear docstrings explaining purpose and output
3. Test independently before integrating into dashboards
4. Update this README with script details

### Modifying Existing Scripts

1. Test changes with sample data first
2. Verify output format matches dashboard expectations
3. Update documentation if metrics change
4. Notify dashboard owners of breaking changes

---

## 🔄 Integration with Pipeline

### Data Flow

```
PostgreSQL (Source)
    ↓
Python Scripts (Calculations)
    ↓
Quadratic Cells (Visualization)
    ↓
Dashboards (Presentation)
```

### Refresh Strategy

- **Manual Refresh:** User triggers script execution in Quadratic
- **Scheduled Refresh:** Scripts can be scheduled via cron or task scheduler
- **Event-Driven:** Trigger after n8n pipeline completes data load

---
