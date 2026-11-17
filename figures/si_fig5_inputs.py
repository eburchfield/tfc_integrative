"""Supplementary figure (grouped bars) + table: 2050 % change applied to each national human-controlled predictor
under three projections:
  linear census trend (trend_pct.json; held at 2009-18 where the variable has one census year)
  Delphi, relative change (main analysis: panel 2050 median / panel present value - 1)
  Delphi, absolute target (sensitivity: panel 2050 median / 2009-18 mean of the model variable - 1)
Outputs: figS_input_comparison.png, data/si_input_comparison.csv"""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.join(_os.path.dirname(_os.path.dirname(_os.path.abspath(__file__))), "src"))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
import sys, json, numpy as np, pandas as pd, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
from experiments import pct, panel_pct

FIGOUT = f"{FIGS}/"
tp = json.load(open(f"{RES}/trend_pct.json"))
# model variable(s) -> label (Delphi item); duplicated variables share one row
rows = [
    (["crop_insurance_acre_rma"], "Crop insurance\n(farmland in crop insurance)"),
    (["sales_usd_gt_500k"], "Large-farm share of sales\n(farm sales by large farms)"),
    (["N_fert_kg", "Cao_fert_N"], "Nitrogen fertilizer\n(N rate on corn)"),
    (["rented_fract"], "Rented share of land\n(farmland operated by renters)"),
    (["Producer_nonwhite"], "Socially disadvantaged operators"),
    (["P_fert_kg", "Cao_fert_P"], "Phosphorus fertilizer\n(P rate on corn)"),
    (["producer_exp_lt_10"], "Beginning farmers"),
    (["animal_sales_usd"], "Livestock share of sales"),
    (["live_cattle_inventory"], "Cattle inventory\n(per capita meat demand)"),
    (["biofuel_corn_percent_used", "biofuel_soy_percent_used"], "Biofuel shares\n(corn used for ethanol)"),
    (["labor_number"], "Hired labor\n(hired farmworkers)"),
    (["CRP_ACRE"], "CRP acres\n(cropland in CRP)"),
    (["no_ops_sales_lt_10k"], "Farms with sales < $10k\n(farmland operated by small farms)"),
]
one_year = {"crop_insurance_acre_rma", "biofuel_corn_percent_used", "biofuel_soy_percent_used",
            "animal_sales_usd", "producer_exp_lt_10"}
recs = []
for vs, lab in rows:
    v = vs[0]
    recs.append(dict(model_variables="; ".join(vs), label=lab.replace("\n", " "),
                     linear_trend_pct=np.nan if v in one_year else tp[v],
                     delphi_relative_pct=panel_pct[v], delphi_absolute_pct=pct[v]))
df = pd.DataFrame(recs)
df.round(1).to_csv(f"{RES}/si_fig5_inputs.csv", index=False)
print(df.round(1).to_string())

S = [("linear_trend_pct", "Linear census trend (1997–2022) extended to 2050", "#8C5A2B", "D"),
     ("delphi_relative_pct", "Delphi, relative change (main analysis)", "#01665E", "o"),
     ("delphi_absolute_pct", "Delphi, absolute target (sensitivity)", "#7F7F7F", "s")]
plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 10})
fig, ax = plt.subplots(figsize=(9.5, 8.2))
n = len(df); y = np.arange(n)[::-1]; bh = 0.26
for j, (k, lab, c, m) in enumerate(S):
    off = (1 - j) * bh
    v = df[k].fillna(0).values
    ax.barh(y + off, v, height=bh * 0.92, color=c, label=lab, zorder=2)
    for i in np.where(df[k].isna())[0]:
        ax.text(1.5, y[i] + off, "no trend (one census year)", fontsize=7, color=c, va="center", ha="left")
ax.axvline(0, color="#555", lw=0.9, zorder=3)
ax.xaxis.grid(True, color="#eee", zorder=0)
ax.set_yticks(y); ax.set_yticklabels(df.label.str.replace(" (", "\n(", regex=False), fontsize=8.8)
ax.set_xlim(-105, 135); ax.set_ylim(-0.7, n - 0.3)
ax.set_xlabel("Change applied to the model variable by 2050 (% of 2009–2018 value)")
for s in ("top", "right"): ax.spines[s].set_visible(False)
ax.legend(loc="upper center", bbox_to_anchor=(0.45, -0.08), ncol=1, frameon=False, fontsize=9)
fig.savefig(f"{FIGS}/si_fig5_inputs.png", dpi=300, bbox_inches="tight", facecolor="white")
