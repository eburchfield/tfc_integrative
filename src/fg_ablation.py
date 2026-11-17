"""What did the focus-group variables change in the model? Ablation within the revised model (Model 2).
FG_ADDED   = crop price, agricultural land value, crop-specific irrigated fraction (added after round one)
FG_REFINED = number of laborers, crop-specific processing, conservation tillage (refined after round one)
Refit (scikit-learn, as circ_run.py: 50,000-point subsample of training counties, 100 trees) as
FULL, NO_ADDED, NO_REFINED, NO_FG (both removed); report held-out accuracy/AUC, SHAP share of the FG variables,
and how the maps and the R3 headline change: baseline likelihood (FULL vs NO_FG) and climate, human and
combined change in likelihood-weighted area under each model. Output RES/fg/fg_<CROP>.json"""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
import sys, json, time, numpy as np
import circdata, circ_run as C, aoa
FG_ADDED = ["PRICE", "ag_land_value_usd", "IRRIG_MIRCA"]
FG_REFINED = ["labor_number", "mean_est_std", "till_new_conservational_acre"]

def run(crop):
    t0 = time.time(); d = circdata.load(crop); rng = np.random.default_rng(2026)
    X, y, cols, gid = d["X"], d["y"].astype(int), list(d["cols"]), d["geoid"]
    tr = np.isin(gid, d["train_cty"]); te = ~tr
    sub = rng.choice(np.where(tr)[0], min(C.NSUB, tr.sum()), replace=False)
    ug, inv = np.unique(gid, return_inverse=True)
    cm = np.zeros((len(ug), X.shape[1])); np.add.at(cm, inv, X); cm /= np.bincount(inv)[:, None]
    rows = rng.choice(len(ug), min(C.NSHAP, len(ug)), replace=False)
    sets = {"FULL": cols, "NO_ADDED": [c for c in cols if c not in FG_ADDED],
            "NO_REFINED": [c for c in cols if c not in FG_REFINED], "NO_FG": [c for c in cols if c not in FG_ADDED + FG_REFINED]}
    o = np.load(f"{OUT}/projections/{crop}.npz"); ok = o["ok"]; H, W = o["shape"]
    lat = 49.375 - (np.arange(H) + .5) / 24; w = np.repeat(np.cos(np.deg2rad(lat)), W)
    sc = aoa.stacks(crop, cols)
    res = {"crop": crop, "models": {}}; P = {}
    for name, keep in sets.items():
        j = [cols.index(c) for c in keep]
        rf = C.fit(X[sub][:, j], y[sub], 1)
        r = C.evaluate(rf, X[te][:, j], y[te])
        if name == "FULL":
            phi, _ = C.forest_shap(rf, cm[rows][:, j]); imp = np.abs(phi).mean(0); tot = imp.sum()
            r["shap_share_added"] = float(sum(imp[keep.index(v)] for v in FG_ADDED) / tot)
            r["shap_share_refined"] = float(sum(imp[keep.index(v)] for v in FG_REFINED) / tot)
            r.update({f"share_{k}": v for k, v in C.shares(rf, cm[rows][:, j], keep).items()})
        pr = {}
        for k in ("B", "N", "PAN"):
            M = sc[k][:, j]; good = ok & ~np.isnan(M).any(1)
            p = np.full(len(ok), np.nan); p[good] = rf.predict_proba(M[good])[:, 1]; pr[k] = p
        m = ok & np.isfinite(pr["B"]) & np.isfinite(pr["N"]) & np.isfinite(pr["PAN"])
        wa = lambda a, b: 100 * np.sum(w[m] * (a - b)[m]) / np.sum(w[m] * pr["B"][m])
        r.update(climate=wa(pr["N"], pr["B"]), human=wa(pr["PAN"], pr["N"]), combined=wa(pr["PAN"], pr["B"]),
                 human_over_climate=float(np.mean(np.abs((pr["PAN"] - pr["N"])[m])) / np.mean(np.abs((pr["N"] - pr["B"])[m]))))
        P[name] = pr; res["models"][name] = r
        print(crop, name, {k: round(v, 3) for k, v in r.items() if isinstance(v, float) and not k.startswith("share_")}, f"{time.time()-t0:.0f}s", flush=True)
    # how adding the FG variables changed the baseline map
    m = ok & np.isfinite(P["FULL"]["B"]) & np.isfinite(P["NO_FG"]["B"]); dB = (P["FULL"]["B"] - P["NO_FG"]["B"])[m]
    res["baseline_map_change"] = dict(mean_abs=float(np.mean(np.abs(dB))), share_over_0p1=float(np.mean(np.abs(dB) > 0.1)),
                                      corr=float(np.corrcoef(P["FULL"]["B"][m], P["NO_FG"]["B"][m])[0, 1]))
    np.savez_compressed(f"{RES}/fg/fg_maps_{crop}.npz", full_B=P["FULL"]["B"].astype(np.float32), nofg_B=P["NO_FG"]["B"].astype(np.float32))
    json.dump(res, open(f"{RES}/fg/fg_{crop}.json", "w"), indent=1)
    print(crop, "baseline map change", res["baseline_map_change"], flush=True)

if __name__ == "__main__":
    for c in sys.argv[1:]: run(c)
