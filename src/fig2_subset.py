"""Fig. 2 (LR's SHAP) human-controlled share over different county sets, to diagnose the refit gap."""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
import sys, numpy as np, pandas as pd
import circdata
f = pd.read_csv(f"{FIGDATA}/fig2_county_group_abs_shap.csv"); f["GEOID"] = f.GEOID.astype(str).str.zfill(5)
BIO = ["Climate", "Soil", "Topography"]
def share(sub):
    g = sub.groupby("group").abs_shap.mean(); return 1 - g[BIO].sum() / g.sum()
for c in ["SOY", "CORN", "HAY", "COTTON", "PEANUTS", "WHEAT", "SORGHUM"]:
    d = circdata.load(c); rng = np.random.default_rng(2026)
    tr = np.isin(d["geoid"], d["train_cty"]); rng.choice(np.where(tr)[0], min(50000, tr.sum()), replace=False)
    ug = np.unique(d["geoid"]); rows = rng.choice(len(ug), min(200, len(ug)), replace=False); samp = set(ug[rows])
    fc = f[f.crop == c]
    print(c, "all counties %.2f" % share(fc), "| counties with sample points %.2f" % share(fc[fc.GEOID.isin(set(ug))]),
          "| refit's 200 counties %.2f" % share(fc[fc.GEOID.isin(samp)]), flush=True)
