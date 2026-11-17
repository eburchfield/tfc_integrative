"""SI figures: place-informed projections for Nebraska and Ohio, drawn exactly like Fig. 6 (Georgia).
a, change in likelihood (2041-2060 minus the 2021-2040 baseline) on state pixels with likelihood > 0.3 in any
scenario, under the climate-only, stakeholder-informed and place-informed projections; b, the state Delphi effect
(place-informed minus stakeholder-informed) mapped with county outlines.
Usage: python3 figures/si_fig_state_place_informed.py NE   (or OH). Reads OUT/states and OUT/projections."""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.join(_os.path.dirname(_os.path.dirname(_os.path.abspath(__file__))), "src"))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
import sys
import geo, numpy as np, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap
from matplotlib.patches import Patch

ST = sys.argv[1] if len(sys.argv) > 1 else "NE"
FIPS = {"NE": "31", "OH": "39"}[ST]
SNAME = {"NE": "Nebraska", "OH": "Ohio"}[ST]
crops = {"NE": ["SOY", "CORN", "HAY", "WHEAT", "SORGHUM"], "OH": ["SOY", "CORN", "HAY", "WHEAT"]}[ST]
names = {"CORN": "Corn", "SOY": "Soybeans", "HAY": "Hay", "WHEAT": "Wheat", "SORGHUM": "Sorghum"}
recs = geo.read_dbf(f"{FOREB}/data/county.dbf"); shp = geo.read_shp(f"{FOREB}/data/county.shp")
cty = [p for r, p in zip(recs, shp) if r.get("STATEFP", r.get("STATE_FIPS", "")) == FIPS]

D, M, share = {}, {}, {}
for c in crops:
    d = np.load(f"{OUT}/projections/{c}.npz"); s = np.load(f"{OUT}/states/{c}_{ST}.npz")
    H, W = d["shape"]; m = s["mask"]
    B, N, P = d["B"][m], d["N"][m], d["PAN"][m]; G = s["PANST"]
    ok = d["ok"][m] & np.isfinite(G) & np.isfinite(P)
    keep = ok & ((B > .3) | (N > .3) | (P > .3) | (G > .3))
    D[c] = {"Climate-only projection": (N - B)[keep], "Stakeholder-informed projection": (P - B)[keep],
            f"Place-informed projection (+ {SNAME} Delphi)": (G - B)[keep]}
    full = np.full(H * W, np.nan); full[np.where(m)[0][keep]] = (G - P)[keep]
    M[c] = full.reshape(H, W)
    share[c] = float(np.mean(np.abs((G - P)[keep]) <= 0.015))

rows, cols_ = np.where(np.load(f"{OUT}/states/{crops[0]}_{ST}.npz")["mask"].reshape(H, W))
r0, r1, c0, c1 = rows.min(), rows.max() + 1, cols_.min(), cols_.max() + 1
ext = (-106.6666667 + c0 / 24, -106.6666667 + c1 / 24, 49.375 - r1 / 24, 49.375 - r0 / 24)
pal = {"Climate-only projection": "#8C5A2B", "Stakeholder-informed projection": "#01665E",
       f"Place-informed projection (+ {SNAME} Delphi)": "#5E3C99"}

plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 10})
ncol = 3 if len(crops) > 4 else len(crops)
nrow = int(np.ceil(len(crops) / ncol))
fig = plt.figure(figsize=(14, 5 + 3.1 * nrow))
gs = fig.add_gridspec(2, 1, height_ratios=[1, 0.62 * nrow], hspace=0.36)
a = fig.add_subplot(gs[0]); w = 0.25
for i, c in enumerate(crops):
    for k, (nm, v) in enumerate(D[c].items()):
        a.boxplot(v, positions=[i + (k - 1) * w], widths=w * 0.85, patch_artist=True, showfliers=False,
                  medianprops=dict(color="black", lw=1.4), whiskerprops=dict(color=pal[nm]), capprops=dict(color=pal[nm]),
                  boxprops=dict(facecolor="white" if k == 0 else pal[nm], edgecolor=pal[nm], lw=1.5, alpha=0.9))
a.axhline(0, color="#888", ls="--", lw=0.8)
a.set_xticks(range(len(crops))); a.set_xticklabels([names[c] for c in crops])
a.set_ylabel("Change in likelihood,\n2050 minus baseline")
for sp in ["top", "right"]: a.spines[sp].set_visible(False)
a.legend(handles=[Patch(facecolor="white" if k == 0 else pal[n], edgecolor=pal[n], label=n) for k, n in enumerate(pal)],
         loc="upper center", bbox_to_anchor=(0.5, -0.1), ncol=3, frameon=False)
a.set_title("a", loc="left", fontweight="bold", fontsize=14, x=-0.06)
a.text(0, 1.04, f"{SNAME} pixels with likelihood > 0.3 in any scenario; SSP2-4.5, 2041–2060 vs 2021–2040 baseline (human-controlled predictors at 2009–2018 values)",
       transform=a.transAxes, fontsize=9)

lim = 0.03; _b = plt.get_cmap("BrBG"); CENTER = (0.89, 0.87, 0.80, 1)
cmap = LinearSegmentedColormap.from_list("c", [_b(x) for x in np.linspace(0, 0.42, 64)] + [CENTER] * 8 + [_b(x) for x in np.linspace(0.58, 1, 64)])
sub = gs[1].subgridspec(nrow, ncol, wspace=0.04, hspace=0.12)
for i, c in enumerate(crops):
    ax = fig.add_subplot(sub[i // ncol, i % ncol]); d = M[c][r0:r1, c0:c1]
    rgb = cmap((np.clip(d / lim, -1, 1) + 1) / 2); rgb[np.abs(d) < 0.002] = CENTER; rgb[np.isnan(d)] = (1, 1, 1, 1)
    ax.imshow(rgb, extent=ext, interpolation="nearest")
    for parts in cty:
        for pt in parts: ax.plot(pt[:, 0], pt[:, 1], color="#b0b0b0", lw=0.25)
    ax.set_xlim(ext[0], ext[1]); ax.set_ylim(ext[2], ext[3]); ax.set_aspect(1 / np.cos(np.deg2rad((ext[2] + ext[3]) / 2)))
    ax.set_xticks([]); ax.set_yticks([])
    for sp in ax.spines.values(): sp.set_visible(False)
    ax.text(0.02, 0.98, names[c], transform=ax.transAxes, fontsize=10.5, fontweight="bold", va="top",
            bbox=dict(facecolor="white", edgecolor="none", alpha=0.85, pad=1))
bb = sub[0, 0].get_position(fig)
fig.text(0.1, bb.y1 + 0.012, "b", fontweight="bold", fontsize=14)
fig.text(0.125, bb.y1 + 0.012, f"{SNAME} Delphi effect: place-informed minus stakeholder-informed projection, 2041–2060", fontsize=9.5)
cax = fig.add_axes([0.33, 0.04, 0.36, 0.012])
cb = fig.colorbar(plt.cm.ScalarMappable(cmap=cmap, norm=plt.Normalize(-lim, lim)), cax=cax, orientation="horizontal", extend="both")
cb.set_ticks([-0.03, -0.015, 0, 0.015, 0.03]); cb.set_label("Place-informed minus stakeholder-informed projection")
cax.text(-0.05, 0.5, "Lower\nlikelihood", transform=cax.transAxes, ha="right", va="center", fontsize=9, color="#8C5A2B", fontweight="bold")
cax.text(1.05, 0.5, "Higher\nlikelihood", transform=cax.transAxes, ha="left", va="center", fontsize=9, color="#01665E", fontweight="bold")
fig.savefig(f"{FIGS}/si_fig_place_informed_{ST}.png", dpi=250, bbox_inches="tight", facecolor="white")
print(ST, {c: round(v, 3) for c, v in share.items()})
