"""Compare three ways of projecting human-controlled predictors to 2050 (SSP2-4.5, 2041-2060):
  TREND : linear trend of each variable's county-mean series (trend_pct.json)
  LR    : Delphi as run in Model 2 (panel 2050 median vs 2009-18 data mean)
  PANEL : Delphi panel-relative (panel 2050 median vs panel present value), shares capped at 1
Human effect = scenario minus naive (2041-60 climate, human predictors at 2009-18).
Outputs: compare3_stats.csv, compare3_human_effect.png"""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.join(_os.path.dirname(_os.path.dirname(_os.path.abspath(__file__))), "src"))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
import sys, numpy as np, pandas as pd, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap
import geo

crops = ["SOY", "CORN", "HAY", "COTTON", "PEANUTS", "WHEAT", "SORGHUM"]   # Fig. 2 order (main-text crops)
names = {"SOY": "Soybeans", "CORN": "Corn", "HAY": "Hay", "FRUITVEG": "Fruit & veg.", "COTTON": "Cotton",
         "PEANUTS": "Peanuts", "WHEAT": "Wheat", "SORGHUM": "Sorghum"}
appr = [("TREND", "Linear trend"), ("LR", "Delphi, absolute target (as run)"), ("PAN", "Delphi, relative change")]
cols = {"TREND": "#8C5A2B", "LR": "#999999", "PAN": "#01665E"}

rows, maps = [], {}
for c in crops:
    d = np.load(f"{OUT}/projections/{c}.npz"); t = d
    H, W = d["shape"]; ok = d["ok"] & t["ok"]
    lat = 49.375 - (np.arange(H) + 0.5) / 24; w = np.repeat(np.cos(np.deg2rad(lat)), W)
    B, N = d["B"], d["N"]
    S = {"TREND": t["TREND"], "LR": d["D"], "PAN": d["PAN"]}
    zones = {"all": ok, "core": ok & (B > 0.3), "margin": ok & (B > 0.1) & (B <= 0.3)}
    clim = np.mean(np.abs((N - B)[ok]))
    for k, _ in appr:
        dl = S[k] - N
        r = dict(crop=c, approach=k, mean_abs=np.mean(np.abs(dl[ok])), ratio_to_climate20=np.mean(np.abs(dl[ok])) / clim)
        for z, m in zones.items():
            r[f"wa_{z}_pct"] = 100 * np.sum(w[m] * dl[m]) / np.sum(w[m] * B[m])
        rows.append(r)
        keep = (B > 0.3) | (N > 0.3) | (S[k] > 0.3)
        maps[(c, k)] = np.where(ok & keep, dl, np.nan).reshape(H, W)
    rows.append(dict(crop=c, approach="CLIMATE20", mean_abs=clim, ratio_to_climate20=1.0,
                     **{f"wa_{z}_pct": 100 * np.sum(w[m] * (N - B)[m]) / np.sum(w[m] * B[m]) for z, m in zones.items()}))
df = pd.DataFrame(rows); df.round(4).to_csv(f"{RES}/compare3_stats.csv", index=False)
pd.set_option("display.width", 200); print(df.round(3).to_string())

# ---- figure ----
recs = geo.read_dbf(f"{FOREB}/data/states.dbf"); shp = geo.read_shp(f"{FOREB}/data/states.shp")
ext = (-106.6667, -106.6667 + W / 24, 49.375 - H / 24, 49.375); lim = 0.06
_b = plt.get_cmap("BrBG"); CENTER = (0.89, 0.87, 0.80, 1)
cmap = LinearSegmentedColormap.from_list("c", [_b(x) for x in np.linspace(0, 0.42, 64)] + [CENTER] * 8 + [_b(x) for x in np.linspace(0.58, 1, 64)])
plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 10})
fig = plt.figure(figsize=(13, 22))
gs = fig.add_gridspec(len(crops) + 2, 3, height_ratios=[1] * len(crops) + [0.55, 1.6], hspace=0.05, wspace=0.02)
for i, c in enumerate(crops):
    for j, (k, lab) in enumerate(appr):
        ax = fig.add_subplot(gs[i, j]); dd = maps[(c, k)]
        rgb = cmap((np.clip(dd / lim, -1, 1) + 1) / 2); rgb[np.abs(dd) < 0.01] = CENTER; rgb[np.isnan(dd)] = (1, 1, 1, 1)
        ax.imshow(rgb, extent=ext, interpolation="nearest")
        for rec, parts in zip(recs, shp):
            if rec["STATE_ABBR"] in ("HI", "AK"): continue
            for pt in parts: ax.plot(pt[:, 0], pt[:, 1], color="#9a9a9a", lw=0.25)
        ax.set_xlim(ext[0], ext[1]); ax.set_ylim(ext[2], ext[3]); ax.set_aspect(1.25); ax.axis("off")
        if i == 0: ax.set_title(lab, fontsize=11, fontweight="bold")
        if j == 0: ax.text(-0.02, 0.5, names[c], transform=ax.transAxes, rotation=90, ha="right", va="center", fontsize=11, fontweight="bold")
row = fig.add_subplot(gs[len(crops), :]); row.axis("off"); cax = row.inset_axes([0.25, 0.62, 0.5, 0.16])
cb = fig.colorbar(plt.cm.ScalarMappable(cmap=cmap, norm=plt.Normalize(-lim, lim)), cax=cax, orientation="horizontal", extend="both")
cb.ax.xaxis.set_label_position("top")
cb.set_label("Human-driven change in likelihood, 2041–2060 (scenario minus naive projection)\nneutral: |Δ| < 0.01; white: likelihood < 0.3 in all scenarios", fontsize=9)
sub = gs[len(crops) + 1, :].subgridspec(1, 2, wspace=0.25)
x = np.arange(len(crops)); bw = 0.27
for p, (met, ttl) in enumerate([("ratio_to_climate20", "Size of human effect relative to 20 years of\nclimate change (mean absolute change ratio)"),
                                ("wa_margin_pct", "Human effect at the margin (baseline 0.1–0.3),\nchange in likelihood-weighted area, %")]):
    ax = fig.add_subplot(sub[0, p])
    for j, (k, lab) in enumerate(appr):
        v = [df[(df.crop == c) & (df.approach == k)][met].values[0] for c in crops]
        ax.bar(x + (j - 1) * bw, v, bw, color=cols[k], label=lab)
    if p == 0: ax.axhline(1, color="#555", ls="--", lw=0.8); ax.text(len(crops) - 0.5, 1.02, "= climate", ha="right", fontsize=8.5, color="#555")
    else: ax.axhline(0, color="#555", lw=0.8)
    ax.set_xticks(x); ax.set_xticklabels([names[c] for c in crops], rotation=35, ha="right")
    ax.set_title(ttl, fontsize=10, loc="left")
    for s in ("top", "right"): ax.spines[s].set_visible(False)
    if p == 0: ax.legend(frameon=False, fontsize=9, loc="upper left")
fig.savefig(f"{FIGS}/si_fig4_three_projections.png", dpi=200, bbox_inches="tight", facecolor="white")
