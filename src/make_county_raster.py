"""County index raster on the 2.5-arcminute projection grid (row order of county.shp), used to assign
pixels to states and counties. Writes OUT/county_raster.npy (-1 outside all counties)."""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
from config import FOREB, OUT
import numpy as np, geo
from matplotlib.path import Path
f, e, s = geo.read_tif(f"{FOREB}/out/fpredictors/ssp245_2041-2060.tif")   # any layer on the projection grid
H, W = f.shape[:2]
lon = e[0] + s[0] * (np.arange(W) + 0.5); lat = e[3] - s[1] * (np.arange(H) + 0.5)
LON, LAT = np.meshgrid(lon, lat)
shp = geo.read_shp(f"{FOREB}/data/county.shp")
cid = np.full((H, W), -1)
for i, parts in enumerate(shp):
    for pt in parts:
        x0, y0 = pt.min(0); x1, y1 = pt.max(0)
        if x1 < e[0] or x0 > e[1] or y1 < e[2] or y0 > e[3]: continue
        c0 = max(int((x0 - e[0]) / s[0]), 0); c1 = min(int((x1 - e[0]) / s[0]) + 1, W)
        r0 = max(int((e[3] - y1) / s[1]), 0); r1 = min(int((e[3] - y0) / s[1]) + 1, H)
        if c1 <= c0 or r1 <= r0: continue
        sub = np.c_[LON[r0:r1, c0:c1].ravel(), LAT[r0:r1, c0:c1].ravel()]
        inside = Path(pt).contains_points(sub).reshape(r1 - r0, c1 - c0)
        blk = cid[r0:r1, c0:c1]; blk[inside] = i
np.save(f"{OUT}/county_raster.npy", cid)
print("county raster", cid.shape, "pixels in a county:", int((cid >= 0).sum()))
