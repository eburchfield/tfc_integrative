# Generate future agricultural suitability rasters 
#updating after delphi and model 2

##
# without using delphi-- ie. AG variables assumes same for the future, just climate change (M2)

future_ag_suitability_rast_no_delphi <- function() {
  
  wc_ref <- rast("./out/hpredictors/hist_biovars.tif")
  roi <- st_as_sf(st_transform(roi, crs(wc_ref)))
  counties_prj <- st_transform(counties, crs(wc_ref))
  
  scen_list <- c("245", "370", "585")
  
  yrs <- c("2021-2040", "2041-2060", "2061-2080", "2081-2100")
  
  
  for (p in 1:length(scen_list)){
    
    scen <- scen_list[p]
    print(scen)
    
    for (i in 1:length(crop_names)) {
      
      print(crop_names[i])
      crop = crop_names[i]
      
      preds <- rast("./out/hpredictors/epsg5070/all_ag_preds_2.tif")  #this one has historical biophysical and ag vars
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
      rf_ap <- readRDS(paste0("./out/model2_R/rf/", crop, "_RF_AG.RDS"))
      
      pras <- rast()
      
      for (y in 1:length(yrs)) {
        
        print(yrs[y])
        
        bv <- rast(paste0("./out/fpredictors/ssp", scen, "_", yrs[y], ".tif"))
        common_bv_vars <- intersect(names(preds), names(bv))
        
        #updating climate vars in preds using future climate rasters
        for (v in common_bv_vars) {
          preds[[v]] <- bv[[v]]
        }
        
        #prob <- stats::predict(preds, rf_ap, type = "prob")
        prob <- predict(preds, rf_ap, type = "prob")
        p1 <- prob[[2]]
        names(p1) <- yrs[y]
        
        pras <- c(pras, p1)
        
      }
      
      #    writeRaster(pras, paste0("./out/fprob/ssp", scen, "_", crop_names[i], "_AG.tif"), overwrite=T)
      writeRaster(pras, paste0("./out/model2_R/fprob/ssp", scen, "_", crop, "_AG.tif"), overwrite=T)  #climate projections but no delphi
      
    }
    
    
  }
  
}

#running future suitability raster functino for clim proj but no delphi proj
future_ag_suitability_rast_no_delphi()



  #building future panel using delphi

build_delphi_panel <- function() {
  
  wc_ref <- rast("./out/hpredictors/hist_biovars.tif")
  roi <- st_as_sf(st_transform(roi, crs(wc_ref)))
  counties_prj <- st_transform(counties, crs(wc_ref))
  
  
  delphi_df_percent_change = read.csv("E:/DISES/quantitative_data/data_input_RF_2/delphi_df_percent_change.csv", 
                                      colClasses = c(GEOID = "character"))
  delphi_df_percent_change$GEOID <- sprintf("%05s", delphi_df_percent_change$GEOID)
  
  delphi_df_percent_change <- merge(counties %>% select(GEOID), delphi_df_percent_change)  #getting the coordinates
  delphi_df_percent_change <- st_transform(delphi_df_percent_change, crs(wc_ref))
  names <- colnames(delphi_df_percent_change)
  out <- list()
  stop <- ncol(delphi_df_percent_change)-1
  
  for (i in 1:stop) {
    print(names[i])
    attr <- rasterize(x = delphi_df_percent_change, y = wc_ref[[1]], names[i])
    out[[i]] <- attr
  }
  
  delphi_df_percent_change_ras <- rast(out)  
  
  scen_list <- c("245", "370", "585")
  # scen_list <- c("585")

  yrs <- c("2021-2040", "2041-2060", "2061-2080", "2081-2100")
  # yrs <- c("2041-2060")

  for (p in 1:length(scen_list)){
    
    scen <- scen_list[p]
    print(scen)
    
    for (i in 1:length(crop_names)) {
      
      print(crop_names[i])
      crop = crop_names[i]
      
      preds <- rast("./out/hpredictors/epsg5070/all_ag_preds_2.tif")  #this one has historical biophysical and ag vars
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
      
      
      
      #Updating the vars in preds based on national and state delphi percent change values
      
      common_vars <- intersect(names(preds), names(delphi_df_percent_change_ras))
      
      preds_future_delphi <- preds  
      
      #updating AG vars in preds from delphi panels
      for (v in common_vars) {
        preds_future_delphi[[v]] <- preds[[v]] * (1 + delphi_df_percent_change_ras[[v]] / 100)
      }
      
      
      # #sanity check
      # v = common_vars[1]
      # global(preds[[v]], "mean", na.rm = TRUE)
      # global(preds_future_delphi[[v]], "mean", na.rm = TRUE)
      # #the below value should be -2.71
      # (preds_future_delphi$live_cattle_inventory[100,100] - preds$live_cattle_inventory[100,100])/preds$live_cattle_inventory[100,100]*100

      y = 2  #bcoz we only considerin 2041-2060 year period as delphi projects for 2050
      
      bv <- rast(paste0("./out/fpredictors/ssp", scen, "_", yrs[y], ".tif"))
      
      common_bv_vars <- intersect(names(preds_future_delphi), names(bv))
      
      preds_future_delphi_bio <- preds_future_delphi  # copy ; preds_future_delphi_bio has all variables future projections
      
      
      #updating climate vars in preds using future climate rasters
      
      for (v in common_bv_vars) {
        preds_future_delphi_bio[[v]] <- bv[[v]]
      } 
        
      writeRaster(preds_future_delphi_bio, paste0("./out/fpredictors/delphi_ras/ssp", scen, "_", crop, "_2041_2060_delphi_AG.tif"), overwrite=T)
      
      
      county_agg_all_ag_pred_delphi = terra::extract(preds_future_delphi_bio, counties_prj, fun = mean, na.rm = TRUE)
      county_agg_all_ag_pred_delphi[is.na(county_agg_all_ag_pred_delphi)] <- 0
      county_agg_all_ag_pred_delphi <- cbind(counties_prj["GEOID"], county_agg_all_ag_pred_delphi)
      county_agg_all_ag_pred_delphi = county_agg_all_ag_pred_delphi %>% select(-ID)
      
      write.csv(st_drop_geometry(county_agg_all_ag_pred_delphi),
                file = paste0("./out/fpredictors/delphi_rds/ssp", scen, "_", crop, "_2041_2060_delphi_AGG.csv"),
                row.names = FALSE)
      
      saveRDS(county_agg_all_ag_pred_delphi, file = paste0("./out/fpredictors/delphi_rds/ssp", scen, "_", crop, "_2041_2060_delphi_AGG.RDS"))
      
      
}}}

#Building delphi panels, no need to run everytime
build_delphi_panel()
##########################################################################
##########################################################################
##########################################################################
#using delphi projections for 2041-2060
future_ag_suitability_rast <- function() {
  

  scen_list <- c("245", "370", "585")
  # scen_list <- c("585")
  
  yrs <- c("2021-2040", "2041-2060", "2061-2080", "2081-2100")
  # yrs <- c("2041-2060")
  

  
   
  for (p in 1:length(scen_list)){
    
    scen <- scen_list[p]
    print(scen)
    y = 2 # for 2041-2060
    for (i in 1:length(crop_names)) {
      
      print(crop_names[i])
      crop = crop_names[i]
      
 
      #    rf_ap <- readRDS(paste0("./out/rf/", crop_names[i], "_RF_AG.RDS"))
      rf_ap <- readRDS(paste0("./out/model2_R/rf/", crop, "_RF_AG.RDS"))

      pras <- rast()
      
      preds_future_delphi_bio <- rast(paste0("./out/fpredictors/delphi_ras/ssp", scen, "_", crop, "_2041_2060_delphi_AG.tif"))  #this one has historical biophysical and ag vars
      
 
      prob <- predict(preds_future_delphi_bio, rf_ap, type = "prob")
      p1 <- prob[[2]]
      names(p1) <- yrs[y]
        
      pras <- c(pras, p1)
        
      
      
      #    writeRaster(pras, paste0("./out/fprob/ssp", scen, "_", crop_names[i], "_AG.tif"), overwrite=T)
      # writeRaster(pras, paste0("./out/model2_R/fprob/ssp", scen, "_", crop, "_2050_AG.tif"), overwrite=T)
      writeRaster(pras, paste0("./out/model2_R/fprob/ssp", scen, "_", crop, "_AG_DELPHI.tif"), overwrite=T)
      
    }
    
  }
  
}


#Running
future_ag_suitability_rast()



#plotting raster into png

pr1 <- Sys.glob("./out/model2_R/fprob/ssp585*_DELPHI.tif")

r1 <- rast()
for (i in 1:length(pr1)) {
  t <- rast(pr1[i])[[1]]

  
  # n <- str_to_title(substr(str_split(pr[i], "/")[[1]][4], 1, nchar(str_split(pr[i], "/")[[1]][4])-4))
  #removes "Ag" from title
  # n <- str_to_title(gsub("(_AG|ssp585_)", "", substr(str_split(pr1[i], "/")[[1]][4], 1, nchar(str_split(pr1[i], "/")[[1]][4]) - 4)))
  # n =tools::toTitleCase(tolower(gsub(".*ssp585_|_2050_AG_DELPHI\\.tif", "", basename(pr1[i]))))
  
  n = tools::toTitleCase(tolower(strsplit(basename(pr1[i]), "_")[[1]][2]))
  names(t) <- n

  r1 <- c(r1, t)

}

r1 <- rename_rast_layer(r1)

states <- st_transform(states, crs(r1))
p1 <- gplot(r1) +
  geom_tile(aes(fill = value)) +
  facet_wrap(~variable, ncol = 5, nrow = 3) +
  geom_sf(data = states, fill = NA, color = "black", size = 0.5, inherit.aes = FALSE) +
  coord_equal() +
  scale_fill_viridis(na.value = NA, limits = c(0,1)) +
  labs(x = "", y = "", fill = "") +
  theme(legend.position = "right") +
  theme_bw() +
  coord_sf() 

p1
ggsave("figs_model2/suit_viz/suit_SSP585_2041_2060_future_delphi_clim.png", plot = p1, width = 10, height = 5, dpi = 300)  # Save as PNG

### Change in suitability

pr <- Sys.glob("./out/model2_R/hprob/*_AG.tif")
# pr_base <- Sys.glob("./out/fprob_new_sampling/ssp245*_AG.tif")
pr2 <- Sys.glob("./out/model2_R/fprob/ssp585*_AG_DELPHI.tif")
Sys.glob("./out/model2_R/fprob/ssp245*_AG_DELPHI.tif")
r3_new <- rast()
for (i in 1:length(pr2)) {
  r_fut = rast(pr2[i])
  # r_cur = rast(pr_base[i])[[1]]
  r_cur = rast(pr[i])[[2]]
  
  mask <- (r_fut > 0.3) | (r_cur > 0.3)
  
  t <- mask * (r_fut - r_cur)  # Apply mask
  t[!mask] <- NA
  # n <- str_to_title(gsub("(_AG|ssp585_)", "", substr(str_split(pr2[i], "/")[[1]][4], 1, nchar(str_split(pr2[i], "/")[[1]][4]) - 4)))
  # n =tools::toTitleCase(tolower(gsub(".*ssp585_|_2050_AG\\.tif", "", basename(pr1[i]))))
  n = tools::toTitleCase(tolower(strsplit(basename(pr2[i]), "_")[[1]][2]))
  
  names(t) <- n
  r3_new <- c(r3_new, t)
}
r3_new<- rename_rast_layer(r3_new)
states <- st_transform(states, crs(r3_new))

p3_new <- gplot(r3_new) +
  geom_tile(aes(fill = value)) +
  facet_wrap(~variable, ncol = 5, nrow = 3) +
  # Overlay states shapefile
  geom_sf(data = states, fill = NA, color = "black", size = 0.5, inherit.aes = FALSE) +
  coord_equal() +
  scale_fill_gradient2(
    low = "red",        # Color for negative values
    mid = "grey",      # Color for zero
    high = "blue",      # Color for positive values
    midpoint = 0,       # Center of the diverging scale
    na.value = 'white'       # Handle NA values
  ) +
  labs(x = "", y = "", fill = "") +
  
  theme_bw() +
  theme(
    legend.position = "right",
    axis.text = element_blank(),  # Remove axis text
    panel.grid = element_blank(), 
    axis.ticks = element_blank()        # Remove axis ticks
  ) +
  coord_sf() 

p3_new
ggsave("figs_model2/suit_viz/diff_prob_surf_delphi_ssp585_hist_masked03_temp.png", plot = p3_new, width = 10, height = 5, dpi = 300)  # Save as PNG
# ggsave("figs_new_sampling/viz_test//diff_prob_surf_ssp585_hist_masked03.png", plot = p3_new, width = 10, height = 5, dpi = 300)  # Save as PNG
############################################
#############################################
# For EMily- for corn, soybeans, what, sorghum, oats, cotton
r3_new_eb = r3_new[[c("Corn", "Soybeans", "Wheat", "Sorghum", "Oats", "Cotton")]]
mx <- max(abs(values(r3_new_eb)), na.rm = TRUE)

p3_new_eb <- gplot(r3_new_eb) +
  geom_tile(aes(fill = value)) +
  facet_wrap(~variable, ncol = 3, nrow = 2) +
  
  geom_sf(data = states, fill = NA, color = "black",
          size = 0.5, inherit.aes = FALSE) +
  
  coord_equal() +
  
  scale_fill_gradient2(
    low = "red",
    mid = "grey",
    high = "blue",
    midpoint = 0,
    limits = c(-mx, mx),   # symmetric color limits
    na.value = "white"
  ) +
  
  labs(x = "", y = "", fill = "") +
  
  theme_bw() +
  theme(
    legend.position = "right",
    axis.text = element_blank(),
    panel.grid = element_blank(),
    axis.ticks = element_blank()
  ) +
  coord_sf()

p3_new_eb
ggsave("figs_model2/suit_viz/diff_prob_surf_delphi_ssp585_hist_masked03_EB6.png", plot = p3_new_eb, width = 10, height = 5, dpi = 300)  # Save as PNG
########################################################
#####################################################

## For Future suit paper- EB; we need to compare the clim only change with national delphi only change.
# The above functions calucate future suitability considering both national and states delphi
# The below code is for considering national level delphi projections only

build_delphi_panel_only_national <- function() {
  
  wc_ref <- rast("./out/hpredictors/hist_biovars.tif")
  roi <- st_as_sf(st_transform(roi, crs(wc_ref)))
  counties_prj <- st_transform(counties, crs(wc_ref))
  
  # Read national-only Delphi percent change CSV
  # Expected format: columns = variable names, single row of percent change values
  # (no GEOID — national projection applied uniformly across all counties)
  delphi_national <- read.csv(
    "E:/DISES/quantitative_data/data_input_RF_2/delphi_df_percent_change_only_national.csv"
  )
  
  # Inspect to confirm structure — should be 1 row x n_variable columns
  print(dim(delphi_national))
  print(names(delphi_national))
  
  scen_list <- c("245", "370", "585")
  yrs <- c("2021-2040", "2041-2060", "2061-2080", "2081-2100")
  
  for (p in 1:length(scen_list)) {
    
    scen <- scen_list[p]
    print(paste("Scenario:", scen))
    
    for (i in 1:length(crop_names)) {
      
      crop <- crop_names[i]
      print(paste("Crop:", crop))
      
      # Load historical predictor stack (biophysical + AG vars)
      preds <- rast("./out/hpredictors/epsg5070/all_ag_preds_2.tif")
      konar <- rast(paste0("./out/hpredictors/epsg5070/konar_norm_", crop, ".tif"))
      naics_est <- rast(paste0("./out/hpredictors/epsg5070/NAICS_EST_", crop, ".tif"))
      
      # Build crop-specific predictor stack (same logic as original)
      if (crop %in% c("PASTURE", "FRUITVEG")) {
        preds <- c(preds, konar, naics_est)
        
      } else if (crop %in% c("OATS", "PECANS")) {
        prices <- rast(paste0("./out/hpredictors/epsg5070/price_", crop, ".tif"))
        preds <- c(preds, konar, prices, naics_est)
        
      } else {
        prices <- rast(paste0("./out/hpredictors/epsg5070/price_", crop, ".tif"))
        irrig_mirca_ras <- rast(paste0("./data/MIRCA_OS/MIRCA-OS_",
                                       tools::toTitleCase(tolower(crop)),
                                       "_2010_15_percent_irrigated_US.tif"))
        irrig_mirca_ras <- resample(irrig_mirca_ras, preds, method = "near")
        names(irrig_mirca_ras) <- "IRRIG_MIRCA"
        preds <- c(preds, konar, irrig_mirca_ras, prices, naics_est)
      }
      
      # --- Apply national percent changes uniformly across the raster stack ---
      # For each variable that appears in both preds and the national CSV,
      # multiply the raster layer by (1 + pct_change / 100) using a scalar
      
      preds_future_delphi <- preds  # copy to modify
      
      national_vars <- names(delphi_national)  # variables in national CSV
      common_vars <- intersect(names(preds), national_vars)
      
      print(paste("Applying national Delphi changes to", length(common_vars), "variables"))
      
      for (v in common_vars) {
        pct_change <- as.numeric(delphi_national[[v]][1])  # scalar from single-row CSV
        preds_future_delphi[[v]] <- preds[[v]] * (1 + pct_change / 100)
      }
      
      # Load future climate (2041-2060 = index 2; Delphi projects to ~2050)
      y <- 2
      bv <- rast(paste0("./out/fpredictors/ssp", scen, "_", yrs[y], ".tif"))
      common_bv_vars <- intersect(names(preds_future_delphi), names(bv))
      
      preds_future_delphi_bio <- preds_future_delphi  # copy with all future vars
      
      # Update climate variables with future climate projections
      for (v in common_bv_vars) {
        preds_future_delphi_bio[[v]] <- bv[[v]]
      }
      
      # Save the full predictor raster for this crop x scenario
      writeRaster(preds_future_delphi_bio,
                  paste0("./out/fpredictors/delphi_ras_national_only/ssp", scen, "_", crop,
                         "_2041_2060_delphi_national_AG.tif"),
                  overwrite = TRUE)
      
      # County-level aggregation (mean per county)
      county_agg <- terra::extract(preds_future_delphi_bio, counties_prj,
                                   fun = mean, na.rm = TRUE)
      county_agg[is.na(county_agg)] <- 0
      county_agg <- cbind(counties_prj["GEOID"], county_agg)
      county_agg <- county_agg %>% select(-ID)
      
      write.csv(st_drop_geometry(county_agg),
                file = paste0("./out/fpredictors/delphi_rds_national_only/ssp", scen, "_", crop,
                              "_2041_2060_delphi_national_AGG.csv"),
                row.names = FALSE)
      
      saveRDS(county_agg,
              file = paste0("./out/fpredictors/delphi_rds_national_only/ssp", scen, "_", crop,
                            "_2041_2060_delphi_national_AGG.RDS"))
      
    }
  }
}

# Build the national only Delphi panels (run once)
build_delphi_panel_only_national()

# STEP 2: Predict future crop likelihood using national only Delphi panels
##########################################################################

future_ag_suitability_rast_national <- function() {
  
  scen_list <- c("245", "370", "585")
  yrs <- c("2021-2040", "2041-2060", "2061-2080", "2081-2100")
  
  for (p in 1:length(scen_list)) {
    
    scen <- scen_list[p]
    print(paste("Scenario:", scen))
    
    y <- 2  # 2041-2060 period
    
    for (i in 1:length(crop_names)) {
      
      crop <- crop_names[i]
      print(paste("Crop:", crop))
      
      rf_ap <- readRDS(paste0("./out/model2_R/rf/", crop, "_RF_AG.RDS"))
      
      preds_future_delphi_bio <- rast(
        paste0("./out/fpredictors/delphi_ras_national_only/ssp", scen, "_", crop,
               "_2041_2060_delphi_national_AG.tif")
      )
      
      prob <- predict(preds_future_delphi_bio, rf_ap, type = "prob")
      p1 <- prob[[2]]
      names(p1) <- yrs[y]
      
      writeRaster(p1,
                  paste0("./out/model2_R/fprob/ssp", scen, "_", crop,
                         "_AG_DELPHI_ONLY_NATIONAL.tif"),
                  overwrite = TRUE)
    }
  }
}

# Run predictions
future_ag_suitability_rast_national()

####
# Boxplot: Change in crop likelihood
# Comparing two scenarios relative to historical:
#   (1) Climate change only  -> ssp{scen}_{crop}_AG.tif         (2041-2060 layer = index 2)
#   (2) National Delphi only -> ssp{scen}_{crop}_AG_DELPHI_ONLY_NATIONAL.tif
# Crops on x-axis; one figure per SSP (245 and 585)


hist_dir    <- "./out/model2_R/hprob"
fut_clim_dir <- "./out/model2_R/fprob"                     # _AG.tif Climate only change
fut_delphi_national_dir <- "./out/model2_R/fprob"                     # _AG_DELPHI_NATIONAL.tif

yrs <- c("2021-2040", "2041-2060", "2061-2080", "2081-2100")
y   <- 2   # 2041-2060 — matches Delphi projection horizon (~2050)

scen_list <- c("245", "585")


# -------------------------------------------------------------------
# Helper: extract pixel values as vector, apply threshold mask
# Only include pixels where hist OR fut > 0.3 (same logic as diff maps)
# -------------------------------------------------------------------
get_diff_vals <- function(r_hist, r_fut, threshold = 0.3) {
  mask <- (r_hist > threshold) | (r_fut > threshold)
  diff <- mask * (r_fut - r_hist)
  diff[!mask] <- NA
  as.vector(values(diff, na.rm = TRUE))
}

# -------------------------------------------------------------------
# Build long dataframe across crops and scenarios
# -------------------------------------------------------------------
df_all <- data.frame()

for (scen in scen_list) {
  
  print(paste("Processing SSP:", scen))
  
  for (crop in crop_names) {
    
    print(crop)
    
    # Historical (layer 2 = for X1)
    r_hist <- rast(file.path(hist_dir, paste0(crop, "_AG.tif")))[[2]]
    
    # Climate-only future (2041-2060)
    r_clim <- rast(file.path(fut_clim_dir, paste0("ssp", scen, "_", crop, "_AG.tif")))[[y]]
    
    # National Delphi future (single layer)
    r_delp <- rast(file.path(fut_delphi_national_dir, paste0("ssp", scen, "_", crop, "_AG_DELPHI_ONLY_NATIONAL.tif")))[[1]]
    
    # Change in likelihood
    vals_clim <- get_diff_vals(r_hist, r_clim)
    vals_delp <- get_diff_vals(r_hist, r_delp)
    
    df_crop <- data.frame(
      Crop     = tools::toTitleCase(tolower(crop)),
      Scenario = paste0("SSP", scen),
      Type     = rep(c("Climate only", "Delphi (national)"),
                     times = c(length(vals_clim), length(vals_delp))),
      Delta    = c(vals_clim, vals_delp)
    )
    
    df_all <- rbind(df_all, df_crop)
  }
}

# Rename Fruitveg for display
df_all$Crop <- gsub("Fruitveg", "Fruit-Veg", df_all$Crop)

# Factor ordering — alphabetical or custom
df_all$Crop <- factor(df_all$Crop)
df_all$Type <- factor(df_all$Type, levels = c("Climate only", "Delphi (national)"))

# -------------------------------------------------------------------
# Color palette
# -------------------------------------------------------------------
type_colors <- c("Climate only"     = "#4575b4",
                 "Delphi (national)" = "#d73027")

#### Plot function
# -------------------------------------------------------------------
make_boxplot <- function(df, ssp_label) {
  
  ggplot(df %>% filter(Scenario == ssp_label),
         aes(x = Crop, y = Delta, fill = Type)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.4) +
    geom_boxplot(
      outlier.size  = 0.3,
      outlier.alpha = 0.3,
      linewidth     = 0.4,
      width         = 0.65,
      position      = position_dodge(width = 0.75)
    ) +
    scale_fill_manual(values = type_colors) +
    scale_y_continuous(
      limits = c(-1, 1),
      breaks = seq(-1, 1, 0.25),
      labels = scales::number_format(accuracy = 0.01)
    ) +
    labs(
      title = paste0("Change in crop likelihood: ", ssp_label, " (2041–2060 vs. historical)"),
      x     = NULL,
      y     = "Change in likelihood (future \u2212 historical)",
      fill  = NULL
    ) +
    theme_bw(base_size = 12) +
    theme(
      axis.text.x      = element_text(angle = 35, hjust = 1, size = 10),
      axis.text.y      = element_text(size = 10),
      legend.position  = "top",
      legend.text      = element_text(size = 11),
      panel.grid.major.x = element_blank(),
      panel.grid.minor   = element_blank(),
      plot.title         = element_text(size = 12, face = "bold")
    )
}

p_245 <- make_boxplot(df_all, "SSP245")
p_585 <- make_boxplot(df_all, "SSP585")

ggsave("figs_model2/FUTURE/box_diff_suit_clim_only_and_nat_delphi_masked03_ssp_245.png", plot = p_245, width = 10, height = 5, dpi = 300)  # Save as PNG
ggsave("figs_model2/FUTURE/box_diff_suit_clim_only_and_nat_delphi_masked03_ssp_585.png", plot = p_585, width = 10, height = 5, dpi = 300)  # Save as PNG
#############################################
#############################################
# Now creating rasters of suitability changes considering state-delphi projection (this includes national delphi too), but only for GA NE OH
# state_fips: used to filter counties shapefile to state counties only
# -------------------------------------------------------------------
state_config <- list(
  GA = list(
    csv   = "E:/DISES/quantitative_data/data_input_RF_2/delphi_df_percent_change_national_and_GA.csv",
    fips  = "13",
    label = "Georgia"
  ),
  NE = list(
    csv   = "E:/DISES/quantitative_data/data_input_RF_2/delphi_df_percent_change_national_and_NE.csv",
    fips  = "31",
    label = "Nebraska"
  ),
  OH = list(
    csv   = "E:/DISES/quantitative_data/data_input_RF_2/delphi_df_percent_change_national_and_OH.csv",
    fips  = "39",
    label = "Ohio"
  )
)

yrs       <- c("2021-2040", "2041-2060", "2061-2080", "2081-2100")
y         <- 2   # 2041-2060 — Delphi projects to ~2050
scen_list <- c("245", "370", "585")

# -------------------------------------------------------------------
# STEP 1: Build state Delphi predictor rasters
# Identical logic to build_delphi_panel() but reads state CSV
# -------------------------------------------------------------------
build_delphi_panel_state <- function(state_abbr) {
  
  cfg <- state_config[[state_abbr]]
  
  wc_ref       <- rast("./out/hpredictors/hist_biovars.tif")
  roi          <- st_as_sf(st_transform(roi, crs(wc_ref)))
  counties_prj <- st_transform(counties, crs(wc_ref))
  
  # --- Filter to state counties only ---
  state_counties_prj <- counties_prj %>% filter(substr(GEOID, 1, 2) == cfg$fips)
  state_ext          <- ext(vect(state_counties_prj))  # bounding box of state
  wc_ref_state       <- crop(wc_ref[[1]], state_ext)   # cropped template raster
  
  delphi_df <- read.csv(cfg$csv, colClasses = c(GEOID = "character"))
  delphi_df$GEOID <- sprintf("%05s", delphi_df$GEOID)
  delphi_df <- merge(counties %>% select(GEOID), delphi_df)
  delphi_df <- st_transform(delphi_df, crs(wc_ref))
  
  col_names <- colnames(delphi_df)
  out       <- list()
  stop_col  <- ncol(delphi_df) - 1
  
  for (i in 1:stop_col) {
    print(col_names[i])
    attr     <- rasterize(x = delphi_df, y = wc_ref_state, col_names[i])  # rasterize to state extent
    out[[i]] <- attr
  }
  
  delphi_ras <- rast(out)
  
  for (p in 1:length(scen_list)) {
    scen <- scen_list[p]
    
    for (i in 1:length(crop_names)) {
      crop <- crop_names[i]
      
      preds     <- rast("./out/hpredictors/epsg5070/all_ag_preds_2.tif")
      konar     <- rast(paste0("./out/hpredictors/epsg5070/konar_norm_", crop, ".tif"))
      naics_est <- rast(paste0("./out/hpredictors/epsg5070/NAICS_EST_", crop, ".tif"))
      
      if (crop %in% c("PASTURE", "FRUITVEG")) {
        preds <- c(preds, konar, naics_est)
      } else if (crop %in% c("OATS", "PECANS")) {
        prices <- rast(paste0("./out/hpredictors/epsg5070/price_", crop, ".tif"))
        preds  <- c(preds, konar, prices, naics_est)
      } else {
        prices      <- rast(paste0("./out/hpredictors/epsg5070/price_", crop, ".tif"))
        irrig_mirca <- rast(paste0("./data/MIRCA_OS/MIRCA-OS_",
                                   tools::toTitleCase(tolower(crop)),
                                   "_2010_15_percent_irrigated_US.tif"))
        irrig_mirca <- resample(irrig_mirca, preds, method = "near")
        names(irrig_mirca) <- "IRRIG_MIRCA"
        preds <- c(preds, konar, irrig_mirca, prices, naics_est)
      }
      
      # --- Crop full predictor stack to state extent before applying changes ---
      preds <- crop(preds, state_ext)
      
      common_vars       <- intersect(names(preds), names(delphi_ras))
      preds_future_delp <- preds
      
      for (v in common_vars) {
        preds_future_delp[[v]] <- preds[[v]] * (1 + delphi_ras[[v]] / 100)
      }
      
      bv             <- rast(paste0("./out/fpredictors/ssp", scen, "_", yrs[y], ".tif"))
      bv             <- crop(bv, state_ext)  # crop climate raster too
      common_bv_vars <- intersect(names(preds_future_delp), names(bv))
      
      preds_future_delp_bio <- preds_future_delp
      for (v in common_bv_vars) {
        preds_future_delp_bio[[v]] <- bv[[v]]
      }
      
      writeRaster(
        preds_future_delp_bio,
        paste0("./out/fpredictors/delphi_ras_national_and_ST/", state_abbr, "/ssp", scen, "_", crop,
               "_2041_2060_delphi_NATIONAL_AND_", state_abbr, "_AG.tif"),
        overwrite = TRUE
      )
      
      # --- Extract only state counties ---
      county_agg <- terra::extract(preds_future_delp_bio, state_counties_prj,
                                   fun = mean, na.rm = TRUE)
      county_agg[is.na(county_agg)] <- 0
      county_agg <- cbind(state_counties_prj["GEOID"], county_agg) %>% select(-ID)
      
      write.csv(
        st_drop_geometry(county_agg),
        file = paste0("./out/fpredictors/delphi_rds_national_and_ST/", state_abbr, "/ssp", scen, "_", crop,
                      "_2041_2060_delphi_NATIONAL_AND_", state_abbr, "_AGG.csv"),
        row.names = FALSE
      )
      
      saveRDS(
        county_agg,
        file = paste0("./out/fpredictors/delphi_rds_national_and_ST/", state_abbr, "/ssp", scen, "_", crop,
                      "_2041_2060_delphi_NATIONAL_AND_", state_abbr, "_AGG.RDS")
      )
    }
  }
}

#### Running for three states 

for (state in c("GA", "NE", "OH")) {
  build_delphi_panel_state(state)

}

# -------------------------------------------------------------------
# STEP 2: Predict future crop likelihood from state Delphi rasters
# -------------------------------------------------------------------
future_suitability_state <- function(state_abbr) {
  
  print(paste("Predicting suitability for:", state_abbr))
  
  dir.create(paste0("./out/model2_R/fprob"), showWarnings = FALSE, recursive = TRUE)
  
  for (p in 1:length(scen_list)) {
    
    scen <- scen_list[p]
    print(paste("Scenario:", scen))
    
    for (i in 1:length(crop_names)) {
      
      crop  <- crop_names[i]
      print(paste("Crop:", crop))
      
      rf_ap <- readRDS(paste0("./out/model2_R/rf/", crop, "_RF_AG.RDS"))
      
      preds_rast <- rast(
        paste0("./out/fpredictors/delphi_ras_national_and_ST/", state_abbr, "/ssp", scen, "_", crop,
               "_2041_2060_delphi_NATIONAL_AND_", state_abbr, "_AG.tif")
      )
      
      prob <- predict(preds_rast, rf_ap, type = "prob")
      p1   <- prob[[2]]
      names(p1) <- yrs[y]
      
      writeRaster(
        p1,
        paste0("./out/model2_R/fprob/ssp", scen, "_", crop,
               "_AG_DELPHI_NATIONAL_AND_", state_abbr, ".tif"),
        overwrite = TRUE
      )
    }
  }
}
 
#### Running for three states 

for (state in c("GA", "NE", "OH")) {
  future_suitability_state(state)
  
}

######### Plotting boxplots


# -------------------------------------------------------------------
# Helper: mask to state, apply threshold, return delta values
# -------------------------------------------------------------------
get_diff_vals_masked <- function(r_hist, r_fut, state_mask, threshold = 0.05) {
  r_hist_s  <- mask(r_hist, state_mask)
  r_fut_s   <- mask(r_fut,  state_mask)
  mask_thr  <- (r_hist_s > threshold) | (r_fut_s > threshold)
  diff      <- mask_thr * (r_fut_s - r_hist_s)
  diff[!mask_thr] <- NA
  as.vector(values(diff, na.rm = TRUE))
}

plot_scens <- c("245", "585")

state_config <- list(
  GA = list(
    csv       = "E:/DISES/quantitative_data/data_input_RF_2/delphi_df_percent_change_national_and_GA.csv",
    fips      = "13",
    label     = "Georgia",
    crops     = c("COTTON", "PEANUTS")
  ),
  NE = list(
    csv       = "E:/DISES/quantitative_data/data_input_RF_2/delphi_df_percent_change_national_and_NE.csv",
    fips      = "31",
    label     = "Nebraska",
    crops     = c("SOY", "CORN", "HAY")
  ),
  OH = list(
    csv       = "E:/DISES/quantitative_data/data_input_RF_2/delphi_df_percent_change_national_and_OH.csv",
    fips      = "39",
    label     = "Ohio",
    crops     = c("SOY", "CORN", "HAY")
  )
)

# -------------------------------------------------------------------
# Main plotting function per state
# -------------------------------------------------------------------
make_state_boxplots_3way <- function(state_abbr) {
  
  cfg <- state_config[[state_abbr]]
  print(paste("Making 3-way boxplots for:", cfg$label))
  
  wc_ref <- rast("./out/hpredictors/hist_biovars.tif")
  
  # Build state extent and mask
  state_counties <- counties %>% filter(substr(GEOID, 1, 2) == cfg$fips)
  state_sf_prj   <- st_transform(st_union(state_counties), crs(wc_ref))
  state_vect     <- vect(state_sf_prj)
  state_ext      <- ext(state_vect)
  
  df_state <- data.frame()
  
  for (scen in plot_scens) {
    for (crop in crop_names) {
      
      # Load and crop CE-US rasters to state extent
      r_hist <- crop(rast(paste0("./out/model2_R/hprob/", crop, "_AG.tif"))[[2]], state_ext)
      r_clim <- crop(rast(paste0("./out/model2_R/fprob/ssp", scen, "_", crop, "_AG.tif"))[[y]], state_ext)
      r_natl <- crop(rast(paste0("./out/model2_R/fprob/ssp", scen, "_", crop, "_AG_DELPHI_ONLY_NATIONAL.tif"))[[1]], state_ext)
      
      # State raster already at state extent
      r_st <- rast(paste0("./out/model2_R/fprob/ssp", scen, "_", crop,
                          "_AG_DELPHI_NATIONAL_AND_", state_abbr, ".tif"))[[1]]
      
      # Build mask from state vector at consistent extent/resolution
      state_mask_r <- rasterize(state_vect, r_hist, field = 1)
      
      vals_clim <- get_diff_vals_masked(r_hist, r_clim, state_mask_r)
      vals_natl <- get_diff_vals_masked(r_hist, r_natl, state_mask_r)
      vals_st   <- get_diff_vals_masked(r_hist, r_st,   state_mask_r)
      

      
      df_crop <- data.frame(
        Crop     = tools::toTitleCase(tolower(crop)),
        Scenario = paste0("SSP", scen),
        Type     = rep(
          c("Climate only", "National Delphi", paste0(cfg$label, " Delphi")),
          times = c(length(vals_clim), length(vals_natl), length(vals_st))
        ),
        Delta    = c(vals_clim, vals_natl, vals_st)
      )
      
      df_state <- rbind(df_state, df_crop)
    }
  }
  
  df_state$Crop <- gsub("Fruitveg", "Fruit-Veg", df_state$Crop)
  df_state$Crop <- factor(df_state$Crop)
  df_state$Type <- factor(df_state$Type,
                          levels = c("Climate only", "National Delphi",
                                     paste0(cfg$label, " Delphi")))
  
  type_colors <- c(
    "Climate only"    = "#4575b4",
    "National Delphi" = "#f46d43",
    placeholder       = "#1a9850"
  )
  names(type_colors)[3] <- paste0(cfg$label, " Delphi")
  
  for (ssp_label in c("SSP245", "SSP585")) {
    
    p <- ggplot(df_state %>% filter(Scenario == ssp_label),
                aes(x = Crop, y = Delta, fill = Type)) +
      geom_hline(yintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.4) +
      geom_boxplot(
        outlier.size  = 0.3,
        outlier.alpha = 0.3,
        linewidth     = 0.4,
        width         = 0.65,
        position      = position_dodge(width = 0.78)
      ) +
      scale_fill_manual(values = type_colors) +
      scale_y_continuous(
        limits = c(-1, 1),
        breaks = seq(-1, 1, 0.25),
        labels = scales::number_format(accuracy = 0.01)
      ) +
      labs(
        title = paste0(cfg$label, " counties — change in crop likelihood: ", ssp_label,
                       " (2041\u20132060 vs. historical)"),
        x    = NULL,
        y    = "Change in likelihood (future \u2212 historical)",
        fill = NULL
      ) +
      theme_bw(base_size = 12) +
      theme(
        axis.text.x        = element_text(angle = 35, hjust = 1, size = 10),
        axis.text.y        = element_text(size = 10),
        legend.position    = "top",
        legend.text        = element_text(size = 11),
        panel.grid.major.x = element_blank(),
        panel.grid.minor   = element_blank(),
        plot.title         = element_text(size = 12, face = "bold")
      )
    
    out_path <- paste0("./figs_model2/FUTURE/boxplot_3way_", state_abbr, "_",
                       tolower(ssp_label), ".png")
    ggsave(out_path, plot = p, width = 11, height = 5, dpi = 300)
    print(paste("Saved:", out_path))
  }
}

for (state in c("GA", "NE", "OH")) {
  make_state_boxplots_3way(state)
}

# -------------------------------------------------------
# Boxplot for Georgia — COTTON and PEANUTS only
# -------------------------------------------------------

wc_ref <- rast("./out/hpredictors/hist_biovars.tif")

state_abbr    <- "GA"
ga_crops      <- c("COTTON", "PEANUTS")
ga_fips       <- "13"
ga_label      <- "Georgia"
plot_scens    <- c("245", "585")
y             <- 2  # 2041-2060

# State extent and mask
state_counties <- counties %>% filter(substr(GEOID, 1, 2) == ga_fips)
state_sf_prj   <- st_transform(st_union(state_counties), crs(wc_ref))
state_vect     <- vect(state_sf_prj)
state_ext      <- ext(state_vect)

df_ga <- data.frame()

for (scen in plot_scens) {
  for (crop in ga_crops) {
    
    print(paste(scen, crop))
    
    r_hist <- crop(rast(paste0("./out/model2_R/hprob/", crop, "_AG.tif"))[[2]], state_ext)
    r_clim <- crop(rast(paste0("./out/model2_R/fprob/ssp", scen, "_", crop, "_AG.tif"))[[y]], state_ext)
    r_natl <- crop(rast(paste0("./out/model2_R/fprob/ssp", scen, "_", crop, "_AG_DELPHI_ONLY_NATIONAL.tif"))[[1]], state_ext)
    r_st   <- rast(paste0("./out/model2_R/fprob/ssp", scen, "_", crop, "_AG_DELPHI_NATIONAL_AND_GA.tif"))[[1]]
    
    # Align all to r_hist
    r_natl <- resample(r_natl, r_hist, method = "bilinear")
    r_st   <- resample(r_st,   r_hist, method = "bilinear")
    
    state_mask_r <- rasterize(state_vect, r_hist, field = 1)
    
    vals_clim <- get_diff_vals_masked(r_hist, r_clim, state_mask_r)
    vals_natl <- get_diff_vals_masked(r_hist, r_natl, state_mask_r)
    vals_st   <- get_diff_vals_masked(r_hist, r_st,   state_mask_r)
    
    print(paste("clim:", length(vals_clim), "natl:", length(vals_natl), "st:", length(vals_st)))
    
    df_crop <- data.frame(
      Crop     = tools::toTitleCase(tolower(crop)),
      Scenario = paste0("SSP", scen),
      Type     = rep(
        c("Climate only", "National Delphi", "Georgia Delphi"),
        times = c(length(vals_clim), length(vals_natl), length(vals_st))
      ),
      Delta    = c(vals_clim, vals_natl, vals_st)
    )
    
    df_ga <- rbind(df_ga, df_crop)
  }
}

df_ga$Crop <- factor(df_ga$Crop)
df_ga$Type <- factor(df_ga$Type,
                     levels = c("Climate only", "National Delphi", "Georgia Delphi"))

type_colors <- c(
  "Climate only"   = "#4575b4",
  "National Delphi" = "#f46d43",
  "Georgia Delphi" = "#1a9850"
)

for (ssp_label in c("SSP245", "SSP585")) {
  
  p <- ggplot(df_ga %>% filter(Scenario == ssp_label),
              aes(x = Crop, y = Delta, fill = Type)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.4) +
    geom_boxplot(
      outlier.size  = 0.3,
      outlier.alpha = 0.3,
      linewidth     = 0.4,
      width         = 0.65,
      position      = position_dodge(width = 0.78)
    ) +
    scale_fill_manual(values = type_colors) +
    scale_y_continuous(
      limits = c(-1, 1),
      breaks = seq(-1, 1, 0.25),
      labels = scales::number_format(accuracy = 0.01)
    ) +
    labs(
      title = paste0("Georgia counties — change in crop likelihood: ", ssp_label,
                     " (2041\u20132060 vs. historical)"),
      x    = NULL,
      y    = "Change in likelihood (future \u2212 historical)",
      fill = NULL
    ) +
    theme_bw(base_size = 12) +
    theme(
      axis.text.x        = element_text(angle = 35, hjust = 1, size = 10),
      axis.text.y        = element_text(size = 10),
      legend.position    = "top",
      legend.text        = element_text(size = 11),
      panel.grid.major.x = element_blank(),
      panel.grid.minor   = element_blank(),
      plot.title         = element_text(size = 12, face = "bold")
    )
  
  out_path <- paste0("./figs_model2/FUTURE/boxplot_3way_GA_", tolower(ssp_label), ".png")
  ggsave(out_path, plot = p, width = 7, height = 5, dpi = 300)
  print(paste("Saved:", out_path))
}


df_ga %>%
  group_by(Crop, Scenario, Type) %>%
  summarise(
    mean  = round(mean(Delta), 4),
    sd    = round(sd(Delta), 4),
    n     = n(),
    .groups = "drop"
  ) %>%
  print(n = Inf)




# Check KONAR_GWW values across all four predictor stacks for GA
# Load one crop as example — COTTON

crop      <- "COTTON"
scen      <- "245"
state_ext <- ext(vect(st_transform(st_union(counties %>% filter(substr(GEOID, 1, 2) == "13")), 
                                   crs(rast("./out/hpredictors/hist_biovars.tif")))))

# Historical predictor stack
preds_hist <- rast("./out/hpredictors/epsg5070/all_ag_preds_2.tif")
konar_hist <- rast("./out/hpredictors/epsg5070/konar_norm_COTTON.tif")
preds_hist <- crop(c(preds_hist, konar_hist), state_ext)

# Climate only predictor stack (AG vars unchanged, only climate updated)
# KONAR_GWW is an AG var so it should be identical to historical
preds_clim <- rast(paste0("./out/fpredictors/delphi_ras/ssp", scen, "_", crop, "_2041_2060_delphi_AG.tif"))
preds_clim <- crop(preds_clim, state_ext)

# National Delphi predictor stack
preds_natl <- rast(paste0("./out/fpredictors/delphi_ras_national_only/ssp", scen, "_", crop, 
                          "_2041_2060_delphi_national_AG.tif"))
preds_natl <- crop(preds_natl, state_ext)

# GA state Delphi predictor stack
preds_st <- rast(paste0("./out/fpredictors/delphi_ras_national_and_ST/GA/ssp", scen, "_", crop,
                        "_2041_2060_delphi_NATIONAL_AND_GA_AG.tif"))

# Compare KONAR_GWW mean values across all four
print("KONAR_GWW mean — Historical:")
print(global(preds_hist[["KONAR_GWW"]], "mean", na.rm = TRUE))

print("KONAR_GWW mean — Climate only (should match historical):")
print(global(preds_clim[["KONAR_GWW"]], "mean", na.rm = TRUE))

print("KONAR_GWW mean — National Delphi:")
print(global(preds_natl[["KONAR_GWW"]], "mean", na.rm = TRUE))

print("KONAR_GWW mean — GA State Delphi:")
print(global(preds_st[["KONAR_GWW"]], "mean", na.rm = TRUE))


delphi_national <- read.csv("E:/DISES/quantitative_data/data_input_RF_2/delphi_df_percent_change_only_national.csv")
"KONAR_GWW" %in% names(delphi_national)



















######################################################
#################################
# MAking Bar chart
# avg suitabilty does not make sense over US


# Initialize dataframe
df_summary <- data.frame(
  Crop = character(),
  Scenario = character(),
  MeanSuitability = numeric(),
  stringsAsFactors = FALSE
)

pr_hist <- Sys.glob("./out/model2_R/hprob/*_AG.tif")
pr_fut  <- Sys.glob("./out/model2_R/fprob/ssp585*_AG.tif")

for (i in 1:length(crop_names)) {
  # Load rasters
  r_hist <- rast(pr_hist[i])[[2]]  # historical
  r_fut  <- rast(pr_fut[i])[[1]]   # future
  

  # Compute mean (ignore NA)
  mean_hist <- global(r_hist, "mean", na.rm = TRUE)[1,1]
  mean_fut  <- global(r_fut, "mean", na.rm = TRUE)[1,1]
  
  # Add to dataframe
  df_summary <- rbind(df_summary,
                      data.frame(Crop = crop_names[i],
                                 Scenario = "Historical",
                                 MeanSuitability = mean_hist),
                      data.frame(Crop = crop_names[i],
                                 Scenario = "Future",
                                 MeanSuitability = mean_fut))
}

p4 <- ggplot(df_summary, aes(x = Crop, y = MeanSuitability, fill = Scenario)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.8), width = 0.7) +
  coord_flip() +  # makes bars horizontal
  scale_fill_manual(values = c("Historical" = "#6baed6", "Future" = "#F88379")) + 
  labs(x = "", y = "Mean Suitability", fill = "") +
  theme_bw(base_size = 14) +
  theme(
    axis.text.y = element_text(size = 12),
    axis.text.x = element_text(size = 12),
    panel.grid.major.y = element_blank(),
    panel.grid.minor.y = element_blank(),
    legend.position = "top"
  ) +
  geom_text(aes(label = round(MeanSuitability, 2)),
            position = position_dodge(width = 0.8),
            hjust = -0.1, size = 3)


p4
