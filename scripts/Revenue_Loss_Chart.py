import pandas as pd
import plotly.graph_objects as go

df = q.cells("Fact_Summary")
monthly = df.groupby(['Month', 'Month Name']).agg(
revenue=('total_amount', 'sum'), ordered=('order_qty', 'sum'), delivered=('delivery_qty', 'sum')
).reset_index()
monthly['loss'] = (monthly['ordered'] - monthly['delivered']) / monthly['ordered'] * monthly['revenue']

fig = go.Figure()
fig.add_trace(go.Bar(name='Revenue', x=monthly['Month Name'], y=monthly['revenue'], marker_color='#27AE60'))
fig.add_trace(go.Bar(name='Revenue Loss', x=monthly['Month Name'], y=monthly['loss'], marker_color='#E74C3C'))
fig.update_layout(title='Monthly Revenue vs Loss', barmode='group')
fig.show()
