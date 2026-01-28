import pandas as pd
import plotly.graph_objects as go
from plotly.subplots import make_subplots

f = q.cells("Fact_Summary")
customers = q.cells("'dim_customers'!A2:D37", first_row_header=True)

f['customer_id'] = pd.to_numeric(f['customer_id'], errors='coerce').astype(int)
customers['customer_id'] = pd.to_numeric(customers['customer_id'], errors='coerce').astype(int)
for c in ['On Time','In Full','On Time In Full','total_amount','Month']:
f[c] = pd.to_numeric(f[c], errors='coerce')

m = f.merge(customers[['customer_id','city']], on='customer_id', how='left')
month_map = {3:'Mar',4:'Apr',5:'May'}

monthly = m.groupby('Month').agg(total=('order_id','count'), otif=('On Time In Full','sum')).reset_index()
monthly['Month'] = monthly['Month'].astype(int)
monthly = monthly.sort_values('Month')
monthly['Month Name'] = monthly['Month'].map(month_map)
monthly['OTIF %'] = (monthly['otif']/monthly['total']*100).round(1)

city = m.groupby('city').agg(total=('order_id','count'), otif=('On Time In Full','sum')).reset_index()
city['OTIF %'] = (city['otif']/city['total']*100).round(1)

fig = make_subplots(rows=1, cols=2, subplot_titles=('OTIF Trend by Month','OTIF by City'))
# Add traces for line chart and bar chart...
fig.show()
