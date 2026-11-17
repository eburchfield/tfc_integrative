"""National (38-state) one-at-a-time attribution of the stakeholder-informed projection.

Same inputs and scenario construction as experiments.py (B, N, PAN with panel-relative changes, shares capped at 1),
plus:
  PAN_nostruct  PAN without no_ops_sales_lt_10k (small farms) and sales_usd_gt_500k (large farms' share of sales)
  nat:<item>    N + one national item only
Memory-light: scenarios are built only on valid rows. Writes {OUT}/national/<CROP>.npz
Usage: python national_attr.py CROP [CROP ...]
"""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, OUT
import os, sys, time, numpy as np
from rfpy import load_forest, predict_prob, read_stack
from experiments import pct, panel_pct, share_vars, C30, n30, C50, n50
# national Delphi items and the model variables each one moves
NAT_ITEMS = {
    "insurance": ["crop_insurance_acre_rma"],
    "CRP": ["CRP_ACRE"],
    "biofuel": ["biofuel_corn_percent_used", "biofuel_soy_percent_used"],
    "N_rate": ["N_fert_kg", "Cao_fert_N"],
    "P_rate": ["P_fert_kg", "Cao_fert_P"],
    "cattle": ["live_cattle_inventory"],
    "livestock_sales": ["animal_sales_usd"],
    "small_farms": ["no_ops_sales_lt_10k"],
    "large_farm_sales": ["sales_usd_gt_500k"],
    "rented": ["rented_fract"],
    "nonwhite": ["Producer_nonwhite"],
    "labor": ["labor_number"],
}

STRUCT = ["no_ops_sales_lt_10k", "sales_usd_gt_500k"]

def run(crop):
    t0 = time.time(); U = f"{FOREB}/"
    F = load_forest(U + f"out/model2_R/rf/{crop}_RF_AG.RDS")
    S, names = read_stack(U + f"out/fpredictors/delphi_ras_national_only/ssp245_{crop}_2041_2060_delphi_national_AG.tif")
    H, W, P = S.shape
    col = {n: i for i, n in enumerate(names)}
    idx = [col[n] for n in F["names"]]
    X = S.reshape(-1, P)
    ok = ~np.isnan(X[:, idx]).any(1)
    c30 = C30.reshape(-1, C30.shape[2]); c50 = C50.reshape(-1, C50.shape[2])
    used = set(F["names"])  # as experiments.py: only predictors the forest uses can make a pixel invalid
    for j, v in enumerate(n30):
        if v in used: ok &= np.isfinite(c30[:, j])
    for j, v in enumerate(n50):
        if v in used: ok &= np.isfinite(c50[:, j])
    X0 = X[ok].astype(np.float64); del S, X
    dv = [v for v in pct.index if v in col]
    for v in dv: X0[:, col[v]] = X0[:, col[v]] / (1 + pct[v] / 100)
    c30o, c50o = c30[ok], c50[ok]
    def with_climate(A, Cf, cn):
        A = A.copy()
        for j, v in enumerate(cn):
            if v in col: A[:, col[v]] = Cf[:, j]
        return A
    N = with_climate(X0, c50o, n50)
    def apply_nat(vars_):
        A = N.copy()
        for v in vars_:
            if v in col and v in panel_pct:
                A[:, col[v]] = X0[:, col[v]] * (1 + panel_pct[v] / 100)
                if v in share_vars: A[:, col[v]] = np.minimum(A[:, col[v]], 1.0)
        return A
    builders = {"B": lambda: with_climate(X0, c30o, n30), "N": lambda: N,
                "PAN": lambda: apply_nat(list(panel_pct)),
                "PAN_nostruct": lambda: apply_nat([v for v in panel_pct if v not in STRUCT])}
    for k, vs in NAT_ITEMS.items():
        if any(v in col for v in vs): builders[f"nat:{k}"] = (lambda vs=vs: apply_nat(vs))
    out = {"ok": ok, "shape": np.array([H, W]), "keys": np.array(list(builders))}
    for k, b in builders.items():
        A = b(); out[k] = predict_prob(F, A[:, idx]).astype(np.float32); del A
        print(crop, k, f"{time.time() - t0:.0f}s", flush=True)
    os.makedirs(f"{OUT}/national", exist_ok=True)
    np.savez_compressed(f"{OUT}/national/{crop}.npz", **out)

if __name__ == "__main__":
    for c in sys.argv[1:]: run(c)
