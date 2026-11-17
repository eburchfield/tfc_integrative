"""Place-informed projections for Nebraska and Ohio with panel-relative inputs (Supplementary Information).

Same construction as georgia_place_informed.py, on the national grid: the stakeholder-informed stack (PAN, national
panel-relative changes) plus each state panel's Round 2 relative changes (median 2050 / present value - 1)
in that state's pixels. Nine Delphi items enter ten model variables (cropland irrigated feeds both
irrigation variables). Withdrawals = irrigation water applied x source share. Shares capped at 1.
State pixels come from the county raster ({OUT}/county_raster.npy, county.shp order).
Writes {OUT}/states/<CROP>_<ST>.npz with PANST and the state mask."""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
import sys, json, numpy as np, pandas as pd
import geo
from rfpy import load_forest, predict_prob, read_stack
from experiments import pct, panel_pct, share_vars

U = f"{FOREB}/"
FIPS = {"NE": "31", "OH": "39", "GA": "13"}
# Round 2 state panel medians (data/delphi/state_round2_medians.csv); panelist-level responses are not shared (IRB).
g = pd.read_csv(_os.path.join(_os.path.dirname(SRC), "data", "delphi", "state_round2_medians.csv")).rename(
    columns={"present_value": "p", "median_2050": "m"})
g["p"] = pd.to_numeric(g["p"], errors="coerce"); g["m"] = pd.to_numeric(g["m"], errors="coerce")
def ratio(st, item):
    r = g[(g.state == st) & (g.item.str.startswith(item))]
    assert len(r) == 1, (st, item); return float(r.m.iloc[0] / r.p.iloc[0])
def state_pct(st):
    w = ratio(st, "Irrigation water applied")
    gw0 = float(g[(g.state == st) & (g.item == "Withdrawals from groundwater")].p.iloc[0]) / 100
    gw1 = float(g[(g.state == st) & (g.item == "Withdrawals from groundwater")].m.iloc[0]) / 100
    rate = "N rate (cotton)" if st == "GA" else "N rate (corn)"
    return {"IRRIG_MIRCA": 100 * (ratio(st, "Cropland irrigated") - 1), "IRRIG_std": 100 * (ratio(st, "Cropland irrigated") - 1),
            "KONAR_GWW": 100 * (w * gw1 / gw0 - 1), "KONAR_SWW": 100 * (w * (1 - gw1) / (1 - gw0) - 1),
            "till_new_conservational_acre": 100 * (ratio(st, "Conservation tillage") - 1),
            "cover_crop_acre": 100 * (ratio(st, "Cover crops") - 1),
            "Cao_fert_N": 100 * (ratio(st, rate) - 1), "Cao_fert_P": 100 * (ratio(st, rate.replace("N rate", "P rate")) - 1),
            "N_manure_kg": 100 * (ratio(st, "N from manure") - 1), "P_manure_kg": 100 * (ratio(st, "P from manure") - 1)}
st_shares = ["IRRIG_MIRCA", "IRRIG_std", "till_new_conservational_acre", "cover_crop_acre"]

cid = np.load(f"{OUT}/county_raster.npy").ravel()
recs = geo.read_dbf(U + "data/county.dbf")
stfp = np.array([r.get("STATEFP", r.get("STATE_FIPS", "")) for r in recs])

def run(crop, states):
    F = load_forest(U + f"out/model2_R/rf/{crop}_RF_AG.RDS")
    S, names = read_stack(U + f"out/fpredictors/delphi_ras_national_only/ssp245_{crop}_2041_2060_delphi_national_AG.tif")
    X = S.reshape(-1, S.shape[2]).astype(np.float64); col = {n: i for i, n in enumerate(names)}
    dv = [v for v in pct.index if v in col]
    X0 = X.copy()
    for v in dv: X0[:, col[v]] = X[:, col[v]] / (1 + pct[v] / 100)
    pan = X0.copy()
    for v in dv: pan[:, col[v]] = X0[:, col[v]] * (1 + panel_pct[v] / 100)
    for v in share_vars:
        if v in col: pan[:, col[v]] = np.minimum(pan[:, col[v]], 1.0)
    idx = [col[n] for n in F["names"]]
    for st in states:
        sp = state_pct(st)
        m = (cid >= 0) & (stfp[np.maximum(cid, 0)] == FIPS[st])
        A = pan[m].copy(); used = []
        for v, p in sp.items():
            if v in col:
                A[:, col[v]] = X0[m, col[v]] * (1 + p / 100); used.append(v)
                if v in st_shares: A[:, col[v]] = np.minimum(A[:, col[v]], 1.0)
        ok = ~np.isnan(A[:, idx]).any(1)
        p = np.full(m.sum(), np.nan, np.float32); p[ok] = predict_prob(F, A[ok][:, idx])
        oor = np.zeros(m.sum(), bool)
        for v in used: oor |= A[:, col[v]] > np.nanmax(X0[:, col[v]]) * 1.0000001
        np.savez_compressed(f"{OUT}/states/{crop}_{st}.npz", PANST=p, mask=m, oor=oor, used=np.array(used))
        print(crop, st, "pixels", m.sum(), "vars", len(used), "out-of-range", round(100 * oor.mean(), 2), flush=True)

if __name__ == "__main__":
    json.dump({s: state_pct(s) for s in ("GA", "NE", "OH")}, open(f"{RES}/state_pct.json", "w"), indent=1)
    states = sys.argv[1].split(","); [run(c, states) for c in sys.argv[2:]]
