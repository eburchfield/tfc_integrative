# Human systems rival climate in shaping where US crops will be grown: code and data

Code and processed data for Burchfield, Rissing, Jackson-Smith, Basche, Rathore, McWherter, Kumar and Desai,
"Human systems rival climate in shaping where US crops will be grown" (submitted to *Earth's Future*).
NSF Dynamics of Integrated Socio-Environmental Systems award #2307271, "Thriving Future Cropscapes."

The analysis fits random-forest models of crop likelihood for seven crops (and six more in the SI) across 38
central and eastern US states, attributes them with SHAP, and projects them to 2041–2060 (SSP2-4.5) under three
futures: climate-only, stakeholder-informed (national Delphi expectations) and place-informed (state Delphi
expectations in Georgia, Nebraska and Ohio). Robustness checks are in the paper's SI Notes 1–8.

**Archive:** Zenodo DOI [to be added at release]. The county panels the models were trained on are archived
with the predictor data of Rathore et al. (2026). The fitted forests and the 2.5-arcminute predictor stacks are
too large to archive and are available from the authors on request; see `data/README.md` for what is where.

## Repository layout

| Folder | Contents |
|---|---|
| `data_prep/` | `compile_model_data.ipynb`: assembles the county predictors from public sources (Census of Agriculture, RMA, FSA, ERS, BLS QCEW and the others in Table S2) into the model inputs. `R/DISES_data_construction.Rmd` samples crop presence from the Cropland Data Layer and extracts climate, soil and topography. Both keep the local file paths they were run with; point them at your own copies of the source data. |
| `R/` | Model fitting and SHAP in R: sampling and training (`DISES_RF_model_training.R`, `DISES_func_new_sampling_model2.R`), predictor stacks and the original Delphi run (`Delphi_future_suit_M2.R`), SHAP (`DISES_SHAP1_MOD2.R`, `DISES_SHAP_calculation_hpc.R`). |
| `src/` | Python: projections, statistics and robustness checks. Paths come from `src/config.py`. |
| `figures/` | One script per paper and SI figure (Fig. 1 is HTML); `figures/README.md` maps each to its figure. |
| `delphi/` | Round 2 Delphi summaries (present value, median, quartiles, coefficient of variation, relative change) for the national panel and the Georgia, Nebraska and Ohio panels. |
| `docs/` | `paper_map.md`: which script produces each figure, table and number in the paper. |

## How the models are rerun

The forests were fit in R (`randomForest` 4.7-1.2; 500 trees, mtry = 7, node size 1). `src/rds.py` reads R's
.RDS format and `src/rfpy.py` with `src/fast.c` reproduces `predict(rf, type = "prob")` in Python, matching the R
predictions to within 3 × 10⁻⁸. `src/treeshap.c` reproduces the SHAP values. Robustness refits (SI Notes 4, 6
and 8) use scikit-learn forests matched to the R settings.

Delphi expectations enter as panel-relative changes: for each item, the Round 2 median 2050 estimate divided by
the present value shown to panelists, minus one, applied multiplicatively to each county's 2009–2018 value
(share variables capped at 1). National items apply in every county; state items in that state's counties.

## Running

```
pip install -r requirements.txt
export DISES_FOREB=/path/to/model_inputs      # training panels (Zenodo); forests and stacks on request
export DISES_FIGDATA=/path/to/delphi_and_figure_data
export DISES_OUT=/path/to/output
bash run_all.sh
```

**What runs from the archive.** The training panels are enough to refit the forests
(`R/DISES_RF_model_training.R`), recompute the SHAP attribution behind Fig. 2, and rerun the robustness refits
of SI Texts S1, S4, S6 and S8. The projection and mapping steps — Figs. 4–6, the 2050 statistics and the
area-of-applicability check — read the fitted forests and the 2.5-arcminute predictor stacks, which are not in
the archive: request them from the authors, or rebuild the stacks with `data_prep/` and
`R/DISES_data_construction.Rmd` from the public sources listed in `data/README.md`. Figs. 3 and 5 and the
panel-uncertainty run in SI Text S5 need panelist-level Delphi responses, which the IRB protocols do not permit
releasing.

`src/fast.c` and `src/treeshap.c` are compiled automatically on first use (needs `gcc`). Each step of
`run_all.sh` logs to `$DISES_OUT/logs/`; `docs/paper_map.md` lists the output behind each number in the paper.

Runtime on two cores: about 1 hour for the projections and statistics, 2–3 hours for the refits, and 3–4
hours for the area-of-applicability check. Memory: 8 GB is enough when scripts run one at a time.

## Data availability and ethics

Model inputs come from public sources listed in Table S2 and `data/README.md`; they are cited, not
redistributed. The county panels the models were trained on are archived with Rathore et al. (2026). The fitted
forests and predictor stacks are available from the authors on request and will be curated for at least five
years. Delphi data are shared as item-level summaries; panelist-level estimates and focus-group materials
cannot be released under the approved protocols. Protocols were approved by the institutional review boards of
the University of Nebraska-Lincoln, The Ohio State University, Emory University and Arizona State University.

## Licenses

Code: MIT (`LICENSE`). Data: CC BY 4.0 (`LICENSE-data.md`). Third-party inputs keep their own terms.

## Citation

See `CITATION.cff`.
