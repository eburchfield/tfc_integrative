import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
import sys, glob, numpy as np, pandas as pd
from rfpy import read_tif

F4 = f"{FIGDATA}/fig4/"
rows = []
for f in sorted(glob.glob(f"{OUT}/projections/*.npz")):
    crop = f.split("/")[-1][:-4]
    if not _os.path.exists(F4 + f"ssp245_{crop}_AG.tif"): continue   # 2070 climate layer only for the main crops
    d = np.load(f); H, W = d["shape"]; ok = d["ok"]
    lat = 49.375 - (np.arange(H) + 0.5) / 24
    w = np.repeat(np.cos(np.deg2rad(lat)), W)
    clim4, _, _ = read_tif(F4 + f"ssp245_{crop}_AG.tif"); clim4 = clim4.reshape(-1, 4)
    B, N, D, D30, REV, TINY, PAN = (d[k] for k in ("B", "N", "D", "D30", "REV", "TINY", "PAN"))
    C70 = clim4[:, 2]
    zones = {"all": ok, "core": ok & (B > 0.3), "margin": ok & (B > 0.1) & (B <= 0.3), "outside": ok & (B <= 0.1)}
    contrasts = {
        "climate_2030to2050": N - B,
        "climate_2030to2070": C70 - B,
        "delphi_asrun": D - N,
        "delphi_asrun_2030clim": D30 - B,
        "delphi_reversed": REV - N,
        "delphi_tiny_x10": (TINY - N) * 10,
        "delphi_panelrel": PAN - N,
        "combined_asrun": D - B,
    }
    for cn, dlt in contrasts.items():
        r = {"crop": crop, "contrast": cn}
        m = ok
        r["mean_abs"] = np.mean(np.abs(dlt[m]))
        r["mean_signed"] = np.mean(dlt[m])
        r["corr_with_base"] = np.corrcoef(dlt[m], B[m])[0, 1]
        for z, zm in zones.items():
            r[f"wa_{z}_pct"] = 100 * np.sum(w[zm] * dlt[zm]) / np.sum(w[zm] * B[zm])
        rows.append(r)
    rows.append({"crop": crop, "contrast": "_meta", "mean_abs": np.mean(d["oor"][ok]),
                 "mean_signed": np.std(B[ok]), "corr_with_base": np.std(D[ok]),
                 "wa_all_pct": np.std(REV[ok]), "wa_core_pct": np.std(N[ok])})
df = pd.DataFrame(rows)
df.to_csv(f"{RES}/stats.csv", index=False)
pd.set_option("display.width", 250)
print(df.round(4).to_string())
