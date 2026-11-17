"""Protocol A: multivariate area of applicability (Meyer & Pebesma 2021), per crop and scenario.
Training data: LR's Model 2 points in training counties (circdata), 100,000-point subsample.
Predictors scaled by training mean/SD and weighted by mean |SHAP| (LR's county SHAP, out/model2_R/SHAP),
scaled so the largest weight is 1. DI = distance to nearest training point / mean distance between training points.
Threshold: 95th percentile of training DI, computed against training points in other folds (5 folds of counties);
CAST's default (upper boxplot whisker of training DI) reported as a sensitivity.
Scenarios: B baseline, N climate-only, PAN stakeholder-informed, PLACE (PAN + GA/NE/OH state inputs in each state),
ABS absolute-target Delphi, TREND linear trend.  Output: {RES}/aoa/aoa_<CROP>.npz and aoa_<CROP>.json"""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
import sys, json, numpy as np, pandas as pd
import circdata, state_rerun as S
from rfpy import load_forest, read_stack
from experiments import pct, panel_pct, share_vars, C30, n30, C50, n50
from sklearn.neighbors import NearestNeighbors
U = f"{FOREB}/"
SH = f"{FOREB}/out/model2_R/SHAP/"
NTRAIN = 100000

def stacks(crop, col):
    A, names = read_stack(U + f"out/fpredictors/delphi_ras_national_only/ssp245_{crop}_2041_2060_delphi_national_AG.tif")
    X = A.reshape(-1, A.shape[2]).astype(np.float64); c = {n: i for i, n in enumerate(names)}
    dv = [v for v in pct.index if v in c]; X0 = X.copy()
    for v in dv: X0[:, c[v]] = X[:, c[v]] / (1 + pct[v] / 100)
    def clim(M, C, cn):
        M = M.copy(); Cf = C.reshape(-1, C.shape[2])
        for j, v in enumerate(cn):
            if v in c: M[:, c[v]] = Cf[:, j]
        return M
    def scaled(f):
        M = X0.copy()
        for v in dv: M[:, c[v]] = X0[:, c[v]] * f(v)
        for v in share_vars:
            if v in c: M[:, c[v]] = np.minimum(M[:, c[v]], 1.0)
        return M
    tp = json.load(open(f"{RES}/trend_pct.json"))
    pan = scaled(lambda v: 1 + panel_pct[v] / 100)
    place = pan.copy()
    for st in ("GA", "NE", "OH"):
        m = (S.cid >= 0) & (S.stfp[np.maximum(S.cid, 0)] == S.FIPS[st])
        for v, p in S.state_pct(st).items():
            if v in c:
                place[m, c[v]] = X0[m, c[v]] * (1 + p / 100)
                if v in S.st_shares: place[m, c[v]] = np.minimum(place[m, c[v]], 1.0)
    sc = {"B": clim(X0, C30, n30), "N": clim(X0, C50, n50), "PAN": pan, "PLACE": place, "ABS": X,
          "TREND": scaled(lambda v: max(1 + tp.get(v, 0.0) / 100, 0.0))}
    idx = [c[n] for n in col]
    return {k: v[:, idx] for k, v in sc.items()}

def run(crop):
    F = load_forest(U + f"out/model2_R/rf/{crop}_RF_AG.RDS"); col = list(F["names"])
    d = circdata.load(crop); ci = [list(d["cols"]).index(n) for n in col]
    tr = np.where(np.isin(d["geoid"], d["train_cty"]))[0]
    rng = np.random.default_rng(42); s = rng.choice(tr, min(NTRAIN, len(tr)), replace=False)
    T = d["X"][s][:, ci]; g = d["geoid"][s]
    shp = pd.read_csv(SH + f"{crop}_shap_vals.csv")
    w = np.array([shp[n].abs().mean() if n in shp else 0.0 for n in col]); w = w / w.max()
    mu, sd = T.mean(0), T.std(0); sd[sd == 0] = 1
    z = lambda M: (((M - mu) / sd) * w).astype(np.float32)
    Tz = z(T)
    i1, i2 = rng.integers(0, len(Tz), 200000), rng.integers(0, len(Tz), 200000)
    dbar = float(np.mean(np.linalg.norm(Tz[i1] - Tz[i2], axis=1)))
    # training DI against other folds (5 folds of counties)
    ug = np.unique(g); fold_of = dict(zip(ug, rng.integers(0, 5, len(ug)))); fold = np.array([fold_of[x] for x in g])
    tdi = np.zeros(len(Tz))
    for f in range(5):
        nn = NearestNeighbors(n_neighbors=1, algorithm="brute", n_jobs=2).fit(Tz[fold != f])
        tdi[fold == f] = nn.kneighbors(Tz[fold == f])[0][:, 0] / dbar
    thr95 = float(np.percentile(tdi, 95)); q1, q3 = np.percentile(tdi, [25, 75]); thr_cast = float(tdi[tdi <= q3 + 1.5 * (q3 - q1)].max())
    nn = NearestNeighbors(n_neighbors=1, algorithm="brute", n_jobs=2).fit(Tz)
    o = np.load(f"{OUT}/projections/{crop}.npz"); ok = o["ok"]
    sc = stacks(crop, col); DI = {}
    for k, M in sc.items():
        di = np.full(len(ok), np.nan, np.float32); good = ok & ~np.isnan(M).any(1)
        rows = np.where(good)[0]
        for a in range(0, len(rows), 20000):
            r = rows[a:a + 20000]; di[r] = nn.kneighbors(z(M[r]))[0][:, 0] / dbar
        DI[k] = di; print(crop, k, "outside AOA %.2f%%" % (100 * np.nanmean(di > thr95)), flush=True)
    np.savez_compressed(f"{RES}/aoa/aoa_{crop}.npz", thr95=thr95, thr_cast=thr_cast, dbar=dbar, w=w, **DI)
    json.dump(dict(crop=crop, thr95=thr95, thr_cast=thr_cast, dbar=dbar, weights=dict(zip(col, map(float, w)))),
              open(f"{RES}/aoa/aoa_{crop}.json", "w"), indent=1)

if __name__ == "__main__":
    for c in sys.argv[1:]: run(c)
