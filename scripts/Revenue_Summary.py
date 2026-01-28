import pandas as pd
df = q.cells("Fact_Summary")
df['total_amount'] = pd.to_numeric(df['total_amount'], errors='coerce')
df['order_qty'] = pd.to_numeric(df['order_qty'], errors='coerce')
df['delivery_qty'] = pd.to_numeric(df['delivery_qty'], errors='coerce')

total_revenue = df['total_amount'].sum()
total_orders = df['order_id'].nunique()
avg_order_value = total_revenue / total_orders
revenue_loss = ((df['order_qty'] - df['delivery_qty']) * (df['total_amount'] / df['delivery_qty'])).sum()
revenue_loss_rate = (revenue_loss / (total_revenue + revenue_loss)) * 100
summary
