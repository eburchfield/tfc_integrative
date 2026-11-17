# Where each result in the paper comes from

Paths are relative to `$DISES_OUT` (outputs) or the repository (scripts). `run_all.sh` runs everything in order.

## Main text

| Paper item | Script | Output |
|---|---|---|
| Fig. 1 research process | `figures/fig1_research_process.html` | — |
| Fig. 2 and human-controlled SHAP shares (Results, "Human-controlled predictors rival climate") | `src/shap_category_table.py`, `figures/fig2_shap_shares.py` | `figs/fig2_shap_group_shares.png` |
| Fig. 3 national Delphi; trend comparison (nitrogen +57% against +9%, etc.) | `figures/fig3_national_delphi.py`, `src/trend.py` | `figs/fig3_national_delphi.png`, `results/trend_pct.json` |
| Expected human change as a share of 20 years of climate change; mean absolute change; corn and soybean reversal; core and margin changes (Results, "Expected human change moves crop likelihood…") | `src/experiments.py`, `src/stats.py` | `results/stats.csv` (contrasts `delphi_panelrel`, `climate_2030to2050`) |
| Fig. 4 | `figures/fig4_change_maps.py` | `figs/fig4_change_maps.png` |
| Delphi vs linear trend (0.38–0.52) | `figures/si_fig4_three_projections.py` | `results/compare3_stats.csv` |
| Fig. 5 state Delphi panels | `figures/fig5_state_delphi.py GA` (NE, OH: SI Fig. 6) | `figs/fig5_state_delphi_GA.png` |
| Fig. 6 and Georgia place-informed numbers | `src/georgia_place_informed.py`, `figures/fig6_georgia_place_informed.py` | `results/georgia_place_informed_stats.csv`, `figs/fig6_georgia_place_informed.png` |
| Place-informed ratios for Georgia, Nebraska and Ohio (Results, "In place-informed projections, change concentrates…") | `src/state_rerun.py`, `src/state_stats.py` | `results/state_stats.csv` |

## Supplementary information

| SI item | Script | Output |
|---|---|---|
| SI Table 2 (held-out accuracy and AUC) | `src/attribution_checks.py` | `refits/attr_<CROP>.json` |
| SI Note 1 table and absolute-target comparison | `src/stats.py`, `src/stats_ins.py`, `figures/si_fig4_three_projections.py` | `results/stats.csv`, `results/stats_insurance.csv`, `results/compare3_stats.csv` |
| SI Note 1 partial bridge | `src/bridge_factors.py`, `src/partial_bridge.py`, `src/partial_bridge_summary.py` | `results/bridge_factors.json`, `bridge/` |
| SI Note 2 (additivity, reversed sign, tiny shift, compression) | `src/stats_rel.py` | `results/stats_relative_robustness.csv` |
| SI Note 3 (three-state table; Nebraska single inputs; Ohio irrigation sensitivity); SI Figs. 6–8 (Nebraska and Ohio Delphi panels and place-informed projections) | `src/state_rerun.py`, `src/state_stats.py`, `src/state_drivers.py`, `src/ohio_rerun.py`; `figures/si_fig_state_delphi_NE_OH.py`, `figures/si_fig_state_place_informed.py NE|OH` | `results/state_stats.csv`, `logs/state_drivers_NE.txt`, `ohio/`, `figs/si_fig_state_delphi_NE_OH.png`, `figs/si_fig_place_informed_<NE|OH>.png` |
| SI Note 4 (circularity refits, SHAP shares without location-tracking predictors; projections with refit forests) | `src/circ_run.py`, `src/summarize.py`, `src/refit_projections.py`, `src/refit_states.py`; TreeSHAP check `src/lrshap.py`, `src/compare_lr.py` | `results/circularity/`, `refits/` |
| SI Note 5 and SI Fig. 9 (area of applicability) | `src/aoa.py`, `src/aoa_summary.py`, `src/aoa_diagnose.py`; `AOA=1 figures/fig4_change_maps.py` | `results/aoa/`, `figs/si_fig6_change_maps_aoa.png` |
| SI Note 6 (focus-group variables) | `src/fg_ablation.py`, `src/fg_summary.py` | `results/fg/` |
| SI Note 7 and SI Tables 5–6 (national items one at a time; without farm-structure items) | `src/national_attr.py`, `src/national_stats.py` | `results/` (national attribution tables) |
| SI Note 8 (model and panel uncertainty) | `src/uncertainty.py` | `refits/unc_<CROP>.json` |
| SI Fig. 1 core and margin | `figures/si_fig1_core_margin.py` | `figs/si_fig1_core_margin.png` |
| SI Fig. 2 SHAP shares, all crops | `figures/si_fig2_shap_all_crops.py` | `figs/si_fig2_shap_all_crops.png` |
| SI Fig. 3 and additional-crop results | `figures/si_fig3_additional_crops.py` | `figs/si_fig3_additional_crops.png`, `results/si_additional_crops_stats.csv` |
| SI Fig. 4 three projections | `figures/si_fig4_three_projections.py` | `figs/si_fig4_three_projections.png` |
| SI Fig. 5 inputs compared | `figures/si_fig5_inputs.py` | `figs/si_fig5_inputs.png`, `results/si_fig5_inputs.csv` |

## Delphi conversion

Every national item enters as the Round 2 median 2050 estimate divided by the present value shown to panelists,
minus one (`panel_pct` in `src/experiments.py`). Cattle inventory has no direct item and takes the change in per
capita meat demand (225 → 206 lb per person, −8.4%). The soybean biodiesel share takes the corn-ethanol change.
The absolute-target sensitivity uses the original model run's stacks, which hold the median divided by the
2010–2019 mean of the same national series.

## AGU supporting-information labels (16 Nov 2026)
The paper now uses AGU labels, numbered by first citation in the main text. Older notes and file names use the earlier labels:

| AGU label | Earlier label | | AGU label | Earlier label |
| --- | --- | --- | --- | --- |
| Text S1 | SI Note 4 (circularity) | | Figure S1 | SI Fig. 2 (SHAP, 13 crops) |
| Text S2 | SI Note 6 (focus-group variables) | | Figure S2 | SI Fig. 4 (three projections) |
| Text S3 | SI Note 1 (conversions, trend, bridge) | | Figure S3 | SI Fig. 6 (NE/OH Delphi) |
| Text S4 | SI Note 2 (robustness) | | Figure S4 | SI Fig. 5 (inputs) |
| Text S5 | SI Note 8 (uncertainty) | | Figure S5 | SI Fig. 1 (core/margin) |
| Text S6 | SI Note 7 (item attribution) | | Figure S6 | SI Fig. 7 (NE place-informed) |
| Text S7 | SI Note 5 (AOA) | | Figure S7 | SI Fig. 8 (OH place-informed) |
| Text S8 | SI Note 3 (state projections) | | Figure S8 | SI Fig. 3 (additional crops) |
| Table S1 | SI Table 2 (performance) | | Figure S9 | SI Fig. 9 (AOA hatched) |
| Table S2 | SI Table 1 (predictors) | | Table S3 | SI Table 4 (interviews) |
| Table S4 | SI Table 3 (NAICS) | | Tables S5–S6 | SI Tables 5–6 |
