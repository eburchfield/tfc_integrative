"""Summarize circ_run_v2.py results -> out/circularity_v2_summary.csv (one row per crop) and a printed table.

Made by Claude on 2026-10-19 for Emily Burchfield (P3, DISES integrative paper; manuscript not edited).
Columns: accuracy and human-controlled SHAP share for FULL, EXCL12 (SI Note 4 as published), EXCL14 (+ two
farm-structure predictors), EXCL15 (+ crop price) and the 14-predictor random-drop control (min-max of 3);
importance of the structure predictors and price in FULL; state-fold results for FULL, EXCL12, EXCL14.
Decision rule (SI Note 4): corn and soybeans keep at least a third of importance in human-controlled predictors
after exclusion, and held-out accuracy stays within 0.05 of FULL.
"""
import os, json, glob, numpy as np, pandas as pd
HERE = os.path.dirname(os.path.abspath(__file__)); OUTD = os.path.join(HERE, "out")
rows = []
for f in sorted(glob.glob(os.path.join(OUTD, "res2_*.json"))):
    r = json.load(open(f)); m = r["models"]; F = m["FULL"]
    R = [m[k] for k in m if k.startswith("R14")]
    sp = r["spatial"]
    row = dict(crop=r["crop"])
    for k in ("FULL", "EXCL12", "EXCL14", "EXCL15"):
        row[f"acc_{k}"] = m[k]["accuracy"]; row[f"human_{k}"] = m[k]["human_share"]; row[f"climate_{k}"] = m[k]["Climate"]
    row.update(acc_R14_mean=np.mean([x["accuracy"] for x in R]),
               human_R14_min=min(x["human_share"] for x in R), human_R14_max=max(x["human_share"] for x in R),
               track12_in_FULL=F["tracking_share"], track14_in_FULL=F["tracking14_share"], track15_in_FULL=F["tracking15_share"],
               imp_small_farms=F["imp_no_ops_sales_lt_10k"], imp_large_farm_sales=F["imp_sales_usd_gt_500k"], imp_price=F["imp_PRICE"])
    row["acc_drop_EXCL14"] = row["acc_FULL"] - row["acc_EXCL14"]; row["acc_drop_EXCL15"] = row["acc_FULL"] - row["acc_EXCL15"]
    row["human_retained_EXCL14"] = row["human_EXCL14"] / row["human_FULL"]
    row["human_retained_EXCL15"] = row["human_EXCL15"] / row["human_FULL"]
    for k in ("FULL", "EXCL12", "EXCL14"):
        row[f"sp_acc_{k}"] = np.mean([x["accuracy"] for x in sp[k]])
        row[f"sp_acc_{k}_min"] = min(x["accuracy"] for x in sp[k])
        row[f"sp_human_{k}_min"] = min(x["human_share"] for x in sp[k]); row[f"sp_human_{k}_max"] = max(x["human_share"] for x in sp[k])
    for k in ("EXCL14", "EXCL15"):
        for g in ("Management", "Inputs", "Economics", "Demographics", "Irrigation", "Infrastructure"):
            row[f"{g}_{k}"] = m[k][g]
    rows.append(row)
df = pd.DataFrame(rows)
order = ["SOY", "CORN", "HAY", "COTTON", "PEANUTS", "WHEAT", "SORGHUM"]
df["o"] = df.crop.map({c: i for i, c in enumerate(order)}); df = df.sort_values("o").drop(columns="o")
df.round(4).to_csv(os.path.join(OUTD, "circularity_v2_summary.csv"), index=False)
pd.set_option("display.width", 250); pd.set_option("display.max_columns", 80)
print(df.round(3).T.to_string())
