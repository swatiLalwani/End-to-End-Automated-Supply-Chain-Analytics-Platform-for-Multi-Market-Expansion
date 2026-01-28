import pandas as pd
df = q.cells("Fact_Summary")
customers = q.cells("'dim_customers'!A2:D37", first_row_header=True)

# Customer activity metrics
total_customers = df['customer_id'].nunique()
monthly_customers = {m: set(df[df['Month'] == m]['customer_id'].unique()) for m in months}
customers_all_months = len(set.intersection(*monthly_customers.values()))
retention_rate = (customers_all_months / total_customers) * 100

# High value customers (top 20%)
customer_revenue = df.groupby('customer_id')['total_amount'].sum().sort_values(ascending=False)
top_20_pct = int(len(customer_revenue) * 0.2)
top_20_contribution = (customer_revenue.head(top_20_pct).sum() / customer_revenue.sum()) * 100
summary
