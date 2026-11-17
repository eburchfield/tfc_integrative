"""Attribution checks (reviewer M4, M9), 2026-11-12.
(1) Published Model 2 forests: held-out accuracy, sensitivity, specificity and AUC computed from LR's saved
    point probabilities (PROB in <CROP>_pt_AG.RDS) on the test counties; AUC from probabilities (rank-based)
    and the thresholded version (sensitivity + specificity) / 2, to see which SI Table 2 reports.
(2) Drop-group refits (SI Note 4 protocol, same sample and seed): biophysical-only (climate, soil, topography)
    and human-only models, held-out accuracy and AUC, against the full refit.
Output {OUT}/refits/attr_<CROP>.json"""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
_os.makedirs(f"{OUT}/refits", exist_ok=True)
import sys, json, numpy as np
import circdata
from refit_projections import NSUB, NTREE
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import roc_auc_score
BIO = ["BV1_Annual_Mean_Temp","BV2_Mean_Diurnal_Range","BV4_Temp_Seasonality","BV5_MaxTemp_Warm_Month","BV6_MinTemp_Cold_Month",
       "BV8_MeanTemp_Wet_Quart","BV9_MeanTemp_Driest_Quart","BV10_MeanTemp_Warm_Quart","BV11_MeanTemp_Cold_Quart","BV12_Annual_Precip",
       "BV13_Precip_Wet_Month","BV14_Precip_Dry_Month","B15_CoV_Precip","B16_Precip_Wet_Quart","B17_Precip_Dry_Quart",
       "B18_Precip_Warm_Quart","B19_Precip_Cold_Quart","T_BULK_DEN","T_CEC_CLAY","T_CLAY","T_GRAVEL","T_SAND","T_SILT","NA_1KM_SLOPE","NA_1KM"]
CLIM = BIO[:17]

def metrics(p, y):
    c = (p > 0.5).astype(int); tp = ((c == 1) & (y == 1)).sum(); tn = ((c == 0) & (y == 0)).sum()
    sens = tp / (y == 1).sum(); spec = tn / (y == 0).sum()
    return dict(accuracy=float((c == y).mean()), sensitivity=float(sens), specificity=float(spec),
                auc_prob=float(roc_auc_score(y, p)), auc_thresholded=float((sens + spec) / 2))

def run(crop):
    d = circdata.load(crop); rng = np.random.default_rng(2026)
    X, y, cols, gid = d["X"], d["y"].astype(int), list(d["cols"]), d["geoid"]
    tr = np.isin(gid, d["train_cty"]); te = ~tr
    res = {"crop": crop, "n_test": int(te.sum()), "published": metrics(d["prob_lr"][te], y[te])}
    sub = rng.choice(np.where(tr)[0], min(NSUB, tr.sum()), replace=False)
    sets = {"FULL": cols, "BIO": [c for c in cols if c in BIO], "CLIMATE": [c for c in cols if c in CLIM],
            "HUMAN": [c for c in cols if c not in BIO]}
    for name, keep in sets.items():
        j = [cols.index(c) for c in keep]
        rf = RandomForestClassifier(n_estimators=NTREE, max_features="sqrt", min_samples_leaf=1, bootstrap=True,
                                    n_jobs=2, random_state=1).fit(X[sub][:, j], y[sub])
        r = metrics(rf.predict_proba(X[te][:, j])[:, 1], y[te]); r["n_predictors"] = len(keep)
        res[name] = r
    print(crop, {k: (round(v["accuracy"], 3), round(v["auc_prob"], 3)) for k, v in res.items() if isinstance(v, dict)},
          "published thr-AUC", round(res["published"]["auc_thresholded"], 3), flush=True)
    json.dump(res, open(f"{OUT}/refits/attr_{crop}.json", "w"), indent=1)

if __name__ == "__main__":
    for c in sys.argv[1:]: run(c)
