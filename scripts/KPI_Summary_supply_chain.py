import pandas as pd
df = q.cells("Fact_Summary")
# Convert columns to numeric
df['order_qty'] = pd.to_numeric(df['order_qty'], errors='coerce')
df['delivery_qty'] = pd.to_numeric(df['delivery_qty'], errors='coerce')
df['In Full'] = pd.to_numeric(df['In Full'], errors='coerce')
df['On Time'] = pd.to_numeric(df['On Time'], errors='coerce')
df['On Time In Full'] = pd.to_numeric(df['On Time In Full'], errors='coerce')

# Calculate KPIs
total_order_lines = len(df)
line_fill_rate = (df['In Full'].sum() / len(df)) * 100
volume_fill_rate = (df['delivery_qty'].sum() / df['order_qty'].sum()) * 100
total_orders = df['order_id'].nunique()
on_time_delivery_pct = (df['On Time'].sum() / len(df)) * 100
in_full_delivery_pct = (df['In Full'].sum() / len(df)) * 100
otif_pct = (df['On Time In Full'].sum() / len(df)) * 100
pd.DataFrame(kpi_data)
