"""Load a randomForest classifier from .RDS and predict P(class '1') in numpy,
matching predict(type='prob') in R (fraction of trees voting for class 2)."""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
import sys, threading, re, pickle, os
import numpy as np
sys.setrecursionlimit(500000)
threading.stack_size(1024 * 1024 * 1024)
from rds import read_rds, RObj
from geo import read_tif

def _arr(o):
    return np.asarray(o.value if isinstance(o, RObj) else o)

def load_forest(path, cache_dir=f"{OUT}/cache"):
    os.makedirs(cache_dir, exist_ok=True)
    cp = os.path.join(cache_dir, os.path.basename(path) + ".pkl")
    if os.path.exists(cp):
        return pickle.load(open(cp, "rb"))
    out = {}
    def run():
        rf = read_rds(path); f = rf["forest"]
        nr = int(_arr(f["nrnodes"])[0]); nt = int(_arr(f["ntree"])[0])
        F = dict(
            status=_arr(f["nodestatus"]).reshape(nt, nr),
            var=_arr(f["bestvar"]).reshape(nt, nr) - 1,
            left=_arr(f["treemap"]).reshape(nt, 2, nr)[:, 0, :] - 1,
            right=_arr(f["treemap"]).reshape(nt, 2, nr)[:, 1, :] - 1,
            pred=_arr(f["nodepred"]).reshape(nt, nr),
            split=_arr(f["xbestsplit"]).reshape(nt, nr),
            ncat=_arr(f["ncat"]), names=f["ncat"].names(),
            classes=list(rf["classes"].value))
        out["F"] = F
    th = threading.Thread(target=run); th.start(); th.join()
    F = out["F"]
    assert (F["ncat"] == 1).all(), "categorical predictors not supported"
    pickle.dump(F, open(cp, "wb"))
    return F

def predict_prob(F, X):
    """X: (n, p) float array in F['names'] order. Returns fraction of trees voting class index 2."""
    n = X.shape[0]; nt = F["status"].shape[0]
    votes = np.zeros(n, np.int32)
    target = F["classes"].index("1") + 1
    rows = np.arange(n)
    for t in range(nt):
        st, var, L, R, sp, pr = (F[k][t] for k in ("status", "var", "left", "right", "split", "pred"))
        node = np.zeros(n, np.int64)
        active = st[node] != -1
        while active.any():
            idx = np.nonzero(active)[0]; nd = node[idx]
            go_left = X[idx, var[nd]] <= sp[nd]
            node[idx] = np.where(go_left, L[nd], R[nd])
            active[idx] = st[node[idx]] != -1
        votes += (pr[node] == target)
    return votes / nt

def band_names(path):
    import tifffile
    md = tifffile.TiffFile(path).pages[0].tags["GDAL_METADATA"].value
    d = dict((int(s), n) for s, n in re.findall(r'<Item name="DESCRIPTION" sample="(\d+)" role="description">([^<]+)</Item>', md))
    return [d[i] for i in range(len(d))]

def read_stack(path):
    a, ext, sc = read_tif(path)
    return a, band_names(path)

import ctypes
if not os.path.exists(f"{SRC}/fast.so"):   # compile the C helpers on first use
    import subprocess
    subprocess.run(["gcc", "-O3", "-shared", "-fPIC", "-o", f"{SRC}/fast.so", f"{SRC}/fast.c"], check=True)
_lib = ctypes.CDLL(f"{SRC}/fast.so")
_lib.lzw_decode.restype = ctypes.c_long

def lzw_fast(raw, outcap):
    out = np.empty(outcap, np.uint8)
    n = _lib.lzw_decode(ctypes.c_char_p(raw), ctypes.c_long(len(raw)),
                        out.ctypes.data_as(ctypes.c_void_p), ctypes.c_long(outcap))
    return out[:n].tobytes()

def read_tif(path):
    import tifffile
    t = tifffile.TiffFile(path); p = t.pages[0]
    w, h, spp = p.imagewidth, p.imagelength, p.samplesperpixel
    offs = p.tags['StripOffsets'].value; cnts = p.tags['StripByteCounts'].value
    rps = p.tags['RowsPerStrip'].value
    fh = t.filehandle; buf = bytearray()
    bps = p.bitspersample if isinstance(p.bitspersample, int) else p.bitspersample[0]
    nbytes = bps // 8
    for o, c in zip(offs, cnts):
        fh.seek(o); raw = fh.read(c)
        buf += lzw_fast(raw, rps * w * spp * nbytes) if p.compression == 5 else raw
    dt = {4: '<f4', 8: '<f8'}[nbytes]
    a = np.frombuffer(bytes(buf[:w*h*spp*nbytes]), dtype=dt).reshape(h, w, spp)
    sc = p.tags['ModelPixelScaleTag'].value; tp = p.tags['ModelTiepointTag'].value
    return a, (tp[3], tp[3] + w*sc[0], tp[4] - h*sc[1], tp[4]), sc

def predict_prob(F, X):
    X = np.ascontiguousarray(X, dtype=np.float64); n, p = X.shape
    votes = np.zeros(n, np.int32)
    c = lambda a, t: np.ascontiguousarray(a, dtype=t)
    keep = [c(F[k], np.int32) for k in ("status", "var", "left", "right", "pred")]
    sp = c(F["split"], np.float64)
    nt, nr = F["status"].shape
    P = ctypes.c_void_p
    _lib.rf_votes(*[k.ctypes.data_as(P) for k in keep], sp.ctypes.data_as(P), ctypes.c_int(nt), ctypes.c_int(nr),
                  X.ctypes.data_as(P), ctypes.c_long(n), ctypes.c_int(p),
                  ctypes.c_int(F["classes"].index("1") + 1), votes.ctypes.data_as(P))
    return votes / nt
