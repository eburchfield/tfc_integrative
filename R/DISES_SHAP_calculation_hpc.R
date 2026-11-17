# ============================================================
# SHAP Value Calculation — Crop Likelihood

# Computes TreeSHAP values for each trained random forest model
# using county-aggregated predictor values as the background
# dataset. Run on HPC (SLURM environment).
#
# Inputs:
#   ./out/model2_R/rf/<CROP>_RF_AG.RDS      — trained RF model
#   ./out/ag_rds2/panel_ag_mirca/<CROP>_AG_MIRCA.RDS
#   ./out/county_agg_mod2_mirca/<CROP>_AGG.csv
#   ./data/lr/data_input_RF_2/ag_data_std_2012_17.csv
#   ./data/lr/Konar_GWW.RDS, Konar_SWW.RDS, Konar_GWD.RDS
#   ./data/crop_harv_acres/<crop>_acres_pivot.csv
#   ./out/random_seed_for_sampling_IRRIG_MIRCA_2.csv
#
# Outputs (per crop):
#   ./out/model2_R/SHAP/<CROP>_SHAP_AG.RDS   — treeshap object
#   ./out/model2_R/SHAP/<CROP>_shap_vals.csv — SHAP values with GEOID
# ============================================================

library(randomForest)
library(treeshap)


# setwd("/group/eburchf-g00/DISES/")   # HPC working directory
source("DISES_load.R")
source("DISES_func_new_sampling_model2.R")

treeshap_func <- function(crop) {

  print(paste("Loading data for", crop))

  coa <- clean_census("./data/quantitative_data/data_input_RF_2/data_input_RF_2/ag_data_std_2012_17.csv") %>%
    select(-GEOID)

  df <- readRDS(paste0("./out/ag_rds2/panel_ag_mirca/", crop, "_AG_MIRCA.RDS")) %>%
    na.omit()

  df$AP <- as.factor(df$TYPE)
  df$IRRIG[df$IRRIG > 0] <- 1

  # ---- Konar irrigation volumes (normalized by crop-specific harvested area) ----
  gww <- readRDS("./data/lr/Konar_GWW.RDS") %>% select(crop, GEOID)
  colnames(gww) <- c("KONAR_GWW", "GEOID")
  sww <- readRDS("./data/lr/Konar_SWW.RDS") %>% select(crop, GEOID)
  colnames(sww) <- c("KONAR_SWW", "GEOID")
  gwd <- readRDS("./data/lr/Konar_GWD.RDS") %>% select(crop, GEOID)
  colnames(gwd) <- c("KONAR_GWD", "GEOID")

  all_konar <- merge(gww, sww, by = "GEOID", all = TRUE)
  all_konar <- merge(all_konar, gwd, by = "GEOID", all = TRUE)

  tc_crp <- read.csv(paste0("./data/crop_harv_acres/", tolower(crop),
                             "_acres_pivot.csv"), check.names = FALSE)
  tc_crp$GEOID <- str_pad(tc_crp$GEOID, width = 5, side = "left", pad = "0")
  temp_yrs <- intersect(as.character(2009:2019), names(tc_crp))

  tc_crp_mean <- tc_crp %>%
    select(GEOID, all_of(temp_yrs)) %>%
    mutate(mean_crop_acres = rowMeans(across(all_of(temp_yrs)), na.rm = TRUE)) %>%
    select(GEOID, mean_crop_acres)

  all_konar <- merge(all_konar, tc_crp_mean, by = "GEOID", all.x = TRUE)
  all_konar$KONAR_GWW <- all_konar$KONAR_GWW / all_konar$mean_crop_acres
  all_konar$KONAR_GWD <- all_konar$KONAR_GWD / all_konar$mean_crop_acres
  all_konar$KONAR_SWW <- all_konar$KONAR_SWW / all_konar$mean_crop_acres
  all_konar[is.na(all_konar)] <- 0

  df <- merge(df %>% select(-c(KONAR_GWW, KONAR_GWD, KONAR_SWW)),
              all_konar, by = "GEOID", all = TRUE)
  df <- na.omit(df)

  # ---- Bioclimatic variable names ----
  biovars <- c("BV1_Annual_Mean_Temp", "BV2_Mean_Diurnal_Range", "BV3_Isothermality",
               "BV4_Temp_Seasonality", "BV5_MaxTemp_Warm_Month", "BV6_MinTemp_Cold_Month",
               "BV7_Temp_Annual_Range", "BV8_MeanTemp_Wet_Quart", "BV9_MeanTemp_Driest_Quart",
               "BV10_MeanTemp_Warm_Quart", "BV11_MeanTemp_Cold_Quart", "BV12_Annual_Precip",
               "BV13_Precip_Wet_Month", "BV14_Precip_Dry_Month", "B15_CoV_Precip",
               "B16_Precip_Wet_Quart", "B17_Precip_Dry_Quart", "B18_Precip_Warm_Quart",
               "B19_Precip_Cold_Quart")

  drop_vars <- c("BV3_Isothermality", "BV7_Temp_Annual_Range", "KONAR_GWD",
                 "irg_acre_total", "labor_usd")

  if (crop %in% c("FRUITVEG", "PASTURE")) {
    df <- df %>%
      select(GEOID, AP, all_of(biovars),
             T_BULK_DEN, T_CEC_CLAY, T_CLAY, T_GRAVEL, T_SAND, T_SILT,
             NA_1KM_SLOPE, NA_1KM, colnames(coa),
             KONAR_GWW, KONAR_GWD, KONAR_SWW, Cao_fert_N, Cao_fert_P,
             mean_est_std, IRRIG_std) %>%
      select(-any_of(drop_vars))

  } else if (crop %in% c("OATS", "PECANS")) {
    df <- df %>%
      select(GEOID, AP, all_of(biovars),
             T_BULK_DEN, T_CEC_CLAY, T_CLAY, T_GRAVEL, T_SAND, T_SILT,
             NA_1KM_SLOPE, NA_1KM, colnames(coa),
             KONAR_GWW, KONAR_GWD, KONAR_SWW, Cao_fert_N, Cao_fert_P,
             PRICE, mean_est_std, IRRIG_std) %>%
      select(-any_of(drop_vars))

  } else {
    df <- df %>%
      select(GEOID, AP, all_of(biovars),
             T_BULK_DEN, T_CEC_CLAY, T_CLAY, T_GRAVEL, T_SAND, T_SILT,
             NA_1KM_SLOPE, NA_1KM, colnames(coa),
             KONAR_GWW, KONAR_GWD, KONAR_SWW, Cao_fert_N, Cao_fert_P,
             PRICE, mean_est_std, IRRIG_MIRCA) %>%
      select(-any_of(drop_vars))
  }

  # ---- Reproduce train split (same seed as RF training) ----
  aps <- df %>%
    select(GEOID, AP) %>%
    st_drop_geometry() %>%
    group_by(GEOID) %>%
    summarize(ABS = sum(AP == 0), PRES = sum(AP == 1), ALL = n())

  random_seed_df <- read.csv("./out/random_seed_for_sampling_IRRIG_MIRCA_2.csv")
  rand_seed_crop <- random_seed_df %>% filter(Crop == crop) %>% pull(random_seed)

  set.seed(rand_seed_crop)
  train_cty <- aps %>% slice_sample(prop = 0.7) %>% pull(GEOID)

  train <- df %>% filter(GEOID %in% train_cty) %>% select(-GEOID)
  st_geometry(train) <- NULL

  df <- df %>% select(-GEOID)

  # ---- County-aggregated predictor data (background for SHAP) ----
  # SHAP is computed on county-mean predictors, not point-level data
  county_agg_org <- read.csv(paste0("./out/county_agg_mod2_mirca/", crop, "_AGG.csv"))
  county_agg_rf  <- county_agg_org[, colnames(train %>% select(-AP))]
  county_agg_rf[is.na(county_agg_rf)] <- 0

  # ---- Compute TreeSHAP values ----
  rf_ap_crop <- readRDS(paste0("./out/model2_R/rf/", crop, "_RF_AG.RDS"))

  print("Building unified model object...")
  unified <- unify(rf_ap_crop, train)

  print("Computing SHAP values...")
  shaps_crop <- treeshap(unified, county_agg_rf)

  print("Saving SHAP outputs...")
  saveRDS(shaps_crop, paste0("./out/model2_R/SHAP/", crop, "_SHAP_AG.RDS"))

  shap_vals_out <- cbind(county_agg_org["GEOID"], shaps_crop$shaps)
  write.csv(shap_vals_out,
            paste0("./out/model2_R/SHAP/", crop, "_shap_vals.csv"),
            row.names = FALSE)

  print(paste("Done:", crop))
  return(shaps_crop)
}

# ---- Run for each  crop (one job per crop on HPC) ----

# Or run sequentially:
crop_names_hist <- c("CORN", "COTTON", "FRUITVEG", "HAY", "OATS",
                     "PEANUTS", "SORGHUM", "SOY", "WHEAT")

for (crop in crop_names_hist) {
  treeshap_func(crop)
}
