"""SI: climate and expected human change for the extra crops (oats, barley, rye, pecans, fruit & veg).
Same definitions as Fig. 4 / compare3: B baseline (2021-40 climate, human 2009-18), N climate-only (2041-60),
PAN stakeholder-informed (panel-relative national Delphi), PREV reversed panel shifts."""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.join(_os.path.dirname(_os.path.dirname(_os.path.abspath(__file__))), "src"))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
import sys, numpy as np, pandas as pd, matplotlib
matplotlib.use("Agg"); import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap
import geo
crops = ["FRUITVEG", "RYE", "PECANS", "BARLEY", "OATS"]
names = {"FRUITVEG": "Fruit and vegetables", "RYE": "Rye", "PECANS": "Pecans", "BARLEY": "Barley", "OATS": "Oats"}
rows, maps = [], {}
for c in crops:
    d = np.load(f"{OUT}/projections/{c}.npz"); H, W = d["shape"]; ok = d["ok"]
    lat = 49.375 - (np.arange(H) + 0.5) / 24; w = np.repeat(np.cos(np.deg2rad(lat)), W)
    B, N, P, R = d["B"], d["N"], d["PAN"], d["PREV"]
    Z = {"all": ok, "core": ok & (B > 0.3), "margin": ok & (B > 0.1) & (B <= 0.3)}
    wa = lambda dl, m: 100 * np.sum(w[m] * dl[m]) / np.sum(w[m] * B[m])
    clim = np.mean(np.abs((N - B)[ok])); hum = np.mean(np.abs((P - N)[ok]))
    r = dict(crop=c, mean_abs_human=hum, mean_abs_climate20=clim, ratio_to_climate20=hum / clim,
             climate_all=wa(N - B, Z["all"]), human_all=wa(P - N, Z["all"]), total_all=wa(P - B, Z["all"]),
             human_core=wa(P - N, Z["core"]), human_margin=wa(P - N, Z["margin"]), reversed_margin=wa(R - N, Z["margin"]),
             climate_core=wa(N - B, Z["core"]), climate_margin=wa(N - B, Z["margin"]),
             oor_pan_pct=100 * np.mean(d["oor_pan"][ok]))
    rows.append(r)
    keep = (B > 0.3) | (N > 0.3) | (P > 0.3)
    maps[c] = np.where(ok & keep, P - B, np.nan).reshape(H, W)
df = pd.DataFrame(rows); df.round(4).to_csv(f"{RES}/si_additional_crops_stats.csv", index=False)
pd.set_option("display.width", 250); print(df.round(3).to_string())
recs = geo.read_dbf(f"{FOREB}/data/states.dbf"); shp = geo.read_shp(f"{FOREB}/data/states.shp")
ext = (-106.6667, -106.6667 + W / 24, 49.375 - H / 24, 49.375); lim = 0.06
_b = plt.get_cmap("BrBG"); CENTER = (0.89, 0.87, 0.80, 1)
cmap = LinearSegmentedColormap.from_list("c", [_b(x) for x in np.linspace(0, 0.42, 64)] + [CENTER] * 8 + [_b(x) for x in np.linspace(0.58, 1, 64)])
plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 10})
fig = plt.figure(figsize=(15, 7.6)); gs = fig.add_gridspec(2, 5, height_ratios=[1, 0.9], hspace=0.62, wspace=0.03)
for j, c in enumerate(crops):
    ax = fig.add_subplot(gs[0, j]); dd = maps[c]
    rgb = cmap((np.clip(dd / lim, -1, 1) + 1) / 2); rgb[np.abs(dd) < 0.01] = CENTER; rgb[np.isnan(dd)] = (1, 1, 1, 1)
    ax.imshow(rgb, extent=ext, interpolation="nearest")
    for rec, parts in zip(recs, shp):
        if rec["STATE_ABBR"] in ("HI", "AK"): continue
        for pt in parts: ax.plot(pt[:, 0], pt[:, 1], color="#9a9a9a", lw=0.25)
    ax.set_xlim(ext[0], ext[1]); ax.set_ylim(ext[2], ext[3]); ax.set_aspect(1.25); ax.axis("off"); ax.set_title(names[c], fontsize=11, fontweight="bold")
cax = fig.add_axes([0.33, 0.535, 0.34, 0.016])
cb = fig.colorbar(plt.cm.ScalarMappable(cmap=cmap, norm=plt.Normalize(-lim, lim)), cax=cax, orientation="horizontal", extend="both")
cb.set_label("a, Change in likelihood, stakeholder-informed projection (2041–2060) minus baseline", fontsize=9)
ax = fig.add_subplot(gs[1, 1:4]); x = np.arange(len(crops)); bw = 0.26
for k, (col, lab, colr) in enumerate([("climate_all", "Climate", "#8C5A2B"), ("human_all", "Expected human change", "#01665E"), ("total_all", "Sum", "#555555")]):
    ax.bar(x + (k - 1) * bw, df[col], bw, color=colr, label=lab)
ax.axhline(0, color="#555", lw=0.8); ax.set_xticks(x); ax.set_xticklabels([names[c] for c in crops])
ax.set_ylabel("Change in likelihood-weighted area (%)"); ax.set_title("b", loc="left", fontweight="bold")
for s in ("top", "right"): ax.spines[s].set_visible(False)
ax.legend(frameon=False, fontsize=9, ncol=1, loc="upper left", bbox_to_anchor=(1.01, 1.0))
fig.savefig(f"{FIGS}/si_fig3_additional_crops.png", dpi=250, bbox_inches="tight", facecolor="white")
