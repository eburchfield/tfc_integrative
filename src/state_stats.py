"""Summaries for place-informed projections (Nebraska, Ohio; Georgia on the county mask as a check). Writes state_stats.csv"""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
import numpy as np, pandas as pd
rows=[]
for st in ("GA","NE","OH"):
    for c in ["SOY","CORN","HAY","COTTON","PEANUTS","WHEAT","SORGHUM"]:
        try: s=np.load(f"{OUT}/states/{c}_{st}.npz")
        except FileNotFoundError: continue
        d=np.load(f"{OUT}/projections/{c}.npz"); H,W=d["shape"]; m=s["mask"]
        B,N,P=d["B"][m],d["N"][m],d["PAN"][m]; G=s["PANST"]
        lat=49.375-(np.arange(H)+.5)/24; w=np.repeat(np.cos(np.deg2rad(lat)),W)[m]
        ok=d["ok"][m]&np.isfinite(G)&np.isfinite(P)
        keep=ok&((B>.3)|(N>.3)|(P>.3)|(G>.3))
        if keep.sum()<50: continue
        Z={"all":ok,"core":ok&(B>.3),"margin":ok&(B>.1)&(B<=.3)}
        r=dict(state=st,crop=c,pixels_kept=int(keep.sum()),
               st_meanabs=np.mean(np.abs((G-P)[keep])),nat_meanabs=np.mean(np.abs((P-N)[keep])),st_meansigned=np.mean((G-P)[keep]),
               oor_pct=100*np.mean(s["oor"][ok]))
        r["ratio"]=r["st_meanabs"]/r["nat_meanabs"]
        for z,mm in Z.items():
            den=np.sum(w[mm]*B[mm])
            if den<=0: continue
            for k,x in (("clim",N),("stake",P),("place",G)): r[f"{z}_{k}"]=100*np.sum(w[mm]*(x-B)[mm])/den
        rows.append(r)
df=pd.DataFrame(rows); df.round(4).to_csv(f"{RES}/state_stats.csv",index=False)
pd.set_option("display.width",250); print(df.round(3).to_string())
