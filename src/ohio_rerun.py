"""Ohio projections with panel-relative inputs, for the Ohio roundtable deck (round 2).
Same construction as the fixed Georgia rerun (2026-10-28), on the Ohio window of LR's
national+OH predictor stacks (origin -84.8333, 41.9583; 1/24 deg; 104 x 85).
Base (2009-18) human predictors are recovered from the national-only stack (national % changes divided out).
Ohio pixels = pixels whose centre falls in an Ohio county polygon (GEOID 39xxx), not a probe of stack differences.
Scenarios (all with LR's fitted forests):
  B      2021-40 climate, base human predictors (today)
  N      2041-60 climate, base human predictors (weather only)
  PAN    2041-60 climate + national panel-relative changes, shares capped at 1
  PANOH  PAN + Ohio panel-relative changes in Ohio pixels (updated results)
  DOH    LR's national+OH stack as run (validation)
"""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
_os.makedirs(f"{OUT}/ohio", exist_ok=True)
import sys, json, numpy as np
from matplotlib.path import Path
import geo
from rfpy import load_forest, predict_prob, read_stack
from experiments import pct, panel_pct, share_vars, C30, n30, C50, n50
from state_rerun_pct import state_pct, st_shares

U = f"{FOREB}/"
H, W = 85, 104
R0, C0 = round((49.375 - 41.958333333) * 24), round((-84.833333333 + 106.6666667) * 24)
oh_pct = state_pct("OH")

# Ohio mask from county polygons
recs = geo.read_dbf(U + "data/county.dbf"); shp = geo.read_shp(U + "data/county.shp")
rr, cc = np.divmod(np.arange(H * W), W)
P = np.c_[-84.833333333 + (cc + 0.5) / 24, 41.958333333 - (rr + 0.5) / 24]
OH = np.zeros(H * W, bool); geoid = np.full(H * W, -1)
for r, parts in zip(recs, shp):
    g = str(r.get("GEOID", r.get("FIPS", "")))
    if not g.startswith("39"): continue
    m = np.zeros(H * W, bool)
    for pt in parts: m ^= Path(pt).contains_points(P)
    OH |= m; geoid[m] = int(g)
np.save(f"{OUT}/ohio/geoid_oh.npy", geoid)

def run(crop):
    fn = "CORN_RF_AG_slim.RDS" if crop == "CORN" else f"{crop}_RF_AG.RDS"
    F = load_forest(U + f"out/model2_R/rf/{fn}")
    Sn, names = read_stack(U + f"out/fpredictors/delphi_ras_national_only/ssp245_{crop}_2041_2060_delphi_national_AG.tif")
    So, no = read_stack(U + f"out/fpredictors/delphi_ras_national_and_ST/OH/ssp245_{crop}_2041_2060_delphi_NATIONAL_AND_OH_AG.tif")
    assert no == names and So.shape[:2] == (H, W)
    Xn = Sn[R0:R0 + H, C0:C0 + W].reshape(-1, Sn.shape[2]).astype(np.float64)
    Xo = So.reshape(-1, So.shape[2]).astype(np.float64)
    col = {n: i for i, n in enumerate(names)}
    dv = [v for v in pct.index if v in col]
    X0 = Xn.copy()
    for v in dv: X0[:, col[v]] = Xn[:, col[v]] / (1 + pct[v] / 100)
    def with_climate(A, C, cn):
        A = A.copy(); Cw = C[R0:R0 + H, C0:C0 + W].reshape(-1, C.shape[2])
        for j, v in enumerate(cn):
            if v in col: A[:, col[v]] = Cw[:, j]
        return A
    pan = X0.copy()
    for v in dv: pan[:, col[v]] = X0[:, col[v]] * (1 + panel_pct[v] / 100)
    for v in share_vars:
        if v in col: pan[:, col[v]] = np.minimum(pan[:, col[v]], 1.0)
    panoh = pan.copy(); used = []
    for v, p in oh_pct.items():
        if v in col:
            used.append(v)
            panoh[OH, col[v]] = X0[OH, col[v]] * (1 + p / 100)
            if v in st_shares: panoh[OH, col[v]] = np.minimum(panoh[OH, col[v]], 1.0)
    # sensitivity (SI Note 3, small present values): place-informed without Ohio's irrigation changes
    # (irrigated area and the groundwater and surface-water withdrawals derived from irrigation)
    panoh_noirr = panoh.copy()
    for v in ("IRRIG_MIRCA", "IRRIG_std", "KONAR_GWW", "KONAR_SWW"):
        if v in col: panoh_noirr[OH, col[v]] = pan[OH, col[v]]
    oor = {v: float(np.mean(panoh[OH, col[v]] > np.nanmax(X0[:, col[v]]) * 1.0000001)) for v in used}
    scen = {"B": with_climate(X0, C30, n30), "N": with_climate(X0, C50, n50), "PAN": pan, "PANOH": panoh, "PANOH_NOIRR": panoh_noirr, "DOH": Xo}
    idx = [col[n] for n in F["names"]]
    ok = np.ones(H * W, bool)
    for A in scen.values(): ok &= ~np.isnan(A[:, idx]).any(1)
    out = {"ok": ok, "oh": OH, "shape": np.array([H, W])}
    for k, A in scen.items():
        p = np.full(H * W, np.nan, np.float32); p[ok] = predict_prob(F, A[ok][:, idx]); out[k] = p
    np.savez_compressed(f"{OUT}/ohio/{crop}.npz", **out)
    m = ok & OH
    print(crop, "OH pixels", OH.sum(), "with predictions", m.sum(), "| mean B %.3f N %.3f PAN %.3f PANOH %.3f DOH %.3f" %
          tuple(np.nanmean(out[k][m]) for k in ("B", "N", "PAN", "PANOH", "DOH")), "| out of range:", {k: round(100 * x, 1) for k, x in oor.items() if x > 0}, flush=True)

if __name__ == "__main__":
    json.dump(oh_pct, open(f"{OUT}/ohio/oh_pct.json", "w"), indent=1)
    for c in sys.argv[1:]: run(c)
