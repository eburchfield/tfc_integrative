"""Paths for the DISES integrative-paper code. Override any of them with environment variables.

FOREB    model inputs from the Zenodo data record: fitted forests, predictor stacks, point data, SHAP, county shapes
FIGDATA  inputs prepared for the figures (Delphi Round 2 csvs, county SHAP group table)
OUT      everything this code writes (projections, results, figures, caches)
"""
import os
SRC = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(SRC)
FOREB = os.environ.get("DISES_FOREB", os.path.join(REPO, "data", "model_inputs"))
FIGDATA = os.environ.get("DISES_FIGDATA", os.path.join(REPO, "data", "figure_data"))
OUT = os.environ.get("DISES_OUT", os.path.join(REPO, "output"))
FIGS = os.path.join(OUT, "figs")
RES = os.path.join(OUT, "results")
for _d in ("projections", "projections_extra", "georgia", "states", "cache", "circularity", "aoa", "previews"):
    os.makedirs(os.path.join(OUT, _d), exist_ok=True)
for _d in (FIGS, RES, os.path.join(RES, "circularity"), os.path.join(RES, "aoa"), os.path.join(RES, "fg")):
    os.makedirs(_d, exist_ok=True)
