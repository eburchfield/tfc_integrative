# ============================================================
# Random Forest Model Training — Crop Likelihood
# DISES Project, Emory University
#
# Trains a random forest classifier for each crop to estimate
# the probability of cultivation (crop likelihood) at 1km
# resolution across the Central and Eastern US.
#
# Inputs:
#   ./data/quantitative_data/data_input_RF_2/data_input_RF_2/ag_data_std_2012_17.csv
#   ./out/ag_rds2/panel_ag_mirca/<CROP>_AG_MIRCA.RDS
#   ./data/lr/Konar_GWW.RDS, Konar_SWW.RDS, Konar_GWD.RDS
#   ./data/crop_harv_acres/<crop>_acres_pivot.csv
#   ./out/random_seed_for_sampling_IRRIG_MIRCA_2.csv
#   ./out/hpredictors/epsg5070/all_ag_preds_2.tif
#   ./out/hpredictors/epsg5070/konar_norm_<CROP>.tif
#   ./out/hpredictors/epsg5070/NAICS_EST_<CROP>.tif
#   ./out/hpredictors/epsg5070/price_<CROP>.tif          (most crops)
#   ./data/MIRCA_OS/MIRCA-OS_<Crop>_*_percent_irrigated_US.tif (most crops)
#
# Outputs (per crop):
#   ./out/model2_R/rf/<CROP>_RF_AG.RDS      — trained RF model
#   ./out/model2_R/rf/<CROP>_ETC_AG.RDS     — performance metrics + importance
#   ./out/model2_R/hprob/<CROP>_AG.tif      — predicted likelihood raster
#   ./out/model2_R/hprob/<CROP>_pt_AG.RDS   — point-level predictions
# ============================================================

setwd("G:/")   # update to local working directory
source("DISES_load.R")
source("DISES_func_new_sampling_model2.R")

# ---- Helper: load and clean agricultural census data ----
clean_census <- function(fname) {
  coa <- read.csv(fname)
  coa$GEOID <- str_pad(coa$GEOID, width = 5, side = "left", pad = "0")
  coa[is.na(coa)] <- 0
  return(coa)
}

# ---- Main function: run RF for one crop ----
run_ag_rf <- function(crop) {

  coa <- clean_census("./data/quantitative_data/data_input_RF_2/data_input_RF_2/ag_data_std_2012_17.csv")

  df <- readRDS(paste0("./out/ag_rds2/panel_ag_mirca/", crop, "_AG_MIRCA.RDS")) %>%
    na.omit()

  df$AP <- as.factor(df$TYPE)
  df$IRRIG[df$IRRIG > 0] <- 1
  df$IRRIG[df$IRRIG_std > 1] <- 1

  # ---- Konar irrigation volumes (normalized by crop-specific harvested area) ----
  gww <- readRDS("./data/lr/Konar_GWW.RDS") %>% select(crop, GEOID)
  colnames(gww) <- c("KONAR_GWW", "GEOID")
  sww <- readRDS("./data/lr/Konar_SWW.RDS") %>% select(crop, GEOID)
  colnames(sww) <- c("KONAR_SWW", "GEOID")
  gwd <- readRDS("./data/lr/Konar_GWD.RDS") %>% select(crop, GEOID)
  colnames(gwd) <- c("KONAR_GWD", "GEOID")

  all_konar <- merge(gww, sww, by = "GEOID", all = TRUE)
  all_konar <- merge(all_konar, gwd, by = "GEOID", all = TRUE)

  tc_crp <- read.csv(paste0("./data/crop_harv_acres/", tolower(crop), "_acres_pivot.csv"),
                     check.names = FALSE)
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

  # ---- Select predictors (crop-specific) ----
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

  # ---- Train-test split: 70% of counties by GEOID ----
  aps <- df %>%
    select(GEOID, AP) %>%
    st_drop_geometry() %>%
    group_by(GEOID) %>%
    summarize(ABS = sum(AP == 0), PRES = sum(AP == 1), ALL = n())

  random_seed_df <- read.csv("./out/random_seed_for_sampling_IRRIG_MIRCA_2.csv")
  rand_seed_crop <- random_seed_df %>% filter(Crop == crop) %>% pull(random_seed)

  set.seed(rand_seed_crop)
  train_cty <- aps %>% slice_sample(prop = 0.7) %>% pull(GEOID)
  test_cty <- setdiff(aps$GEOID, train_cty)

  train <- df %>% filter(GEOID %in% train_cty) %>% select(-GEOID)
  test  <- df %>% filter(GEOID %in% test_cty)  %>% select(-GEOID)
  st_geometry(train) <- NULL
  st_geometry(test)  <- NULL

  df <- df %>% select(-GEOID)

  # ---- Train random forest ----
  print(paste("Training RF for", crop))
  set.seed(42)
  rf_ap <- randomForest(AP ~ ., data = train)
  saveRDS(rf_ap, paste0("./out/model2_R/rf/", crop, "_RF_AG.RDS"))

  # ---- Model performance ----
  pred <- predict(rf_ap, test, type = "class")
  cm   <- caret::confusionMatrix(pred, test$AP)
  pcc  <- (sum(diag(table(pred, test$AP)))) / nrow(test)

  library(ROCR)
  pred2 <- prediction(as.numeric(pred), test$AP)
  auc   <- performance(pred2, measure = "auc")@y.values[[1]]

  perf <- data.frame(
    PCC         = pcc,
    SENSITIVITY = cm$byClass["Sensitivity"],
    SPECIFICITY = cm$byClass["Specificity"],
    KAPPA       = cm$overall["Kappa"],
    AUC         = auc
  )

  imp <- as.data.frame(importance(rf_ap))
  imp$varnames <- rownames(imp)
  rownames(imp) <- NULL

  saveRDS(list(PERF = perf, IMP = imp, TRAIN_CTY = train_cty),
          paste0("./out/model2_R/rf/", crop, "_ETC_AG.RDS"))

  # ---- Predict probability raster ----
  preds     <- rast("./out/hpredictors/epsg5070/all_ag_preds_2.tif")
  konar     <- rast(paste0("./out/hpredictors/epsg5070/konar_norm_", crop, ".tif"))
  naics_est <- rast(paste0("./out/hpredictors/epsg5070/NAICS_EST_", crop, ".tif"))

  if (crop %in% c("PASTURE", "FRUITVEG")) {
    preds <- c(preds, konar, naics_est)

  } else if (crop %in% c("OATS", "PECANS")) {
    prices <- rast(paste0("./out/hpredictors/epsg5070/price_", crop, ".tif"))
    preds  <- c(preds, konar, prices, naics_est)

  } else {
    prices          <- rast(paste0("./out/hpredictors/epsg5070/price_", crop, ".tif"))
    irrig_mirca_ras <- rast(paste0("./data/MIRCA_OS/MIRCA-OS_",
                                   tools::toTitleCase(tolower(crop)),
                                   "_2010_15_percent_irrigated_US.tif"))
    irrig_mirca_ras <- resample(irrig_mirca_ras, preds, method = "near")
    names(irrig_mirca_ras) <- "IRRIG_MIRCA"
    preds <- c(preds, konar, irrig_mirca_ras, prices, naics_est)
  }

  prob_raster <- predict(preds, rf_ap, type = "prob")
  writeRaster(prob_raster,
              paste0("./out/model2_R/hprob/", crop, "_AG.tif"),
              overwrite = TRUE)

  prob_pt  <- predict(rf_ap, st_drop_geometry(df), type = "prob")
  df$PROB  <- prob_pt[, 2]
  saveRDS(df, paste0("./out/model2_R/hprob/", crop, "_pt_AG.RDS"))

  print(paste("Done:", crop))
}

# ---- Run for all nine crops; for the paper ----
crop_names_hist <- c("CORN", "COTTON", "FRUITVEG", "HAY", "OATS",
                     "PEANUTS", "SORGHUM", "SOY", "WHEAT")

for (crop in crop_names_new) {
  run_ag_rf(crop)
}
