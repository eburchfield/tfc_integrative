"""Exact TreeSHAP on LR's own R randomForest (as treeshap::unify + treeshap do): node covers from the
training points (training counties), leaf value = 1 if the leaf predicts presence (class '1'), averaged
over trees; explained rows = LR's county aggregates (out/county_agg_mod2_mirca/<CROP>_AGG.RDS, NA -> 0).
Usage: python3 lrshap.py CROP NCOUNTIES -> {RES}/circularity/lrshap_<CROP>.csv (GEOID x predictor SHAP)"""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
import sys, ctypes, numpy as np, pandas as pd, multiprocessing as mp
from rds import read_rds
from rfpy import load_forest
import circdata
from tshap import _lib
U = f"{FOREB}/"

def covers(F, X):
    nt, nr = F["status"].shape; C = np.zeros((nt, nr))
    for t in range(nt):
        node = np.zeros(len(X), np.int64); active = np.ones(len(X), bool)
        while active.any():
            idx = np.where(active)[0]; nd = node[idx]
            np.add.at(C[t], nd, 1)
            term = F["status"][t, nd] == -1
            idx2 = idx[~term]; nd2 = nd[~term]
            go_left = X[idx2, F["var"][t, nd2]] <= F["split"][t, nd2]
            node[idx2] = np.where(go_left, F["left"][t, nd2], F["right"][t, nd2])
            active[idx[term]] = False
    return C

def depth(F, t):
    d = np.zeros(F["status"].shape[1], int); best = 0; stack = [(0, 0)]
    while stack:
        n, k = stack.pop(); best = max(best, k)
        if F["status"][t, n] != -1: stack += [(F["left"][t, n], k + 1), (F["right"][t, n], k + 1)]
    return best

G = {}
def shap_rows(Xr):
    F, C, D = G["F"], G["C"], G["D"]; nt = F["status"].shape[0]; n, p = Xr.shape
    phi = np.zeros((n, p)); Xr = np.ascontiguousarray(Xr, np.float64)
    for t in range(nt):
        val = (F["pred"][t] == 2).astype(np.float64)
        _lib.tree_shap(int(D[t]), np.ascontiguousarray(F["left"][t], np.int32), np.ascontiguousarray(F["right"][t], np.int32),
                       np.ascontiguousarray(np.maximum(F["var"][t], 0), np.int32), np.ascontiguousarray(F["split"][t], np.float64),
                       val, np.ascontiguousarray(C[t]), Xr, n, p, phi, 1.0 / nt)
    return phi

if __name__ == "__main__":
    crop, ncty = sys.argv[1], int(sys.argv[2])
    F = load_forest(U + f"out/model2_R/rf/{crop}_RF_AG.RDS"); names = list(F["names"])
    d = circdata.load(crop); col = [list(d["cols"]).index(n) for n in names]
    Xtr = d["X"][np.isin(d["geoid"], d["train_cty"])][:, col]
    C = covers(F, Xtr); D = [depth(F, t) for t in range(F["status"].shape[0])]
    o = read_rds(U + f"out/county_agg_mod2_mirca/{crop}_AGG.RDS")
    gid = np.asarray(o["GEOID"].value).astype(str)
    Xc = np.column_stack([np.nan_to_num(np.asarray(getattr(o[n], "value", o[n]), dtype=np.float64)) for n in names])
    rows = np.random.default_rng(7).choice(len(gid), ncty, replace=False)
    G.update(F=F, C=C, D=D)
    with mp.get_context("fork").Pool(2) as pool: phi = np.vstack(pool.map(shap_rows, np.array_split(Xc[rows], 2)))
    out = pd.DataFrame(phi, columns=names); out.insert(0, "GEOID", gid[rows]); out.to_csv(f"{RES}/circularity/lrshap_{crop}.csv", index=False)
    print(crop, "done", phi.shape, flush=True)
