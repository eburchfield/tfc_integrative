"""Place-informed projections with the refit forests (reviewer M6), 2026-11-12.
For each crop: the FULL, EXCL12 and EXCL14 refits of proj_refit.py (same samples and seeds) are run on
B, N, PAN (national panel-relative) and, in each state's pixels, PAN with that state's panel-relative changes
replacing the national value for the same variable (state_rerun.py rule). Reports, within each state,
change in likelihood-weighted area (% of baseline) for climate (N-B), national (PAN-N), state increment
(PANST-PAN) and the place-informed total (PANST-B). Output {OUT}/refits/state_<CROP>.json"""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
_os.makedirs(f"{OUT}/refits", exist_ok=True)
import sys, json, time, numpy as np, pandas as pd
import circdata
from refit_projections import stacks, NSUB, NTREE, TRACK, STRUCT
from sklearn.ensemble import RandomForestClassifier

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
FIPS = {"NE": "31", "OH": "39", "GA": "13"}
from statesgrid import state_grid
stgrid = state_grid()

def lwa(dlt, B, w, m): return float(100 * np.sum(w[m] * dlt[m]) / np.sum(w[m] * B[m]))

def run(crop):
    t0 = time.time(); dd = circdata.load(crop); rng = np.random.default_rng(2026)
    Xt, y, cols, gid = dd["X"], dd["y"].astype(int), list(dd["cols"]), dd["geoid"]
    tr = np.isin(gid, dd["train_cty"])
    sub = rng.choice(np.where(tr)[0], min(NSUB, tr.sum()), replace=False)
    sets = {"FULL": cols, "EXCL12": [c for c in cols if c not in TRACK], "EXCL14": [c for c in cols if c not in TRACK + STRUCT]}
    sc, col, (H, W) = stacks(crop)
    idx = [col[c] for c in cols]
    ok = ~np.isnan(sc["_X"][:, idx]).any(1)
    for k in ("B", "N", "PAN"): ok &= ~np.isnan(sc[k][:, idx]).any(1)
    lat = 49.375 - (np.arange(H) + 0.5) / 24; w = np.repeat(np.cos(np.deg2rad(lat)), W)
    X0 = sc["N"]
    res = {"crop": crop, "states": {}}
    for name, keep in sets.items():
        rf = RandomForestClassifier(n_estimators=NTREE, max_features="sqrt", min_samples_leaf=1, bootstrap=True,
                                    n_jobs=2, random_state=1).fit(Xt[sub][:, [cols.index(c) for c in keep]], y[sub])
        jj = [col[c] for c in keep]
        for st, fp in FIPS.items():
            m = ok & (stgrid == fp)
            if m.sum() < 100: continue
            P = {k: rf.predict_proba(sc[k][m][:, jj])[:, 1].astype(np.float64) for k in ("B", "N", "PAN")}
            A = sc["PAN"][m].copy()
            for v, p in state_pct(st).items():
                if v in col:
                    A[:, col[v]] = X0[m, col[v]] * (1 + p / 100)
                    if v in st_shares: A[:, col[v]] = np.minimum(A[:, col[v]], 1.0)
            PS = rf.predict_proba(A[:, jj])[:, 1].astype(np.float64)
            wm = w[m]; B = P["B"]; one = np.ones(m.sum(), bool)
            f = lambda dlt: float(100 * np.sum(wm * dlt) / np.sum(wm * B))
            r = {"pixels": int(m.sum()), "climate": f(P["N"] - B), "national": f(P["PAN"] - P["N"]),
                 "state_increment": f(PS - P["PAN"]), "place_informed_total": f(PS - B), "stakeholder_total": f(P["PAN"] - B)}
            r["increment_to_national"] = r["state_increment"] / r["national"] if r["national"] else float("nan")
            res["states"].setdefault(st, {})[name] = r
            print(crop, name, st, {k: round(v, 2) for k, v in r.items() if k != "pixels"}, f"{time.time()-t0:.0f}s", flush=True)
        del rf
    json.dump(res, open(f"{OUT}/refits/state_{crop}.json", "w"), indent=1)

if __name__ == "__main__":
    for c in sys.argv[1:]: run(c)
