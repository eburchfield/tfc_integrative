"""Partial bridge (2026-11-10). Same construction as oh_rerun.py / experiments.py, plus:
  BR   = PAN with national bridge factors (2022 / 2009-18 baseline, same source) multiplied in
         for the national items whose RF predictor has 2022 values in LR's file
  BROH = PANOH with the same national factors, plus Ohio factors for the Ohio state items with 2022 values
Items without 2022 values in the model's own source keep factor 1 (= panel-relative)."""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
_os.makedirs(f"{OUT}/bridge", exist_ok=True)
import sys, json, numpy as np
from matplotlib.path import Path
import geo
from rfpy import load_forest, predict_prob, read_stack
from experiments import pct, panel_pct, share_vars, C30, n30, C50, n50
from state_rerun_pct import state_pct, st_shares
U = f"{FOREB}/"
F = json.load(open(f"{RES}/bridge_factors.json"))
NAT_BR = ["CRP_ACRE", "live_cattle_inventory", "no_ops_sales_lt_10k", "sales_usd_gt_500k", "rented_fract", "Producer_nonwhite", "labor_number"]
OH_BR = ["cover_crop_acre", "till_new_conservational_acre"]
oh_pct = state_pct("OH")
H, W = 85, 104
R0, C0 = round((49.375 - 41.958333333) * 24), round((-84.833333333 + 106.6666667) * 24)
geoid = np.load(f"{OUT}/ohio/geoid_oh.npy"); OH = geoid > 0

def run(crop):
    fn = "CORN_RF_AG_slim.RDS" if crop == "CORN" else f"{crop}_RF_AG.RDS"
    Fo = load_forest(U + f"out/model2_R/rf/{fn}")
    Sn, names = read_stack(U + f"out/fpredictors/delphi_ras_national_only/ssp245_{crop}_2041_2060_delphi_national_AG.tif")
    col = {n: i for i, n in enumerate(names)}; idx = [col[n] for n in Fo["names"]]
    HN, WN = Sn.shape[:2]
    Xd = Sn.reshape(-1, Sn.shape[2]).astype(np.float64)
    dv = [v for v in pct.index if v in col]
    X0 = Xd.copy()
    for v in dv: X0[:, col[v]] = Xd[:, col[v]] / (1 + pct[v] / 100)
    def clim(A, C, cn, win=None):
        A = A.copy(); Cw = C if win is None else C[R0:R0 + H, C0:C0 + W]; Cw = Cw.reshape(-1, C.shape[2])
        for j, v in enumerate(cn):
            if v in col: A[:, col[v]] = Cw[:, j]
        return A
    def pan_of(A0, bridge):
        A = A0.copy()
        for v in dv:
            f = F["national"][v] if (bridge and v in NAT_BR) else 1.0
            A[:, col[v]] = A0[:, col[v]] * f * (1 + panel_pct[v] / 100)
        for v in share_vars:
            if v in col: A[:, col[v]] = np.minimum(A[:, col[v]], 1.0)
        return A
    res = {}
    # national
    scen = {"B": clim(X0, C30, n30), "N": clim(X0, C50, n50), "PAN": pan_of(X0, False), "BR": pan_of(X0, True), "D": Xd}
    ok = np.ones(HN * WN, bool)
    for A in scen.values(): ok &= ~np.isnan(A[:, idx]).any(1)
    nat = {"ok": ok, "shape": np.array([HN, WN])}
    for k, A in scen.items():
        p = np.full(HN * WN, np.nan, np.float32); p[ok] = predict_prob(Fo, A[ok][:, idx]); nat[k] = p
    np.savez_compressed(f"{OUT}/bridge/nat_{crop}.npz", **nat)
    # Ohio window (national stack window; state items added in Ohio pixels)
    win = lambda A: A.reshape(HN, WN, -1)[R0:R0 + H, C0:C0 + W].reshape(H * W, -1)
    X0w = win(X0)
    def oh_of(bridge):
        A = pan_of(X0w, bridge)
        for v, p in oh_pct.items():
            if v not in col: continue
            f = F["OH"][v] if (bridge and v in OH_BR) else 1.0
            A[OH, col[v]] = X0w[OH, col[v]] * f * (1 + p / 100)
            if v in st_shares: A[OH, col[v]] = np.minimum(A[OH, col[v]], 1.0)
        return A
    so = {"B": clim(X0w, C30, n30, True), "PANOH": oh_of(False), "BROH": oh_of(True)}
    okw = OH.copy()
    for A in so.values(): okw &= ~np.isnan(A[:, idx]).any(1)
    oh = {"ok": okw}
    for k, A in so.items():
        p = np.full(H * W, np.nan, np.float32); p[okw] = predict_prob(Fo, A[okw][:, idx]); oh[k] = p
    np.savez_compressed(f"{OUT}/bridge/oh_{crop}.npz", **oh)
    print(crop, "done", flush=True)

if __name__ == "__main__":
    for c in sys.argv[1:]: run(c)
