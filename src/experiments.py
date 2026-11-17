"""Scenario experiments with the Model 2 forests (SSP2-4.5).

Scenarios (all predicted with LR's fitted forests, reproduced in Python):
  B    baseline      : human predictors 2009-18, climate 2021-40
  N    naive         : human predictors 2009-18, climate 2041-60
  D    Delphi as run : national Delphi % changes (CSV used by LR), climate 2041-60
  D30  Delphi, 2030 climate : as D but climate 2021-40   (factorial cell)
  REV  reversed sign : human predictors x (1 - pct), climate 2041-60
  TINY tiny shift    : human predictors x (1 + pct/10), climate 2041-60
  PAN  panel-relative: % change = panel median 2050 vs panel's own present value,
                       shares capped at 1, climate 2041-60
Writes {OUT}/projections/<CROP>.npz
"""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
import sys, os, numpy as np, pandas as pd
from rfpy import load_forest, predict_prob, read_stack, read_tif

U = f"{FOREB}/"
pct = pd.read_csv(U + "data/quantitative_data/data_input_RF_2/delphi_df_percent_change_only_national.csv").iloc[0]
pct = pct.drop(["GEOID", "ST"]).astype(float)

# Panel-relative % change: Round 2 national panel median 2050 vs the panel's present value.
panel_pct = {
    "crop_insurance_acre_rma": 27.05, "CRP_ACRE": -12.50,
    "biofuel_corn_percent_used": -2.78, "biofuel_soy_percent_used": -2.78,
    "N_fert_kg": 9.33, "Cao_fert_N": 9.33, "P_fert_kg": 1.56, "Cao_fert_P": 1.56,
    "live_cattle_inventory": None,   # set below from per capita meat demand
    "animal_sales_usd": -2.48, "no_ops_sales_lt_10k": -28.57, "sales_usd_gt_500k": 13.92,
    "rented_fract": 7.69, "producer_exp_lt_10": 0.0, "Producer_nonwhite": 3.90, "labor_number": -10.78,
}
# 2026-11-13: cattle inventory converted the same way as every other item (meat demand: 2050 median 206 / present value 225 - 1).
# Set CATTLE_PCT to override (e.g. the original run's value) for validation.
panel_pct["live_cattle_inventory"] = float(os.environ.get("CATTLE_PCT", 100 * (206 / 225 - 1)))
share_vars = ["crop_insurance_acre_rma", "CRP_ACRE", "biofuel_corn_percent_used", "biofuel_soy_percent_used",
              "animal_sales_usd", "no_ops_sales_lt_10k", "sales_usd_gt_500k", "rented_fract",
              "producer_exp_lt_10", "Producer_nonwhite"]

C30, n30 = read_stack(U + "out/fpredictors/ssp245_2021-2040.tif")
C50, n50 = read_stack(U + "out/fpredictors/ssp245_2041-2060.tif")

def run(crop):
    F = load_forest(U + f"out/model2_R/rf/{crop}_RF_AG.RDS")
    S, names = read_stack(U + f"out/fpredictors/delphi_ras_national_only/ssp245_{crop}_2041_2060_delphi_national_AG.tif")
    H, W, _ = S.shape
    X = S.reshape(-1, S.shape[2]).astype(np.float64)
    col = {n: i for i, n in enumerate(names)}
    dv = [v for v in pct.index if v in col]
    # recover 2009-18 human predictors
    X0 = X.copy()
    for v in dv: X0[:, col[v]] = X[:, col[v]] / (1 + pct[v] / 100)
    def with_climate(A, C, cn):
        A = A.copy()
        Cf = C.reshape(-1, C.shape[2])
        for j, v in enumerate(cn):
            if v in col: A[:, col[v]] = Cf[:, j]
        return A
    def scaled(fac):
        A = X0.copy()
        for v in dv: A[:, col[v]] = X0[:, col[v]] * fac(v)
        return A
    # check that the stack's climate equals 2041-60
    cl = [v for v in n50 if v in col]
    dclim = np.nanmax(np.abs(X[:, col[cl[0]]] - C50.reshape(-1, C50.shape[2])[:, n50.index(cl[0])]))
    pan = scaled(lambda v: 1 + panel_pct[v] / 100)
    for v in share_vars:
        if v in col: pan[:, col[v]] = np.minimum(pan[:, col[v]], 1.0)
    ins = X.copy()
    if "crop_insurance_acre_rma" in col:
        j = col["crop_insurance_acre_rma"]; ins[:, j] = np.minimum(X0[:, j] * (1 + panel_pct["crop_insurance_acre_rma"] / 100), 1.0)
    only = os.environ.get("ONLY")
    import json
    tp = json.load(open(f"{RES}/trend_pct.json"))
    trend = scaled(lambda v: max(1 + tp.get(v, 0.0) / 100, 0.0))
    for v in share_vars:
        if v in col: trend[:, col[v]] = np.minimum(trend[:, col[v]], 1.0)
    # 2026-11-13: build scenarios lazily (memory)
    def _pan(): return pan
    def _prev():
        A = scaled(lambda v: 1 - panel_pct[v] / 100)
        for v in share_vars:
            if v in col: A[:, col[v]] = np.clip(A[:, col[v]], 0.0, 1.0)
        return A
    def _ptiny():
        A = scaled(lambda v: 1 + panel_pct[v] / 1000)
        for v in share_vars:
            if v in col: A[:, col[v]] = np.clip(A[:, col[v]], 0.0, 1.0)
        return A
    builders = {
        "INS": lambda: ins, "TREND": lambda: trend,
        "B": lambda: with_climate(X0, C30, n30), "N": lambda: with_climate(X0, C50, n50), "D": lambda: X,
        "D30": lambda: with_climate(X, C30, n30),
        "REV": lambda: scaled(lambda v: 1 - pct[v] / 100), "TINY": lambda: scaled(lambda v: 1 + pct[v] / 1000),
        "PAN": _pan, "PAN30": lambda: with_climate(pan, C30, n30), "PREV": _prev, "PTINY": _ptiny,
    }
    if only:
        builders = {k: v for k, v in builders.items() if k in only.split(",") + ["B", "N"]}
    idx = [col[n] for n in F["names"]]
    ok = ~np.isnan(X[:, idx]).any(1)  # same mask as main runs
    for k, f in builders.items():
        A = f(); ok &= ~np.isnan(A[:, idx]).any(1); del A
    out = {"ok": ok, "shape": np.array([H, W]), "dclim": dclim}
    for k, f in builders.items():
        A = f()
        p = np.full(H * W, np.nan, np.float32)
        p[ok] = predict_prob(F, A[ok][:, idx])
        out[k] = p; del A
        print(crop, k, flush=True)
    # out-of-range share: Delphi pixels beyond training max for any shifted variable
    oor = np.zeros(H * W, bool)
    for v in dv:
        mx = np.nanmax(X0[:, col[v]]); oor |= X[:, col[v]] > mx * 1.0000001
    out["oor"] = oor
    oorp = np.zeros(H * W, bool)
    for v in dv:
        mx = np.nanmax(X0[:, col[v]]); oorp |= pan[:, col[v]] > mx * 1.0000001
    out["oor_pan"] = oorp
    os.makedirs(f"{OUT}/projections", exist_ok=True); os.makedirs(f"{OUT}/projections_extra", exist_ok=True)
    if only:
        np.savez_compressed(f"{OUT}/projections_extra/{crop}_{only.replace(',', '_')}.npz", **out)
    else:
        np.savez_compressed(f"{OUT}/projections/{crop}.npz", **out)

if __name__ == "__main__":
    for c in sys.argv[1:]:
        run(c)
