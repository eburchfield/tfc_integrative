# Data

## In the Zenodo record (`DISES_FOREB`)

Archived with the predictor data of Rathore et al. (2026). This is what the models were trained on, so the
forests can be refit and the attribution recomputed from the archive alone.

| Path | Contents |
|---|---|
| `out/model2_R/hprob/<CROP>_pt_AG.RDS` | Modelling points: crop presence/absence and predictor values, for the 13 crops. These are the panels the forests were trained on. |
| `out/model2_R/rf/<CROP>_ETC_AG.RDS` | Training and test county split for each crop, so the held-out metrics in Table S1 can be reproduced on the same split. |
| `fig2_county_group_abs_shap.csv` | County SHAP shares by predictor category, the input to Fig. 2. |

## Available from the authors on request

Too large to archive; curated for at least five years. Without these, the projection and mapping steps do not
run — see "What runs from the archive" in the top-level README.

| Path | Contents | Size |
|---|---|---|
| `out/model2_R/rf/<CROP>_RF_AG.RDS` | Fitted random forests (revised model), one per crop. `CORN_RF_AG_slim.RDS` is a slimmed copy that keeps only what prediction needs. | ~2.9 GB (13 crops) |
| `out/fpredictors/delphi_ras_national_only/ssp245_<CROP>_2041_2060_delphi_national_AG.tif` | Predictor stack on the 2.5-arcminute grid for each crop. Human-controlled layers hold the original model run's Delphi values; the code recovers the 2009–2018 values from them before applying any scenario. | ~660 MB (13 crops, SSP2-4.5) |
| `out/fpredictors/ssp245_2021-2040.tif`, `ssp245_2041-2060.tif` | WorldClim 2.1 bioclimatic variables, mean of IPSL-CM6A-LR, MIROC-ES2L and MRI-ESM2-0, SSP2-4.5. | ~34 MB |
| `out/model2_R/SHAP/<CROP>_shap_vals.csv` | County SHAP values behind Figure S1 (13 crops). | |
| `data/county.shp`, `data/states.shp` | County and state boundaries. | |
| `data/quantitative_data/data_input_RF_2/` | County predictor tables (2009–2018 and census years), used for trends and the partial bridge. | |

The stacks and the climate layers can also be rebuilt from the public sources below with `data_prep/` and
`R/DISES_data_construction.Rmd`.

## In `DISES_FIGDATA`

| File | Contents |
|---|---|
| `fig3_national_delphi_round2.csv`, `fig5a_state_delphi_round2.csv` | Round 2 Delphi estimates by panelist. **Not shared:** the IRB protocols do not permit releasing individual responses. Only Figs. 3 and 5, Figure S3 (panelist points) and the panel-uncertainty runs in Text S5 (`src/uncertainty.py`) need them; every other projection uses the medians in `data/delphi/`. |
| `fig2_county_group_abs_shap.csv` | County SHAP shares by predictor category (Fig. 2). Archived in the Zenodo record above. |

## In this repository (`data/delphi/`)

| File | Contents |
|---|---|
| `national_round2_medians.csv` | National Round 2 panel: present value shown to panelists, median 2050 estimate, number of panelists and relative change, by item. |
| `state_round2_medians.csv` | The same for the Georgia, Nebraska and Ohio panels. `src/state_rerun_pct.py` reads this file. |

Focus-group and key-informant transcripts are not shared (IRB).

## Public sources

Crop presence: USDA NASS Cropland Data Layer, 2009–2018. Climate: WorldClim 2.1 (Fick & Hijmans 2017). Soils:
Harmonized World Soil Database v1.2 (FAO 2012). Topography: National Elevation Dataset (Gesch 2007).
Human-controlled predictors: USDA Census of Agriculture and Quick Stats; USDA RMA Summary of Business; USDA FSA
Conservation Reserve Program statistics; USDA ERS Rural-Urban Continuum Codes; BLS Quarterly Census of
Employment and Wages; MIRCA-OS (Kebede et al. 2025); MIRAD (Shrestha et al. 2021); Ruess et al. (2024)
irrigation withdrawals; Falcone (2021) and Cao et al. (2018, 2024) fertilizer; Limb et al. (2024) biofuel
shares; Basche et al. (2020) EQIP. Definitions, years and denominators are in the paper's Table S2.
