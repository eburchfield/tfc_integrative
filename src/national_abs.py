"""National (38-state) checks on how the two farm-structure Delphi items enter the model.

Made by Claude on 2026-10-19 for Emily Burchfield (P3, DISES integrative paper; manuscript not edited).
Same inputs, valid-pixel mask and scenario construction as national_attr.py / experiments.py. Adds:
  1. Cap check: share of valid pixels where the panel-relative change pushes a share variable to the cap of 1
     (sales_usd_gt_500k x 1.1392) or where an absolute change hits the floor of 0, unweighted and weighted by
     the crop's baseline likelihood (B), so the second number says how much of the crop's area is affected.
  2. Absolute conversion: the two items applied as percentage-point changes in the model's share variables,
     using the Round 2 national panel medians (small farms' share of farmland 42% -> 30%, -12 points;
     large farms' share of sales 79% -> 90%, +11 points), clipped to [0, 1]. All other items as in PAN.
       PAN_ABS          PAN with both structure items absolute
       nat:small_abs    N + small-farm item only, absolute
       nat:large_abs    N + large-farm item only, absolute
Writes {OUT}/national_abs/<CROP>.npz (new scenarios; B, N, PAN, PAN_nostruct come from {OUT}/national/<CROP>.npz)
and {OUT}/national_abs/cap_<CROP>.json.
Usage: python national_abs.py CROP [CROP ...]   (CAP_ONLY=1 rewrites only cap_<CROP>.json)
"""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, OUT
import os, sys, json, time, numpy as np
from rfpy import load_forest, predict_prob, read_stack
from experiments import pct, panel_pct, share_vars, C30, n30, C50, n50

SMALL, LARGE = "no_ops_sales_lt_10k", "sales_usd_gt_500k"
ABS = {SMALL: -0.12, LARGE: +0.11}

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
    used = set(F["names"])
    for j, v in enumerate(n30):
        if v in used: ok &= np.isfinite(c30[:, j])
    for j, v in enumerate(n50):
        if v in used: ok &= np.isfinite(c50[:, j])
    prev = np.load(f"{OUT}/national/{crop}.npz", allow_pickle=True)
    assert np.array_equal(prev["ok"], ok), "valid-pixel mask differs from national_attr.py"
    X0 = X[ok].astype(np.float64); del S, X
    for v in [v for v in pct.index if v in col]: X0[:, col[v]] = X0[:, col[v]] / (1 + pct[v] / 100)
    c50o = c50[ok]
    N = X0.copy()
    for j, v in enumerate(n50):
        if v in col: N[:, col[v]] = c50o[:, j]
    B = prev["B"].astype(float)
    cap = {"crop": crop, "pixels": int(ok.sum()), "in_model": {v: v in used for v in (SMALL, LARGE)}}
    for v in (SMALL, LARGE):
        x = X0[:, col[v]]
        rel = x * (1 + panel_pct[v] / 100); ab = x + ABS[v]
        cap[v] = dict(median_present=float(np.median(x)),
                      rel_at_cap_share=float(np.mean(rel >= 1)), rel_at_cap_Bweighted=float(np.sum(B * (rel >= 1)) / np.sum(B)),
                      abs_at_bound_share=float(np.mean((ab >= 1) | (ab <= 0))),
                      abs_at_bound_Bweighted=float(np.sum(B * ((ab >= 1) | (ab <= 0))) / np.sum(B)),
                      median_abs_as_relative_pct=float(100 * np.nanmedian(np.clip(ab, 0, 1) / np.where(x > 0, x, np.nan) - 1)))
    def apply(rel_vars, abs_vars):
        A = N.copy()
        for v in rel_vars:
            if v in col and v in panel_pct:
                A[:, col[v]] = X0[:, col[v]] * (1 + panel_pct[v] / 100)
                if v in share_vars: A[:, col[v]] = np.minimum(A[:, col[v]], 1.0)
        for v in abs_vars:
            if v in col: A[:, col[v]] = np.clip(X0[:, col[v]] + ABS[v], 0.0, 1.0)
        return A
    if os.environ.get("CAP_ONLY"):  # recompute the cap summary only, keeping the stored predictions
        old = json.load(open(f"{OUT}/national_abs/cap_{crop}.json")); cap["N_reproduces"] = old["N_reproduces"]
        json.dump(cap, open(f"{OUT}/national_abs/cap_{crop}.json", "w"), indent=1); print(crop, "cap only", flush=True); return
    others = [v for v in panel_pct if v not in ABS]
    builders = {"PAN_ABS": lambda: apply(others, [SMALL, LARGE]),
                "nat:small_abs": lambda: apply([], [SMALL]), "nat:large_abs": lambda: apply([], [LARGE]),
                "N_check": lambda: N}
    out = {"ok": ok, "shape": np.array([H, W]), "keys": np.array(list(builders))}
    for k, b in builders.items():
        A = b(); out[k] = predict_prob(F, A[:, idx]).astype(np.float32); del A
        print(crop, k, f"{time.time() - t0:.0f}s", flush=True)
    cap["N_reproduces"] = float(np.max(np.abs(out["N_check"] - prev["N"])))
    os.makedirs(f"{OUT}/national_abs", exist_ok=True)
    np.savez_compressed(f"{OUT}/national_abs/{crop}.npz", **out)
    json.dump(cap, open(f"{OUT}/national_abs/cap_{crop}.json", "w"), indent=1)
    print(json.dumps(cap, indent=1), flush=True)

if __name__ == "__main__":
    for c in sys.argv[1:]: run(c)
