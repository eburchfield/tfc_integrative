"""Fig. 6 (Georgia place-informed projection) redrawn from the county-mask run (2026-11-13_ga_fixed_mask.py).
Same design as DISES_integrative_code/src/fig5b_georgia.py."""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.join(_os.path.dirname(_os.path.dirname(_os.path.abspath(__file__))), "src"))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
import sys
import geo, numpy as np, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap
from matplotlib.patches import Patch
IN, OUTF = f"{OUT}/georgia", f"{FIGS}/fig6_georgia_place_informed.png"
crops = ["SOY", "CORN", "HAY", "COTTON", "PEANUTS", "WHEAT", "SORGHUM"]
names = {"CORN": "Corn", "SOY": "Soybeans", "HAY": "Hay", "COTTON": "Cotton", "PEANUTS": "Peanuts", "WHEAT": "Wheat", "SORGHUM": "Sorghum"}
recs = geo.read_dbf(f"{FOREB}/data/county.dbf"); shp = geo.read_shp(f"{FOREB}/data/county.shp")
ga_cty = [p for r, p in zip(recs, shp) if r.get("STATEFP", r.get("STATE_FIPS", "")) == "13"]
D = {}; M = {}; share = {}
for c in crops:
    z = np.load(f"{IN}/{c}.npz"); H, W = z["shape"]; top, left = z["origin"]
    B, N, P, G = (z[k].reshape(H, W) for k in ("B", "N", "PAN", "PANGA"))
    gm = (z["ok"] & z["ga"]).reshape(H, W)
    keep = gm & ((B > 0.3) | (N > 0.3) | (P > 0.3) | (G > 0.3))
    D[c] = {"Climate-only projection": (N - B)[keep], "Stakeholder-informed projection": (P - B)[keep],
            "Place-informed projection (+ Georgia Delphi)": (G - B)[keep]}
    M[c] = np.where(keep, G - P, np.nan)
    share[c] = float(np.mean(np.abs((G - P)[keep]) <= 0.015))
ext = (left, left + W / 24, top - H / 24, top)
cols = {"Climate-only projection": "#8C5A2B", "Stakeholder-informed projection": "#01665E", "Place-informed projection (+ Georgia Delphi)": "#5E3C99"}
plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 10})
fig = plt.figure(figsize=(14, 9.6))
gs = fig.add_gridspec(2, 1, height_ratios=[1, 1.15], hspace=0.36)
a = fig.add_subplot(gs[0]); w = 0.25
for i, c in enumerate(crops):
    for k, (nm, v) in enumerate(D[c].items()):
        a.boxplot(v, positions=[i + (k - 1) * w], widths=w * 0.85, patch_artist=True, showfliers=False,
                  medianprops=dict(color="black", lw=1.4), whiskerprops=dict(color=cols[nm]), capprops=dict(color=cols[nm]),
                  boxprops=dict(facecolor="white" if k == 0 else cols[nm], edgecolor=cols[nm], lw=1.5, alpha=0.9))
a.axhline(0, color="#888", ls="--", lw=0.8)
a.set_xticks(range(len(crops))); a.set_xticklabels([names[c] for c in crops])
a.set_ylabel("Change in likelihood,\n2050 minus baseline")
for sp in ["top", "right"]: a.spines[sp].set_visible(False)
a.legend(handles=[Patch(facecolor="white" if k == 0 else cols[n], edgecolor=cols[n], label=n) for k, n in enumerate(cols)],
         loc="upper center", bbox_to_anchor=(0.5, -0.1), ncol=3, frameon=False)
a.set_title("a", loc="left", fontweight="bold", fontsize=14, x=-0.06)
fig.text(0.125, 0.895, "Georgia pixels with likelihood > 0.3 in any scenario; SSP2-4.5, 2041–2060 vs 2021–2040 baseline (human-controlled predictors at 2009–2018 values)", fontsize=9)
lim = 0.03; _b = plt.get_cmap("BrBG"); CENTER = (0.89, 0.87, 0.80, 1)
cmap = LinearSegmentedColormap.from_list("c", [_b(x) for x in np.linspace(0, 0.42, 64)] + [CENTER] * 8 + [_b(x) for x in np.linspace(0.58, 1, 64)])
sub = gs[1].subgridspec(2, 4, wspace=0.03, hspace=0.12)
for i, c in enumerate(crops):
    ax = fig.add_subplot(sub[i // 4, i % 4]); d = M[c]
    rgb = cmap((np.clip(d / lim, -1, 1) + 1) / 2); rgb[np.abs(d) < 0.002] = CENTER; rgb[np.isnan(d)] = (1, 1, 1, 1)
    ax.imshow(rgb, extent=ext, interpolation="nearest")
    for parts in ga_cty:
        for pt in parts: ax.plot(pt[:, 0], pt[:, 1], color="#b0b0b0", lw=0.25)
    ax.set_xlim(-85.7, -80.8); ax.set_ylim(30.3, 35.05); ax.set_aspect(1.15); ax.set_xticks([]); ax.set_yticks([])
    for sp in ax.spines.values(): sp.set_visible(False)
    ax.text(0.02, 0.98, names[c], transform=ax.transAxes, fontsize=10.5, fontweight="bold", va="top", bbox=dict(facecolor="white", edgecolor="none", alpha=0.85, pad=1))
fig.text(0.1, 0.455, "b", fontweight="bold", fontsize=14)
fig.text(0.125, 0.455, "Georgia Delphi effect: place-informed minus stakeholder-informed projection, 2041–2060", fontsize=9.5)
cax = fig.add_axes([0.33, 0.045, 0.36, 0.012])
cb = fig.colorbar(plt.cm.ScalarMappable(cmap=cmap, norm=plt.Normalize(-lim, lim)), cax=cax, orientation="horizontal", extend="both")
cb.set_ticks([-0.03, -0.015, 0, 0.015, 0.03]); cb.set_label("Place-informed minus stakeholder-informed projection")
cax.text(-0.02, 0.5, "Lower\nlikelihood", transform=cax.transAxes, ha="right", va="center", fontsize=9, color="#8C5A2B", fontweight="bold")
cax.text(1.02, 0.5, "Higher\nlikelihood", transform=cax.transAxes, ha="left", va="center", fontsize=9, color="#01665E", fontweight="bold")
fig.savefig(OUTF, dpi=250, bbox_inches="tight", facecolor="white")
print({c: round(v, 3) for c, v in share.items()})
