"""Summary table for the focus-group-variable ablation -> RES/fg/fg_summary.csv"""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
import json, glob, pandas as pd
rows = []
for f in sorted(glob.glob(f"{RES}/fg/fg_*.json")):
    r = json.load(open(f)); m = r["models"]; F = m["FULL"]
    rows.append(dict(crop=r["crop"], acc_full=F["accuracy"], acc_no_added=m["NO_ADDED"]["accuracy"], acc_no_refined=m["NO_REFINED"]["accuracy"],
        acc_no_fg=m["NO_FG"]["accuracy"], auc_full=F["auc"], auc_no_fg=m["NO_FG"]["auc"],
        shap_added=F["shap_share_added"], shap_refined=F["shap_share_refined"],
        base_mean_abs=r["baseline_map_change"]["mean_abs"], base_share_gt01=r["baseline_map_change"]["share_over_0p1"], base_corr=r["baseline_map_change"]["corr"],
        clim_full=F["climate"], clim_nofg=m["NO_FG"]["climate"], human_full=F["human"], human_nofg=m["NO_FG"]["human"],
        comb_full=F["combined"], comb_nofg=m["NO_FG"]["combined"], hoc_full=F["human_over_climate"], hoc_nofg=m["NO_FG"]["human_over_climate"]))
d = pd.DataFrame(rows); d.round(4).to_csv(f"{RES}/fg/fg_summary.csv", index=False)
pd.set_option("display.width", 250); print(d.round(3).to_string())
