"""Reproduces the small SI numbers that no other script prints (final check, 16 Nov 2026).
  - SI Note 1: largest insured share under the absolute-target conversion (2.26)
  - SI Note 3 / SI Note 7: share of valid pixels where the cap at 1 binds under the relative conversion
    (crop insurance 13.6%, large-farm share of sales 15.4%)
  - SI Note 3: Ohio crop-specific irrigated share (corn model), 2009-2018 mean -> relative (x7.14, capped) and
    absolute-target stack (2.6% -> 18.2%; x10 and 26%)
  - SI Table 2: held-out performance of the seven main-crop forests, read from LR's <CROP>_ETC_AG.RDS.
    R's SENSITIVITY and SPECIFICITY are swapped relative to presence = positive (LR, Nov 2026), so they are
    reported swapped here, as in SI Table 2. Balanced accuracy = mean of the two. The six SI crops have no
    ETC file in the inputs; their rows come from LR.
Writes RES/traced_numbers.csv."""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, OUT, RES
import glob, numpy as np, pandas as pd
from experiments import pct, panel_pct
from rfpy import read_stack
from rds import read_rds
from state_rerun_pct import state_pct
rows = []
add = lambda item, value, note="": rows.append(dict(item=item, value=value, note=note))
S, names = read_stack(f"{FOREB}/out/fpredictors/delphi_ras_national_only/ssp245_CORN_2041_2060_delphi_national_AG.tif")
X = S.reshape(-1, S.shape[2]).astype(float); col = {n: i for i, n in enumerate(names)}
ok = np.load(f"{OUT}/projections/CORN.npz")["ok"]
for v in ["crop_insurance_acre_rma", "sales_usd_gt_500k"]:
    x0 = X[ok, col[v]] / (1 + pct[v] / 100)
    add(f"cap binds, relative, {v}", float(np.mean(x0 * (1 + panel_pct[v] / 100) >= 1)), "share of valid pixels")
    add(f"max under absolute target, {v}", float(np.max(x0 * (1 + pct[v] / 100))))
H, W = 85, 104; R0, C0 = round((49.375 - 41.958333333) * 24), round((-84.833333333 + 106.6666667) * 24)
OH = np.load(f"{OUT}/ohio/geoid_oh.npy") > 0
Xw = S[R0:R0 + H, C0:C0 + W].reshape(-1, S.shape[2]).astype(float)
x0 = Xw[OH, col["IRRIG_std"]]; x0 = x0[~np.isnan(x0)]
add("Ohio IRRIG_std mean, 2009-2018", float(x0.mean()))
add("Ohio IRRIG_std mean, relative (capped at 1)", float(np.minimum(x0 * (1 + state_pct("OH")["IRRIG_std"] / 100), 1).mean()))
A, an = read_stack(glob.glob(f"{FOREB}/out/fpredictors/delphi_ras_national_and_ST/OH/*CORN*")[0])
xa = A.reshape(-1, A.shape[2])[OH, {n: i for i, n in enumerate(an)}["IRRIG_std"]].astype(float)
add("Ohio IRRIG_std mean, absolute-target stack", float(np.nanmean(xa)))
for c in ["CORN", "SOY", "WHEAT", "SORGHUM", "COTTON", "HAY", "PEANUTS"]:
    o = read_rds(f"{FOREB}/out/model2_R/rf/{c}_ETC_AG.RDS"); p = o.value[list(o.attrs["names"]).index("PERF")]
    m = {n: float(x.value[0]) if hasattr(x, "value") else float(x[0]) for n, x in zip(p.attrs["names"], p.value)}
    add(f"SI Table 2 {c} accuracy", m["PCC"]); add(f"SI Table 2 {c} specificity (R SENSITIVITY)", m["SENSITIVITY"])
    add(f"SI Table 2 {c} sensitivity (R SPECIFICITY)", m["SPECIFICITY"]); add(f"SI Table 2 {c} kappa", m["KAPPA"])
    add(f"SI Table 2 {c} balanced accuracy", (m["SENSITIVITY"] + m["SPECIFICITY"]) / 2)
df = pd.DataFrame(rows); df.to_csv(f"{RES}/traced_numbers.csv", index=False); print(df.round(4).to_string())
