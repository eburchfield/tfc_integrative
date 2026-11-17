"""Summaries for national_abs.py, on the integrative paper's metrics (same as national_stats.py).

Made by Claude on 2026-10-19 for Emily Burchfield (P3, DISES integrative paper; manuscript not edited).
Likelihood-weighted area change (cos-latitude weight), % of the zone's baseline; zones on stored float32 B
(core > 0.3, margin 0.1-0.3); human / 20-yr climate = mean |PAN - N| / mean |N - B| on all valid pixels.
Usage: python national_abs_stats.py OUTDIR CROP [CROP ...] -> OUTDIR/national_abs_summary.csv, national_cap_check.csv
"""
import sys, json, numpy as np, pandas as pd
OUTD, crops = sys.argv[1], sys.argv[2:]
rows, caps = [], []
for c in crops:
    d = np.load(f"{OUTD}/national/{c}.npz", allow_pickle=True); a = np.load(f"{OUTD}/national_abs/{c}.npz", allow_pickle=True)
    H, W = d["shape"]; ok = d["ok"]; row = np.nonzero(ok)[0] // W
    w = np.cos(np.deg2rad(49.375 - (row + .5) / 24))
    Bz = d["B"]; B = Bz.astype(float); N = d["N"].astype(float)
    Z = {"all": np.ones(len(B), bool), "core": Bz > .3, "margin": (Bz > .1) & (Bz <= .3)}
    wa = lambda x, m: 100 * np.sum(w[m] * (x - N)[m]) / np.sum(w[m] * B[m])
    sc = {"PAN (relative, as published)": d["PAN"], "PAN without structure items": d["PAN_nostruct"],
          "PAN, structure items absolute": a["PAN_ABS"],
          "small farms only, relative": d["nat:small_farms"], "small farms only, absolute": a["nat:small_abs"],
          "large-farm sales only, relative": d["nat:large_farm_sales"], "large-farm sales only, absolute": a["nat:large_abs"]}
    clim = np.mean(np.abs(N - B))
    for k, X in sc.items():
        X = X.astype(float); r = dict(crop=c, scenario=k)
        for z, m in Z.items(): r[f"{z}_human_pct"] = wa(X, m)
        r["climate_all_pct"] = 100 * np.sum(w * (N - B)) / np.sum(w * B)
        r["ratio_human_to_climate20"] = np.mean(np.abs(X - N)) / clim
        rows.append(r)
    j = json.load(open(f"{OUTD}/national_abs/cap_{c}.json"))
    for v in ("no_ops_sales_lt_10k", "sales_usd_gt_500k"):
        caps.append(dict(crop=c, variable=v, in_model=j["in_model"][v], **j[v]))
    caps[-1]["N_reproduces_maxdiff"] = j["N_reproduces"]
R = pd.DataFrame(rows); C = pd.DataFrame(caps)
R.round(4).to_csv(f"{OUTD}/national_abs_summary.csv", index=False); C.round(4).to_csv(f"{OUTD}/national_cap_check.csv", index=False)
pd.set_option("display.width", 250); pd.set_option("display.max_columns", 40); pd.set_option("display.max_rows", 200)
print(R.round(2).to_string()); print(C.round(3).to_string())
