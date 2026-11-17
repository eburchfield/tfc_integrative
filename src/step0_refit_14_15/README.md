# Step 0 checks for the integrative revision (Oct 19, 2026)

*Made by Claude for Emily Burchfield. P3, DISES integrative paper. The manuscript was not edited. Results: `../../notes/2026-10-19_step0_refit_and_conversion_checks.md`.*

## What each file does
| File | Does |
|---|---|
| `circ_run_v2.py` | SI Note 4 refit, extended. Same data, county split, forest settings and seeds as `DISES_integrative/figs/analysis/circularity/circ_run.py`, so FULL and EXCL12 reproduce the published table. Adds EXCL14 (adds the two farm-structure predictors to the location-tracking set), EXCL15 (also adds crop price), a 14-predictor random-drop control, and state folds for EXCL14. |
| `summarize_v2.py` | One row per crop: `tables/2026-10-19_SI_note4_refit_extended.csv` |
| `circdata.py`, `tshap.py`, `treeshap.c` | Copied from `figs/analysis/circularity/`. Only the paths were changed (they point at Claude's workspace; edit the paths at the top to rerun elsewhere). Compile with `gcc -O3 -shared -fPIC -o treeshap.so treeshap.c`. |
| `national_abs.py` | National cap check, plus the two structure items applied as percentage-point changes (absolute) instead of relative ones. Needs the pipeline in `DISES/claude_output/code/DISES_integrative_code/src/` (config, rfpy, rds, experiments) and the outputs of `DISES/claude_output/code/2026-10-19_national_structure_check/national_attr.py`. |
| `national_abs_stats.py` | `tables/2026-10-19_national_structure_conversion.csv` and `tables/2026-10-19_national_cap_check.csv` |

## Inputs (read only)
- `DISES_suitability/forEB/out/model2_R/hprob/<CROP>_pt_AG.RDS` (LR's point data) and `rf/<CROP>_ETC_AG.RDS` (county split)
- `DISES_suitability/forEB/out/fpredictors/` (predictor stacks); `rf/<CROP>_RF_AG.RDS` (fitted forests)
- `DISES_integrative/figs/data/fig3_national_delphi_round2.csv` (panelist-level; restricted, IRB. The medians are in data/delphi/)

## Run
```
python3 circ_run_v2.py CORN SOY COTTON PEANUTS HAY WHEAT SORGHUM   # about 30 min per crop on 2 cores
python3 summarize_v2.py
python3 national_abs.py CORN SOY COTTON PEANUTS HAY WHEAT SORGHUM  # about 1.5 min per crop
python3 national_abs_stats.py <OUT> CORN SOY COTTON PEANUTS HAY WHEAT SORGHUM
```
