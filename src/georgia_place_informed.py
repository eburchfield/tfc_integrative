"""Georgia place-informed projection (Fig. 6). Georgia pixels come from the county raster (STATEFP 13; 8,465 pixels).
Scenarios (2041-60 climate unless noted): B (2021-40 climate, 2009-18 human), N climate-only,
PAN stakeholder-informed (national panel-relative), PANGA place-informed (PAN + Georgia changes in GA pixels).
Writes OUT/georgia/<CROP>.npz (Georgia window) and RES/georgia_place_informed_stats.csv."""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, OUT, RES
import sys, json, numpy as np, pandas as pd
from rfpy import load_forest, predict_prob, read_stack
from experiments import pct, panel_pct, share_vars, C30, n30, C50, n50
U = f"{FOREB}/"
GOUT = f"{OUT}/georgia"; _os.makedirs(GOUT, exist_ok=True)
irr_applied = 1798 / 1299; gw_share = 85 / 83; sw_share = 15 / 17
ga_pct = {"IRRIG_MIRCA": 27.17, "IRRIG_std": 27.17,
          "KONAR_GWW": 100 * (irr_applied * gw_share - 1), "KONAR_SWW": 100 * (irr_applied * sw_share - 1),
          "till_new_conservational_acre": 11.44, "cover_crop_acre": 83.49,
          "Cao_fert_N": -0.83, "Cao_fert_P": 1.69, "N_manure_kg": 2.94, "P_manure_kg": -1.64}
ga_shares = ["IRRIG_MIRCA", "IRRIG_std", "till_new_conservational_acre", "cover_crop_acre"]
from statesgrid import state_grid
st = state_grid()

def run(crop):
    F = load_forest(U + f"out/model2_R/rf/{crop}_RF_AG.RDS")
    S, names = read_stack(U + f"out/fpredictors/delphi_ras_national_only/ssp245_{crop}_2041_2060_delphi_national_AG.tif")
    H, W, _ = S.shape
    ga_full = (st == "13").reshape(H, W)
    rr, cc = np.where(ga_full); r0, r1, c0, c1 = rr.min(), rr.max() + 1, cc.min(), cc.max() + 1
    win = lambda A: A[r0:r1, c0:c1].reshape(-1, A.shape[2]).astype(np.float64)
    Xn = win(S); ga = ga_full[r0:r1, c0:c1].ravel()
    col = {n: i for i, n in enumerate(names)}
    dv = [v for v in pct.index if v in col]
    X0 = Xn.copy()
    for v in dv: X0[:, col[v]] = Xn[:, col[v]] / (1 + pct[v] / 100)
    def with_climate(A, C, cn):
        A = A.copy(); Cw = win(C)
        for j, v in enumerate(cn):
            if v in col: A[:, col[v]] = Cw[:, j]
        return A
    pan = X0.copy()
    for v in dv: pan[:, col[v]] = X0[:, col[v]] * (1 + panel_pct[v] / 100)
    for v in share_vars:
        if v in col: pan[:, col[v]] = np.minimum(pan[:, col[v]], 1.0)
    panga = pan.copy()
    for v, p in ga_pct.items():
        if v in col:
            panga[ga, col[v]] = X0[ga, col[v]] * (1 + p / 100)
            if v in ga_shares: panga[ga, col[v]] = np.minimum(panga[ga, col[v]], 1.0)
    scen = {"B": with_climate(X0, C30, n30), "N": with_climate(X0, C50, n50), "PAN": pan, "PANGA": panga}
    idx = [col[n] for n in F["names"]]
    ok = ga.copy()
    for A in scen.values(): ok &= ~np.isnan(A[:, idx]).any(1)
    out = {"ok": ok, "ga": ga, "shape": np.array([r1 - r0, c1 - c0]), "origin": np.array([49.375 - r0 / 24, -106.6666667 + c0 / 24])}
    for k, A in scen.items():
        p = np.full(len(ga), np.nan, np.float32); p[ok] = predict_prob(F, A[ok][:, idx]); out[k] = p
    np.savez_compressed(f"{GOUT}/{crop}.npz", **out)
    h, w = out["shape"]
    lat = out["origin"][0] - (np.arange(h) + .5) / 24; wt = np.repeat(np.cos(np.deg2rad(lat)), w)
    B, N, P, G = (out[k] for k in ("B", "N", "PAN", "PANGA"))
    r = dict(crop=crop, ga_pixels=int(ga.sum()), ok_pixels=int(ok.sum()), ga_meanabs=np.mean(np.abs(G - P)[ok]),
             nat_meanabs=np.mean(np.abs(P - N)[ok]))
    r["ratio"] = r["ga_meanabs"] / r["nat_meanabs"]; r["ga_meansigned"] = np.mean((G - P)[ok])
    for z, m in {"all": ok, "core": ok & (B > .3), "margin": ok & (B > .1) & (B <= .3)}.items():
        den = np.sum(wt[m] * B[m])
        for k, X in (("clim", N), ("stake", P), ("place", G)):
            r[f"{z}_{k}"] = 100 * np.sum(wt[m] * (X - B)[m]) / den if den > 0 else np.nan
    print({k: (round(v, 4) if isinstance(v, float) else v) for k, v in r.items()}, flush=True)
    return r

if __name__ == "__main__":
    rows = [run(c) for c in ["SOY", "CORN", "HAY", "COTTON", "PEANUTS", "WHEAT", "SORGHUM"]]
    pd.DataFrame(rows).round(4).to_csv(f"{RES}/georgia_place_informed_stats.csv", index=False)
