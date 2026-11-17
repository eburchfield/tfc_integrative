"""Linear-trend ('naive') projection of the national Delphi variables to 2050.
County-mean series per census year from ag_data_all_years_std.csv; OLS line through
available years; % change = fit(2050)/fit(2014.5) - 1 (2014.5 = midpoint of the 2012/2017
training panel). Variables observed in only one year are held at 2009-18 values (0%).
labor_number uses 2012+ only (series break between 2007 and 2012)."""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
import pandas as pd, numpy as np, json
s = pd.read_csv(f'{FOREB}/data/quantitative_data/data_input_RF_2/ag_data_all_years_std.csv')
V = ['crop_insurance_acre_rma','CRP_ACRE','biofuel_corn_percent_used','biofuel_soy_percent_used','N_fert_kg','P_fert_kg',
     'live_cattle_inventory','animal_sales_usd','no_ops_sales_lt_10k','sales_usd_gt_500k','rented_fract',
     'producer_exp_lt_10','Producer_nonwhite','labor_number']
m = s.groupby('Year')[V].mean(); n = s.groupby('Year')[V].count()
out = {}; rows = []
for v in V:
    y = m[v][n[v] > 1000].dropna()
    if v == 'labor_number': y = y[y.index >= 2012]
    if len(y) < 2:
        out[v] = 0.0; rows.append((v, list(y.index.astype(int)), np.nan, 0.0)); continue
    b, a = np.polyfit(y.index.values, y.values, 1)
    f = lambda t: a + b * t
    pct = max(100 * (f(2050) / f(2014.5) - 1), -100.0)
    out[v] = pct; rows.append((v, list(y.index.astype(int)), b, pct))
out['Cao_fert_N'] = out['N_fert_kg']; out['Cao_fert_P'] = out['P_fert_kg']
json.dump(out, open(f'{RES}/trend_pct.json', 'w'), indent=1)
print(pd.DataFrame(rows, columns=['variable', 'years', 'slope_per_yr', 'pct_2050']).round(4).to_string())
