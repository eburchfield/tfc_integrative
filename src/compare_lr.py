"""Compare TreeSHAP on LR's own forests (lrshap_<CROP>.csv) with Fig. 2's SHAP values for the same counties."""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
import sys, numpy as np, pandas as pd
from circ_run import GROUPS, BIO
f = pd.read_csv(f"{FIGDATA}/fig2_county_group_abs_shap.csv"); f["GEOID"] = f.GEOID.astype(str).str.zfill(5)
for c in sys.argv[1:]:
    s = pd.read_csv(f"{RES}/circularity/lrshap_{c}.csv", dtype={"GEOID": str}); s["GEOID"] = s.GEOID.str.zfill(5)
    grp = pd.DataFrame({g: s[[v for v in vs if v in s]].abs().sum(1) for g, vs in GROUPS.items()}); grp["GEOID"] = s.GEOID
    fig = f[(f.crop == c) & f.GEOID.isin(s.GEOID)].pivot(index="GEOID", columns="group", values="abs_shap").loc[s.GEOID]
    mine = grp.set_index("GEOID")[fig.columns]
    r = np.corrcoef(mine.values.ravel(), fig.values.ravel())[0, 1]; md = np.abs(mine.values - fig.values).max()
    sh = lambda m: 1 - m[BIO].mean().sum() / m.mean().sum()
    print(c, f"counties {len(s)}; per-county group |SHAP| r = {r:.4f}, max abs diff = {md:.4f}; "
             f"human share: LR forest (this check) {sh(mine):.3f}, Fig. 2 file same counties {sh(fig):.3f}")
