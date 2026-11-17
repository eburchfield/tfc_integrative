"""SI Note 4 refit, extended (Step 0 of the 2026-10-19 integrative revision plan).

Made by Claude on 2026-10-19 for Emily Burchfield (P3, DISES integrative paper; manuscript not edited).
Adapted from DISES_integrative/figs/analysis/circularity/circ_run.py (Protocol B). Same data, county split,
forest settings (scikit-learn matched to R randomForest defaults; 50,000-point training subsample; 100 trees),
SHAP setup (exact TreeSHAP on county-mean predictors, 200 random counties; 100 for state folds) and seeds,
so FULL and EXCL12 reproduce the SI Note 4 table. Adds:
  EXCL14    EXCL12 minus the two farm-structure predictors the national Delphi moves most
            (no_ops_sales_lt_10k, sales_usd_gt_500k)
  EXCL15    EXCL14 minus crop price (PRICE), a state average that acts as a state label in Georgia
  R14_k     control: drop 14 randomly chosen other human-controlled predictors (k = 1..3; separate seed)
  spatial   5 groups of states, leave one out, for FULL, EXCL12 and EXCL14 (same folds as SI Note 4)
Usage: python3 circ_run_v2.py CROP [CROP ...]  -> out/res2_<CROP>.json
"""
import os, sys, json, time, numpy as np
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import circdata
from tshap import forest_shap
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import roc_auc_score, cohen_kappa_score

GROUPS = {
 "Climate": ["BV1_Annual_Mean_Temp","BV2_Mean_Diurnal_Range","BV4_Temp_Seasonality","BV5_MaxTemp_Warm_Month","BV6_MinTemp_Cold_Month",
             "BV8_MeanTemp_Wet_Quart","BV9_MeanTemp_Driest_Quart","BV10_MeanTemp_Warm_Quart","BV11_MeanTemp_Cold_Quart","BV12_Annual_Precip",
             "BV13_Precip_Wet_Month","BV14_Precip_Dry_Month","B15_CoV_Precip","B16_Precip_Wet_Quart","B17_Precip_Dry_Quart",
             "B18_Precip_Warm_Quart","B19_Precip_Cold_Quart"],
 "Soil": ["T_BULK_DEN","T_CEC_CLAY","T_CLAY","T_GRAVEL","T_SAND","T_SILT"],
 "Topography": ["NA_1KM_SLOPE","NA_1KM"],
 "Irrigation": ["IRRIG_std","KONAR_GWW","KONAR_SWW","IRRIG_MIRCA"],
 "Management": ["cover_crop_acre","till_new_conservational_acre","tile_drain_acres","CRP_ACRE","EQIP_ACRE","live_cattle_inventory","organic_number_operations"],
 "Inputs": ["fert_exp_usd","chem_exp_usd","N_manure_kg","P_manure_kg","N_fert_kg","P_fert_kg","labor_number","machinery_usd","Cao_fert_N","Cao_fert_P"],
 "Economics": ["animal_sales_usd","rented_fract","no_ops_sales_lt_10k","directsales_retail","sales_usd_gt_500k","ag_land_value_usd","PRICE","crop_insurance_acre_rma"],
 "Demographics": ["RUCC_2013","Producer_female","Producer_nonwhite","median_farmsize","Producer_age_le_35","producer_exp_lt_10"],
 "Infrastructure": ["mean_est_std","biofuel_corn_percent_used","biofuel_soy_percent_used"]}
BIO = ["Climate", "Soil", "Topography"]
TRACK12 = ["Cao_fert_N","Cao_fert_P","N_fert_kg","P_fert_kg","fert_exp_usd","chem_exp_usd","crop_insurance_acre_rma",
           "mean_est_std","ag_land_value_usd","IRRIG_MIRCA","KONAR_GWW","KONAR_SWW"]
STRUCT = ["no_ops_sales_lt_10k", "sales_usd_gt_500k"]
TRACK14 = TRACK12 + STRUCT
TRACK15 = TRACK14 + ["PRICE"]
NSUB, NTREE, NSHAP, NSHAP_FOLD = 50000, 100, 200, 100
OUTD = os.path.join(HERE, "out")

def fit(X, y, seed):
    return RandomForestClassifier(n_estimators=NTREE, max_features="sqrt", min_samples_leaf=1, bootstrap=True,
                                  n_jobs=2, random_state=seed).fit(X, y)

def evaluate(rf, X, y):
    p = rf.predict_proba(X)[:, 1]; c = (p > 0.5).astype(int)
    return dict(accuracy=float((c == y).mean()), auc=float(roc_auc_score(y, p)), kappa=float(cohen_kappa_score(y, c)))

_RF = None
def _shap_part(Xp): return forest_shap(_RF, Xp)[0]
def shares(rf, Xc, cols):
    global _RF; _RF = rf
    import multiprocessing as mp
    with mp.get_context("fork").Pool(2) as pool: phi = np.vstack(pool.map(_shap_part, np.array_split(Xc, 2)))
    imp = np.abs(phi).mean(0)
    g = {k: float(sum(imp[cols.index(v)] for v in vs if v in cols)) for k, vs in GROUPS.items()}
    tot = sum(g.values()); g = {k: v / tot for k, v in g.items()}
    g["human_share"] = 1 - sum(g[b] for b in BIO)
    for nm, T in (("tracking_share", TRACK12), ("tracking14_share", TRACK14), ("tracking15_share", TRACK15)):
        g[nm] = float(sum(imp[cols.index(v)] for v in T if v in cols) / imp.sum())
    for v in STRUCT + ["PRICE"]:
        g[f"imp_{v}"] = float(imp[cols.index(v)] / imp.sum()) if v in cols else 0.0
    return g

def run(crop):
    t0 = time.time(); d = circdata.load(crop); rng = np.random.default_rng(2026)
    X, y, cols, gid = d["X"], d["y"].astype(int), list(d["cols"]), d["geoid"]
    tr = np.isin(gid, d["train_cty"]); te = ~tr
    sub = rng.choice(np.where(tr)[0], min(NSUB, tr.sum()), replace=False)
    ug, inv = np.unique(gid, return_inverse=True)
    cm = np.zeros((len(ug), X.shape[1])); np.add.at(cm, inv, X); cm /= np.bincount(inv)[:, None]
    shp_rows = rng.choice(len(ug), min(NSHAP, len(ug)), replace=False)
    human = [v for k, vs in GROUPS.items() if k not in BIO for v in vs if v in cols]
    others12 = [v for v in human if v not in TRACK12]
    for k in range(3):  # original RAND draws, kept only so the rng state (and state folds) match SI Note 4
        rng.choice(others12, len([v for v in TRACK12 if v in cols]), replace=False)
    sets = {"FULL": cols, "EXCL12": [c for c in cols if c not in TRACK12],
            "EXCL14": [c for c in cols if c not in TRACK14], "EXCL15": [c for c in cols if c not in TRACK15]}
    rng2 = np.random.default_rng(2027); others14 = [v for v in human if v not in TRACK15]
    n14 = len([v for v in TRACK14 if v in cols])
    for k in range(3):
        drop = set(rng2.choice(others14, n14, replace=False))
        sets[f"R14_{k+1}"] = [c for c in cols if c not in drop]
    res = {"crop": crop, "n_points": int(len(y)), "n_train_counties": int(len(np.unique(gid[tr]))),
           "price_in_model": "PRICE" in cols, "models": {}}
    for name, keep in sets.items():
        j = [cols.index(c) for c in keep]
        rf = fit(X[sub][:, j], y[sub], 1)
        r = evaluate(rf, X[te][:, j], y[te]); r.update(shares(rf, cm[shp_rows][:, j], keep)); r["n_predictors"] = len(keep)
        if name.startswith("R14"): r["dropped"] = sorted(set(cols) - set(keep))
        res["models"][name] = r
        print(crop, name, {k: round(v, 3) for k, v in r.items() if isinstance(v, float) and not k.startswith("imp_")}, f"{time.time()-t0:.0f}s", flush=True)
    st = np.array([g[:2] for g in gid]); us = np.unique(st); rng.shuffle(us); grp = {s: i % 5 for i, s in enumerate(us)}
    fold = np.array([grp[s] for s in st]); res["spatial"] = {"FULL": [], "EXCL12": [], "EXCL14": []}
    for f in range(5):
        trf = np.where(fold != f)[0]; tef = fold == f
        if tef.sum() < 1000 or len(np.unique(y[tef])) < 2: continue
        sf = rng.choice(trf, min(NSUB, len(trf)), replace=False)
        for name in ("FULL", "EXCL12", "EXCL14"):
            j = [cols.index(c) for c in sets[name]]
            rf = fit(X[sf][:, j], y[sf], 1)
            r = evaluate(rf, X[tef][:, j], y[tef]); r.update(shares(rf, cm[shp_rows[:NSHAP_FOLD]][:, j], sets[name]))
            r["states"] = sorted(s for s in us if grp[s] == f); res["spatial"][name].append(r)
        print(crop, "fold", f, [round(res["spatial"][n][-1]["accuracy"], 3) for n in ("FULL", "EXCL12", "EXCL14")], f"{time.time()-t0:.0f}s", flush=True)
    json.dump(res, open(os.path.join(OUTD, f"res2_{crop}.json"), "w"), indent=1)

if __name__ == "__main__":
    for c in sys.argv[1:]: run(c)
