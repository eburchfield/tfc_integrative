"""One-at-a-time attribution of a state increment: add each state variable alone to the stakeholder-informed
stack in the state's pixels and record the change in likelihood-weighted area (% of baseline).
Usage: python3 state_drivers.py NE CORN SOY"""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
import sys, numpy as np
import state_rerun as S
from rfpy import load_forest, predict_prob, read_stack
st = sys.argv[1]
for crop in sys.argv[2:]:
    F = load_forest(S.U + f"out/model2_R/rf/{crop}_RF_AG.RDS")
    A0, names = read_stack(S.U + f"out/fpredictors/delphi_ras_national_only/ssp245_{crop}_2041_2060_delphi_national_AG.tif")
    X = A0.reshape(-1, A0.shape[2]).astype(np.float64); col = {n: i for i, n in enumerate(names)}
    dv = [v for v in S.pct.index if v in col]; X0 = X.copy()
    for v in dv: X0[:, col[v]] = X[:, col[v]] / (1 + S.pct[v] / 100)
    pan = X0.copy()
    for v in dv: pan[:, col[v]] = X0[:, col[v]] * (1 + S.panel_pct[v] / 100)
    for v in S.share_vars:
        if v in col: pan[:, col[v]] = np.minimum(pan[:, col[v]], 1.0)
    m = (S.cid >= 0) & (S.stfp[np.maximum(S.cid, 0)] == S.FIPS[st])
    d = np.load(f"{OUT}/projections/{crop}.npz"); B = d["B"][m]; ok = d["ok"][m]
    H, W = d["shape"]; w = np.repeat(np.cos(np.deg2rad(49.375 - (np.arange(H) + .5) / 24)), W)[m]
    idx = [col[n] for n in F["names"]]; base = pan[m]
    pr = lambda A: predict_prob(F, A[ok][:, idx])
    p0 = pr(base); den = np.sum(w[ok] * B[ok])
    sp = S.state_pct(st); out = []
    for v, p in sp.items():
        if v not in col or v not in F["names"]: continue
        A = base.copy(); A[:, col[v]] = X0[m, col[v]] * (1 + p / 100)
        if v in S.st_shares: A[:, col[v]] = np.minimum(A[:, col[v]], 1.0)
        out.append((v, p, 100 * np.sum(w[ok] * (pr(A) - p0)) / den))
    for v, p, e in sorted(out, key=lambda t: t[2]): print(st, crop, f"{v:32s} input {p:+7.1f}%  area effect {e:+.2f}%", flush=True)
