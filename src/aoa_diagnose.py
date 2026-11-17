"""Which predictors put baseline pixels outside the AOA? For a sample of flagged pixels, the weighted, scaled
gap to the nearest training point, by predictor group."""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
import sys, numpy as np, pandas as pd
import aoa, circdata
from rfpy import load_forest
from circ_run import GROUPS
from sklearn.neighbors import NearestNeighbors
for crop in sys.argv[1:]:
    F = load_forest(aoa.U + f"out/model2_R/rf/{crop}_RF_AG.RDS"); col = list(F["names"])
    d = circdata.load(crop); ci = [list(d["cols"]).index(n) for n in col]
    tr = np.where(np.isin(d["geoid"], d["train_cty"]))[0]; rng = np.random.default_rng(42)
    s = rng.choice(tr, min(aoa.NTRAIN, len(tr)), replace=False); T = d["X"][s][:, ci]
    shp = pd.read_csv(aoa.SH + f"{crop}_shap_vals.csv"); w = np.array([shp[n].abs().mean() if n in shp else 0 for n in col]); w /= w.max()
    mu, sd = T.mean(0), T.std(0); sd[sd == 0] = 1; z = lambda M: ((M - mu) / sd) * w
    Tz = z(T); nn = NearestNeighbors(n_neighbors=1, algorithm="brute").fit(Tz)
    a = np.load(f"{RES}/aoa/aoa_{crop}.npz"); sc = aoa.stacks(crop, col)
    for k in ("B", "N"):
        flag = np.where(a[k] > a["thr95"])[0]; flag = rng.choice(flag, min(3000, len(flag)), replace=False)
        Q = z(sc[k][flag]); j = nn.kneighbors(Q)[1][:, 0]; gap = (Q - Tz[j]) ** 2
        g = {grp: gap[:, [col.index(v) for v in vs if v in col]].sum(1).mean() for grp, vs in GROUPS.items()}
        tot = sum(g.values()); print(crop, k, {grp: round(100 * v / tot) for grp, v in g.items() if v / tot > 0.03}, flush=True)
