import pandas as pd

df = q.cells("Fact_Summary")
df['total_amount'] = pd.to_numeric(df['total_amount'], errors='coerce')
df['On Time In Full'] = pd.to_numeric(df['On Time In Full'], errors='coerce')
df['On Time'] = pd.to_numeric(df['On Time'], errors='coerce')
df['In Full'] = pd.to_numeric(df['In Full'], errors='coerce')

monthly = df.groupby(['Month', 'Month Name']).agg({
'order_id': 'count', 'total_amount': 'sum',
'On Time In Full': 'mean', 'On Time': 'mean', 'In Full': 'mean'
}).reset_index()
monthly = monthly.sort_values('Month')

result = pd.DataFrame({
'Month': monthly['Month Name'],
'Orders': monthly['order_id'].astype(int),
'Revenue': monthly['total_amount'].apply(lambda x: f'${x:,.0f}'),
'OTIF %': (monthly['On Time In Full'] * 100).round(1).astype(str) + '%',
'OT %': (monthly['On Time'] * 100).round(1).astype(str) + '%',
'IF %': (monthly['In Full'] * 100).round(1).astype(str) + '%'
})
result
