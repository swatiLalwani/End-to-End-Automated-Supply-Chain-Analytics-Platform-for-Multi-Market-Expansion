import pandas as pd
df = q.cells("Fact_Summary")
df['order_qty'] = pd.to_numeric(df['order_qty'])
df['delivery_qty'] = pd.to_numeric(df['delivery_qty'])
df['total_amount'] = pd.to_numeric(df['total_amount'])
df['On Time'] = pd.to_numeric(df['On Time'])
df['In Full'] = pd.to_numeric(df['In Full'])
df['On Time In Full'] = pd.to_numeric(df['On Time In Full'])
df['order_placement_date'] = pd.to_datetime(df['order_placement_date'], format='%m/%d/%Y')

total_orders = len(df)
unique_days = df['order_placement_date'].nunique()
unique_customers = df['customer_id'].nunique()
unique_products = df['product_id'].nunique()

otif_rate = (df['On Time In Full'].sum() / total_orders * 100)
on_time_rate = (df['On Time'].sum() / total_orders * 100)
in_full_rate = (df['In Full'].sum() / total_orders * 100)
fill_rate = (df['delivery_qty'].sum() / df['order_qty'].sum() * 100)
orders_per_day = total_orders / unique_days
revenue_per_day = df['total_amount'].sum() / unique_days

summary = pd.DataFrame({...})  # Creates summary table
summary
