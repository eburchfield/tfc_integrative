import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
import numpy as np, pandas as pd
FIPS = {"NE": "31", "OH": "39", "GA": "13"}
# Round 2 state panel medians (data/delphi/state_round2_medians.csv); panelist-level responses are not shared (IRB).
g = pd.read_csv(_os.path.join(_os.path.dirname(SRC), "data", "delphi", "state_round2_medians.csv")).rename(
    columns={"present_value": "p", "median_2050": "m"})
g["p"] = pd.to_numeric(g["p"], errors="coerce"); g["m"] = pd.to_numeric(g["m"], errors="coerce")
def ratio(st, item):
    r = g[(g.state == st) & (g.item.str.startswith(item))]
    assert len(r) == 1, (st, item); return float(r.m.iloc[0] / r.p.iloc[0])
def state_pct(st):
    w = ratio(st, "Irrigation water applied")
    gw0 = float(g[(g.state == st) & (g.item == "Withdrawals from groundwater")].p.iloc[0]) / 100
    gw1 = float(g[(g.state == st) & (g.item == "Withdrawals from groundwater")].m.iloc[0]) / 100
    rate = "N rate (cotton)" if st == "GA" else "N rate (corn)"
    return {"IRRIG_MIRCA": 100 * (ratio(st, "Cropland irrigated") - 1), "IRRIG_std": 100 * (ratio(st, "Cropland irrigated") - 1),
            "KONAR_GWW": 100 * (w * gw1 / gw0 - 1), "KONAR_SWW": 100 * (w * (1 - gw1) / (1 - gw0) - 1),
            "till_new_conservational_acre": 100 * (ratio(st, "Conservation tillage") - 1),
            "cover_crop_acre": 100 * (ratio(st, "Cover crops") - 1),
            "Cao_fert_N": 100 * (ratio(st, rate) - 1), "Cao_fert_P": 100 * (ratio(st, rate.replace("N rate", "P rate")) - 1),
            "N_manure_kg": 100 * (ratio(st, "N from manure") - 1), "P_manure_kg": 100 * (ratio(st, "P from manure") - 1)}
st_shares = ["IRRIG_MIRCA", "IRRIG_std", "till_new_conservational_acre", "cover_crop_acre"]

