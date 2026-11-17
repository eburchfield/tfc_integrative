"""State FIPS code for every pixel of the projection grid, from the county raster (make_county_raster.py)
and county.dbf. Returns a flat array of 2-character FIPS strings ('' outside all counties)."""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, OUT
import numpy as np, geo

def state_grid():
    cid = np.load(f"{OUT}/county_raster.npy").ravel()
    recs = geo.read_dbf(f"{FOREB}/data/county.dbf")
    fips = np.array([str(r.get("STATEFP", r.get("STATE_FIPS", ""))).zfill(2) for r in recs] + [""])
    return fips[np.where(cid >= 0, cid, len(recs))]
