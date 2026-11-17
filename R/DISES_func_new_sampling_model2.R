
# Slice national CDL rasters into smaller state rasters for use in velox
write_states <- function(year = 2008) {
  foreach(i = 1:length(unique(states$STATE_FIPS)),
          .export = c("states", "cdl"),
          .packages = c("sf", "rgeos", "raster")) %dopar% {
            stateFIPS <- unique(states$STATE_FIPS)
            state <- states[states$STATE_FIPS == stateFIPS[i],]
            state <- sf::st_as_sf(rgeos::gBuffer(as(state, "Spatial"), width = 20000, byid=T))  # add 50K buffer around the state 
            raster::crop(cdl, state, filename = paste0(CDL_STATE_DIR, "/", year, "_", state$STATE_NAME, ".gri"))  # set CDL_STATE_DIR to your CDL working directory
          }
}

# Clean the COA (make meta changes to COA content here)
clean_census <- function(fname) {
  
  coa <- read.csv(fname) 
  coa$GEOID <- str_pad(coa$GEOID, width = 5, side = "left", pad="0")
  
  # naive assumption that missing is zero for major variables, see Ag Data
  coa[is.na(coa)] <- 0
  
  return(coa)
  
}

# Make historical hagricultural panels for RF
build_ag_panel <- function(crop) {
  
  # load sampling points
  pt_ap <- readRDS(paste0("./out/", crop, ".RDS"))
  counties_prj <- st_transform(counties, crs(pt_ap)) %>% select(GEOID, NAME)
  colnames(counties_prj) <- c("GEOID", "COUNTY_NAME", "geometry")
  
  # extract GEOID to points
  pt_ap <- st_join(pt_ap, counties_prj) # takes a sec, also drops some points
  
  # extract and merge to Cao
  flist <- Sys.glob("./data/lr/CaoN/*.tif")[160:166] # 2009 to 2015
  n <- rast(flist)
  nm <- mean(n)
  
  fert_n <- terra::extract(nm, pt_ap) %>% select(mean)
  colnames(fert_n) <- c("Cao_fert_N")
  
  flist <- Sys.glob("./data/lr/CaoP/Gridded_P_fertilizer_application_rate_county_4km_4km_1970_2021_g_P_m-2/*.tif")[40:50] #2009-2019 like CDL
  n <- rast(flist)
  nm <- mean(n)
  ## technically can make crop specific for barley, corn, cotton, durum wheat, rice, sorghum, soy, spring wheat, winter wheat, but for now keep generic like N use
  
  fert_p <- terra::extract(nm, pt_ap) %>% select(mean)
  colnames(fert_p) <- c("Cao_fert_P")
  
  pt_ap <- cbind.data.frame(pt_ap, fert_n, fert_p)
  
  coa <- clean_census("./data/lr/ag_data_std_2012_17.csv")
  
  pt_ap <- merge(pt_ap, coa, by = "GEOID") # this now contains NAICS
  
  # load and merge to Konar
  gww <- readRDS("./data/lr/Konar_GWW.RDS") %>% select(crop, GEOID)
  colnames(gww) <- c("KONAR_GWW", "GEOID")
  sww <- readRDS("./data/lr/Konar_SWW.RDS") %>% select(crop, GEOID)
  colnames(sww) <- c("KONAR_SWW", "GEOID")
  gwd <- readRDS("./data/lr/Konar_GWD.RDS") %>% select(crop, GEOID)
  colnames(gwd) <- c("KONAR_GWD", "GEOID")
  all_konar <- merge(gww, sww, by = "GEOID", all = T)
  all_konar <- merge(all_konar, gwd, by = "GEOID", all = T)
  pt_ap <- merge(pt_ap, all_konar, by = "GEOID")
  pt_ap <- st_as_sf(pt_ap)
  print(paste0("With missing data: ", nrow(pt_ap)))
  
  no_na <- pt_ap %>% na.omit()
  print(paste0("Without missing data: ", nrow(no_na)))
  
  saveRDS(pt_ap, paste0("./out/", crop, "_AG.RDS"))
  
}



# Run agricultural random forests and write out results
run_ag_rf <- function(crop) {

  # Load agricultural census data
  coa <- clean_census("./data/lr/data_input_RF_2/ag_data_std_2012_17.csv")
  
  # Load crop-specific RDS data
 # df <- readRDS(paste0("./out/ag_rds2/", crop, "_AG.RDS")) %>% na.omit()
  df <- readRDS(paste0("./out/ag_rds2/panel_ag_mirca/", crop, "_AG_MIRCA.RDS")) %>% na.omit()

  df$AP <- as.factor(df$TYPE)
  df$IRRIG[df$IRRIG > 0] <- 1  # binary irrigation flag
  df$IRRIG[df$IRRIG_std > 1] <- 1
  
  ############################################################################
  # Load Konar data
  gww <- readRDS("./data/lr/Konar_GWW.RDS") %>% select(crop, GEOID)
  colnames(gww) <- c("KONAR_GWW", "GEOID")
  sww <- readRDS("./data/lr/Konar_SWW.RDS") %>% select(crop, GEOID)
  colnames(sww) <- c("KONAR_SWW", "GEOID")
  gwd <- readRDS("./data/lr/Konar_GWD.RDS") %>% select(crop, GEOID)
  colnames(gwd) <- c("KONAR_GWD", "GEOID")
  
  all_konar <- merge(gww, sww, by = "GEOID", all = TRUE)
  all_konar <- merge(all_konar, gwd, by = "GEOID", all = TRUE)
  
  # Normalize by total cropland
  #tc <- read.csv("./data/GEOID_tot_cropland.csv")
  #tc$GEOID <- str_pad(tc$GEOID, width = 5, side = "left", pad = "0")
  
  #divide each by crop-specific harvested area average 2009-2019
  tc_crp <- read.csv(paste0("./data/crop_harv_acres/", tolower(crop), "_acres_pivot.csv"), check.names = FALSE)
  tc_crp$GEOID <- str_pad(tc_crp$GEOID, width = 5, side = c("left"), pad = 0)
  temp_yrs = intersect(as.character(2009:2019), names(tc_crp)) #only consider years from 2009 to 2018
  
  tc_crp_mean <- tc_crp %>%
    select(GEOID, all_of(temp_yrs)) %>%   
    mutate(mean_crop_acres = rowMeans(across(all_of(temp_yrs)), na.rm = TRUE)) %>%
    select(GEOID, mean_crop_acres)
  


  #all_konar <- merge(all_konar, tc, by = "GEOID", all.x = TRUE)
  #all_konar$KONAR_GWW <- all_konar$KONAR_GWW / all_konar$tot_cropland_acre
  #all_konar$KONAR_GWD <- all_konar$KONAR_GWD / all_konar$tot_cropland_acre
  #all_konar$KONAR_SWW <- all_konar$KONAR_SWW / all_konar$tot_cropland_acre
  #all_konar <- na.omit(all_konar)
  
  all_konar <- merge(all_konar, tc_crp_mean, by = "GEOID", all.x = TRUE)
  all_konar$KONAR_GWW <- all_konar$KONAR_GWW/all_konar$mean_crop_acres
  all_konar$KONAR_GWD <- all_konar$KONAR_GWD/all_konar$mean_crop_acres
  all_konar$KONAR_SWW <- all_konar$KONAR_SWW/all_konar$mean_crop_acres
  #replacing all NAs with 0
  all_konar[is.na(all_konar)] <- 0


  # Merge Konar data to df
  df <- merge(df %>% select(-c(KONAR_GWW, KONAR_GWD, KONAR_SWW)), all_konar, by = "GEOID", all = TRUE)
  df <- na.omit(df)
  
  # Bioclimatic variable names
  names <- c("BV1_Annual_Mean_Temp", "BV2_Mean_Diurnal_Range", "BV3_Isothermality", "BV4_Temp_Seasonality",
             "BV5_MaxTemp_Warm_Month", "BV6_MinTemp_Cold_Month", "BV7_Temp_Annual_Range", "BV8_MeanTemp_Wet_Quart",
             "BV9_MeanTemp_Driest_Quart", "BV10_MeanTemp_Warm_Quart", "BV11_MeanTemp_Cold_Quart",
             "BV12_Annual_Precip", "BV13_Precip_Wet_Month", "BV14_Precip_Dry_Month", "B15_CoV_Precip", 
             "B16_Precip_Wet_Quart", "B17_Precip_Dry_Quart", "B18_Precip_Warm_Quart", "B19_Precip_Cold_Quart")
  
  # price is not avl for fruitveg and pasture; removed pasture as it does not have irrig_mirca, price, and crop-specific area so no konar vars
  # also removing pecans
  if (crop %in% c("FRUITVEG", "PASTURE")) {   #no price and IRRIG MIRCA
    df <- df %>%
      select(GEOID, AP, all_of(names), 
             T_BULK_DEN, T_CEC_CLAY, T_CLAY, T_GRAVEL, T_SAND, T_SILT,
             NA_1KM_SLOPE, NA_1KM, colnames(coa),
             KONAR_GWW, KONAR_GWD, KONAR_SWW, Cao_fert_N, Cao_fert_P, mean_est_std, IRRIG_std) %>%
      select(-c("BV3_Isothermality", "BV7_Temp_Annual_Range", "KONAR_GWD", "irg_acre_total", "labor_usd"))
    
  } else if (crop %in% c("OATS", "PECANS")){                              #OATS specific irrig is not avl in MIRCA OS, so using IRRIG_std from MIRAD 
    df <- df %>%                                              #Same for fruit veg; using MIRAD
      select(GEOID, AP, all_of(names), 
             T_BULK_DEN, T_CEC_CLAY, T_CLAY, T_GRAVEL, T_SAND, T_SILT,
             NA_1KM_SLOPE, NA_1KM, colnames(coa),
             KONAR_GWW, KONAR_GWD, KONAR_SWW, Cao_fert_N, Cao_fert_P, PRICE, mean_est_std, IRRIG_std) %>%
      select(-c("BV3_Isothermality", "BV7_Temp_Annual_Range", "KONAR_GWD", "irg_acre_total", "labor_usd"))
   
  } else {
    df <- df %>%
      select(GEOID, AP, all_of(names), 
             T_BULK_DEN, T_CEC_CLAY, T_CLAY, T_GRAVEL, T_SAND, T_SILT,
             NA_1KM_SLOPE, NA_1KM, colnames(coa),
             KONAR_GWW, KONAR_GWD, KONAR_SWW, Cao_fert_N, Cao_fert_P, PRICE, mean_est_std, IRRIG_MIRCA) %>%
      select(-c("BV3_Isothermality", "BV7_Temp_Annual_Range", "KONAR_GWD", "irg_acre_total", "labor_usd"))
  }  
  ########################
  # Train-test split by GEOID
  aps <- df %>%
    select(GEOID, AP) %>%
    st_drop_geometry() %>%
    group_by(GEOID) %>%
    summarize(ABS = sum(AP == 0), PRES = sum(AP == 1), ALL = n()) %>%
    collect()
  
  #random_seed_df <- read.csv("./out/random_seed_for_sampling_IRRIG_std_2.csv")
  random_seed_df <- read.csv("./out/random_seed_for_sampling_IRRIG_MIRCA_2.csv")
  rand_seed_crop <- random_seed_df %>% filter(Crop == crop) %>% pull(random_seed)
  
  set.seed(rand_seed_crop)
  train_cty <- aps %>% slice_sample(prop = 0.7) %>% pull(GEOID)
  test_cty <- setdiff(aps$GEOID, train_cty)
  
  aps_train <- aps %>% filter(GEOID %in% train_cty)
  aps_test <- aps %>% filter(GEOID %in% test_cty)
  
  train <- df %>% filter(GEOID %in% train_cty) %>% select(-GEOID)
  test <- df %>% filter(GEOID %in% test_cty) %>% select(-GEOID)
  st_geometry(train) <- NULL
  st_geometry(test) <- NULL
  
  ap_ratio_train <- sum(aps_train$ABS) / sum(aps_train$PRES)
  ap_ratio_test <- sum(aps_test$ABS) / sum(aps_test$PRES)
  
  df <- df %>% select(-GEOID)
  
  ########################
  print("Data built, training models...")
  
  set.seed(42)
  rf_ap <- randomForest(AP ~ ., data = train)
  saveRDS(rf_ap, paste0("./out/model2_R/rf/", crop, "_RF_AG.RDS"))
  
  print("Models done, assessing performance...")
  pred <- predict(rf_ap, test, type = "class")
  t <- with(test, table(pred, test$AP))
  pcc <- (t[1,1] + t[2,2])/nrow(test)
  
  cm <- caret::confusionMatrix(pred, test$AP)
  sens <- cm$byClass["Sensitivity"]
  spec <- cm$byClass["Specificity"]
  kappa <- cm$overall["Kappa"]
  
  library(ROCR)
  pred2 <- prediction(as.numeric(pred), test$AP)
  auc <- performance(pred2, measure = "auc")@y.values[[1]]
  
  perf <- data.frame(PCC = pcc, SENSITIVITY = sens, SPECIFICITY = spec, KAPPA = kappa, AUC = auc)
  
  imp <- as.data.frame(importance(rf_ap))
  imp$varnames <- rownames(imp)
  rownames(imp) <- NULL
  
  out_list <- list(PERF = perf, IMP = imp, TRAIN_CTY = train_cty)
  saveRDS(out_list, paste0("./out/model2_R/rf/", crop, "_ETC_AG.RDS"))
  
  # Prediction on points
  prob_pt <- predict(rf_ap, df, type = "prob")
  df$PROB <- prob_pt[,2]
  
  # Prediction on raster
  preds <- rast("./out/hpredictors/epsg5070/all_ag_preds_2.tif")
  konar <- rast(paste0("./out/hpredictors/epsg5070/konar_norm_", crop, ".tif"))  #make sure its normalized
  naics_est <- rast(paste0("./out/hpredictors/epsg5070/NAICS_EST_", crop, ".tif"))
  

  if (crop %in% c("PASTURE", "FRUITVEG")) {
    preds <- c(preds, konar, naics_est)

  } else if (crop %in% c("OATS", "PECANS")){
    prices <- rast(paste0("./out/hpredictors/epsg5070/price_", crop, ".tif"))
    preds <- c(preds, konar, prices, naics_est)

  } else{
    
    prices <- rast(paste0("./out/hpredictors/epsg5070/price_", crop, ".tif"))
    irrig_mirca_ras <- rast(paste0("./data/MIRCA_OS/MIRCA-OS_", tools::toTitleCase(tolower(crop)), "_2010_15_percent_irrigated_US.tif"))
    irrig_mirca_ras <- resample(irrig_mirca_ras , preds , method = "near") #resample MIRCA as its org res is 0.0833 deg
    names(irrig_mirca_ras) = "IRRIG_MIRCA"
    preds <- c(preds, konar, irrig_mirca_ras, prices, naics_est)

    }

  
  prob_raster <- predict(preds, rf_ap, type = "prob")
  writeRaster(prob_raster, paste0("./out/model2_R/hprob/", crop, "_AG.tif"), overwrite = TRUE)
  
  saveRDS(df, paste0("./out/model2_R/hprob/", crop, "_pt_AG.RDS"))
  
  print(paste("Random forest processing completed for", crop))
}
