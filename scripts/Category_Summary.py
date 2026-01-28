import pandas as pd
df = q.cells("Fact_Summary")

cat_summary = df.groupby('category').agg(
products=('product_id', 'nunique'), orders=('order_id', 'count'),
revenue=('total_amount', 'sum'), qty_ordered=('order_qty', 'sum'),
qty_delivered=('delivery_qty', 'sum'), on_time=('On Time', 'sum'),
in_full=('In Full', 'sum'), otif=('On Time In Full', 'sum')
).reset_index()

cat_summary['Revenue Share %'] = (cat_summary['revenue'] / cat_summary['revenue'].sum() * 100).round(1)
cat_summary['OTIF %'] = (cat_summary['otif'] / cat_summary['orders'] * 100).round(1)
cat_summary['Shortfall'] = cat_summary['qty_ordered'] - cat_summary['qty_delivered']
output
