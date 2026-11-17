"""Summaries for national_attr.py (38 states), on the integrative paper's own metrics.

Likelihood-weighted area change (cos-latitude weight; lat = 49.375 - (row + 0.5)/24), % of the zone's baseline;
zones on stored float32 B (core > 0.3, margin 0.1-0.3); mean absolute change on all valid pixels.
Usage: python national_stats.py CROP [CROP ...]  (reads OUT/national, writes RES)
"""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import OUT, RES
import sys, numpy as np, pandas as pd
crops = sys.argv[1:]
rows, items = [], []
for c in crops:
    d = np.load(f"{OUT}/national/{c}.npz", allow_pickle=True)
    H, W = d["shape"]; ok = d["ok"]
    row = np.nonzero(ok)[0] // W
    w = np.cos(np.deg2rad(49.375 - (row + .5) / 24))
    Bz = d["B"]; B = Bz.astype(float); N = d["N"].astype(float)
    Z = {"all": np.ones(len(B), bool), "core": Bz > .3, "margin": (Bz > .1) & (Bz <= .3)}
    wa = lambda x, base, m: 100 * np.sum(w[m] * (x - base)[m]) / np.sum(w[m] * B[m])
    P, PN = d["PAN"].astype(float), d["PAN_nostruct"].astype(float)
    r = dict(crop=c, pixels=int(ok.sum()),
             meanabs_climate=np.mean(np.abs(N - B)), meanabs_human=np.mean(np.abs(P - N)),
             meanabs_human_nostruct=np.mean(np.abs(PN - N)))
    r["ratio_human_to_climate20"] = r["meanabs_human"] / r["meanabs_climate"]
    r["ratio_nostruct_to_climate20"] = r["meanabs_human_nostruct"] / r["meanabs_climate"]
    for z, m in Z.items():
        r[f"{z}_climate"] = wa(N, B, m); r[f"{z}_human"] = wa(P, N, m); r[f"{z}_human_nostruct"] = wa(PN, N, m)
        r[f"{z}_combined"] = wa(P, B, m); r[f"{z}_combined_nostruct"] = wa(PN, B, m)
    rows.append(r)
    for k in [str(k) for k in d["keys"] if str(k).startswith("nat:")]:
        X = d[k].astype(float); it = dict(crop=c, item=k)
        for z, m in Z.items(): it[f"{z}_pct"] = wa(X, N, m)
        it["meanabs"] = np.mean(np.abs(X - N))
        items.append(it)
R = pd.DataFrame(rows); A = pd.DataFrame(items)
R.round(4).to_csv(f"{RES}/national_attr_summary.csv", index=False)
A.round(4).to_csv(f"{RES}/national_item_attribution.csv", index=False)
pd.set_option("display.width", 260); pd.set_option("display.max_columns", 40); pd.set_option("display.max_rows", 200)
print(R.round(3).T.to_string()); print(A.round(2).to_string())
