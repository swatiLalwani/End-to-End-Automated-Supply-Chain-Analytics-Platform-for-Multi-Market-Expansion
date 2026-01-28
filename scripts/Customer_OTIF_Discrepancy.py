import pandas as pd
df = q.cells("Fact_Summary")
customers = q.cells("'dim_customers'!A2:D37", first_row_header=True)
merged = df.merge(customers[['customer_id', 'customer_name', 'city']], on='customer_id', how='left')

customer_metrics = merged.groupby(['customer_id', 'customer_name', 'city']).agg(
total_orders=('order_id', 'count'),
on_time_orders=('On Time', 'sum'),
in_full_orders=('In Full', 'sum'),
otif_orders=('On Time In Full', 'sum')
).reset_index()

customer_metrics['OTIF %'] = (customer_metrics['otif_orders'] / customer_metrics['total_orders'] * 100)
customer_metrics['Failed OTIF Orders'] = customer_metrics['total_orders'] - customer_metrics['otif_orders']
worst_performers = customer_metrics.nlargest(10, 'Failure Rate %')
output
