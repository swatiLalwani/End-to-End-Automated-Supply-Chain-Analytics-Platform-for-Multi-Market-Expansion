import pandas as pd
df = q.cells("Fact_Summary")
# Convert numeric columns...
day_order = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
daily_perf = df.groupby('Day Name').agg(
orders=('order_id', 'count'), revenue=('total_amount', 'sum'),
on_time=('On Time', 'sum'), in_full=('In Full', 'sum'),
otif=('On Time In Full', 'sum'), qty_ordered=('order_qty', 'sum'),
qty_delivered=('delivery_qty', 'sum')
).reset_index()

daily_perf['OT %'] = (daily_perf['on_time'] / daily_perf['orders'] * 100).round(1)
daily_perf['IF %'] = (daily_perf['in_full'] / daily_perf['orders'] * 100).round(1)
daily_perf['OTIF %'] = (daily_perf['otif'] / daily_perf['orders'] * 100).round(1)
daily_perf['Fill %'] = (daily_perf['qty_delivered'] / daily_perf['qty_ordered'] * 100).round(1)
output
