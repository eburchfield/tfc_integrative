import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
import ctypes, numpy as np
if not _os.path.exists(f"{SRC}/treeshap.so"):   # compile on first use
    import subprocess
    subprocess.run(["gcc", "-O3", "-shared", "-fPIC", "-o", f"{SRC}/treeshap.so", f"{SRC}/treeshap.c"], check=True)
_lib = ctypes.CDLL(f"{SRC}/treeshap.so")
_P = np.ctypeslib.ndpointer
_lib.tree_shap.argtypes = [ctypes.c_int, _P(np.int32), _P(np.int32), _P(np.int32), _P(np.float64), _P(np.float64),
                           _P(np.float64), _P(np.float64), ctypes.c_int, ctypes.c_int, _P(np.float64), ctypes.c_double]
def forest_shap(rf, X):
    """Exact TreeSHAP for P(class 1) of a fitted sklearn RandomForestClassifier. Returns phi (n x p), base."""
    X = np.ascontiguousarray(X.astype(np.float32).astype(np.float64)); n, p = X.shape
    phi = np.zeros((n, p)); base = 0.0; k = 1.0 / len(rf.estimators_)
    for est in rf.estimators_:
        t = est.tree_
        v = t.value[:, 0, :]; v = v[:, 1] / v.sum(1)
        _lib.tree_shap(int(t.max_depth), t.children_left.astype(np.int32), t.children_right.astype(np.int32),
                       np.maximum(t.feature, 0).astype(np.int32), t.threshold.astype(np.float64), np.ascontiguousarray(v),
                       t.weighted_n_node_samples.astype(np.float64), X, n, p, phi, k)
        base += k * v[0]
    return phi, base
