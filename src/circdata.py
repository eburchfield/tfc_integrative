"""Load LR's Model 2 point-level modelling data (out/model2_R/hprob/<CROP>_pt_AG.RDS), recover each point's
county (GEOID) by point-in-polygon after inverting EPSG:5070, and attach LR's train/test county split
(out/model2_R/rf/<CROP>_ETC_AG.RDS, TRAIN_CTY). Cached to {OUT}/circularity/data_<CROP>.npz."""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
import sys, os, numpy as np
from rds import read_rds
import geo
from matplotlib.path import Path
U = f"{FOREB}/"

def albers_inv(x, y):
    a = 6378137.0; f = 1 / 298.257222101; e2 = 2 * f - f * f; e = np.sqrt(e2)
    p0, p1, p2, l0 = np.radians([23.0, 29.5, 45.5, -96.0])
    m = lambda p: np.cos(p) / np.sqrt(1 - e2 * np.sin(p) ** 2)
    q = lambda p: (1 - e2) * (np.sin(p) / (1 - e2 * np.sin(p) ** 2) - (1 / (2 * e)) * np.log((1 - e * np.sin(p)) / (1 + e * np.sin(p))))
    m1, m2, q0, q1, q2 = m(p1), m(p2), q(p0), q(p1), q(p2)
    n = (m1 ** 2 - m2 ** 2) / (q2 - q1); C = m1 ** 2 + n * q1; r0 = a * np.sqrt(C - n * q0) / n
    rho = np.sqrt(x ** 2 + (r0 - y) ** 2); th = np.arctan2(x, r0 - y)
    qq = (C - (rho * n / a) ** 2) / n
    phi = np.arcsin(qq / 2)
    for _ in range(15):
        s = np.sin(phi)
        phi = phi + (1 - e2 * s ** 2) ** 2 / (2 * np.cos(phi)) * (qq / (1 - e2) - s / (1 - e2 * s ** 2) + (1 / (2 * e)) * np.log((1 - e * s) / (1 + e * s)))
    return np.degrees(l0 + th / n), np.degrees(phi)

def load(crop):
    cache = f"{OUT}/circularity/data_{crop}.npz"
    if os.path.exists(cache):
        z = np.load(cache, allow_pickle=True); return {k: z[k] for k in z.files}
    o = read_rds(U + f"out/model2_R/hprob/{crop}_pt_AG.RDS")
    names = o.names()
    cols = [n for n in names if n not in ("AP", "geometry", "PROB")]
    X = np.column_stack([np.asarray(o[n].value if hasattr(o[n], "value") else o[n], dtype=np.float64) for n in cols])
    y = (np.asarray(o["AP"].value) == 2).astype(np.int8)          # factor levels '0','1' -> codes 1,2
    xy = np.array([g.value for g in o["geometry"].value], dtype=np.float64)
    lon, lat = albers_inv(xy[:, 0], xy[:, 1])
    recs = geo.read_dbf(U + "data/county.dbf"); shp = geo.read_shp(U + "data/county.shp")
    geoid = np.full(len(lon), "", dtype=object); pts = np.c_[lon, lat]
    for r, parts in zip(recs, shp):
        gid = r.get("GEOID") or (r.get("STATEFP", "") + r.get("COUNTYFP", ""))
        for pt in parts:
            x0, y0 = pt.min(0); x1, y1 = pt.max(0)
            cand = np.where((lon >= x0) & (lon <= x1) & (lat >= y0) & (lat <= y1) & (geoid == ""))[0]
            if len(cand): geoid[cand[Path(pt).contains_points(pts[cand])]] = gid
    e = read_rds(U + f"out/model2_R/rf/{crop}_ETC_AG.RDS")
    train_cty = np.asarray(getattr(e["TRAIN_CTY"], "value", e["TRAIN_CTY"]), dtype=object)
    d = dict(X=X, y=y, cols=np.array(cols), geoid=geoid.astype(str), lon=lon, lat=lat, train_cty=train_cty.astype(str),
             prob_lr=np.asarray(getattr(o["PROB"], "value", o["PROB"]), dtype=np.float64))
    np.savez_compressed(cache, **d); return d

if __name__ == "__main__":
    for c in sys.argv[1:]:
        d = load(c); g = d["geoid"]
        print(c, d["X"].shape, "presence share", d["y"].mean().round(3), "unassigned", (g == "").mean().round(4),
              "train share", np.isin(g, d["train_cty"]).mean().round(3), "counties", len(np.unique(g)), flush=True)
