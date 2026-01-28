import pandas as pd
df = q.cells("Fact_Summary")
df['agreed_delivery_date'] = pd.to_datetime(df['agreed_delivery_date'], errors='coerce')
df['actual_delivery_date'] = pd.to_datetime(df['actual_delivery_date'], errors='coerce')
df['delay_days'] = (df['actual_delivery_date'] - df['agreed_delivery_date']).dt.days

late_deliveries = df[df['On Time'] == 0].copy()
avg_delay = late_deliveries['delay_days'].mean()
max_delay = late_deliveries['delay_days'].max()
pd.DataFrame(summary_data)
