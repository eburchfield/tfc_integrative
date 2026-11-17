#!/usr/bin/env bash
# Reproduce every projection, statistic and figure in the paper and SI.
# Set DISES_FOREB, DISES_FIGDATA and DISES_OUT first (see README). Steps run one at a time so 8 GB of memory is enough.
# Each step logs to $DISES_OUT/logs/<step>.txt; a failed step is reported and the rest continue.
set -u
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"
: "${DISES_OUT:=$ROOT/output}"; export DISES_OUT
mkdir -p "$DISES_OUT/logs"
MAIN="SOY CORN HAY COTTON PEANUTS WHEAT SORGHUM"
EXTRA="OATS FRUITVEG BARLEY RYE PECANS"
# RESUME=1 skips steps that already finished (logs/<step>.done), so an interrupted run can pick up where it stopped.
r(){ n=$1; shift
  if [ "${RESUME:-0}" = 1 ] && [ -f "$DISES_OUT/logs/$n.done" ]; then return; fi
  echo "$(date +%T) $n"
  if "$@" > "$DISES_OUT/logs/$n.txt" 2>&1; then touch "$DISES_OUT/logs/$n.done"; else echo "  FAILED: $n (see logs/$n.txt)"; fi; }

# 1. Historical trends (linear census trend comparison, SI Note 1) and the projections (Fig. 4)
r trend python3 src/trend.py
for c in $MAIN $EXTRA; do r "proj_$c" python3 src/experiments.py "$c"; done

# 2. Statistics behind the Results, SI Notes 1-2 and the additional crops
r stats python3 src/stats.py
r stats_rel python3 src/stats_rel.py
r stats_ins python3 src/stats_ins.py

# 3. Place-informed projections: Georgia (Fig. 6), Nebraska and Ohio (SI Note 3)
r county_raster python3 src/make_county_raster.py
r georgia python3 src/georgia_place_informed.py
r states python3 src/state_rerun.py GA,NE,OH $MAIN
r state_stats python3 src/state_stats.py
r state_drivers_NE python3 src/state_drivers.py NE CORN SOY

# 4. Which national items drive the human effect (SI Note 7)
for c in $MAIN; do r "natattr_$c" python3 src/national_attr.py "$c"; done
r natstats python3 src/national_stats.py $MAIN

# 5. Partial bridge and Ohio irrigation sensitivity (SI Notes 1 and 3)
r bridge_factors python3 src/bridge_factors.py
for c in CORN SOY WHEAT SORGHUM HAY OATS FRUITVEG; do r "ohio_$c" python3 src/ohio_rerun.py "$c"; done
for c in CORN SOY WHEAT SORGHUM HAY OATS FRUITVEG; do r "bridge_$c" python3 src/partial_bridge.py "$c"; done
r bridge_summary python3 src/partial_bridge_summary.py
r trace_numbers python3 src/trace_numbers.py   # small SI numbers (caps, Ohio irrigation, SI Table 2)

# 6. Refits: circularity (SI Note 4), model and panel uncertainty (SI Note 8), held-out accuracy (SI Table 2)
for c in $MAIN; do r "circ_$c" python3 src/circ_run.py "$c"; done
r circ_summary python3 src/summarize.py
for c in $MAIN; do r "refitproj_$c" python3 src/refit_projections.py "$c"; done
for c in SOY CORN HAY WHEAT SORGHUM; do r "refitstate_$c" python3 src/refit_states.py "$c"; done
for c in $MAIN; do r "unc_$c" python3 src/uncertainty.py "$c"; done
for c in $MAIN; do r "attr_$c" python3 src/attribution_checks.py "$c"; done

# 7. Focus-group variables (SI Note 6) and area of applicability (SI Note 5, SI Fig. 6)
for c in $MAIN; do r "fg_$c" python3 src/fg_ablation.py "$c"; done
r fg_summary python3 src/fg_summary.py
for c in $MAIN; do r "aoa_$c" python3 src/aoa.py "$c"; done
r aoa_summary python3 src/aoa_summary.py

# 8. Figures (Fig. 1 is figures/fig1_research_process.html)
r shap_table python3 src/shap_category_table.py $MAIN
r fig2 python3 figures/fig2_shap_shares.py
r fig3 python3 figures/fig3_national_delphi.py
r fig4 python3 figures/fig4_change_maps.py
for s in GA NE OH; do r "fig5_$s" python3 figures/fig5_state_delphi.py "$s"; done
r fig6 python3 figures/fig6_georgia_place_informed.py
r si_fig1 python3 figures/si_fig1_core_margin.py
r si_fig2 python3 figures/si_fig2_shap_all_crops.py
r si_fig3 python3 figures/si_fig3_additional_crops.py
r si_fig4 python3 figures/si_fig4_three_projections.py
r si_fig5 python3 figures/si_fig5_inputs.py
r si_fig6 python3 figures/si_fig_state_delphi_NE_OH.py
for s in NE OH; do r "si_fig_place_$s" python3 figures/si_fig_state_place_informed.py "$s"; done
r si_fig9 env AOA=1 python3 figures/fig4_change_maps.py
echo "$(date +%T) done"
