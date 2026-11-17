"""Circularity test for the projections (reviewer M1), 2026-11-12.

For each crop, refit three random forests on LR's Model 2 modelling data with the SI Note 4 protocol
(scikit-learn matched to R randomForest defaults; same county split, same 50,000-point training subsample
drawn with default_rng(2026), 100 trees, seed 1):
  FULL    all 62 predictors
  EXCL12  minus the 12 predictors that partly track where the crop already is (SI Note 4)
  EXCL14  EXCL12 minus the two farm-structure predictors (no_ops_sales_lt_10k, sales_usd_gt_500k)
Each forest is then run on the same three predictor stacks used in the paper (SSP2-4.5):
  B    baseline       : human-controlled predictors 2009-18, climate 2021-40
  N    climate-only   : human-controlled predictors 2009-18, climate 2041-60
  PAN  stakeholder-informed: national panel-relative Delphi changes (shares capped at 1), climate 2041-60
Predictors a forest does not use are simply ignored, so EXCL12/EXCL14 projections carry only the Delphi
changes on predictors they keep. Outputs: {OUT}/refits/proj_<CROP>.npz and {OUT}/refits/proj_<CROP>.json.
Usage: python3 proj_refit.py CROP [CROP ...]"""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
_os.makedirs(f"{OUT}/refits", exist_ok=True)
import sys, json, time, numpy as np, pandas as pd
import circdata
from rfpy import read_stack
from sklearn.ensemble import RandomForestClassifier

U = f"{FOREB}/"
TRACK = ["Cao_fert_N","Cao_fert_P","N_fert_kg","P_fert_kg","fert_exp_usd","chem_exp_usd","crop_insurance_acre_rma",
         "mean_est_std","ag_land_value_usd","IRRIG_MIRCA","KONAR_GWW","KONAR_SWW"]
STRUCT = ["no_ops_sales_lt_10k", "sales_usd_gt_500k"]
NSUB, NTREE = 50000, 100

pct = pd.read_csv(U + "data/quantitative_data/data_input_RF_2/delphi_df_percent_change_only_national.csv").iloc[0]
pct = pct.drop(["GEOID", "ST"]).astype(float)
panel_pct = {
    "crop_insurance_acre_rma": 27.05, "CRP_ACRE": -12.50,
    "biofuel_corn_percent_used": -2.78, "biofuel_soy_percent_used": -2.78,
    "N_fert_kg": 9.33, "Cao_fert_N": 9.33, "P_fert_kg": 1.56, "Cao_fert_P": 1.56,
    "live_cattle_inventory": 100 * (206 / 225 - 1),   # 2026-11-13: panel-relative meat demand
    "animal_sales_usd": -2.48, "no_ops_sales_lt_10k": -28.57, "sales_usd_gt_500k": 13.92,
    "rented_fract": 7.69, "producer_exp_lt_10": 0.0, "Producer_nonwhite": 3.90, "labor_number": -10.78,
}
share_vars = ["crop_insurance_acre_rma", "CRP_ACRE", "biofuel_corn_percent_used", "biofuel_soy_percent_used",
              "animal_sales_usd", "no_ops_sales_lt_10k", "sales_usd_gt_500k", "rented_fract",
              "producer_exp_lt_10", "Producer_nonwhite"]
C30, n30 = read_stack(U + "out/fpredictors/ssp245_2021-2040.tif")
C50, n50 = read_stack(U + "out/fpredictors/ssp245_2041-2060.tif")

def stacks(crop):
    S, names = read_stack(U + f"out/fpredictors/delphi_ras_national_only/ssp245_{crop}_2041_2060_delphi_national_AG.tif")
    H, W, _ = S.shape
    X = S.reshape(-1, S.shape[2]).astype(np.float64); col = {n: i for i, n in enumerate(names)}
    dv = [v for v in pct.index if v in col]
    X0 = X.copy()
    for v in dv: X0[:, col[v]] = X[:, col[v]] / (1 + pct[v] / 100)
    def with_climate(A, C, cn):
        A = A.copy(); Cf = C.reshape(-1, C.shape[2])
        for j, v in enumerate(cn):
            if v in col: A[:, col[v]] = Cf[:, j]
        return A
    pan = X0.copy()
    for v in dv: pan[:, col[v]] = X0[:, col[v]] * (1 + panel_pct[v] / 100)
    for v in share_vars:
        if v in col: pan[:, col[v]] = np.minimum(pan[:, col[v]], 1.0)
    return {"B": with_climate(X0, C30, n30), "N": with_climate(X0, C50, n50), "PAN": pan, "_X": X}, col, (H, W)

def stats(B, N, P, ok, w):
    zones = {"all": ok, "core": ok & (B > 0.3), "margin": ok & (B > 0.1) & (B <= 0.3)}
    r = {}
    for name, dlt in (("climate", N - B), ("human", P - N), ("combined", P - B)):
        r[f"meanabs_{name}"] = float(np.mean(np.abs(dlt[ok])))
        for z, zm in zones.items():
            r[f"{z}_{name}"] = float(100 * np.sum(w[zm] * dlt[zm]) / np.sum(w[zm] * B[zm]))
    r["ratio_human_to_climate20"] = r["meanabs_human"] / r["meanabs_climate"]
    return r

def run(crop):
    t0 = time.time(); d = circdata.load(crop); rng = np.random.default_rng(2026)
    Xt, y, cols, gid = d["X"], d["y"].astype(int), list(d["cols"]), d["geoid"]
    tr = np.isin(gid, d["train_cty"]); te = ~tr
    sub = rng.choice(np.where(tr)[0], min(NSUB, tr.sum()), replace=False)
    sets = {"FULL": cols, "EXCL12": [c for c in cols if c not in TRACK],
            "EXCL14": [c for c in cols if c not in TRACK + STRUCT]}
    scen, col, (H, W) = stacks(crop)
    idx_all = [col[c] for c in cols]
    ok = ~np.isnan(scen["_X"][:, idx_all]).any(1)
    for k in ("B", "N", "PAN"): ok &= ~np.isnan(scen[k][:, idx_all]).any(1)
    lat = 49.375 - (np.arange(H) + 0.5) / 24; w = np.repeat(np.cos(np.deg2rad(lat)), W)
    out = {"ok": ok, "shape": np.array([H, W])}; res = {"crop": crop, "pixels": int(ok.sum()), "models": {}}
    for name, keep in sets.items():
        j = [cols.index(c) for c in keep]
        rf = RandomForestClassifier(n_estimators=NTREE, max_features="sqrt", min_samples_leaf=1, bootstrap=True,
                                    n_jobs=2, random_state=1).fit(Xt[sub][:, j], y[sub])
        acc = float(((rf.predict_proba(Xt[te][:, j])[:, 1] > 0.5).astype(int) == y[te]).mean())
        jj = [col[c] for c in keep]; preds = {}
        for k in ("B", "N", "PAN"):
            p = np.full(H * W, np.nan, np.float32)
            p[ok] = rf.predict_proba(scen[k][ok][:, jj])[:, 1]
            preds[k] = p; out[f"{name}_{k}"] = p
        r = stats(preds["B"].astype(np.float64), preds["N"].astype(np.float64), preds["PAN"].astype(np.float64), ok, w)
        r["accuracy"] = acc; r["n_predictors"] = len(keep)
        res["models"][name] = r
        print(crop, name, f"acc {acc:.4f}", f"ratio {r['ratio_human_to_climate20']:.3f}",
              f"clim {r['all_climate']:+.2f} hum {r['all_human']:+.2f} comb {r['all_combined']:+.2f}",
              f"margin_hum {r['margin_human']:+.2f}", f"{time.time()-t0:.0f}s", flush=True)
        del rf
    np.savez_compressed(f"{OUT}/refits/proj_{crop}.npz", **out)
    json.dump(res, open(f"{OUT}/refits/proj_{crop}.json", "w"), indent=1)

if __name__ == "__main__":
    for c in sys.argv[1:]: run(c)
