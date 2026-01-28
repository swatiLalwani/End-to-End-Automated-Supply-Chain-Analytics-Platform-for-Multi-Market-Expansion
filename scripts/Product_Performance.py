import pandas as pd
df = q.cells("Fact_Summary")
# Convert numeric columns

product_perf = df.groupby(['product_name', 'category']).agg(
orders=('order_id', 'count'), revenue=('total_amount', 'sum'),
qty_ordered=('order_qty', 'sum'), qty_delivered=('delivery_qty', 'sum'),
on_time=('On Time', 'sum'), in_full=('In Full', 'sum'), otif=('On Time In Full', 'sum')
).reset_index()

product_perf['OT %'] = (product_perf['on_time'] / product_perf['orders'] * 100).round(1)
product_perf['IF %'] = (product_perf['in_full'] / product_perf['orders'] * 100).round(1)
product_perf['OTIF %'] = (product_perf['otif'] / product_perf['orders'] * 100).round(1)
product_perf['Fill %'] = (product_perf['qty_delivered'] / product_perf['qty_ordered'] * 100).round(1)
product_perf['Shortfall'] = product_perf['qty_ordered'] - product_perf['qty_delivered']
product_perf = product_perf.sort_values('revenue', ascending=False)
output
