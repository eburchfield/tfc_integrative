"""Robustness tests with panel-relative inputs (Supplementary Note 3): additivity (PAN30),
reversed sign (PREV), tiny shift (PTINY), area of applicability (oor_pan). Writes stats_relative_robustness.csv"""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
import numpy as np, pandas as pd
rows=[]
for c in ["SOY","CORN","HAY","COTTON","PEANUTS","WHEAT","SORGHUM"]:
    d=np.load(f"{OUT}/projections/{c}.npz"); e=d   # PAN30, PREV and PTINY are written with the main projections
    H,W=d["shape"]; ok=d["ok"]&e["ok"]
    lat=49.375-(np.arange(H)+.5)/24; w=np.repeat(np.cos(np.deg2rad(lat)),W)
    B,N,P=d["B"],d["N"],d["PAN"]; P30,R,T=e["PAN30"],e["PREV"],e["PTINY"]
    Z={"all":ok,"core":ok&(B>.3),"margin":ok&(B>.1)&(B<=.3),"outside":ok&(B<=.1)}
    wa=lambda x,base,m: 100*np.sum(w[m]*(x-base)[m])/np.sum(w[m]*B[m])
    r=dict(crop=c)
    for z,m in Z.items():
        r[f"delphi_{z}"]=wa(P,N,m); r[f"delphi30_{z}"]=wa(P30,B,m); r[f"rev_{z}"]=wa(R,N,m); r[f"tiny10_{z}"]=10*wa(T,N,m)
    r["meanabs_delphi"]=np.mean(np.abs((P-N)[ok])); r["meanabs_tiny10"]=10*np.mean(np.abs((T-N)[ok]))
    r["aoa_out_pan_pct"]=100*np.mean(e["oor_pan"][ok]); r["aoa_out_abs_pct"]=100*np.mean(e["oor"][ok])
    for k,x in (("B",B),("N",N),("PAN",P),("PREV",R)): r[f"sd_{k}"]=np.std(x[ok])
    rows.append(r)
df=pd.DataFrame(rows); df.round(4).to_csv(f"{RES}/stats_relative_robustness.csv",index=False)
pd.set_option("display.width",250)
print(df[["crop","delphi_all","delphi30_all","delphi_margin","rev_margin","delphi_core","rev_core","delphi_outside","rev_outside"]].round(2).to_string())
print(df[["crop","delphi_all","tiny10_all","delphi_margin","tiny10_margin","aoa_out_pan_pct","aoa_out_abs_pct","sd_B","sd_N","sd_PAN","sd_PREV"]].round(3).to_string())
