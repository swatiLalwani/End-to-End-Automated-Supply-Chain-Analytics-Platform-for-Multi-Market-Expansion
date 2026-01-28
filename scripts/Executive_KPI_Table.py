import pandas as pd

df = q.cells("Fact_Summary")

# Conversions
for c in ['order_qty','delivery_qty','total_amount','In Full','On Time','On Time In Full']:
df[c] = pd.to_numeric(df[c], errors='coerce')

# Core metrics
order_lines = len(df)
unique_orders = df['order_id'].nunique()
active_customers = df['customer_id'].nunique()
active_products = df['product_id'].nunique()
total_revenue = df['total_amount'].sum()

# Delivery rates
otif = (df['On Time In Full'].sum() / order_lines) * 100
on_time = (df['On Time'].sum() / order_lines) * 100
in_full = (df['In Full'].sum() / order_lines) * 100
volume_fill = (df['delivery_qty'].sum() / df['order_qty'].sum()) * 100

# Revenue loss
unit_price = df['total_amount'] / df['order_qty']
undelivered_qty = df['order_qty'] - df['delivery_qty']
revenue_loss = (undelivered_qty * unit_price).sum()
loss_rate = (revenue_loss / total_revenue) * 100

kpi = pd.DataFrame({
'Metric': ['Total Orders','Total Order Lines','Total Revenue','Revenue Loss',
'Revenue Loss Rate','OTIF %','On-Time %','In-Full %',
'Volume Fill %','Active Customers','Active Products'],
'Value': [f"{unique_orders:,}",f"{order_lines:,}",f"${total_revenue:,.2f}",
f"${revenue_loss:,.2f}",f"{loss_rate:.2f}%",f"{otif:.1f}%",
f"{on_time:.1f}%",f"{in_full:.1f}%",f"{volume_fill:.1f}%",
f"{active_customers:,}",f"{active_products:,}"],
'Notes': ['','','','','Loss / Total Revenue','Target ≥ 50%','','','','','']
})
kpi
