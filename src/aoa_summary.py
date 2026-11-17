import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
f"""Summarize Protocol A: share of pixels outside the area of applicability (AOA) by crop, scenario and zone,
and the R3 / Fig. 4b headline recomputed inside the AOA. Writes {RES}/aoa/aoa_summary.csv, aoa_fig4b_inside.csv."""
import glob, json, numpy as np, pandas as pd
rows, bars = [], []
for f in sorted(glob.glob(f"{RES}/aoa/aoa_*.npz")):
    crop = f.split("aoa_")[1][:-4]; a = np.load(f); o = np.load(f"{OUT}/projections/{crop}.npz")
    H, W = o["shape"]; ok = o["ok"]; B, N, P = o["B"], o["N"], o["PAN"]
    lat = 49.375 - (np.arange(H) + .5) / 24; w = np.repeat(np.cos(np.deg2rad(lat)), W)
    mapped = ok & ((B > .3) | (N > .3) | (P > .3))
    zones = {"all": ok, "mapped": mapped, "core": ok & (B > .3), "margin": ok & (B > .1) & (B <= .3), "outside_zone": ok & (B <= .1)}
    for k in ("B", "N", "PAN", "PLACE", "ABS", "TREND"):
        if k not in a: continue
        di = a[k]; r = dict(crop=crop, scenario=k)
        for z, m in zones.items():
            mm = m & np.isfinite(di)
            r[f"out95_{z}_pct"] = 100 * np.mean(di[mm] > a["thr95"]); r[f"outcast_{z}_pct"] = 100 * np.mean(di[mm] > a["thr_cast"])
        r["pushed_out_vs_B_mapped_pct"] = 100 * np.mean((di[mapped] > a["thr95"]) & (a["B"][mapped] <= a["thr95"]))
        rows.append(r)
    inside = ok & (a["B"] <= a["thr95"]) & (a["N"] <= a["thr95"]) & (a["PAN"] <= a["thr95"])
    def wa(x, m): return 100 * np.sum(w[m] * x[m]) / np.sum(w[m] * B[m])
    for lab, m in (("all pixels", ok), ("inside AOA", inside)):
        bars.append(dict(crop=crop, set=lab, share_of_pixels=float(m.sum() / ok.sum()),
                         climate=wa(N - B, m), human=wa(P - N, m), combined=wa(P - B, m),
                         human_over_climate_meanabs=float(np.mean(np.abs((P - N)[m])) / np.mean(np.abs((N - B)[m])))))
pd.set_option("display.width", 250)
s = pd.DataFrame(rows); s.round(2).to_csv(f"{RES}/aoa/aoa_summary.csv", index=False)
b = pd.DataFrame(bars); b.round(3).to_csv(f"{RES}/aoa/aoa_fig4b_inside.csv", index=False)
print(s[["crop", "scenario", "out95_all_pct", "out95_mapped_pct", "out95_core_pct", "out95_margin_pct", "outcast_mapped_pct", "pushed_out_vs_B_mapped_pct"]].round(1).to_string())
print(b.round(2).to_string())
