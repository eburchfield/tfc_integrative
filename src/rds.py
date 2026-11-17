"""Minimal reader for R .RDS files (XDR, serialization v2/v3), enough for
randomForest objects. Returns nested Python structures:
  vectors -> numpy arrays (with .attrs dict via RObj wrapper)
  lists   -> RObj(kind='list', value=[...], attrs={...})
Environments, closures and language objects are parsed but kept opaque.
"""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, FIGDATA, OUT, FIGS, RES, SRC
import gzip, bz2, lzma, struct
import numpy as np

class RObj:
    __slots__ = ("kind", "value", "attrs")
    def __init__(self, kind, value, attrs=None):
        self.kind, self.value, self.attrs = kind, value, attrs or {}
    def __repr__(self):
        return f"RObj({self.kind}, attrs={list(self.attrs)})"
    def names(self):
        n = self.attrs.get("names")
        return list(n.value) if n is not None else None
    def __getitem__(self, k):
        if isinstance(k, str):
            return self.value[self.names().index(k)]
        return self.value[k]

NA_INT = -2147483648

class Reader:
    def __init__(self, data):
        self.d = memoryview(data); self.p = 0; self.refs = []
    def int(self):
        v = struct.unpack_from(">i", self.d, self.p)[0]; self.p += 4; return v
    def ints(self, n):
        a = np.frombuffer(self.d, dtype=">i4", count=n, offset=self.p); self.p += 4 * n; return a
    def reals(self, n):
        a = np.frombuffer(self.d, dtype=">f8", count=n, offset=self.p); self.p += 8 * n; return a
    def length(self):
        n = self.int()
        if n == -1:
            hi, lo = self.int(), self.int(); n = (hi << 32) + lo
        return n
    def string(self):
        n = self.int()
        if n == -1: return None
        s = bytes(self.d[self.p:self.p + n]).decode("utf-8", "replace"); self.p += n; return s

    def header(self):
        fmt = bytes(self.d[:2]); assert fmt == b"X\n", fmt
        self.p = 2
        ver = self.int(); self.int(); self.int()
        if ver == 3:
            n = self.int(); self.p += n  # native encoding
    def item(self):
        flags = self.int()
        t = flags & 0xFF
        has_attr = bool(flags & (1 << 9)); has_tag = bool(flags & (1 << 10))
        lev = flags >> 12
        if t == 254: return None                      # NILVALUE
        if t in (253, 242, 241, 251, 252, 250, 249, 248, 247):  # special envs / markers
            return RObj("special", t)
        if t == 255:                                  # REFSXP
            idx = flags >> 8
            if idx == 0: idx = self.int()
            return self.refs[idx - 1]
        if t == 1:                                    # SYMSXP
            s = self.item(); obj = RObj("sym", s); self.refs.append(obj); return obj
        if t == 9:                                    # CHARSXP
            n = self.int()
            if n == -1: return None
            s = bytes(self.d[self.p:self.p + n]).decode("utf-8", "replace"); self.p += n; return s
        if t in (2, 6, 17, 5):                        # LISTSXP, LANGSXP, DOTSXP, PROMSXP: pairlist cells
            attrs = self.item() if has_attr else None
            tag = self.item() if has_tag else None
            car = self.item(); cdr = self.item()
            cell = [(tag.value if isinstance(tag, RObj) and tag.kind == "sym" else tag, car)]
            if isinstance(cdr, RObj) and cdr.kind in ("pairlist", "lang"):
                cell += cdr.value
            return RObj("lang" if t == 6 else "pairlist", cell)
        if t == 4:                                    # ENVSXP
            locked = self.int(); obj = RObj("env", None); self.refs.append(obj)
            enclos = self.item(); frame = self.item(); hashtab = self.item(); attrs = self.item()
            obj.value = {"frame": frame, "hashtab": hashtab}; return obj
        if t in (3,):                                 # CLOSXP
            attrs = self.item() if has_attr else None
            env = self.item() if has_tag else None
            formals = self.item(); body = self.item(); return RObj("closure", None)
        if t in (7, 8):                               # SPECIALSXP/BUILTINSXP
            n = self.int(); self.p += n; return RObj("builtin", None)
        if t == 21:                                   # BCODESXP
            nreps = self.int(); reps = [None] * max(nreps, 1)
            self.bc1(reps); return RObj("bytecode", None)
        if t == 22:                                   # EXTPTRSXP
            obj = RObj("extptr", None); self.refs.append(obj); self.item(); self.item()
            if has_attr: self.item()
            return obj
        if t == 23:                                   # WEAKREFSXP
            obj = RObj("weakref", None); self.refs.append(obj)
            if has_attr: self.item()
            return obj
        if t in (10, 13, 14, 15, 16, 19, 20, 24):
            n = self.length()
            if t in (10, 13): v = self.ints(n)
            elif t == 14: v = self.reals(n)
            elif t == 15: v = self.reals(2 * n)
            elif t == 16: v = [self.item() for _ in range(n)]
            elif t in (19, 20): v = [self.item() for _ in range(n)]
            elif t == 24: v = bytes(self.d[self.p:self.p + n]); self.p += n
            attrs = self.item() if has_attr else None
            ad = {}
            if isinstance(attrs, RObj):
                for k, val in attrs.value: ad[k] = val
            kind = {10: "lgl", 13: "int", 14: "real", 15: "cplx", 16: "str", 19: "list", 20: "expr", 24: "raw"}[t]
            if kind in ("int", "lgl", "real", "str") and not ad:
                return v if kind != "str" else RObj("str", v)
            return RObj(kind, v, ad)
        if t == 25:                                   # S4
            attrs = self.item() if has_attr else None
            return RObj("s4", None)
        raise ValueError(f"unknown SEXP type {t} at {self.p}")

def _bc1(self, reps):
    self.item()                       # code vector
    n = self.int()
    for _ in range(n):
        ty = self.int()
        if ty == 21: self.bc1(reps)
        elif ty in (6, 2, 243, 244, 240, 239): self.bclang(ty, reps)
        else: self.item()
def _bclang(self, ty, reps):
    if ty == 243: return reps[self.int()]
    if ty in (244, 6, 2, 240, 239):
        pos = -1
        if ty == 244: pos = self.int(); ty = self.int()
        if ty in (240, 239): self.item()
        self.item()                   # tag
        self.bclang(self.int(), reps); self.bclang(self.int(), reps)
        o = RObj("lang", None)
        if pos >= 0: reps[pos] = o
        return o
    return self.item()
Reader.bc1 = _bc1; Reader.bclang = _bclang

def read_rds(path):
    raw = open(path, "rb").read()
    if raw[:2] == b"\x1f\x8b": raw = gzip.decompress(raw)
    elif raw[:3] == b"BZh": raw = bz2.decompress(raw)
    elif raw[:6] == b"\xfd7zXZ\x00": raw = lzma.decompress(raw)
    r = Reader(raw); r.header(); return r.item()
