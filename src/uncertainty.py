"""Uncertainty ranges for the projections (reviewer M3), 2026-11-12.

Two sources, each propagated to the human/climate ratio, expected human change and net change:
  (1) Model: five FULL refits (SI Note 4 protocol: scikit-learn, LR's county split, 50,000-point training
      subsample, 100 trees), each with a different subsample draw and seed; each run on B, N and PAN.
  (2) Panel: the seed-1 FULL refit run on 26 stakeholder-informed stacks, one per national panelist, using that
      panelist's own Round 2 estimates (relative to the present value) for every converted item; a missing answer
      takes the panel median. Plus item-wise quartile stacks (every item at its Q1, and at its Q3).
Climate: three-model CMIP6 ensemble mean only (individual GCM stacks are not in the project files).
Outputs {OUT}/refits/unc_<CROP>.json.  Usage: python3 unc_run.py CROP [CROP ...]"""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
_os.makedirs(f"{OUT}/refits", exist_ok=True)
import sys, json, time, numpy as np, pandas as pd
import circdata
from refit_projections import stacks, stats, NSUB, NTREE, panel_pct, share_vars, pct
from sklearn.ensemble import RandomForestClassifier

F3 = f"{FIGDATA}/fig3_national_delphi_round2.csv"
ITEM2VARS = {"Farmland in crop insurance": ["crop_insurance_acre_rma"], "Cropland in CRP": ["CRP_ACRE"],
             "Corn used for ethanol": ["biofuel_corn_percent_used", "biofuel_soy_percent_used"],
             "N rate on corn": ["N_fert_kg", "Cao_fert_N"], "P rate on corn": ["P_fert_kg", "Cao_fert_P"],
             "Farm sales from livestock": ["animal_sales_usd"], "Farmland operated by small farms": ["no_ops_sales_lt_10k"],
             "Farm sales by large farms": ["sales_usd_gt_500k"], "Farmland operated by renters": ["rented_fract"],
             "Beginning farmers (share of operators)": ["producer_exp_lt_10"], "Socially disadvantaged operators": ["Producer_nonwhite"],
             "Hired farmworkers": ["labor_number"], "Per capita meat demand": ["live_cattle_inventory"]}
d3 = pd.read_csv(F3); d3["pct"] = 100 * (d3.estimate_2050 / d3.present_value - 1)
d3 = d3[d3.item.isin(ITEM2VARS)]
med = d3.groupby("item").apply(lambda g: 100 * (g.estimate_2050.median() / g.present_value.iloc[0] - 1))
def pctset(item_pct):
    out = dict(panel_pct)
    for it, vs in ITEM2VARS.items():
        for v in vs: out[v] = float(item_pct.get(it, med[it]))
    return out
SCEN = {}
for p, g in d3.groupby("panelist"): SCEN[f"P_{p}"] = pctset(dict(zip(g.item, g.pct)))
SCEN["Q1"] = pctset(d3.groupby("item").pct.quantile(0.25).to_dict())
SCEN["Q3"] = pctset(d3.groupby("item").pct.quantile(0.75).to_dict())
SCEN["MED"] = pctset({})   # should reproduce PAN

def run(crop):
    t0 = time.time(); dd = circdata.load(crop)
    Xt, y, cols, gid = dd["X"], dd["y"].astype(int), list(dd["cols"]), dd["geoid"]
    tr = np.isin(gid, dd["train_cty"]); te = ~tr
    sc, col, (H, W) = stacks(crop)
    idx = [col[c] for c in cols]
    ok = ~np.isnan(sc["_X"][:, idx]).any(1)
    for k in ("B", "N", "PAN"): ok &= ~np.isnan(sc[k][:, idx]).any(1)
    lat = 49.375 - (np.arange(H) + 0.5) / 24; w = np.repeat(np.cos(np.deg2rad(lat)), W)
    # recover 2009-18 human predictors from the N stack (same as PAN's base)
    X0 = sc["N"]
    res = {"crop": crop, "model": [], "panel": {}}
    keep = None
    for s in range(5):
        rng = np.random.default_rng(2026 + s)
        sub = rng.choice(np.where(tr)[0], min(NSUB, tr.sum()), replace=False)
        rf = RandomForestClassifier(n_estimators=NTREE, max_features="sqrt", min_samples_leaf=1, bootstrap=True,
                                    n_jobs=2, random_state=1 + s).fit(Xt[sub], y[sub])
        P = {k: rf.predict_proba(sc[k][ok][:, idx])[:, 1].astype(np.float64) for k in ("B", "N", "PAN")}
        full = lambda a: (lambda z: (z.__setitem__(ok, a), z)[1])(np.full(H * W, np.nan))
        r = stats(full(P["B"]), full(P["N"]), full(P["PAN"]), ok, w); r["seed"] = s
        res["model"].append(r)
        print(crop, "model seed", s, f"ratio {r['ratio_human_to_climate20']:.3f} hum {r['all_human']:+.2f} comb {r['all_combined']:+.2f}", f"{time.time()-t0:.0f}s", flush=True)
        if s == 0: keep = (rf, P)
        else: del rf
    rf, P0 = keep
    Bf = np.full(H * W, np.nan); Bf[ok] = P0["B"]; Nf = np.full(H * W, np.nan); Nf[ok] = P0["N"]
    for name, pp in SCEN.items():
        A = X0[ok].copy()
        for v, p in pp.items():
            if v in col: A[:, col[v]] = A[:, col[v]] * (1 + p / 100)
        for v in share_vars:
            if v in col: A[:, col[v]] = np.minimum(A[:, col[v]], 1.0)
        Pf = np.full(H * W, np.nan); Pf[ok] = rf.predict_proba(A[:, idx])[:, 1]
        res["panel"][name] = stats(Bf, Nf, Pf, ok, w)
    pr = [v["ratio_human_to_climate20"] for k, v in res["panel"].items() if k.startswith("P_")]
    print(crop, "panel ratio range", round(min(pr), 3), round(np.median(pr), 3), round(max(pr), 3),
          "MED", round(res["panel"]["MED"]["ratio_human_to_climate20"], 3), "Q1", round(res["panel"]["Q1"]["ratio_human_to_climate20"], 3),
          "Q3", round(res["panel"]["Q3"]["ratio_human_to_climate20"], 3), f"{time.time()-t0:.0f}s", flush=True)
    json.dump(res, open(f"{OUT}/refits/unc_{crop}.json", "w"), indent=1)

if __name__ == "__main__":
    for c in sys.argv[1:]: run(c)
