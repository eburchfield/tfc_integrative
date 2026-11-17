"""Bridge factors: RF predictor in 2022 / RF baseline (2009-18 mean of available years), same source,
ratio of totals over counties with both. National (38-state model extent not applied; all counties in file) and Ohio."""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, RES
import pandas as pd, numpy as np, json
D=f"{FOREB}/data/quantitative_data/data_input_RF_2/"
a=pd.read_csv(D+'ag_data_all_years.csv',low_memory=False)
den={'CRP_ACRE':'tot_farm_acre','live_cattle_inventory':'tot_farm_acre','no_ops_sales_lt_10k':'tot_no_operation',
     'sales_usd_gt_500k':'tot_sales_usd','rented_fract':None,'Producer_nonwhite':'Producer_total_no',
     'labor_number':'tot_cropland_acre','cover_crop_acre':'tot_cropland_acre','till_new_conservational_acre':'tot_cropland_acre',
     'organic_number_operations':'tot_no_operation'}
base=a[(a.Year>=2009)&(a.Year<=2018)].groupby('GEOID').mean(numeric_only=True)
y22=a[a.Year==2022].set_index('GEOID')
def factor(v, sel):
    d=den[v]
    cols=[v]+([d] if d else [])
    B=base.loc[base.index.isin(sel),cols].dropna(); N=y22.loc[y22.index.isin(sel),cols].dropna()
    j=B.index.intersection(N.index); B=B.loc[j]; N=N.loc[j]
    if d is None:   # rented_fract is already a fraction per county: weight by farmland
        wB=base.loc[j,'tot_farm_acre']; wN=y22.loc[j,'tot_farm_acre']
        return float((N[v]*wN).sum()/wN.sum() / ((B[v]*wB).sum()/wB.sum())), len(j), float((B[v]*wB).sum()/wB.sum()), float((N[v]*wN).sum()/wN.sum())
    rb=B[v].sum()/B[d].sum(); rn=N[v].sum()/N[d].sum()
    return float(rn/rb), len(j), float(rb), float(rn)
allc=set(a.GEOID.unique()); oh={g for g in allc if 39000<=g<40000}
out={'national':{}, 'OH':{}}
for v in den:
    for k,sel in (('national',allc),('OH',oh)):
        f,n,rb,rn=factor(v,sel); out[k][v]=f
        print(f'{k:8s} {v:30s} base {rb:.4g} -> 2022 {rn:.4g}  factor {f:.3f}  (n={n})')
json.dump(out,open(f'{RES}/bridge_factors.json','w'),indent=1)
