"""County |SHAP| summed by predictor category, for Fig. 2 and SI Fig. 2.
Usage: python src/shap_category_table.py CORN SOY HAY COTTON PEANUTS WHEAT SORGHUM (reads FOREB/out/model2_R/SHAP/<CROP>_shap_vals.csv,
writes FIGDATA/fig2_county_group_abs_shap.csv)."""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from config import FOREB, FIGDATA
import pandas as pd, numpy as np, sys
G=dict(Climate=["BV1_Annual_Mean_Temp","BV2_Mean_Diurnal_Range","BV4_Temp_Seasonality","BV5_MaxTemp_Warm_Month","BV6_MinTemp_Cold_Month","BV8_MeanTemp_Wet_Quart","BV9_MeanTemp_Driest_Quart","BV10_MeanTemp_Warm_Quart","BV11_MeanTemp_Cold_Quart","BV12_Annual_Precip","BV13_Precip_Wet_Month","BV14_Precip_Dry_Month","B15_CoV_Precip","B16_Precip_Wet_Quart","B17_Precip_Dry_Quart","B18_Precip_Warm_Quart","B19_Precip_Cold_Quart"],
Soil=["T_BULK_DEN","T_CEC_CLAY","T_CLAY","T_GRAVEL","T_SAND","T_SILT"],Topography=["NA_1KM_SLOPE","NA_1KM"],
Management=["cover_crop_acre","till_new_conservational_acre","tile_drain_acres","CRP_ACRE","EQIP_ACRE","live_cattle_inventory","organic_number_operations"],
Inputs=["fert_exp_usd","chem_exp_usd","N_manure_kg","P_manure_kg","N_fert_kg","P_fert_kg","labor_number","machinery_usd","Cao_fert_N","Cao_fert_P"],
Economics=["animal_sales_usd","rented_fract","no_ops_sales_lt_10k","directsales_retail","sales_usd_gt_500k","ag_land_value_usd","PRICE","crop_insurance_acre_rma"],
Demographics=["RUCC_2013","Producer_female","Producer_nonwhite","median_farmsize","Producer_age_le_35","producer_exp_lt_10"],
Infrastructure=["mean_est_std","biofuel_corn_percent_used","biofuel_soy_percent_used"])
D=f'{FOREB}/out/model2_R/SHAP/'

def build(crops):
    rows=[]
    for crop in crops:
        df=pd.read_csv(D+f'{crop}_shap_vals.csv')
        irr=["IRRIG_MIRCA","KONAR_GWW","KONAR_SWW"] if "IRRIG_MIRCA" in df.columns else ["IRRIG_std","KONAR_GWW","KONAR_SWW"]
        g=dict(G); g['Irrigation']=irr
        for k,v in g.items():
            cols=[c for c in v if c in df.columns]
            a=df[cols].abs().sum(axis=1)
            for geo,val in zip(df.GEOID,a): rows.append((geo,crop,k,val))
    return pd.DataFrame(rows,columns=['GEOID','crop','group','abs_shap'])

if __name__ == "__main__":
    build(sys.argv[1:]).to_csv(f'{FIGDATA}/fig2_county_group_abs_shap.csv',index=False)
