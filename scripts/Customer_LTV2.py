import pandas as pd
df = q.cells("Fact_Summary")
customers = q.cells("'dim_customers'!A2:D37", first_row_header=True)
merged = df.merge(customers[['customer_id', 'customer_name', 'city']], on='customer_id', how='left')

clv = merged.groupby(['customer_name', 'city']).agg(
orders=('order_id', 'count'), revenue=('total_amount', 'sum')
).reset_index()
clv['avg_order'] = (clv['revenue'] / clv['orders']).round(0)
top10 = clv.nlargest(10, 'revenue')
result
