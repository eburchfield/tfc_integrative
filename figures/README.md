# Figures

Every figure in the paper and SI is drawn by one script in this folder. Scripts import shared code from `../src`
and read paths from `src/config.py` (`DISES_FOREB`, `DISES_FIGDATA`, `DISES_OUT`). Images are written to
`$DISES_OUT/figs/`, any tables behind them to `$DISES_OUT/results/`. Run from the repository root after
`run_all.sh` has produced the projections (or run `run_all.sh`, which calls these at the end).

| Figure | Script | Needs first |
|---|---|---|
| Fig. 1 Research process | `fig1_research_process.html` (open in a browser; exported to PNG) | — |
| Fig. 2 SHAP shares, seven crops | `fig2_shap_shares.py` | `src/shap_category_table.py` (county SHAP by category) |
| Fig. 3 National Delphi | `fig3_national_delphi.py` | `src/trend.py` (historical trend markers) |
| Fig. 4 Change in likelihood, 2050 | `fig4_change_maps.py` | `src/experiments.py` |
| Fig. 5 State Delphi (GA, NE, OH) | `fig5_state_delphi.py GA` (and `NE`, `OH`) | — |
| Fig. 6 Georgia place-informed | `fig6_georgia_place_informed.py` | `src/georgia_place_informed.py` |
| SI Fig. 1 Core and margin | `si_fig1_core_margin.py` | `src/experiments.py`, `src/stats.py` |
| SI Fig. 2 SHAP shares, all crops | `si_fig2_shap_all_crops.py` | `src/shap_category_table.py` |
| SI Fig. 3 Additional crops | `si_fig3_additional_crops.py` | `src/experiments.py` for OATS, BARLEY, RYE, PECANS, FRUITVEG |
| SI Fig. 4 Three ways to project human predictors | `si_fig4_three_projections.py` | `src/experiments.py`, `src/trend.py` |
| SI Fig. 5 Inputs compared | `si_fig5_inputs.py` | `src/trend.py` |
| SI Fig. 6 Nebraska and Ohio Delphi panels | `si_fig_state_delphi_NE_OH.py` (after `fig5_state_delphi.py NE` and `OH`) | — |
| SI Figs. 7–8 Place-informed projections, Nebraska and Ohio | `si_fig_state_place_informed.py NE` / `OH` | `src/state_rerun.py` |
| SI Fig. 9 Change maps within the area of applicability | `AOA=1 python figures/fig4_change_maps.py` | `src/aoa.py`, `src/aoa_summary.py` |
