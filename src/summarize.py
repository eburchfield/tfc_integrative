"""Summarize Protocol B results -> circularity_summary.csv and printed table."""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
import json, glob, numpy as np, pandas as pd
rows = []
for f in sorted(glob.glob(f"{RES}/circularity/res_*.json")):
    r = json.load(open(f)); m = r["models"]; F, E = m["FULL"], m["EXCL"]
    R = [m[k] for k in m if k.startswith("RAND")]
    sf, se = r["spatial"]["FULL"], r["spatial"]["EXCL"]
    rows.append(dict(crop=r["crop"],
        acc_full=F["accuracy"], acc_excl=E["accuracy"], acc_rand=np.mean([x["accuracy"] for x in R]),
        auc_full=F["auc"], auc_excl=E["auc"], auc_rand=np.mean([x["auc"] for x in R]),
        human_full=F["human_share"], tracking_in_full=F["tracking_share"], human_excl=E["human_share"],
        human_rand_min=min(x["human_share"] for x in R), human_rand_max=max(x["human_share"] for x in R),
        clim_full=F["Climate"], clim_excl=E["Climate"],
        sp_acc_full=np.mean([x["accuracy"] for x in sf]), sp_acc_full_min=min(x["accuracy"] for x in sf), sp_acc_full_max=max(x["accuracy"] for x in sf),
        sp_acc_excl=np.mean([x["accuracy"] for x in se]),
        sp_human_full_min=min(x["human_share"] for x in sf), sp_human_full_max=max(x["human_share"] for x in sf),
        sp_human_excl_min=min(x["human_share"] for x in se), sp_human_excl_max=max(x["human_share"] for x in se)))
df = pd.DataFrame(rows); df.round(3).to_csv(f"{RES}/circularity/circularity_summary.csv", index=False)
pd.set_option("display.width", 250); print(df.round(3).to_string())
