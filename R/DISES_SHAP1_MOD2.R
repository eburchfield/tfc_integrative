#This script reads the SHAP output files and performs the analysis  

library(randomForest)
library(treeshap)
library(MASS)
library(quantreg)
library(mgcv)
library(grid) 
library(gridExtra)
library(ggpattern)
library(ggforce)
library(Ternary)
library(RColorBrewer)

setwd("G:/") # change to your WD
source("DISES_load.R")


# Reading SHAP outputs for HPC


# Reading SHAP values obtained from HPC

# model 1 SHAP files
# shap_barley = readRDS("./out/SHAP/BARLEY_SHAP_AG.RDS")
# shap_cotton = readRDS("./out/SHAP/COTTON_SHAP_AG.RDS")
# shap_pecans = readRDS("./out/SHAP/PECANS_SHAP_AG.RDS")
# shap_oats = readRDS("./out/SHAP/OATS_SHAP_AG.RDS")
# shap_peanuts = readRDS("./out/SHAP/PEANUTS_SHAP_AG.RDS")
# shap_sorghum = readRDS("./out/SHAP/SORGHUM_SHAP_AG.RDS")
# shap_fruitveg = readRDS("./out/SHAP/FRUITVEG_SHAP_AG.RDS")
# shap_rye = readRDS("./out/SHAP/RYE_SHAP_AG.RDS")
# shap_soy = readRDS("./out/SHAP/SOY_SHAP_AG.RDS")
# shap_wheat = readRDS("./out/SHAP/WHEAT_SHAP_AG.RDS")
# shap_corn = readRDS("./out/SHAP/CORN_SHAP_AG.RDS")
# shap_pasture = readRDS("./out/SHAP/PASTURE_SHAP_AG.RDS")
# shap_hay = readRDS("./out/SHAP/HAY_SHAP_AG.RDS")

shap_barley = readRDS("./out/model2_R/SHAP/BARLEY_SHAP_AG.RDS")
shap_cotton = readRDS("./out/model2_R/SHAP/COTTON_SHAP_AG.RDS")
shap_pecans = readRDS("./out/model2_R/SHAP/PECANS_SHAP_AG.RDS")
shap_oats = readRDS("./out/model2_R/SHAP/OATS_SHAP_AG.RDS")
shap_peanuts = readRDS("./out/model2_R/SHAP/PEANUTS_SHAP_AG.RDS")
shap_sorghum = readRDS("./out/model2_R/SHAP/SORGHUM_SHAP_AG.RDS")
shap_fruitveg = readRDS("./out/model2_R/SHAP/FRUITVEG_SHAP_AG.RDS")
shap_rye = readRDS("./out/model2_R/SHAP/RYE_SHAP_AG.RDS")
shap_soy = readRDS("./out/model2_R/SHAP/SOY_SHAP_AG.RDS")
shap_wheat = readRDS("./out/model2_R/SHAP/WHEAT_SHAP_AG.RDS")
shap_corn = readRDS("./out/model2_R/SHAP/CORN_SHAP_AG.RDS")
shap_pasture = readRDS("./out/model2_R/SHAP/PASTURE_SHAP_AG.RDS")
shap_hay = readRDS("./out/model2_R/SHAP/HAY_SHAP_AG.RDS")

# $shaps gives the shap value dataframe
barley_shap_vals = shap_barley$shaps
cotton_shap_vals = shap_cotton$shaps
pecans_shap_vals = shap_pecans$shaps
oats_shap_vals = shap_oats$shaps
peanuts_shap_vals = shap_peanuts$shaps
sorghum_shap_vals = shap_sorghum$shaps
fruitveg_shap_vals = shap_fruitveg$shaps
rye_shap_vals = shap_rye$shaps
soy_shap_vals = shap_soy$shaps
wheat_shap_vals = shap_wheat$shaps
corn_shap_vals = shap_corn$shaps
pasture_shap_vals = shap_pasture$shaps
hay_shap_vals = shap_hay$shaps

# Calculating feature importances (mean shap values)

barley_shap_imp = sort(colMeans(abs(barley_shap_vals)), decreasing  = TRUE)
cotton_shap_imp = sort(colMeans(abs(cotton_shap_vals)), decreasing  = TRUE)
pecans_shap_imp = sort(colMeans(abs(pecans_shap_vals)), decreasing  = TRUE)
oats_shap_imp = sort(colMeans(abs(oats_shap_vals)), decreasing  = TRUE)
peanuts_shap_imp = sort(colMeans(abs(peanuts_shap_vals)), decreasing  = TRUE)
sorghum_shap_imp = sort(colMeans(abs(sorghum_shap_vals)), decreasing  = TRUE)
fruitveg_shap_imp = sort(colMeans(abs(fruitveg_shap_vals)), decreasing  = TRUE)
rye_shap_imp = sort(colMeans(abs(rye_shap_vals)), decreasing  = TRUE)
soy_shap_imp = sort(colMeans(abs(soy_shap_vals)), decreasing  = TRUE)
wheat_shap_imp = sort(colMeans(abs(wheat_shap_vals)), decreasing  = TRUE)
pasture_shap_imp = sort(colMeans(abs(pasture_shap_vals)), decreasing  = TRUE)
hay_shap_imp = sort(colMeans(abs(hay_shap_vals)), decreasing  = TRUE)
corn_shap_imp = sort(colMeans(abs(corn_shap_vals)), decreasing  = TRUE)

county_agg_barley  <- readRDS("G:/out/county_agg_mod2_mirca/BARLEY_AGG.RDS")
county_agg_cotton  <- readRDS("G:/out/county_agg_mod2_mirca/COTTON_AGG.RDS")
county_agg_pecans  <- readRDS("G:/out/county_agg_mod2_mirca/PECANS_AGG.RDS")
county_agg_oats    <- readRDS("G:/out/county_agg_mod2_mirca/OATS_AGG.RDS")
county_agg_peanuts <- readRDS("G:/out/county_agg_mod2_mirca/PEANUTS_AGG.RDS")
county_agg_sorghum <- readRDS("G:/out/county_agg_mod2_mirca/SORGHUM_AGG.RDS")
county_agg_fruitveg<- readRDS("G:/out/county_agg_mod2_mirca/FRUITVEG_AGG.RDS")
county_agg_rye     <- readRDS("G:/out/county_agg_mod2_mirca/RYE_AGG.RDS")
county_agg_soy     <- readRDS("G:/out/county_agg_mod2_mirca/SOY_AGG.RDS")
county_agg_wheat   <- readRDS("G:/out/county_agg_mod2_mirca/WHEAT_AGG.RDS")
county_agg_corn    <- readRDS("G:/out/county_agg_mod2_mirca/CORN_AGG.RDS")
county_agg_pasture <- readRDS("G:/out/county_agg_mod2_mirca/PASTURE_AGG.RDS")
county_agg_hay     <- readRDS("G:/out/county_agg_mod2_mirca/HAY_AGG.RDS")

# Making spatial st dataframe of shap values 
for (crop in crop_names) {
  shap_obj <- get(paste0(tolower(crop), "_shap_vals"))
  county_obj <- get(paste0("county_agg_", tolower(crop)))
  
  shap_obj$GEOID <- county_obj$GEOID
  shap_obj$geometry <- county_obj$geometry
  
  # Convert to sf object (spatial dataframe)
  shap_obj <- st_as_sf(shap_obj)
  
  # Save back to the same variable
  assign(paste0(tolower(crop), "_shap_vals_st"), shap_obj)
}
###########

colnames(barley_shap_vals)
names(corn_shap_imp[1:24])

############################   PLOT-1: Feature importance for features ###################################
# Making custom function for plottting importance, so that we can change the colors, fonts, etc
plot_feature_importance1 <- function(shap_imp, title = "Crop SHAP Importance", text_size_y = 10 , 
                                     text_size_x = 8, x_label = "SHAP Importance", y_label = "Variables"){
  p <- ggplot() +
    geom_bar(aes(x = reorder(names(shap_imp), shap_imp), y = shap_imp), 
             stat = "identity", fill = "skyblue") +
    coord_flip() +  # Flips the plot horizontally
    labs(x = y_label, y = x_label, title = title) +
    theme_bw() +
    theme(axis.text.y = element_text(size = text_size_y, hjust = 1, vjust = 0.5, color = 'black'),
          axis.text.x = element_text(size = text_size_x, hjust = 1, vjust = 0.5, color = 'black'),
          panel.grid.major = element_blank(),  # Remove major grid lines
          panel.grid.minor = element_blank(),
          axis.line.x = element_line(color = "grey"),  # Keep only the bottom axis line
          axis.line.y = element_line(color = "grey"),  # Keep only the left axis line
          panel.border = element_blank(),  # Remove the border around the plot
          plot.title = element_text(hjust = 0.5, size = 16) ) # Center the title 
  print(p)
}

#Plotting feature importance bar plots
plot_feature_importance(shap_barley)
plot_feature_importance1(corn_shap_imp)
test1 = plot_feature_importance1(corn_shap_imp)
ggsave(paste0("./figs_model2/test1_importance_shap.png"), scale = 1.2, bg = "white", width = 10, height = 10)

#crop_names11 = c("BARLEY", "COTTON", "FRUITVEG", "OATS", "PEANUTS", "PECANS", "RYE", "SORGHUM")
crop_names <- c("CORN", "COTTON", "SOY", "WHEAT", "PEANUTS", "HAY", "PASTURE", "FRUITVEG", "PECANS", "OATS", "BARLEY", "SORGHUM", "RYE")
crop_names2 <- c("CORN", "COTTON", "SOY", "WHEAT", "HAY", "PASTURE")

for (i in 1: length(crop_names)){
  plot_feature_importance1(get(paste0(tolower(crop_names[i]), "_shap_imp")), crop_names[i])
  ggsave(paste0("./figs_model2/feature_importance/", crop_names[i], "_importance_shap.png"), scale = 1.2, bg = "white", width = 10, height = 10)
}

#################################################################################################################

group_list <- list(
  Climate = c("BV1_Annual_Mean_Temp", "BV2_Mean_Diurnal_Range", "BV4_Temp_Seasonality",
              "BV5_MaxTemp_Warm_Month", "BV6_MinTemp_Cold_Month", "BV8_MeanTemp_Wet_Quart",
              "BV9_MeanTemp_Driest_Quart", "BV10_MeanTemp_Warm_Quart", "BV11_MeanTemp_Cold_Quart",
              "BV12_Annual_Precip", "BV13_Precip_Wet_Month", "BV14_Precip_Dry_Month", "B15_CoV_Precip", 
              "B16_Precip_Wet_Quart", "B17_Precip_Dry_Quart", "B18_Precip_Warm_Quart", "B19_Precip_Cold_Quart"),
  Soil = c("T_BULK_DEN", "T_CEC_CLAY", "T_CLAY", "T_GRAVEL", "T_SAND", "T_SILT"),
  Topography = c("NA_1KM_SLOPE", "NA_1KM"),
  Irrigation = c("IRRIG_std", "KONAR_GWW",  "KONAR_SWW", "IRRIG_MIRCA"),  #IRRIG_std i MIRAD data which needs to be replaced with MIRCA
  Management = c("cover_crop_acre",  "till_new_conservational_acre", 
                 "tile_drain_acres", "CRP_ACRE", "EQIP_ACRE", 
                 "live_cattle_inventory", "organic_number_operations"),
  Inputs = c("fert_exp_usd", "chem_exp_usd", "N_manure_kg", "P_manure_kg", 
             "N_fert_kg", "P_fert_kg", "labor_number", "machinery_usd", "Cao_fert_N", "Cao_fert_P"),
  Economics = c("animal_sales_usd", "rented_fract", "no_ops_sales_lt_10k", "directsales_retail", 
                "sales_usd_gt_500k", "ag_land_value_usd","PRICE", 
                "crop_insurance_acre_rma"),
  Demographics = c("RUCC_2013", "Producer_female", "Producer_nonwhite", "median_farmsize", 
                    "Producer_age_le_35", "producer_exp_lt_10"),             
  Infrastructure = c("mean_est_std", "biofuel_corn_percent_used", "biofuel_soy_percent_used")
)


#####


list_clim_temp = c("BV1_Annual_Mean_Temp", "BV2_Mean_Diurnal_Range", "BV4_Temp_Seasonality",
                   "BV5_MaxTemp_Warm_Month", "BV6_MinTemp_Cold_Month", "BV8_MeanTemp_Wet_Quart",
                   "BV9_MeanTemp_Driest_Quart", "BV10_MeanTemp_Warm_Quart", "BV11_MeanTemp_Cold_Quart")

list_clim_prec = c("BV12_Annual_Precip", "BV13_Precip_Wet_Month", "BV14_Precip_Dry_Month", "B15_CoV_Precip", 
                   "B16_Precip_Wet_Quart", "B17_Precip_Dry_Quart", "B18_Precip_Warm_Quart", "B19_Precip_Cold_Quart")


sapply(group_list, length)

###################### PLOT 2- Feature importance for categories ###################################

#Below function sums raw shap values over columns based on group categories

func_agg_shap_vals <- function(df) {
  
  # Determine correct irrigation variable based on column presence
  if ("IRRIG_MIRCA" %in% colnames(df)) {
    irrigation_vars <- c("IRRIG_MIRCA", "KONAR_GWW", "KONAR_SWW")
  } else {
    irrigation_vars <- c("IRRIG_std", "KONAR_GWW", "KONAR_SWW")
  }
  
  econ_vars <- group_list$Economics
  if (!("PRICE" %in% colnames(df))) {   #if PRICE isnt in the df column, then drop it from the economics categories
    econ_vars <- setdiff(econ_vars, "PRICE")
  }
  
  
  df %>%
    mutate(
      Climate = rowSums(df[, group_list$Climate], na.rm = TRUE),
      Soil = rowSums(df[, group_list$Soil], na.rm = TRUE),
      Topography = rowSums(df[, group_list$Topography], na.rm = TRUE),
      Irrigation = rowSums(df[, irrigation_vars], na.rm = TRUE),
      Management = rowSums(df[, group_list$Management], na.rm = TRUE),
      Inputs = rowSums(df[, group_list$Inputs], na.rm = TRUE),
      Economics = rowSums(df[, econ_vars], na.rm = TRUE),
      Demographics = rowSums(df[, group_list$Demographics], na.rm = TRUE),
      Infrastructure = rowSums(df[, group_list$Infrastructure], na.rm = TRUE)
    ) %>%
    select(Climate, Soil, Topography, Irrigation, Management, Inputs, Economics, Demographics, Infrastructure)
}

# Used absolute sum for the paper
func_agg_shap_vals_abs <- function(df) {
  # Determine correct irrigation variable based on column presence
  if ("IRRIG_MIRCA" %in% colnames(df)) {
    irrigation_vars <- c("IRRIG_MIRCA", "KONAR_GWW", "KONAR_SWW")
  } else {
    irrigation_vars <- c("IRRIG_std", "KONAR_GWW", "KONAR_SWW")
  }
  
  econ_vars <- group_list$Economics
  if (!("PRICE" %in% colnames(df))) {   #if PRICE isnt in the df column, then drop it from the economics categories
    econ_vars <- setdiff(econ_vars, "PRICE")
  }
  
  
  df %>%
    mutate(
      Climate = rowSums(abs(df[, group_list$Climate]), na.rm = TRUE),
      Soil = rowSums(abs(df[, group_list$Soil]), na.rm = TRUE),
      Topography = rowSums(abs(df[, group_list$Topography]), na.rm = TRUE),
      Irrigation = rowSums(abs(df[, irrigation_vars]), na.rm = TRUE),
      Management = rowSums(abs(df[, group_list$Management]), na.rm = TRUE),
      Inputs = rowSums(abs(df[, group_list$Inputs]), na.rm = TRUE),
      Economics = rowSums(abs(df[, econ_vars]), na.rm = TRUE),
      Demographics = rowSums(abs(df[, group_list$Demographics]), na.rm = TRUE),
      Infrastructure = rowSums(abs(df[, group_list$Infrastructure]), na.rm = TRUE)
    ) %>%
    select(Climate, Soil, Topography, Irrigation, Management, Inputs, Economics, Demographics, Infrastructure)
}


#Using the function which sums the absolute values of shap values to get the importance of a group
# Summing using the actual shap values would return how much (+ve/-ve) influence of a group on the response variable
aggregated_cat_shap_barley = func_agg_shap_vals_abs(barley_shap_vals)
aggregated_cat_shap_cotton = func_agg_shap_vals_abs(cotton_shap_vals)
aggregated_cat_shap_pecans = func_agg_shap_vals_abs(pecans_shap_vals)
aggregated_cat_shap_oats = func_agg_shap_vals_abs(oats_shap_vals)
aggregated_cat_shap_peanuts = func_agg_shap_vals_abs(peanuts_shap_vals)
aggregated_cat_shap_sorghum = func_agg_shap_vals_abs(sorghum_shap_vals)
aggregated_cat_shap_fruitveg = func_agg_shap_vals_abs(fruitveg_shap_vals)
aggregated_cat_shap_rye = func_agg_shap_vals_abs(rye_shap_vals)
aggregated_cat_shap_corn = func_agg_shap_vals_abs(corn_shap_vals)
aggregated_cat_shap_soy = func_agg_shap_vals_abs(soy_shap_vals)
aggregated_cat_shap_wheat = func_agg_shap_vals_abs(wheat_shap_vals)
aggregated_cat_shap_hay = func_agg_shap_vals_abs(hay_shap_vals)
aggregated_cat_shap_pasture = func_agg_shap_vals_abs(pasture_shap_vals)

barley_shap_imp_cat = colMeans(abs(aggregated_cat_shap_barley))
cotton_shap_imp_cat = colMeans(abs(aggregated_cat_shap_cotton))
pecans_shap_imp_cat = colMeans(abs(aggregated_cat_shap_pecans))
oats_shap_imp_cat = colMeans(abs(aggregated_cat_shap_oats))
peanuts_shap_imp_cat = colMeans(abs(aggregated_cat_shap_peanuts))
sorghum_shap_imp_cat = colMeans(abs(aggregated_cat_shap_sorghum))
fruitveg_shap_imp_cat = colMeans(abs(aggregated_cat_shap_fruitveg))
rye_shap_imp_cat = colMeans(abs(aggregated_cat_shap_rye))
corn_shap_imp_cat = colMeans(abs(aggregated_cat_shap_corn))
soy_shap_imp_cat = colMeans(abs(aggregated_cat_shap_soy))
wheat_shap_imp_cat = colMeans(abs(aggregated_cat_shap_wheat))
hay_shap_imp_cat = colMeans(abs(aggregated_cat_shap_hay))
pasture_shap_imp_cat = colMeans(abs(aggregated_cat_shap_pasture))


########### NOT ABSOLUTE (RAW SUM)
#Using the function which sums the NOT ABSOLUTE (RAW) values of shap values to get the importance of a group
aggregated_cat_shap_raw_barley = func_agg_shap_vals(barley_shap_vals)
aggregated_cat_shap_raw_cotton = func_agg_shap_vals(cotton_shap_vals)
aggregated_cat_shap_raw_pecans = func_agg_shap_vals(pecans_shap_vals)
aggregated_cat_shap_raw_oats = func_agg_shap_vals(oats_shap_vals)
aggregated_cat_shap_raw_peanuts = func_agg_shap_vals(peanuts_shap_vals)
aggregated_cat_shap_raw_sorghum = func_agg_shap_vals(sorghum_shap_vals)
aggregated_cat_shap_raw_fruitveg = func_agg_shap_vals(fruitveg_shap_vals)
aggregated_cat_shap_raw_rye = func_agg_shap_vals(rye_shap_vals)
aggregated_cat_shap_raw_corn = func_agg_shap_vals(corn_shap_vals)
aggregated_cat_shap_raw_soy = func_agg_shap_vals(soy_shap_vals)
aggregated_cat_shap_raw_wheat = func_agg_shap_vals(wheat_shap_vals)
aggregated_cat_shap_raw_hay = func_agg_shap_vals(hay_shap_vals)
aggregated_cat_shap_raw_pasture = func_agg_shap_vals(pasture_shap_vals)

barley_shap_raw_imp_cat = colMeans(abs(aggregated_cat_shap_raw_barley))
cotton_shap_raw_imp_cat = colMeans(abs(aggregated_cat_shap_raw_cotton))
pecans_shap_raw_imp_cat = colMeans(abs(aggregated_cat_shap_raw_pecans))
oats_shap_raw_imp_cat = colMeans(abs(aggregated_cat_shap_raw_oats))
peanuts_shap_raw_imp_cat = colMeans(abs(aggregated_cat_shap_raw_peanuts))
sorghum_shap_raw_imp_cat = colMeans(abs(aggregated_cat_shap_raw_sorghum))
fruitveg_shap_raw_imp_cat = colMeans(abs(aggregated_cat_shap_raw_fruitveg))
rye_shap_raw_imp_cat = colMeans(abs(aggregated_cat_shap_raw_rye))
corn_shap_raw_imp_cat = colMeans(abs(aggregated_cat_shap_raw_corn))
soy_shap_raw_imp_cat = colMeans(abs(aggregated_cat_shap_raw_soy))
wheat_shap_raw_imp_cat = colMeans(abs(aggregated_cat_shap_raw_wheat))
hay_shap_raw_imp_cat = colMeans(abs(aggregated_cat_shap_raw_hay))
pasture_shap_raw_imp_cat = colMeans(abs(aggregated_cat_shap_raw_pasture))


############################

check_temp_plot = ggplot(data.frame(Category = names(barley_shap_raw_imp_cat), Importance = barley_shap_raw_imp_cat), 
       aes(x = reorder(Category, Importance), y = Importance)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  coord_flip() +  # Flip coordinates for better readability
  labs(title = "Bar Plot of SHAP Importance Values for Barley Categories",
       x = "Category",
       y = "Importance") +
  theme_minimal()
check_temp_plot

combined_crop_group_imp = data.frame(
  Category = rep(names(barley_shap_imp_cat), 13),  # replicate for each crop
  Importance = c(barley_shap_imp_cat, cotton_shap_imp_cat, pecans_shap_imp_cat, 
                 oats_shap_imp_cat, peanuts_shap_imp_cat, sorghum_shap_imp_cat, 
                 fruitveg_shap_imp_cat, rye_shap_imp_cat, corn_shap_imp_cat,
                 soy_shap_imp_cat, wheat_shap_imp_cat, hay_shap_imp_cat,pasture_shap_imp_cat ),
  Crop = rep(c("Barley", "Cotton", "Pecans", "Oats", "Peanuts", "Sorghum", "Fruit/Veg", "Rye",
               "Corn", "Soy", "Wheat", "Hay", "Pasture"), 
             each = length(barley_shap_imp_cat))  # replicate each crop's category
)

combined_crop_group_imp$Category <- factor(
  combined_crop_group_imp$Category,
  levels = rev(c(
    "Climate", "Soil", "Topography",
    "Irrigation", "Management", "Inputs",
    "Economics", "Demographics", "Infrastructure"
  ))
)

combined_crop_group_imp_raw = data.frame(
  Category = rep(names(barley_shap_raw_imp_cat), 13),  # replicate for each crop
  Importance = c(barley_shap_raw_imp_cat, cotton_shap_raw_imp_cat, pecans_shap_raw_imp_cat, 
                 oats_shap_raw_imp_cat, peanuts_shap_raw_imp_cat, sorghum_shap_raw_imp_cat, 
                 fruitveg_shap_raw_imp_cat, rye_shap_raw_imp_cat, corn_shap_raw_imp_cat,
                 soy_shap_raw_imp_cat, wheat_shap_raw_imp_cat, hay_shap_raw_imp_cat,pasture_shap_raw_imp_cat ),
  Crop = rep(c("Barley", "Cotton", "Pecans", "Oats", "Peanuts", "Sorghum", "Fruit/Veg", "Rye",
               "Corn", "Soy", "Wheat", "Hay", "Pasture"), 
             each = length(barley_shap_raw_imp_cat))  # replicate each crop's category
)

combined_crop_group_imp_raw$Category <- factor(
  combined_crop_group_imp_raw$Category,
  levels = rev(c(
    "Climate", "Soil", "Topography",
    "Irrigation", "Management", "Inputs",
    "Economics", "Demographics", "Infrastructure"
  ))
)

## 25 distinct color scheme taken from https://stackoverflow.com/a/9568659/10705248
c25 <- c(
  "dodgerblue2", "#E31A1C", # red
  "green4",
  "#6A3D9A", # purple
  "#FF7F00", # orange
  "black", "gold1",
  "skyblue2", "#FB9A99", # lt pink
  "palegreen2",
  "#CAB2D6", # lt purple
  "#FDBF6F", # lt orange
  "gray70", "khaki2",
  "maroon", "orchid1", "deeppink1", "blue1", "steelblue4",
  "darkturquoise", "green1", "yellow4", "yellow3",
  "darkorange4", "brown"
)

# X-axis has categories; and colors based on crops
group_imp_1 = ggplot(combined_crop_group_imp, aes(x = reorder(Category, Category), y = Importance, fill = Crop)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "Group-wise SHAP Importance",
       x = "Category",
       y = "Importance") +
  theme_minimal() +
  scale_fill_manual(values = c25) +  
  theme(axis.text.x = element_text(angle = 45, hjust = 1))  # Rotate x-axis text for better readability
group_imp_1
# ggsave("./figs/shap_categories1.png", group_imp_1, bg = "white")
ggsave("./figs_model2/shap_categories1.png", group_imp_1, bg = "white")

group_imp_1_raw = ggplot(combined_crop_group_imp_raw, aes(x = reorder(Category, Category), y = Importance, fill = Crop)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "Group-wise SHAP Importance",
       x = "Category",
       y = "Importance") +
  theme_minimal() +
  scale_fill_manual(values = c25) +  
  theme(axis.text.x = element_text(angle = 45, hjust = 1))  # Rotate x-axis text for better readability

group_imp_1_raw
ggsave("./figs_model2/shap_categories1_raw.png", group_imp_1_raw, bg = "white")


# X-axis has Crops; and colors based on categories
group_imp_2 = ggplot(combined_crop_group_imp, aes(x = Crop, y = Importance, fill = Category)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "Group-wise SHAP Importance",
       x = "Crop",
       y = "SHAP Importance Value") +
  theme_minimal() +
  scale_fill_manual(values = c25) +  
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.title = element_blank())  # Rotate x-axis text for better readability

group_imp_2
# ggsave("./figs/shap_categories2.png", group_imp_2, bg = "white")
ggsave("./figs_model2//shap_categories2.png", group_imp_2, bg = "white")

group_imp_2_stack = ggplot(combined_crop_group_imp, aes(x = Crop, y = Importance, fill = Category)) +
  geom_bar(stat = "identity", position = "fill") +  # Change position to "fill" for 100% stacking
  labs(title = "Group-wise SHAP Importance",
       x = "Crop",
       y = "Proportion of SHAP Importance") +  # Adjust the y-axis label to reflect proportion
  theme_minimal() +
  scale_fill_manual(values = c25) +  
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.title = element_blank())  # Rotate x-axis text for better readability

group_imp_2_stack
 # ggsave("./figs/shap_categories2_stacked.png", group_imp_2_stack, bg = "white")
ggsave("./figs_model2//shap_categories2_stacked.png", group_imp_2_stack, bg = "white")

## This does absolute sum; Using this in paper, not raw sum of shap values
group_imp_2_stack_hist_paper = ggplot(combined_crop_group_imp %>% filter(!Crop %in% stringr::str_to_title(crop_excluded_hist)) %>%
                                        mutate(
                                          Crop = recode(
                                            Crop,
                                            "Soy" = "Soybeans",
                                            "Fruit/Veg" = "Fruit-Vegetable")),
                                      aes(x = Crop, y = Importance, fill = Category)) +
  geom_bar(stat = "identity", position = "fill") +  # Change position to "fill" for 100% stacking
  labs(title = "Group-wise SHAP Importance",
       x = "",
       y = "Proportion of SHAP Importance") +  # Adjust the y-axis label to reflect proportion
  theme_minimal() +
  scale_fill_manual(values = c25) +  
  theme(
    axis.text.x = element_text(size = 14, angle = 45, hjust = 1),  # x-axis tick labels
    axis.text.y = element_text(size = 12),                         # y-axis tick labels
    axis.title.y = element_text(size = 18),                        # y-axis title
    axis.title.x = element_text(size = 0),                        # x-axis title (optional)
    legend.text = element_text(size = 14),                         # legend entries
    legend.title = element_blank()
  )

group_imp_2_stack_hist_paper
# ggsave("./figs/shap_categories2_stacked.png", group_imp_2_stack, bg = "white")
ggsave("./figs_model2//shap_categories2_stacked_hist_paper.png", group_imp_2_stack_hist_paper, bg = "white")

### This is circular bar plot 
# group_imp_2_stack_cir = ggplot(
#   combined_crop_group_imp,
#   aes(x = Crop, y = Importance, fill = Category, pattern = Group)
# ) +
#   geom_bar_pattern(
#     stat = "identity",
#     position = "fill",                 # 100% stacked
#     color = "black",
#     pattern_fill = "black",
#     pattern_alpha = 0.35,
#     pattern_density = 0.1,
#     pattern_spacing = 0.03
#   ) +
#   coord_polar(theta = "x") +           # <-- circular
#   scale_fill_manual(
#     values = c25,
#     guide = guide_legend(override.aes = list(pattern = "none"))   # no stripes in legend
#   ) +
#   scale_pattern_manual(values = c(
#     "Biophysical"    = "stripe",       # stripes inside bar
#     "Production"     = "none",
#     "Socio-economic" = "none"
#   )) +
#   guides(pattern = "none") +           # remove second pattern legend
#   theme_minimal() +
#   labs(
#     title = "Circular SHAP Importance (100% Stacked)",
#     x = NULL,
#     y = NULL
#   ) +
#   theme(
#     panel.grid = element_blank(),
#     axis.text.x = element_text(size = 10),
#     plot.title = element_text(face = "bold", size = 14)
#   )
# 
# group_imp_2_stack_cir
# ggsave("./figs_model2//shap_categories2_stacked_cir.png", group_imp_2_stack_cir, bg = "white")


# X-axis has Crops; and colors based on categories
group_imp_2_raw = ggplot(combined_crop_group_imp_raw, aes(x = Crop, y = Importance, fill = Category)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "Group-wise SHAP Importance",
       x = "Crop",
       y = "SHAP Importance Value") +
  theme_minimal() +
  scale_fill_manual(values = c25) +  
  theme(axis.text.x = element_text(angle = 45, hjust = 1))  # Rotate x-axis text for better readability

group_imp_2_raw
ggsave("./figs_model2/shap_categories2_raw.png", group_imp_2_raw, bg = "white")

group_imp_2_raw_stack = ggplot(combined_crop_group_imp_raw, aes(x = Crop, y = Importance, fill = Category)) +
  geom_bar(stat = "identity", position = "fill") +  # Change position to "fill" for 100% stacking
  labs(title = "Group-wise SHAP Importance",
       x = "Crop",
       y = "Proportion of SHAP Importance") +  # Adjust the y-axis label to reflect proportion
  theme_minimal() +
  scale_fill_manual(values = c25) +  
  theme(axis.text.x = element_text(angle = 45, hjust = 1))  # Rotate x-axis text for better readability

group_imp_2_raw_stack
ggsave("./figs_model2/shap_categories2_raw_stacked.png", group_imp_2_raw_stack, bg = "white")


group_imp_2_raw_stack_hist_paper = ggplot(combined_crop_group_imp_raw %>% filter(!Crop %in% stringr::str_to_title(crop_excluded_hist)),
                                          aes(x = Crop, y = Importance, fill = Category)) +
  geom_bar(stat = "identity", position = "fill") +  # Change position to "fill" for 100% stacking
  labs(title = "",
       x = "",
       y = "") +  # Adjust the y-axis label to reflect proportion
  theme_minimal() +
  scale_fill_manual(values = c25) +  
  theme(
    axis.text.x = element_text(angle = 90, hjust = 1, size = 15),
    axis.text.y = element_text( size = 14),
    legend.text = element_text(size = 14),
    legend.title = element_text(size = 15),
    legend.key.size = unit(1.2, "cm")
  )

group_imp_2_raw_stack_hist_paper
ggsave("./figs_model2/shap_categories2_raw_stacked_hist_paper.png", group_imp_2_raw_stack_hist_paper, 
       width = 8,height = 8,bg = "white")


#further adding dashes and lines to separate catgory types
combined_crop_group_imp_raw$Group <- case_when(
  combined_crop_group_imp_raw$Category %in% c("Climate", "Soil", "Topography") ~ "Biophysical",
  combined_crop_group_imp_raw$Category %in% c("Irrigation", "Management", "Inputs") ~ "Production",
  TRUE ~ "Socio-economic"
)
#further adding dashes and lines to separate catgory types
combined_crop_group_imp$Group <- case_when(
  combined_crop_group_imp$Category %in% c("Climate", "Soil", "Topography") ~ "Biophysical",
  combined_crop_group_imp$Category %in% c("Irrigation", "Management", "Inputs") ~ "Production",
  TRUE ~ "Socio-economic"
)




###################
## Content for draft #content for paper #notes for paper
combined_crop_group_imp %>% filter(!Crop %in% stringr::str_to_title(crop_excluded_hist)) %>%
  select(Crop, Category, Importance) %>%
  pivot_wider(names_from = Category, values_from = Importance)

#same thing but in percentage
combined_crop_group_imp_percen_paper <- combined_crop_group_imp %>% 
  filter(!Crop %in% stringr::str_to_title(crop_excluded_hist)) %>%
  select(Crop, Category, Importance) %>%
  pivot_wider(names_from = Category, values_from = Importance) %>%
  rowwise() %>%
  mutate(total = sum(c_across(-Crop), na.rm = TRUE)) %>%
  mutate(across(-c(Crop, total), ~ .x / total * 100)) %>%
  ungroup() %>%
  select(-total)


combined_crop_group_imp_percen_paper %>%
  arrange(desc(Management)) %>%
  select(Crop, Management) %>%
  slice(1:4) %>% summarise(mean = mean(Management))  # top 4 crops's average contribution to management

combined_crop_group_imp_percen_paper %>%
  select(Crop, Climate) %>%
  summarise(mean = mean(Climate))

combined_crop_group_imp_percen_paper %>%
  mutate(biophy = rowSums(across(c(Climate, Soil, Topography)))) %>%
  summarise(mean = mean(biophy))

combined_crop_group_imp_percen_paper %>%
  summarise(mean = mean(Inputs))

combined_crop_group_imp_percen_paper %>%
  summarise(mean = mean(Infrastructure))

combined_crop_group_imp_raw%>% select(Crop, Category, Importance) %>%
  pivot_wider(names_from = Category, values_from = Importance)


combined_crop_group_imp %>% group_by(Crop, Group) %>%
  summarise(tot_imp = sum(Importance), .groups = "drop") %>%
  pivot_wider(names_from = Group, 
              values_from = tot_imp)

combined_crop_group_imp %>% filter(!Crop %in% stringr::str_to_title(crop_excluded_hist)) %>%
  group_by(Crop, Group) %>%
  summarise(tot_imp = sum(Importance), .groups = "drop") %>%
  pivot_wider(names_from = Group,
    values_from = tot_imp
  ) %>%
  rowwise() %>%
  mutate(
    total_sum = sum(c_across(where(is.numeric))),
    Biophysical      = Biophysical     / total_sum,
    Production   = Production  / total_sum,
    `Socio-economic` = `Socio-economic` / total_sum
  ) %>%
  ungroup() %>%
  mutate(Human = Production + `Socio-economic`)




###
 # Biophysical vs anthropogenic contribution scatterplot

# This is the same as combined_shap_imp_ag_bio which is ag/bio based separation
combined_crop_group_imp_anthro_bio = combined_crop_group_imp %>% mutate(Driver = case_when(
  Group == "Biophysical"    ~ "Biophysical",
  TRUE                      ~ "Anthropogenic"   # Production + Socio-economic
)) %>%
  group_by(Crop, Driver) %>%
  summarise(SHAP = sum(Importance), .groups = "drop") %>%
  pivot_wider(names_from = Driver, values_from = SHAP) %>%
  mutate(Dominant = if_else(Biophysical > `Anthropogenic`, "Biophysical", "Anthropogenic"))

combined_crop_group_imp_anthro_bio_percent = combined_crop_group_imp_anthro_bio <- combined_crop_group_imp_anthro_bio %>%
  mutate(
    Total        = Anthropogenic + Biophysical,
    Anthro_pct   = Anthropogenic / Total * 100,
    Bio_pct      = Biophysical   / Total * 100,
    Dominant     = if_else(Bio_pct > Anthro_pct, "Biophysical", "Anthropogenic")
  )

p_sca_anth_bio = ggplot(combined_crop_group_imp_anthro_bio  %>% filter(!Crop %in% stringr::str_to_title(crop_excluded_hist)) %>%
                          mutate(
                            Crop = recode(
                              Crop,
                              "Soy" = "Soybeans",
                              "Fruit/Veg" = "Fruit-Vegetable")), 
       aes(x = Anthropogenic, y = Biophysical)) +
  geom_abline(slope = 1, intercept = 0,
              linetype = "dashed", linewidth = 0.5, colour = "black") +
  # annotate("text", x = 0.09, y = 0.43,
  #          label = "Biophysical dominant", hjust = 0, vjust = 1,
  #          size = 3, colour = "#2d6a4f", fontface = "italic") +
  # annotate("text", x = 0.43, y = 0.09,
  #          label = "Anthropogenic dominant", hjust = 1, vjust = 0,
  #          size = 3, colour = "#c05c1a", fontface = "italic") +
  geom_point(aes(fill = Dominant),
             colour = "white",
             shape = 21, size = 10, stroke = 0.8, alpha = 0.95) +
  ggrepel::geom_text_repel(
    aes(label = Crop, colour = Dominant),
    size = 6.2, fontface = "bold",
    box.padding   = 0.6,
    point.padding = 0.6,
    segment.size  = 0.6,
    segment.alpha = 0.6,
    max.overlaps  = Inf,
    show.legend   = FALSE
  ) +
  scale_fill_manual(values = c("Biophysical"   = "#74c69d",
                               "Anthropogenic" = "#f4a261")) +
  scale_colour_manual(values = c("Biophysical"   = "#2d6a4f",
                                 "Anthropogenic" = "#c05c1a")) +
  scale_x_continuous(breaks = seq(0.1, 0.4, 0.1)) +
  scale_y_continuous(breaks = seq(0.1, 0.4, 0.1)) +
  labs(
    x = "Human-controlled SHAP importance",
    y = "Biophysical SHAP importance"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position  = "none",
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(colour = "grey90"),
    axis.title       = element_text(size = 18),
    aspect.ratio     = 1
  )
  
p_sca_anth_bio
ggsave("./figs_model2//scatter_anthro_bio_dominant.png", p_sca_anth_bio, bg = "white")


#######################################################################################
#######################################################################################
# local or regional controlled-
# Making two different groups and ternary plots based on local, regional and no controls 
# Based on who controls it AND who makes the decision

# This is based on who makes the decision ultimately== local, regional and no factors
group_list_local_regional1 <- list(
  Local = c(
    # inputs
    "N_fert_kg", "P_fert_kg", "N_manure_kg", "P_manure_kg", 
    "Cao_fert_N", "Cao_fert_P", "fert_exp_usd", "chem_exp_usd",
    "machinery_usd", "labor_number", 
    "IRRIG_std", "IRRIG_MIRCA", "KONAR_GWW", "KONAR_SWW",
    
    # management choices
    "organic_number_operations", 
    "live_cattle_inventory", "animal_sales_usd", 
    "till_new_conservational_acre", 
    "cover_crop_acre", 
    "tile_drain_acres", 
    "rented_fract",
    
    # MARKET / POLICY CHOICES
    "directsales_retail",  
    "biofuel_corn_percent_used", "biofuel_soy_percent_used",
    "CRP_ACRE", "EQIP_ACRE", 
    "crop_insurance_acre_rma"
  ),
  
  Regional = c(
    "no_ops_sales_lt_10k", "sales_usd_gt_500k", "median_farmsize",
    "Producer_female", "Producer_nonwhite", "Producer_age_le_35", 
    "PRICE", 
    "mean_est_std", 
    "RUCC_2013", 
    "ag_land_value_usd"
  ),
  
  no_control = c(
    "BV1_Annual_Mean_Temp", "BV2_Mean_Diurnal_Range", "BV4_Temp_Seasonality", 
    "BV5_MaxTemp_Warm_Month", "BV6_MinTemp_Cold_Month", "BV8_MeanTemp_Wet_Quart", 
    "BV9_MeanTemp_Driest_Quart", "BV10_MeanTemp_Warm_Quart", "BV11_MeanTemp_Cold_Quart", 
    "BV12_Annual_Precip", "BV13_Precip_Wet_Month", "BV14_Precip_Dry_Month", 
    "B15_CoV_Precip", "B16_Precip_Wet_Quart", "B17_Precip_Dry_Quart", 
    "B18_Precip_Warm_Quart", "B19_Precip_Cold_Quart", 
    "NA_1KM_SLOPE", "NA_1KM", "T_BULK_DEN", "T_CEC_CLAY", 
    "T_CLAY", "T_GRAVEL", "T_SAND", "T_SILT"
  )
)

# This is based on who controls== local, regional and no factors
group_list_local_regional2 <- list(
  Local = c(
    # INPUTS
    "N_fert_kg", "P_fert_kg", "N_manure_kg", "P_manure_kg",
    "Cao_fert_N", "Cao_fert_P", "fert_exp_usd", "chem_exp_usd",
    "machinery_usd",
    "IRRIG_std", "IRRIG_MIRCA", "KONAR_GWW", "KONAR_SWW",
    
    # MANAGEMENT
    "organic_number_operations",
    "till_new_conservational_acre",
    "cover_crop_acre",
    "tile_drain_acres",
    "rented_fract",
    "live_cattle_inventory"
  ),
  
  Regional = c(
    # REGIONAL CHOICE / ATTRIBUTES
    "no_ops_sales_lt_10k", "sales_usd_gt_500k", "median_farmsize",
    "Producer_female", "Producer_nonwhite", "Producer_age_le_35",
    "PRICE",
    "mean_est_std",
    "RUCC_2013",
    "ag_land_value_usd",
    
    # NEW ADDITIONS 
    "labor_number",
    "CRP_ACRE", "EQIP_ACRE",
    "crop_insurance_acre_rma",
    "directsales_retail",
    "biofuel_corn_percent_used", "biofuel_soy_percent_used",
    "animal_sales_usd"
  ),
  
  no_control = c(
    # NO CHOICE
    "BV1_Annual_Mean_Temp", "BV2_Mean_Diurnal_Range", "BV4_Temp_Seasonality",
    "BV5_MaxTemp_Warm_Month", "BV6_MinTemp_Cold_Month", "BV8_MeanTemp_Wet_Quart",
    "BV9_MeanTemp_Driest_Quart", "BV10_MeanTemp_Warm_Quart", "BV11_MeanTemp_Cold_Quart",
    "BV12_Annual_Precip", "BV13_Precip_Wet_Month", "BV14_Precip_Dry_Month",
    "B15_CoV_Precip", "B16_Precip_Wet_Quart", "B17_Precip_Dry_Quart",
    "B18_Precip_Warm_Quart", "B19_Precip_Cold_Quart",
    "NA_1KM_SLOPE", "NA_1KM",
    "T_BULK_DEN", "T_CEC_CLAY", "T_CLAY", "T_GRAVEL", "T_SAND", "T_SILT"
  )
)


func_agg_shap_local_regional <- function(df, group_list) {
 
  local_vars <- group_list$Local
  
  # If IRRIG_MIRCA exists, use it and drop IRRIG_std
  if ("IRRIG_MIRCA" %in% colnames(df)) {
    local_vars <- setdiff(local_vars, "IRRIG_std")
  } else {
    # If MIRCA missing, drop MIRCA and use IRRIG_std
    local_vars <- setdiff(local_vars, "IRRIG_MIRCA")
  }

  regional_vars <- group_list$Regional
  if (!("PRICE" %in% colnames(df))) {
    regional_vars <- setdiff(regional_vars, "PRICE")
  }

  df %>%
    mutate(
      Local = rowSums(df[, local_vars], na.rm = TRUE),
      Regional = rowSums(df[, regional_vars], na.rm = TRUE),
      NoControl = rowSums(df[, group_list$no_control], na.rm = TRUE)
    ) %>%
    select(Local, Regional, NoControl)
}

func_agg_shap_local_regional_abs <- function(df, group_list) {
  
  local_vars <- group_list$Local
  
  # If IRRIG_MIRCA exists, use it and drop IRRIG_std
  if ("IRRIG_MIRCA" %in% colnames(df)) {
    local_vars <- setdiff(local_vars, "IRRIG_std")
  } else {
    # If MIRCA missing, drop MIRCA and use IRRIG_std
    local_vars <- setdiff(local_vars, "IRRIG_MIRCA")
  }
  
  regional_vars <- group_list$Regional
  if (!("PRICE" %in% colnames(df))) {
    regional_vars <- setdiff(regional_vars, "PRICE")
  }  
  df %>%
    mutate(
      Local = rowSums(abs(df[, local_vars]), na.rm = TRUE),
      Regional = rowSums(abs(df[, regional_vars]), na.rm = TRUE),
      NoControl = rowSums(abs(df[, group_list$no_control]), na.rm = TRUE)
    ) %>%
    select(Local, Regional, NoControl)
}


# head(func_agg_shap_local_regional(barley_shap_vals), 10)
# head(func_agg_shap_local_regional_abs(barley_shap_vals), 10)

aggregated_local_reg_shap_corn1     = func_agg_shap_local_regional(corn_shap_vals, group_list = group_list_local_regional1)
aggregated_local_reg_shap_cotton1   = func_agg_shap_local_regional(cotton_shap_vals, group_list = group_list_local_regional1)
aggregated_local_reg_shap_soy1     = func_agg_shap_local_regional(soy_shap_vals, group_list = group_list_local_regional1)
aggregated_local_reg_shap_wheat1    = func_agg_shap_local_regional(wheat_shap_vals, group_list = group_list_local_regional1)
aggregated_local_reg_shap_peanuts1  = func_agg_shap_local_regional(peanuts_shap_vals, group_list = group_list_local_regional1)
aggregated_local_reg_shap_hay1     = func_agg_shap_local_regional(hay_shap_vals, group_list = group_list_local_regional1)
aggregated_local_reg_shap_barley1   = func_agg_shap_local_regional(barley_shap_vals, group_list = group_list_local_regional1)
aggregated_local_reg_shap_sorghum1  = func_agg_shap_local_regional(sorghum_shap_vals, group_list = group_list_local_regional1)
aggregated_local_reg_shap_rye1      = func_agg_shap_local_regional(rye_shap_vals, group_list = group_list_local_regional1)
aggregated_local_reg_shap_pasture1  = func_agg_shap_local_regional(pasture_shap_vals, group_list = group_list_local_regional1)
aggregated_local_reg_shap_fruitveg1 = func_agg_shap_local_regional(fruitveg_shap_vals, group_list = group_list_local_regional1)
aggregated_local_reg_shap_pecans1   = func_agg_shap_local_regional(pecans_shap_vals, group_list = group_list_local_regional1)
aggregated_local_reg_shap_oats1     = func_agg_shap_local_regional(oats_shap_vals, group_list = group_list_local_regional1)

aggregated_local_reg_shap_abs_corn1     = func_agg_shap_local_regional_abs(corn_shap_vals, group_list = group_list_local_regional1)
aggregated_local_reg_shap_abs_cotton1   = func_agg_shap_local_regional_abs(cotton_shap_vals, group_list = group_list_local_regional1)
aggregated_local_reg_shap_abs_soy1      = func_agg_shap_local_regional_abs(soy_shap_vals, group_list = group_list_local_regional1)
aggregated_local_reg_shap_abs_wheat1    = func_agg_shap_local_regional_abs(wheat_shap_vals, group_list = group_list_local_regional1)
aggregated_local_reg_shap_abs_peanuts1  = func_agg_shap_local_regional_abs(peanuts_shap_vals, group_list = group_list_local_regional1)
aggregated_local_reg_shap_abs_hay1      = func_agg_shap_local_regional_abs(hay_shap_vals, group_list = group_list_local_regional1)
aggregated_local_reg_shap_abs_barley1   = func_agg_shap_local_regional_abs(barley_shap_vals, group_list = group_list_local_regional1)
aggregated_local_reg_shap_abs_sorghum1  = func_agg_shap_local_regional_abs(sorghum_shap_vals, group_list = group_list_local_regional1)
aggregated_local_reg_shap_abs_rye1      = func_agg_shap_local_regional_abs(rye_shap_vals, group_list = group_list_local_regional1)
aggregated_local_reg_shap_abs_pasture1  = func_agg_shap_local_regional_abs(pasture_shap_vals, group_list = group_list_local_regional1)
aggregated_local_reg_shap_abs_fruitveg1 = func_agg_shap_local_regional_abs(fruitveg_shap_vals, group_list = group_list_local_regional1)
aggregated_local_reg_shap_abs_pecans1   = func_agg_shap_local_regional_abs(pecans_shap_vals, group_list = group_list_local_regional1)
aggregated_local_reg_shap_abs_oats1     = func_agg_shap_local_regional_abs(oats_shap_vals, group_list = group_list_local_regional1)

aggregated_local_reg_shap_corn2     = func_agg_shap_local_regional(corn_shap_vals, group_list = group_list_local_regional2)
aggregated_local_reg_shap_cotton2   = func_agg_shap_local_regional(cotton_shap_vals, group_list = group_list_local_regional2)
aggregated_local_reg_shap_soy2      = func_agg_shap_local_regional(soy_shap_vals, group_list = group_list_local_regional2)
aggregated_local_reg_shap_wheat2    = func_agg_shap_local_regional(wheat_shap_vals, group_list = group_list_local_regional2)
aggregated_local_reg_shap_peanuts2  = func_agg_shap_local_regional(peanuts_shap_vals, group_list = group_list_local_regional2)
aggregated_local_reg_shap_hay2      = func_agg_shap_local_regional(hay_shap_vals, group_list = group_list_local_regional2)
aggregated_local_reg_shap_barley2   = func_agg_shap_local_regional(barley_shap_vals, group_list = group_list_local_regional2)
aggregated_local_reg_shap_sorghum2  = func_agg_shap_local_regional(sorghum_shap_vals, group_list = group_list_local_regional2)
aggregated_local_reg_shap_rye2      = func_agg_shap_local_regional(rye_shap_vals, group_list = group_list_local_regional2)
aggregated_local_reg_shap_pasture2  = func_agg_shap_local_regional(pasture_shap_vals, group_list = group_list_local_regional2)
aggregated_local_reg_shap_fruitveg2 = func_agg_shap_local_regional(fruitveg_shap_vals, group_list = group_list_local_regional2)
aggregated_local_reg_shap_pecans2   = func_agg_shap_local_regional(pecans_shap_vals, group_list = group_list_local_regional2)
aggregated_local_reg_shap_oats2     = func_agg_shap_local_regional(oats_shap_vals, group_list = group_list_local_regional2)


aggregated_local_reg_shap_abs_corn2     = func_agg_shap_local_regional_abs(corn_shap_vals, group_list = group_list_local_regional2)
aggregated_local_reg_shap_abs_cotton2   = func_agg_shap_local_regional_abs(cotton_shap_vals, group_list = group_list_local_regional2)
aggregated_local_reg_shap_abs_soy2      = func_agg_shap_local_regional_abs(soy_shap_vals, group_list = group_list_local_regional2)
aggregated_local_reg_shap_abs_wheat2    = func_agg_shap_local_regional_abs(wheat_shap_vals, group_list = group_list_local_regional2)
aggregated_local_reg_shap_abs_peanuts2  = func_agg_shap_local_regional_abs(peanuts_shap_vals, group_list = group_list_local_regional2)
aggregated_local_reg_shap_abs_hay2      = func_agg_shap_local_regional_abs(hay_shap_vals, group_list = group_list_local_regional2)
aggregated_local_reg_shap_abs_barley2   = func_agg_shap_local_regional_abs(barley_shap_vals, group_list = group_list_local_regional2)
aggregated_local_reg_shap_abs_sorghum2  = func_agg_shap_local_regional_abs(sorghum_shap_vals, group_list = group_list_local_regional2)
aggregated_local_reg_shap_abs_rye2      = func_agg_shap_local_regional_abs(rye_shap_vals, group_list = group_list_local_regional2)
aggregated_local_reg_shap_abs_pasture2  = func_agg_shap_local_regional_abs(pasture_shap_vals, group_list = group_list_local_regional2)
aggregated_local_reg_shap_abs_fruitveg2 = func_agg_shap_local_regional_abs(fruitveg_shap_vals, group_list = group_list_local_regional2)
aggregated_local_reg_shap_abs_pecans2   = func_agg_shap_local_regional_abs(pecans_shap_vals, group_list = group_list_local_regional2)
aggregated_local_reg_shap_abs_oats2     = func_agg_shap_local_regional_abs(oats_shap_vals, group_list = group_list_local_regional2)

colMeans(aggregated_local_reg_shap_corn1)


colMeans(aggregated_local_reg_shap_abs_corn1)
colMeans(aggregated_local_reg_shap_abs_cotton1)
colMeans(aggregated_local_reg_shap_abs_soy1)
colMeans(aggregated_local_reg_shap_abs_wheat1)
colMeans(aggregated_local_reg_shap_abs_peanuts1)
colMeans(aggregated_local_reg_shap_abs_hay1)
colMeans(aggregated_local_reg_shap_abs_barley1)
colMeans(aggregated_local_reg_shap_abs_sorghum1)
colMeans(aggregated_local_reg_shap_abs_rye1)
colMeans(aggregated_local_reg_shap_abs_pasture1)
colMeans(aggregated_local_reg_shap_abs_fruitveg1)
colMeans(aggregated_local_reg_shap_abs_pecans1)
colMeans(aggregated_local_reg_shap_abs_oats1)



list_crop_control_abs1 <- list(
  corn = aggregated_local_reg_shap_abs_corn1,
  cotton = aggregated_local_reg_shap_abs_cotton1,
  soy = aggregated_local_reg_shap_abs_soy1,
  wheat = aggregated_local_reg_shap_abs_wheat1,
  peanuts = aggregated_local_reg_shap_abs_peanuts1,
  hay = aggregated_local_reg_shap_abs_hay1,
  barley = aggregated_local_reg_shap_abs_barley1,
  sorghum = aggregated_local_reg_shap_abs_sorghum1,
  rye = aggregated_local_reg_shap_abs_rye1,
  pasture = aggregated_local_reg_shap_abs_pasture1,
  fruitveg = aggregated_local_reg_shap_abs_fruitveg1,
  pecans = aggregated_local_reg_shap_abs_pecans1,
  oats = aggregated_local_reg_shap_abs_oats1
)

list_crop_control_raw2 <- list(
  corn = aggregated_local_reg_shap_corn2,
  cotton = aggregated_local_reg_shap_cotton2,
  soy = aggregated_local_reg_shap_soy2,
  wheat = aggregated_local_reg_shap_wheat2,
  peanuts = aggregated_local_reg_shap_peanuts2,
  hay = aggregated_local_reg_shap_hay2,
  barley = aggregated_local_reg_shap_barley2,
  sorghum = aggregated_local_reg_shap_sorghum2,
  rye = aggregated_local_reg_shap_rye2,
  pasture = aggregated_local_reg_shap_pasture2,
  fruitveg = aggregated_local_reg_shap_fruitveg2,
  pecans = aggregated_local_reg_shap_pecans2,
  oats = aggregated_local_reg_shap_oats2
)

list_crop_control_abs2 <- list(
  corn = aggregated_local_reg_shap_abs_corn2,
  cotton = aggregated_local_reg_shap_abs_cotton2,
  soy = aggregated_local_reg_shap_abs_soy2,
  wheat = aggregated_local_reg_shap_abs_wheat2,
  peanuts = aggregated_local_reg_shap_abs_peanuts2,
  hay = aggregated_local_reg_shap_abs_hay2,
  barley = aggregated_local_reg_shap_abs_barley2,
  sorghum = aggregated_local_reg_shap_abs_sorghum2,
  rye = aggregated_local_reg_shap_abs_rye2,
  pasture = aggregated_local_reg_shap_abs_pasture2,
  fruitveg = aggregated_local_reg_shap_abs_fruitveg2,
  pecans = aggregated_local_reg_shap_abs_pecans2,
  oats = aggregated_local_reg_shap_abs_oats2
)
control_df_abs1 <- bind_rows(
  lapply(names(list_crop_control_abs1), function(crop_name) {
    means <- colMeans(list_crop_control_abs1[[crop_name]], na.rm = TRUE)
    
    data.frame(
      Crop = toupper(crop_name),
      Local = means["Local"],
      Regional = means["Regional"],
      NoControl = means["NoControl"]
    )
  })
)
rownames(control_df_abs1) <- NULL
control_df_abs1$LocalMinusRegional <- control_df_abs1$Local - control_df_abs1$Regional

control_df_abs1

control_df_raw2 <- bind_rows(
  lapply(names(list_crop_control_raw2), function(crop_name) {
    means <- colMeans(abs(list_crop_control_raw2[[crop_name]]), na.rm = TRUE)
    
    data.frame(
      Crop = toupper(crop_name),
      Local = means["Local"],
      Regional = means["Regional"],
      NoControl = means["NoControl"]
    )
  })
)
rownames(control_df_raw2) <- NULL
control_df_raw2$LocalMinusRegional <- control_df_raw2$Local - control_df_raw2$Regional

control_df_raw2


control_df_abs2 <- bind_rows(
  lapply(names(list_crop_control_abs2), function(crop_name) {
    means <- colMeans(list_crop_control_abs2[[crop_name]], na.rm = TRUE)
    
    data.frame(
      Crop = toupper(crop_name),
      Local = means["Local"],
      Regional = means["Regional"],
      NoControl = means["NoControl"]
    )
  })
)
rownames(control_df_abs2) <- NULL
control_df_abs2$LocalMinusRegional <- control_df_abs2$Local - control_df_abs2$Regional

control_df_abs2

# A quadrant plot; just two variables
quadrant_plot_controls1 = ggplot(control_df_abs1, aes(x = NoControl, y = LocalMinusRegional, label = Crop)) +
  geom_point(size = 8, shape = 16, color = "firebrick") +
  geom_text(nudge_x = 0.01, nudge_y = 0.01, size = 4, color = "black") +
  theme_minimal(base_size = 14) +
  labs(
    x = "Biophysical (NoControl) importance",
    y = "Net Local (Local-Regional) importance",
    title = "Local vs Biophysical Importance Across Crops"
  ) +
  theme(
    axis.line = element_line(color = "black", linewidth = 0.6),
    panel.border = element_blank(),
    panel.grid.major = element_line(color = "grey80", linewidth = 0.5),
    panel.grid.minor = element_line(color = "grey90", linewidth = 0.3)
  )
quadrant_plot_controls1
ggsave("./figs_model2//quadrant_plot_controls_abs.png", quadrant_plot_controls, bg = "white")


# three vars; regional with colors

quadrant_plot_controls_3_1 = ggplot(control_df_abs1, aes(x = NoControl, y = Local, color = Regional, label = Crop)) +
  geom_point(size = 8, shape = 16) +
  scale_color_gradientn(colors = c("darkgreen", "orange", "firebrick"))+

  geom_text(nudge_x = 0.01, nudge_y = 0.015, size = 3.5, color = "black") +
  theme_minimal(base_size = 14) +
  labs(
    x = "Biophysical (NoControl) importance",
    y = "Local importance",
    title = "Local vs Biophysical Importance Across Crops"
  ) +
  theme(
    axis.line = element_line(color = "black", linewidth = 0.6),
    panel.border = element_blank(),
    panel.grid.major = element_line(color = "grey80", linewidth = 0.5),
    panel.grid.minor = element_line(color = "grey90", linewidth = 0.3)
  )
quadrant_plot_controls_3_1
ggsave("./figs_model2//quadrant_plot_controls_abs_3.png", quadrant_plot_controls_3, bg = "white")


# Ternary plot#1

control_df_abs_norm1 <- control_df_abs1 %>%
  mutate(total = Local + Regional + NoControl,
         Local_n = Local / total,
         Regional_n = Regional / total,
         NoControl_n = NoControl / total) %>%
  select(c(Crop, Local_n, Regional_n, NoControl_n))


png("figs_model2/ternary_plot_controls_abs1.png", width = 800, height = 800)  # Start saving plot

TernaryPlot(
  atip = "Local",
  btip = "Regional",
  ctip = "Biophysical\n(NoControl)",
  grid.lines = 5,
  col = "white",
  lab.cex = 1.0
)

# Add crop points
TernaryPoints(
  control_df_abs_norm1[, c("Local_n", "Regional_n", "NoControl_n")],
  pch = 16,
  cex = 2,
  col = "firebrick"
)

# Add crop labels
TernaryText(
  control_df_abs_norm1[, c("Local_n", "Regional_n", "NoControl_n")],
  labels = control_df_abs_norm1$Crop,
  pos = 2,
  cex = 0.9
)

dev.off()  # Finish and save the file

# Ternary plot#2 (abs)

control_df_abs_norm2 <- control_df_abs2 %>%
  mutate(total = Local + Regional + NoControl,
         Local_n = Local / total,
         Regional_n = Regional / total,
         NoControl_n = NoControl / total) %>%
  select(c(Crop, Local_n, Regional_n, NoControl_n))


png("figs_model2/ternary_plot_controls_abs2.png", width = 800, height = 800)  # Start saving plot

TernaryPlot(
  atip = "Local",
  btip = "Regional",
  ctip = "Biophysical\n(NoControl)",
  grid.lines = 5,
  col = "white",
  lab.cex = 1.0
)

# Add crop points
TernaryPoints(
  control_df_abs_norm2[, c("Local_n", "Regional_n", "NoControl_n")],
  pch = 16,
  cex = 2,
  col = "firebrick"
)

# Add crop labels
TernaryText(
  control_df_abs_norm2[, c("Local_n", "Regional_n", "NoControl_n")],
  labels = control_df_abs_norm2$Crop,
  pos = 2,
  cex = 0.9
)

 dev.off()  # Finish and save the file

#### # 
 #Ternary plot#2 (abs) for historical paper, exluding crops
 
control_df_abs_norm2 <- control_df_abs2 %>%
   mutate(total = Local + Regional + NoControl,
          Local_n = Local / total,
          Regional_n = Regional / total,
          NoControl_n = NoControl / total) %>%
   select(c(Crop, Local_n, Regional_n, NoControl_n))

control_df_abs_norm2_hist_paper = control_df_abs_norm2 %>% filter(!Crop %in% crop_excluded_hist) 
 
png("figs_model2/ternary_plot_controls_abs2_hist_paper.png", width = 800, height = 800)  # Start saving plot
 
TernaryPlot(
   atip = "Local",
   btip = "Regional",
   ctip = "Biophysical\n(NoControl)",
   grid.lines = 5,
   col = "white",
   lab.cex = 1.0
 )
 
 # Add crop points
TernaryPoints(
   control_df_abs_norm2_hist_paper[, c("Local_n", "Regional_n", "NoControl_n")],
   pch = 16,
   cex = 2,
   col = "firebrick"
 )
 
 # Add crop labels
TernaryText(
  control_df_abs_norm2_hist_paper[, c("Local_n", "Regional_n", "NoControl_n")],
   labels = control_df_abs_norm2_hist_paper$Crop,
   pos = 2,
   cex = 0.9
 )
 
dev.off()  # Finish and save the file
 
 
 #### # 
 #Ternary plot#2 (raw) for historical paper, exluding crops
 
control_df_raw_norm2 <- control_df_raw2 %>%
   mutate(total = Local + Regional + NoControl,
          Local_n = Local / total,
          Regional_n = Regional / total,
          NoControl_n = NoControl / total) %>%
   select(c(Crop, Local_n, Regional_n, NoControl_n))
 
control_df_raw_norm2_hist_paper = control_df_raw_norm2 %>% filter(!Crop %in% crop_excluded_hist) 

png("figs_model2/ternary_plot_controls_raw2_hist_paper.png", width = 800, height = 800)  # Start saving plot

TernaryPlot(
  atip = "Local",
  btip = "Regional",
  ctip = "Biophysical\n(NoControl)",
  grid.lines = 5,
  col = "white",
  lab.cex = 1.0
)

# Add crop points
TernaryPoints(
  control_df_raw_norm2_hist_paper[, c("Local_n", "Regional_n", "NoControl_n")],
  pch = 16,
  cex = 2,
  col = "firebrick"
)

# Add crop labels
TernaryText(
  control_df_raw_norm2_hist_paper[, c("Local_n", "Regional_n", "NoControl_n")],
  labels = control_df_raw_norm2_hist_paper$Crop,
  pos = 2,
  cex = 0.9
)

dev.off()  # Finish and save the file


 
########################################################################
########################################################################
# Climate vs non-climate variable importance and bio vs ag importance
climate_categories <- c("Climate")
non_climate_categories <- c("Soil", "Topography", "Irrigation", "Management", "Inputs", "Economics", "Demographics", "Infrastructure")
bio_categories <- c("Climate", "Soil", "Topography")
ag_categories <- c("Irrigation", "Management", "Inputs", "Economics", "Demographics", "Infrastructure")

# Combine categories
combined_categories <- c(climate_categories, non_climate_categories)
combined_categories_ag_bio <- c(bio_categories, ag_categories)

# Create a new data frame with summed values based on categories
combined_shap_imp_clim_nonclim <- combined_crop_group_imp %>%
  mutate(Category_Type = ifelse(Category %in% climate_categories, "Climate", "Non-Climate")) %>%
  group_by(Crop, Category_Type) %>%
  summarise(Total_Importance = sum(Importance, na.rm = TRUE), .groups = "drop")

combined_shap_imp_ag_bio <- combined_crop_group_imp %>%
  mutate(Category_Type = ifelse(Category %in% bio_categories, "Biophysical", "Agricultural")) %>%
  group_by(Crop, Category_Type) %>%
  summarise(Total_Importance = sum(Importance, na.rm = TRUE), .groups = "drop")


group_imp_clim_nonclim = ggplot(combined_shap_imp_clim_nonclim, aes(x = Crop, y = Total_Importance, fill = Category_Type)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "Total SHAP Importance by Crop and Category Type",
       x = "Crops",
       y = "Total Importance") +
  theme_minimal() +
  scale_fill_brewer(palette = "Set1") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.title = element_blank())  # Rotate x-axis text for better readability

group_imp_clim_nonclim
# ggsave("./figs/shap_categories_clim_nonclim.png", group_imp_clim_nonclim, bg = "white")
ggsave("./figs_model2/shap_categories_clim_nonclim.png", group_imp_clim_nonclim, bg = "white")

group_imp_clim_nonclim_stack = ggplot(combined_shap_imp_clim_nonclim, aes(x = Crop, y = Total_Importance, fill = Category_Type)) +
  geom_bar(stat = "identity", position = "fill") +
  labs(title = "Total SHAP Importance by Crop and Category Type",
       x = "Crops",
       y = "Total Importance") +
  theme_minimal() +
  scale_fill_manual(values= c("#56B4E9", "#D1438C")) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.title = element_blank())   # Rotate x-axis text for better readability

group_imp_clim_nonclim_stack
ggsave("./figs_model2/shap_categories_clim_nonclim_stack.png", group_imp_clim_nonclim_stack, bg = "white")

# Create a new data frame with summed values based on categories
combined_shap_imp_clim_nonclim_raw <- combined_crop_group_imp_raw %>%
  mutate(Category_Type = ifelse(Category %in% climate_categories, "Climate", "Non-Climate")) %>%
  group_by(Crop, Category_Type) %>%
  summarise(Total_Importance = sum(Importance, na.rm = TRUE), .groups = "drop")

combined_shap_imp_ag_bio_raw <- combined_crop_group_imp_raw %>%
  mutate(Category_Type = ifelse(Category %in% bio_categories, "Biophysical", "Agricultural")) %>%
  group_by(Crop, Category_Type) %>%
  summarise(Total_Importance = sum(Importance, na.rm = TRUE), .groups = "drop")

group_imp_clim_nonclim_raw = ggplot(combined_shap_imp_clim_nonclim_raw, aes(x = Crop, y = Total_Importance, fill = Category_Type)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "Total SHAP Importance by Crop and Category Type",
       x = "Crops",
       y = "Total Importance") +
  theme_minimal() +
  scale_fill_brewer(palette = "Set1") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))  # Rotate x-axis text for better readability

group_imp_clim_nonclim_raw
ggsave("./figs_model2//shap_categories_clim_nonclim_raw.png", group_imp_clim_nonclim_raw, bg = "white")

group_imp_clim_nonclim_raw_stack = ggplot(combined_shap_imp_clim_nonclim_raw, aes(x = Crop, y = Total_Importance, fill = Category_Type)) +
  geom_bar(stat = "identity", position = "fill") +
  labs(title = "Total SHAP Importance by Crop and Category Type",
       x = "Crops",
       y = "Total Importance") +
  theme_minimal() +
  scale_fill_manual(values= c("#56B4E9", "#D1438C")) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.title = element_blank())   # Rotate x-axis text for better readability
  
group_imp_clim_nonclim_raw_stack
ggsave("./figs_model2//shap_categories_clim_nonclim_raw_stacked.png", group_imp_clim_nonclim_raw_stack, bg = "white")

### ARRANGING THE STACKED BAR CHART BASED ON THE DESCENDING ORDER OF RELATIVE NON_CLIMATE IMPORTANCE
crop_proportions <- combined_shap_imp_clim_nonclim_raw %>%
  group_by(Crop) %>%
  summarize(non_climate_prop = sum(Total_Importance[Category_Type == "Non-Climate"]) / 
              sum(Total_Importance))

# Reorder the crops based on the non-climate proportion
combined_shap_imp_clim_nonclim_raw <- combined_shap_imp_clim_nonclim_raw %>%
  mutate(Crop = factor(Crop, levels = crop_proportions$Crop[order(-crop_proportions$non_climate_prop)]))

# Plot the stacked bar chart
group_imp_clim_nonclim_raw_stack_reorder = ggplot(combined_shap_imp_clim_nonclim_raw, 
       aes(x = Crop, 
           y = Total_Importance, 
           fill = Category_Type)) +
  geom_bar(stat = "identity", position = "fill") +
  labs(title = "Total SHAP Importance by Crop and Category Type",
       x = "Crops",
       y = "Proportion of Importance") +
  theme_minimal() +
  scale_fill_manual(values = c("#56B4E9", "#D1438C")) +  # Climate: blue, Non-Climate: pink
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.title = element_blank())
ggsave("./figs_model2/shap_categories_clim_nonclim_raw_stacked_reordered.png", group_imp_clim_nonclim_raw_stack_reorder, bg = "white")



### Reorderd for absolute vals
crop_proportions_abs <- combined_shap_imp_clim_nonclim %>%
  group_by(Crop) %>%
  summarize(non_climate_prop = sum(Total_Importance[Category_Type == "Non-Climate"]) / 
              sum(Total_Importance))
combined_shap_imp_clim_nonclim <- combined_shap_imp_clim_nonclim %>%
  mutate(Crop = factor(Crop, levels = crop_proportions_abs$Crop[order(-crop_proportions_abs$non_climate_prop)]))

group_imp_clim_nonclim_stack_reorder = ggplot(combined_shap_imp_clim_nonclim, 
                                                  aes(x = Crop, 
                                                      y = Total_Importance, 
                                                      fill = Category_Type)) +
  geom_bar(stat = "identity", position = "fill") +
  labs(title = "Total SHAP Importance by Crop and Category Type",
       x = "Crops",
       y = "Proportion of Importance") +
  theme_minimal() +
  scale_fill_manual(values = c("#56B4E9", "#D1438C")) +  # Climate: blue, Non-Climate: pink
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.title = element_blank())
group_imp_clim_nonclim_stack_reorder

# ggsave("./figs/shap_categories_clim_nonclim_abs_stacked_reordered.png", group_imp_clim_nonclim_stack_reorder, bg = "white")

ggsave("./figs_model2/shap_categories_clim_nonclim_abs_stacked_reordered.png", group_imp_clim_nonclim_stack_reorder, bg = "white")



######################


group_imp_ag_bio_raw_stack = ggplot(combined_shap_imp_ag_bio_raw, aes(x = Crop, y = Total_Importance, fill = Category_Type)) +
  geom_bar(stat = "identity", position = "fill") +
  labs(title = "Total SHAP Importance by Crop and Category Type",
       x = "Crops",
       y = "Total Importance") +
  theme_minimal() +
  scale_fill_manual(values= c( "#099c3d","#e65410")) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.title = element_blank())  # Rotate x-axis text for better readability
group_imp_ag_bio_raw_stack
ggsave("./figs_model2//shap_categories_ag_bio_raw_stacked.png", group_imp_ag_bio_raw_stack, bg = "white")

### ARRANGING THE STACKED BAR CHART BASED ON THE DESCENDING ORDER OF RELATIVE NON_CLIMATE IMPORTANCE
crop_proportions_ag_bio <- combined_shap_imp_ag_bio %>%
  group_by(Crop) %>%
  summarize(bio_prop = sum(Total_Importance[Category_Type == "Biophysical"]) / 
              sum(Total_Importance))

# Reorder the crops based on the non-climate proportion
combined_shap_imp_ag_bio <- combined_shap_imp_ag_bio %>%
  mutate(Crop = factor(Crop, levels = crop_proportions_ag_bio$Crop[order(-crop_proportions_ag_bio$bio_prop)]))

# Plot the stacked bar chart
group_imp_ag_bio_stack_reorder = ggplot(combined_shap_imp_ag_bio, 
       aes(x = Crop, 
           y = Total_Importance, 
           fill = Category_Type)) +
  geom_bar(stat = "identity", position = "fill") +
  labs(title = "Total SHAP Importance by Crop and Category Type",
       x = "Crops",
       y = "Proportion of Importance") +
  theme_minimal() +
  scale_fill_manual(values = c("#099c3d","#e65410")) +  
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.title = element_blank())

group_imp_ag_bio_stack_reorder
# ggsave("./figs/shap_categories_ag_bio_abs_stacked_reordered.png", group_imp_ag_bio_stack_reorder, bg = "white")
ggsave("./figs_model2//shap_categories_ag_bio_abs_stacked_reordered.png", group_imp_ag_bio_stack_reorder, bg = "white")



## Reorder stack bar for Raw vals:

crop_proportions_ag_bio_abs <- combined_shap_imp_ag_bio_raw %>%
  group_by(Crop) %>%
  summarize(bio_prop = sum(Total_Importance[Category_Type == "Biophysical"]) / 
              sum(Total_Importance))

# Reorder the crops based on the non-climate proportion
combined_shap_imp_ag_bio_raw <- combined_shap_imp_ag_bio_raw %>%
  mutate(Crop = factor(Crop, levels = crop_proportions_ag_bio$Crop[order(-crop_proportions_ag_bio$bio_prop)]))

# Plot the stacked bar chart
group_imp_ag_bio_raw_stack_reorder = ggplot(combined_shap_imp_ag_bio_raw, 
                                            aes(x = Crop, 
                                                y = Total_Importance, 
                                                fill = Category_Type)) +
  geom_bar(stat = "identity", position = "fill") +
  labs(title = "Total SHAP Importance by Crop and Category Type",
       x = "Crops",
       y = "Proportion of Importance") +
  theme_minimal() +
  scale_fill_manual(values = c("#099c3d","#e65410")) +  
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
ggsave("./figs/shap_categories_ag_bio_raw_stacked_reordered.png", group_imp_ag_bio_raw_stack_reorder, bg = "white")

####################################################################################################################

### Plotting relative SHAP importance plots for temperature- vs precipitation based variables
##################################

## The function sums abs shap value for temperature and precipitation based vars to see relative importance
func_agg_shap_vals_clim_only_abs <- function(df) {
  df %>%
    mutate(
      Temperature = rowSums(abs(df[, list_clim_temp]), na.rm = TRUE),
      Precipitation = rowSums(abs(df[, list_clim_prec]), na.rm = TRUE)) %>%
    select(Temperature, Precipitation)
}

aggregated_cat_shap_clim_only_barley = func_agg_shap_vals_clim_only_abs(barley_shap_vals)
aggregated_cat_shap_clim_only_cotton = func_agg_shap_vals_clim_only_abs(cotton_shap_vals)
aggregated_cat_shap_clim_only_pecans = func_agg_shap_vals_clim_only_abs(pecans_shap_vals)
aggregated_cat_shap_clim_only_oats = func_agg_shap_vals_clim_only_abs(oats_shap_vals)
aggregated_cat_shap_clim_only_peanuts = func_agg_shap_vals_clim_only_abs(peanuts_shap_vals)
aggregated_cat_shap_clim_only_sorghum = func_agg_shap_vals_clim_only_abs(sorghum_shap_vals)
aggregated_cat_shap_clim_only_fruitveg = func_agg_shap_vals_clim_only_abs(fruitveg_shap_vals)
aggregated_cat_shap_clim_only_rye = func_agg_shap_vals_clim_only_abs(rye_shap_vals)
aggregated_cat_shap_clim_only_corn = func_agg_shap_vals_clim_only_abs(corn_shap_vals)
aggregated_cat_shap_clim_only_soy = func_agg_shap_vals_clim_only_abs(soy_shap_vals)
aggregated_cat_shap_clim_only_wheat = func_agg_shap_vals_clim_only_abs(wheat_shap_vals)
aggregated_cat_shap_clim_only_hay = func_agg_shap_vals_clim_only_abs(hay_shap_vals)
aggregated_cat_shap_clim_only_pasture = func_agg_shap_vals_clim_only_abs(pasture_shap_vals)

barley_shap_imp_cat_clim_only = colMeans(abs(aggregated_cat_shap_clim_only_barley))
cotton_shap_imp_cat_clim_only = colMeans(abs(aggregated_cat_shap_clim_only_cotton))
pecans_shap_imp_cat_clim_only = colMeans(abs(aggregated_cat_shap_clim_only_pecans))
oats_shap_imp_cat_clim_only = colMeans(abs(aggregated_cat_shap_clim_only_oats))
peanuts_shap_imp_cat_clim_only = colMeans(abs(aggregated_cat_shap_clim_only_peanuts))
sorghum_shap_imp_cat_clim_only = colMeans(abs(aggregated_cat_shap_clim_only_sorghum))
fruitveg_shap_imp_cat_clim_only = colMeans(abs(aggregated_cat_shap_clim_only_fruitveg))
rye_shap_imp_cat_clim_only = colMeans(abs(aggregated_cat_shap_clim_only_rye))
corn_shap_imp_cat_clim_only = colMeans(abs(aggregated_cat_shap_clim_only_corn))
soy_shap_imp_cat_clim_only = colMeans(abs(aggregated_cat_shap_clim_only_soy))
wheat_shap_imp_cat_clim_only = colMeans(abs(aggregated_cat_shap_clim_only_wheat))
hay_shap_imp_cat_clim_only = colMeans(abs(aggregated_cat_shap_clim_only_hay))
pasture_shap_imp_cat_clim_only = colMeans(abs(aggregated_cat_shap_clim_only_pasture))



combined_crop_group_imp_clim_only = data.frame(
  Category = rep(names(barley_shap_imp_cat_clim_only), 13),  # replicate for each crop
  Importance = c(barley_shap_imp_cat_clim_only, cotton_shap_imp_cat_clim_only, pecans_shap_imp_cat_clim_only, 
                 oats_shap_imp_cat_clim_only, peanuts_shap_imp_cat_clim_only, sorghum_shap_imp_cat_clim_only, 
                 fruitveg_shap_imp_cat_clim_only, rye_shap_imp_cat_clim_only, corn_shap_imp_cat_clim_only,
                 soy_shap_imp_cat_clim_only, wheat_shap_imp_cat_clim_only, hay_shap_imp_cat_clim_only,pasture_shap_imp_cat_clim_only ),
  Crop = rep(c("Barley", "Cotton", "Pecans", "Oats", "Peanuts", "Sorghum", "Fruit/Veg", "Rye",
               "Corn", "Soy", "Wheat", "Hay", "Pasture"), 
             each = length(barley_shap_imp_cat_clim_only))  # replicate each crop's category
)


p_clim <- ggplot(combined_crop_group_imp_clim_only %>% filter(!Crop %in% stringr::str_to_title(crop_excluded_hist)), 
                    aes(x = Crop, y = Importance, fill = Category)) +
  geom_bar(stat = "identity", position = "fill")+
  scale_fill_manual(values = c("Temperature" = "#FF6666", "Precipitation" = "#00C4B4"),
                    labels = c("Precipitation based", "Temperature based")) +  # Colors
  labs(
    x = "Crop",
    y = "",
    fill = "Category",
    title = ""
  ) +
  theme_bw() +
  theme(axis.text.x = element_text(size = 18, angle = 90, hjust = 1),
        legend.title = element_blank(),
        legend.position = "bottom",                           # Move legend to top
        legend.direction = "horizontal",                   # Horizontal layout
        legend.box = "horizontal")

p_clim

ggsave("./figs_model2//shap_imp_abs_clim_only_stacked_hist_paper.png", p_clim, bg = "white")

#content for paper

combined_crop_group_imp_clim_only %>% filter(!Crop %in% stringr::str_to_title(crop_excluded_hist)) %>%
  group_by(Category) %>%
  summarise(median(Importance))

#percent contri within climate group
combined_crop_group_imp_clim_only %>% filter(!Crop %in% stringr::str_to_title(crop_excluded_hist)) %>%
  group_by(Crop) %>%
  mutate(Total_Importance = sum(Importance),
         Percent = Importance / Total_Importance * 100) %>%
  select(Crop, Category, Percent)%>%
  pivot_wider(names_from = Category, values_from = Percent)

combined_crop_group_imp_clim_only %>% filter(!Crop %in% stringr::str_to_title(crop_excluded_hist)) %>%
  group_by(Crop) %>%
  mutate(Total_Importance = sum(Importance),
         Percent = Importance / Total_Importance * 100) %>%
  select(Crop, Category, Percent)%>%
  pivot_wider(names_from = Category, values_from = Percent) %>%
  ungroup() %>%  
  summarise(mean_temp = mean(Temperature, na.rm = TRUE),
            mean_precip = mean(Precipitation, na.rm = TRUE))

######################
####################################################################################################################
####################   PLOT 3- Feature Dependence plots #######################

#Plotting feature dependence plots
plot_feature_dependence(shap_barley, variable = "cover_crop_acre")

#Making custom functions so that we can change plots 

# plot_feature_dependence1 plots feature dependence plots with a loess and robust regression curves
plot_feature_dependence1 <- function(treeshap, variable, title = NULL, subtitle = NULL) {
  shaps <- treeshap$shaps
  x <- treeshap$observations
  # Create a dataframe with the variable values and shap values
  df <- data.frame(var_value = x[, variable], shap_value = shaps[, variable])
  
  # Fit the robust linear regression (rlm)
  rlm_model <- rlm(shap_value ~ var_value, data = df)
  
  # Extract the slope from the rlm model
  slope <- coef(rlm_model)[2]
  
  # Create the ggplot
  p <- ggplot(df, aes(x = var_value, y = shap_value)) +
    geom_point(color = "#ee9f17") +  # Change dot color to #ee9f17
    
    # Add robust regression line in red
    geom_smooth(method = "rlm", color = "red", se = FALSE, linetype = "solid", size = 1) +
    
    # Add LOESS smoothing line in blue
    geom_smooth(method = "gam", color = "blue", se = FALSE, linetype = "dashed", size = 1) +
    
    theme_minimal() +  # Minimal theme to remove most elements
    xlab(variable) +   # X-axis label
    labs(title = title, subtitle = subtitle) +  # Add title and subtitle
    scale_y_continuous(labels = scales::comma) +  # Adjust y-axis format
    
    # Annotate the slope of the robust linear regression
    annotate("text", x = Inf, y = Inf, label = paste0("Slope: ", round(slope, 4)),
             vjust = 2, hjust = 1.1, size = 5, color = "red")  # Position the slope text on the plot
  
  # Additional styling: remove gridlines and enclose in a box
  p <- p +
    theme(
      axis.title.y = element_blank(),  # Remove y-axis label
      panel.grid.major = element_blank(),  # Remove major grid lines
      panel.grid.minor = element_blank(),  # Remove minor grid lines
      panel.border = element_rect(color = "black", fill = NA, size = 1)  # Add black border
    )
  
  return(p)
}

# plot_feature_dependence2 plots feature dependence plots with a loess and robust slope line
plot_feature_dependence2 <- function(treeshap, variable, title = NULL, subtitle = NULL) {
  shaps <- treeshap$shaps
  x <- treeshap$observations
  
  # Create a dataframe with the variable values and shap values
  df <- data.frame(var_value = x[, variable], shap_value = shaps[, variable])
  
  # Create the plot
  p <- ggplot(df, aes(x = var_value, y = shap_value)) +
    geom_point(color = "#ee9f17") +  # Change dot color to #ee9f17
    theme_minimal() +  # Minimal theme
    xlab(variable) +   # X-axis label
    labs(title = title, subtitle = subtitle) +  # Add title and subtitle
    scale_y_continuous(labels = scales::comma)  # Adjust y-axis format
  
  # Fit Theil-Sen regression
  theil_sen_fit <- rq(shap_value ~ var_value, data = df, tau = 0.5)  # Median slope (Theil-Sen)
  
  # Create a sequence for the fitted line
  x_seq <- seq(min(df$var_value, na.rm = TRUE), max(df$var_value, na.rm = TRUE), length.out = 100)
  
  # Generate predicted values using Theil-Sen regression
  y_fit <- predict(theil_sen_fit, newdata = data.frame(var_value = x_seq))  # Use predict to get y_fit
  
  # Create a data frame for the fitted line
  fit_df <- data.frame(var_value = x_seq, shap_value = y_fit)
  
  # Add Theil-Sen regression line to the plot
  p <- p + geom_line(data = fit_df, aes(x = var_value, y = shap_value), color = "red", size = 1.2) +
    labs(caption = paste("Theil-Sen Slope:", round(coef(theil_sen_fit)[2], 5)))  # Add slope in the caption
  
  # Additional styling: remove gridlines and enclose in a box
  p <- p +
    theme(
      axis.title.y = element_blank(),  # Remove y-axis label
      panel.grid.major = element_blank(),  # Remove major grid lines
      panel.grid.minor = element_blank(),  # Remove minor grid lines
      panel.border = element_rect(color = "black", fill = NA, size = 1)  # Add black border
    )
  
  return(p)
}

# plot_feature_dependence3 plots feature dependence plots with a loess and robust slope line
plot_feature_dependence3 <- function(treeshap, variable, title = NULL, subtitle = NULL) {
  shaps <- treeshap$shaps
  x <- treeshap$observations
  
  # Create a dataframe with the variable values and shap values
  df <- data.frame(var_value = x[, variable], shap_value = shaps[, variable])
  
  # Fit the robust linear regression (rlm)
  rlm_model <- rlm(shap_value ~ var_value, data = df)
  
  # Create the ggplot
  p <- ggplot(df, aes(x = var_value, y = shap_value)) +
    geom_point(color = "#ee9f17", size = 0.1) +  # Change dot color to #ee9f17
    
    # Add robust linear regression line in red
    geom_smooth(method = "rlm", color = "red", se = FALSE, linetype = "solid", size = 0.5) +
    
    # Add LOESS smoothing line in blue
    geom_smooth(method = "gam", color = "blue", se = FALSE, linetype = "dashed", size = 0.5) +
    
    # Add Theil-Sen regression line in green (commented out for now)
    # geom_abline(intercept = coef(theil_sen_model)[1], slope = coef(theil_sen_model)[2], color = "green", linetype = "dotted", size = 1) +
    
    theme_minimal() +  # Minimal theme to remove most elements
    xlab(NULL) +   # Remove x-axis label
    ylab(NULL) +   # Remove y-axis label
    labs(title = variable, subtitle = subtitle) +  # Set title as the variable name
    
    scale_y_continuous(labels = scales::comma)  # Adjust y-axis format
  
  # Additional styling: remove gridlines and enclose in a box
  p <- p +
    theme(
      panel.grid.major = element_blank(),  # Remove major grid lines
      panel.grid.minor = element_blank(),  # Remove minor grid lines
      panel.border = element_rect(color = "black", fill = NA, size = 1),  # Add black border
      plot.title = element_text(size = 12, hjust = 0.5, vjust = 1.5),  # Center the title
      plot.subtitle = element_text(vjust = 1, hjust = 0.5)  # Center subtitle
    )
  
  return(p)
}



plot_feature_dependence3(shap_barley, variable = "BV12_Annual_Precip")
#Plotting top N variabls dependence plots for barley with theil-sen slope

top_vars_barley = names(barley_shap_imp[1:25])

plot_list <- list()
for (var in top_vars_barley) {
  p <- plot_feature_dependence3(shap_barley, variable = var,title = NULL)
  plot_list[[var]] <- p
}

temp_combined_plot <- grid.arrange(grobs = plot_list, ncol = 5, nrow = 5)
titled_plot <- arrangeGrob(temp_combined_plot, top = textGrob("BArley test", gp = gpar(fontsize = 13, fontface = "bold")))
titled_plot
grid.newpage()
grid.draw(titled_plot)
#ggsave("./figs/barley_feat_dep.png",temp_combined_plot, height = 10, bg = "white", width = 10)

#below is feature dependence plots from both functions
plot_feature_dependence1(shap_barley, variable = "BV12_Annual_Precip",title = NULL)
plot_feature_dependence2(shap_barley, variable = "cover_crop_acre",title = NULL)


#plotting for all crops for top 42
for (i in 1: length(crop_names)){
  temp_shap_imp = get(paste0(tolower(crop_names[i]), "_shap_imp"))
  top_vars_temp = names(temp_shap_imp[1:42])
  plot_list <- list()
  for (var in top_vars_temp) {
    p <- plot_feature_dependence3(get(paste0("shap_", tolower(crop_names[i]))), variable = var,title = NULL)
    plot_list[[var]] <- p
  }
  combined_plot <- grid.arrange(grobs = plot_list, ncol = 7, nrow = 6)
  titled_plot <- arrangeGrob(combined_plot, top = textGrob(crop_names[i], gp = gpar(fontsize = 13, fontface = "bold")))
  
  # ggsave(paste0("./figs/feature_dependece/", crop_names[i], "_feat_dep_shap.png"),titled_plot, height = 10, bg = "white", width = 13)
  ggsave(paste0("./figs_model2/feature_dependece/", crop_names[i], "_feat_dep_shap.png"),titled_plot, height = 11, bg = "white", width = 14)
}

######################################################################################################
## Plotting PDP plots for multiple crops


plot_feature_dependence_all <- function(shap_list, variable) {
  
  # Build combined df but SKIP crops where variable is missing
  all_df_list <- lapply(names(shap_list), function(crop) {
    ts <- shap_list[[crop]]
    
    # Check if variable exists in the dataset
    if (!(variable %in% colnames(ts$observations)) ||
        !(variable %in% colnames(ts$shaps))) {
      message(paste("Skipping", crop, "- variable not found:", variable))
      return(NULL)
    }
    
    # Extract available variable
    data.frame(
      var_value = ts$observations[, variable],
      shap_value = ts$shaps[, variable],
      Crop = crop
    )
  })
  
  # Bind rows but ignore NULL crops
  all_df <- do.call(rbind, all_df_list)
  
  if (nrow(all_df) == 0) {
    stop("No crops contained the variable: ", variable)
  }
  
  # Create plot
  p <- ggplot(all_df, aes(x = var_value, y = shap_value)) +
    geom_point(color = "#ee9f17", size = 0.1) +
    geom_smooth(method = "rlm", color = "red", se = FALSE, size = 0.5) +   # robust line
    geom_smooth(method = "gam", color = "blue", se = FALSE, linetype = "dashed", size = 0.5) + # loess
    facet_wrap(~ Crop, scales = "free") +
    theme_minimal(base_size = 11) +
    labs(
      title = paste("Partial Dependence Across Crops for:", variable),
      x = "Feature value",
      y = "SHAP value"
    ) +
    theme(
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      panel.border = element_rect(color = "black", fill = NA, size = 1),
      plot.title = element_text(size = 14, hjust = 0.5)
    )
  
  return(p)
}

all_shap_objects <- list(
  CORN = shap_corn,
  SOY = shap_soy,
  WHEAT = shap_wheat,
  COTTON = shap_cotton,
  PEANUTS = shap_peanuts,
  HAY = shap_hay,
  BARLEY = shap_barley,
  SORGHUM = shap_sorghum,
  RYE = shap_rye,
  PASTURE = shap_pasture,
  FRUITVEG = shap_fruitveg,
  PECANS = shap_pecans,
  OATS = shap_oats
)

temp_p_all <- plot_feature_dependence_all(all_shap_objects, "BV12_Annual_Precip")
plot_feature_dependence_all(all_shap_objects, "PRICE")


for (var in colnames(barley_shap_vals)){
  
  temp_p1 <- plot_feature_dependence_all(all_shap_objects, var)
  ggsave(paste0("./figs_model2/pdp_all_vars/", var, ".png"), temp_p1, bg = "white", width = 10, height = 10)
  
}

## Plotting ranks of the vars instead of values to see non-linear relationships
plot_feature_dependence_rank_all <- function(shap_list, variable) {
  
  # Build combined df but SKIP crops where variable is missing
  all_df_list <- lapply(names(shap_list), function(crop) {
    ts <- shap_list[[crop]]
    
    # Check if variable exists in the dataset
    if (!(variable %in% colnames(ts$observations)) ||
        !(variable %in% colnames(ts$shaps))) {
      message(paste("Skipping", crop, "- variable not found:", variable))
      return(NULL)
    }
    
    # Extract available variable
    data.frame(
      var_value = ts$observations[, variable],
      shap_value = ts$shaps[, variable],
      Crop = crop
    )
  })
  
  # Bind rows but ignore NULL crops
  all_df <- do.call(rbind, all_df_list)
  
  
  all_df <- all_df %>%
    group_by(Crop) %>%
    mutate(
      var_rank = rank(var_value),
      shap_rank = rank(shap_value)
    ) %>%
    ungroup()
  
  if (nrow(all_df) == 0) {
    stop("No crops contained the variable: ", variable)
  }
  
  # Create plot
  p <- ggplot(all_df, aes(x = var_rank, y = shap_rank)) +
    geom_point(color = "#ee9f17", size = 0.1) +
    geom_smooth(method = "rlm", color = "red", se = FALSE, size = 0.5) +   # robust line
    geom_smooth(method = "gam", color = "blue", se = FALSE, linetype = "dashed", size = 0.5) + # loess
    facet_wrap(~ Crop, scales = "free") +
    theme_minimal(base_size = 11) +
    labs(
      title = paste("Partial Dependence Across Crops for:", variable),
      x = "Feature rank",
      y = "SHAP val rank"
    ) +
    theme(
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      panel.border = element_rect(color = "black", fill = NA, size = 1),
      plot.title = element_text(size = 14, hjust = 0.5)
    )
  
  return(p)
}

ggplot(data = tmp, aes(x = rank(var_value), y = rank(shap_value))) +
  geom_point(color = "#ee9f17", size = 0.1)

ggplot(data = NULL, aes(x = rank(ts$observations[, "ag_land_value_usd"]), y = rank(ts$shaps[, "ag_land_value_usd"]))) +
  geom_point(color = "#ee9f17", size = 0.1)

plot_feature_dependence_rank_all(all_shap_objects, "ag_land_value_usd")


for (var in colnames(barley_shap_vals)){
  
  temp_p1 <- plot_feature_dependence_rank_all(all_shap_objects, var)
  ggsave(paste0("./figs_model2/pdp_all_vars_ranks/", var, ".png"), temp_p1, bg = "white", width = 10, height = 10)
  
}



## all crops in one plot
#not used
plot_feature_dependence_single_plot_all <- function(shap_list, variable, title = NULL) {
  
  # Build one dataframe for all crops
  df_all <- bind_rows(
    lapply(names(shap_list), function(crop_name) {
      ts <- shap_list[[crop_name]]
      
      # skip crops missing the variable
      if (!variable %in% colnames(ts$observations)) return(NULL)
      
      data.frame(
        Crop = crop_name,
        var_value = ts$observations[, variable],
        shap_value = ts$shaps[, variable]
      )
    })
  )
  
  # if all missing
  if (nrow(df_all) == 0) stop("Variable not found for any crop.")
  
  # color palette
  n_crops <- length(unique(df_all$Crop))
  palette_cols <- colorRampPalette(RColorBrewer::brewer.pal(12, "Paired"))(n_crops)
  
  # Plot
  p <- ggplot(df_all, aes(x = var_value, y = shap_value, color = Crop)) +
    
    # geom_smooth(se = FALSE, method = "loess", linewidth = 1) +
    # GAM spline curve for each crop (key fix: color = Crop must be in aes)
    geom_smooth(
      aes(color = Crop),
      method = "gam",
      formula = y ~ s(x, bs = "cs"),
      se = FALSE,
      linetype = "solid",
      linewidth = 1.0
    ) +

    scale_color_manual(values = palette_cols) +
    
    theme_minimal(base_size = 14) +
    labs(
      title = ifelse(is.null(title), paste("Dependence Plot:", variable), title),
      x = variable,
      y = "SHAP value"
    ) +
    theme(
      panel.grid.minor = element_blank(),
      panel.border = element_rect(color = "black", fill = NA),
      legend.position = "right"
    )
  
  return(p)
}


plot_feature_dependence_single_plot_all(
  shap_list = all_shap_objects,
  variable = "BV12_Annual_Precip"
)


for (var in colnames(barley_shap_vals)){
  
  temp_p1 <- plot_feature_dependence_single_plot_all(all_shap_objects, var)
  ggsave(paste0("./figs_model2/pdp_all_vars_single_plot/", var, ".png"), temp_p1, bg = "white", width = 10, height = 10)
  
}
########################################### PLOT 4: Directionality and Sign heatmaps #####################

# directionality using theil-sen slop regression (linear or robust regression can also be used)

#below function is to calculate the theil-sen slope to know the directions 
calculate_theil_sen_slopes <- function(shap_df) {
  slopes <- sapply(1:ncol(shap_df$shaps), function(i) {
    
    df <- data.frame(var_value = shap_df$observations[, i], shap_value = shap_df$shaps[, i])
    
    theil_sen_fit <- rq(shap_value ~ var_value, data = df, tau = 0.5)
    
    return(coef(theil_sen_fit)[2])
  })
  
  # Create a data frame with variable names and slopes
  slope_df <- data.frame(variable = colnames(shap_df$shaps), slope = slopes)
  return(slope_df)
}

# Alternative to the theil-sen slope:: ==> robust linear regerssion slope 
calculate_rlm_slopes <- function(shap_df) {
  slopes <- sapply(1:ncol(shap_df$shaps), function(i) {
    
    # Create a dataframe for the i-th variable's values and SHAP values
    df <- data.frame(var_value = shap_df$observations[, i], shap_value = shap_df$shaps[, i])
    
    # Fit the robust linear regression (rlm)
    rlm_fit <- rlm(shap_value ~ var_value, data = df)
    
    # Extract the slope from the rlm model (second coefficient)
    return(coef(rlm_fit)[2])
  })
  slope_df <- data.frame(variable = colnames(shap_df$shaps), slope = slopes)
  return(slope_df)
}

slopes_barley <- calculate_rlm_slopes(shap_barley)
slopes_pecans <- calculate_rlm_slopes(shap_pecans)
slopes_cotton <- calculate_rlm_slopes(shap_cotton)
slopes_oats <- calculate_rlm_slopes(shap_oats)
slopes_peanuts <- calculate_rlm_slopes(shap_peanuts)
slopes_sorghum <- calculate_rlm_slopes(shap_sorghum)
slopes_fruitveg <- calculate_rlm_slopes(shap_fruitveg)
slopes_rye <- calculate_rlm_slopes(shap_rye)
slopes_corn <- calculate_rlm_slopes(shap_corn)
slopes_soy <- calculate_rlm_slopes(shap_soy)
slopes_wheat <- calculate_rlm_slopes(shap_wheat)
slopes_pasture <- calculate_rlm_slopes(shap_pasture)
slopes_hay <- calculate_rlm_slopes(shap_hay)

combined_slopes <- bind_rows(
  mutate(slopes_barley, crop = "BARLEY"),
  mutate(slopes_pecans, crop = "PECANS"),
  mutate(slopes_cotton, crop = "COTTON"),
  mutate(slopes_oats, crop = "OATS"),
  mutate(slopes_peanuts, crop = "PEANUTS"),
  mutate(slopes_sorghum, crop = "SORGHUM"),
  mutate(slopes_fruitveg, crop = "FRUITVEG"),
  mutate(slopes_rye, crop = "RYE"),
  mutate(slopes_corn, crop = "CORN"),
  mutate(slopes_wheat, crop = "WHEAT"),
  mutate(slopes_soy, crop = "SOY"),
  mutate(slopes_pasture, crop = "PASTURE"),
  mutate(slopes_hay, crop = "HAY")
)





# Plot the slopes

#very high slopes for GWW and SWW columns, so making them zero 
#combined_slopes_4heat = combined_slopes %>%
#  mutate(slope = ifelse(variable %in% c("KONAR_GWW", "KONAR_SWW"), 0, slope))

combined_slopes_4heat = combined_slopes %>%
  mutate(slope = ifelse(slope > 10, 0, slope))

combined_slopes_4heat_sign = combined_slopes %>%
  mutate(slope = case_when(
    slope > 0 ~ 1,
    slope < 0 ~ -1,
    slope == 0 ~ 0
  ))


# Create the heatmap plot with a gradient from red to blue, handling negative values

## below heatmap is not informative as some slopes are too large 
heatmap_plot <- ggplot(combined_slopes_4heat, aes(x = variable, y = crop, fill = slope)) +
  geom_tile(color = "white") +  # Create tiles with white borders
  scale_fill_gradient2(
    low = "red",        # Color for negative values
    mid = "white",     # Color for zero (midpoint)
    high = "blue",     # Color for positive values
    midpoint = 0,      # Set the midpoint to 0 for proper color distribution
    limits = c(min(combined_slopes_4heat$slope, na.rm = TRUE), 
               max(combined_slopes_4heat$slope, na.rm = TRUE))  # Adjust limits
  ) +
  labs(x = "Variables", y = "Crops", title = "Regression slopes") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), 
        legend.position = "right")  # Rotate x-axis text for better visibility

# Print the heatmap
print(heatmap_plot)
ggsave(paste0("./figs/robust_reg_slope.png"),heatmap_plot, height =8, bg = "white", width = 16)

# Heatmap that just plots the signs +ve/-ve
heatmap_plot_sign <- ggplot(combined_slopes_4heat_sign, aes(x = variable, y = crop, fill = slope)) +
  geom_tile(color = "white") +  # Create tiles with white borders
  scale_fill_gradient2(
    low = "brown2",        # Color for negative values
    mid = "white",     # Color for zero (midpoint)
    high = "light green",     # Color for positive values
    midpoint = 0,      # Set the midpoint to 0 for proper color distribution
    limits = c(min(combined_slopes_4heat_sign$slope, na.rm = TRUE), 
               max(combined_slopes_4heat_sign$slope, na.rm = TRUE)),  # Adjust limits
    name = "Slope Sign" 
  ) +
  labs(x = "Variables", y = "Crops", title = "+ve/-ve influence") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1), 
        legend.position = "right")  # Rotate x-axis text for better visibility

print(heatmap_plot_sign)
ggsave(paste0("./figs/directionality.png"),heatmap_plot_sign, height =8, bg = "white", width = 16)


df_all_with_counties_for_rf = read.csv(paste0("./out/county_agg/", "CORN", "_AGG.csv"))
df_all_with_counties_for_rf = df_all_with_counties_for_rf[,colnames(train %>% select(-AP))]

df_all_with_counties_for_rf[is.na(df_all_with_counties_for_rf)] <- 0

################################################################################################################

## DIRECTIONALITY based on kendall tau correlation and monotonicity


get_crop_kendall_tau <- function(crop, remove_zero_vals = FALSE) {
  
  shap_df <- get(paste0(crop, "_shap_vals"), envir = .GlobalEnv)
  x_df    <- get(paste0("county_agg_", crop), envir = .GlobalEnv)
  
  vars <- intersect(colnames(shap_df), colnames(x_df))
  
  res <- lapply(vars, function(v) {
    
    x <- x_df[[v]]
    y <- shap_df[[v]]
    df <- data.frame(x = x, y = y)
    
    non_agri_groups <- c("Climate", "Soil", "Topography")
    
    # all agri variables = everything else in group_list
    agri_vars <- unlist(
      group_list[!names(group_list) %in% non_agri_groups],
      use.names = FALSE
    )
    
    if (remove_zero_vals && v %in% agri_vars) {  #removing zeros from ag variables
      df <- df[df$x != 0, ]
    }
    
    
    
  test <- cor.test(x = df$x, y=df$y, method = "kendall")
    
    c(
      tau = unname(test$estimate),
      p.value = test$p.value
    )
  })
  
  res_df <- as.data.frame(do.call(rbind, res))
  res_df$Variable <- vars
  
  res_df
}


# get_crop_kendall_tau(crop = "corn")
# get_crop_kendall_tau(crop = "corn", remove_zero_vals = TRUE)

all_crops_tau <- do.call(
  rbind,
  lapply(crop_names, function(cr) {
    df <- get_crop_kendall_tau(tolower(cr))
    # df <- get_crop_kendall_tau(tolower(cr), remove_zero_vals = TRUE)
    df$Crop <- stringr::str_to_title(cr)
    df
  })
)


var_order_heatmap <- unlist(group_list, use.names = FALSE)
var_group_map <- data.frame(
  Variable = var_order_heatmap,
  Group = rep(names(group_list), lengths(group_list)),
  stringsAsFactors = FALSE
)


all_crops_tau_order <- all_crops_tau |>
  dplyr::left_join(var_group_map, by = "Variable") |>
  dplyr::mutate(
    Variable = factor(Variable, levels = var_order_heatmap)
  )

var_name_mapping_new <- c(
  IRRIG = "Irrigation fraction (MIRAD)",
  IRRIG_std = "Irrigation fraction (MIRAD)",
  IRRIG_MIRCA = "Irrigation fraction (MIRCA)",
  irg_acre_total = "Irrigated acres",
  KONAR_GWW = "Irrigation volume (groundwater)",
  KONAR_SWW = "Irrigation volume, (surface water)",
  cover_crop_acre = "Cover crops planted, acres",
  till_no_till_acre = "No-till acres",
  till_conventional_acre = "Conventional tillage acres",
  organic_number_operations = "Organic farms, # operations",
  tile_drain_acres = "Land drained by tile, acres",
  crop_insurance_acre_rma = "Crop insurance, acres, RMA",
  fert_exp_usd = "Fertilizer expense, $",
  chem_exp_usd = "Chemical expense, $",
  N_manure_kg = "N from manure, kg",
  P_manure_kg = "P from manure, kg",
  N_fert_kg = "N from fertilizer, kg",
  P_fert_kg = "P from fertilizer, kg",
  labor_usd = "Labor expense, contract+hired, $",
  machinery_usd = "Machinery value, $",
  live_cattle_inventory = "Livestock- cattle, inventory",
  animal_sales_usd = "Total animal sales, $",
  RUCC_2013 = "Urban-rural continuum",
  Producer_female = "No of female producers",
  Producer_nonwhite = "No of non-white producers",
  median_farmsize = "Median farm size",
  producer_exp_lt_10 = "# Producers with experience <=10 yr",
  Producer_age_le_35 = "Producers with age < 35 yr",
  rented_fract = "Part owner, tenant, %acres",
  no_ops_sales_lt_10k = "%farm operations with sales less than $10k",
  CRP_ACRE = "CRP acres",
  directsales_retail = "Direct sales, retail, $",
  sales_usd_gt_500k = "Sales by mega farms (> $500k)",
  EQIP_ACRE = "EQIP acres",
  biofuel_corn_percent_used = "Corn biofuel % use",
  biofuel_soy_percent_used = "Soy biofuel % use",
  Cao_fert_N = "N rate, kg/acre",
  Cao_fert_P = "P rate, kg/acre",
  NA_1KM = "Elevation",
  NA_1KM_SLOPE = "Slope",
  T_BULK_DEN = "Bulk density (topsoil)",
  T_CLAY = "Clay content (topsoil)",
  T_GRAVEL = "Gravel content (topsoil)",
  T_SAND = "Sand content (topsoil)",
  T_SILT = "Silt content (topsoil)",
  T_CEC_CLAY = "Clay Cation Exc. Cap. (topsoil)",
  BV1_Annual_Mean_Temp = "Annual Mean Temperature",
  BV2_Mean_Diurnal_Range = "Mean Diurnal Temperature Range",
  BV4_Temp_Seasonality = "Temperature Seasonality",
  BV5_MaxTemp_Warm_Month = "Maximum Temperature of Warmest Month",
  BV6_MinTemp_Cold_Month = "Minimum Temperature of Coldest Month",
  BV8_MeanTemp_Wet_Quart = "Mean Temperature of Wettest Quarter",
  BV9_MeanTemp_Driest_Quart = "Mean Temperature of Driest Quarter",
  BV10_MeanTemp_Warm_Quart = "Mean Temperature of Warmest Quarter",
  BV11_MeanTemp_Cold_Quart = "Mean Temperature of Coldest Quarter",
  BV12_Annual_Precip = "Annual Precipitation",
  BV13_Precip_Wet_Month = "Precipitation of Wettest Month",
  BV14_Precip_Dry_Month = "Precipitation of Driest Month",
  B15_CoV_Precip = "Coefficient of Variation of Precipitation",
  B16_Precip_Wet_Quart = "Precipitation of Wettest Quarter",
  B17_Precip_Dry_Quart = "Precipitation of Driest Quarter",
  B18_Precip_Warm_Quart = "Precipitation of Warmest Quarter",
  B19_Precip_Cold_Quart = "Precipitation of Coldest Quarter",
  PRICE = "Crop price",
  mean_est_std = "Crop-specific infrastructure",
  ag_land_value_usd = "Ag land value ($)",
  till_new_conservational_acre = "Conservation tillage acres"
)

all_crops_tau_order <- all_crops_tau_order %>%
  mutate(
    Variable_full = recode(Variable, !!!var_name_mapping_new)
  )


p_ken = ggplot(all_crops_tau_order, aes(x = Crop, y = Variable_full, fill = tau)) +
  geom_tile() +
  # geom_text(
  #   data = subset(all_crops_tau_order, p.value > 0.05),
  #   aes(label = "o"),
  #   color = "black",
  #   size = 2.5
  # ) +
  scale_fill_gradient2(
    low = "darkred",
    mid = "white",
    high = "darkblue",
    midpoint = 0,
    limits = c(-1, 1),
    name = "Kendall τ"
  ) +
  # scale_fill_manual(
  #   values = bin_colors,
  #   name = "Kendall τ"
  # ) +
  theme_minimal() +
  labs(x = NULL, y = NULL) +  # removes x and y axis labels
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    axis.text.y = element_text(size = 8)
  )
p_ken

ggsave(paste0("./figs_model2/heatmap_kendall_tau.png"),p_ken, height =10, bg = "white", width = 8)
# ggsave(paste0("./figs_model2/heatmap_kendall_tau_zeros_removed.png"),p_ken, height =8, bg = "white", width = 16)


x11 = county_agg_corn$ag_land_value_usd
y11 = corn_shap_vals$ag_land_value_usd
cor.test(x = x11, y=y11, method = "kendall")
ggplot(data = NULL, aes(x = rank(x11), y = rank(y11))) +
  geom_point(color = "blue", alpha = 0.6) +
  theme_minimal() 

ggplot(data = NULL, aes(x = (x11), y = (y11))) +
  geom_point(color = "blue", alpha = 0.6) +
  theme_minimal() 

### Kendal tau for historical paper

all_crops_tau_hist_paper <- do.call(
  rbind,
  lapply(crop_names_hist, function(cr) {
    df <- get_crop_kendall_tau(tolower(cr))
    # df <- get_crop_kendall_tau(tolower(cr), remove_zero_vals = TRUE)
    df$Crop <- stringr::str_to_title(cr)
    df
  })
)

all_crops_tau_hist_paper_order <- all_crops_tau_hist_paper |>
  dplyr::left_join(var_group_map, by = "Variable") |>
  dplyr::mutate(
    Variable = factor(Variable, levels = var_order_heatmap)
  )

all_crops_tau_hist_paper_order <- all_crops_tau_hist_paper_order %>%
  mutate(
    Variable_full = recode(Variable, !!!var_name_mapping_new)
  )

all_crops_tau_hist_paper_order=all_crops_tau_hist_paper_order %>%mutate(
  Crop = recode(
    Crop,
    "Soy" = "Soybeans",
    "Fruitveg" = "Fruit-Vegetable"))

p_ken_hist = ggplot(all_crops_tau_hist_paper_order, aes(x = Crop, y = Variable_full, fill = tau)) +
  geom_tile() +
  # geom_text(
  #   data = subset(all_crops_tau_order, p.value > 0.05),
  #   aes(label = "o"),
  #   color = "black",
  #   size = 2.5
  # ) +
  scale_fill_gradient2(
    low = "darkred",
    mid = "white",
    high = "darkblue",
    midpoint = 0,
    limits = c(-1, 1),
    name = "Kendall τ"
  ) +
  # scale_fill_manual(
  #   values = bin_colors,
  #   name = "Kendall τ"
  # ) +
  theme_minimal() +
  labs(x = NULL, y = NULL) +  # removes x and y axis labels
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    axis.text.y = element_text(size = 8)
  )
p_ken_hist
ggsave(paste0("./figs_model2/heatmap_kendall_tau_hist_paper.png"),p_ken_hist, height =10, bg = "white", width = 8)



####
## plotting heatmaps for each crop separately
plot_heat_single_crop_tau <- function(crop){
 
  temp_tau = get_crop_kendall_tau(tolower(crop))
  
  temp_tau = temp_tau %>%
    arrange(tau) %>%                         # sort by Kendall τ
    mutate(
      Variable = factor(Variable, levels = Variable)  # preserve sorted order
    )
  temp_tau <- temp_tau %>%
    mutate(
      Variable_full = recode(Variable, !!!var_name_mapping_new)
    )
  
 p =  ggplot(temp_tau, aes(x = Variable_full, y = toupper(crop), fill = tau)) +
    geom_tile(color = "white", linewidth = 0.3) +
    scale_fill_gradient2(
      low = "darkred",
      mid = "white",
      high = "darkblue",
      midpoint = 0,
      limits = c(-1, 1),
      name = "Kendall τ"
    ) +
    geom_text(
      aes(label = sprintf("%.2f", tau)),
      angle = 90,          
      size = 2.5,
      color = "black",
      fontface = "bold"
    ) +
    coord_fixed(ratio = 7) +   
    
    labs(x = NULL, y = toupper(crop)) +
    theme_minimal() +
    theme(
      axis.text.y = element_blank(),
      axis.ticks.y = element_blank(),
      axis.text.x = element_text(angle = 90, hjust = 1, size = 9)
    )
   return(p)
  }


# ggsave(paste0("./figs_model2/heatmap_kendall_tau_single_soy.png"),plot_heat_single_crop_tau("soy"),height =4, bg = "white", width = 8)

for (crop in crop_names_hist) {
  p <- plot_heat_single_crop_tau(crop)
  ggsave(paste0("./figs_model2/heatmap_kendall_tau_single_", tolower(crop), ".png"),plot = p, width = 8,height = 4,bg = "white")
  message("Saved heatmap for ", crop)
}
####################


## Plotting the feature importance barchart and kendall tau based colors

plot_feature_importance_tau <- function(shap_imp,
                                        tau_df,
                                        title = "Crop SHAP Importance",
                                        text_size_y = 10,
                                        text_size_x = 8,
                                        x_label = "SHAP Importance",
                                        y_label = "Variables") {
  

  
  # Convert shap vector to dataframe
  shap_df <- data.frame(
    Variable = names(shap_imp),
    shap_imp = as.numeric(shap_imp)
  )
  
  # Merge tau
  plot_df <- shap_df %>%
    left_join(tau_df[, c("Variable", "tau")], by = "Variable")
  
  # Order by shap importance
  plot_df <- plot_df %>%
    arrange(shap_imp)
  
  p <- ggplot(plot_df,
              aes(x = reorder(Variable, shap_imp),
                  y = shap_imp,
                  fill = tau)) +
    
    geom_bar(stat = "identity") +
    
    # Tau text at end of bars
    geom_text(aes(label = round(tau, 2)),
              hjust = -0.1,
              size = 3) +
    
    coord_flip() +
    
    scale_fill_gradient2(
      low = "darkred",      # red for negative
      mid = "white",
      high = "darkblue",     # blue for positive
      midpoint = 0,
      limits = c(-1, 1),
      name = "Kendall τ"
    ) +
    
    labs(x = y_label, y = x_label, title = title) +
    
    theme_bw() +
    theme(
      axis.text.y = element_text(size = text_size_y, color = 'black'),
      axis.text.x = element_text(size = text_size_x, color = 'black'),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      axis.line = element_line(color = "grey"),
      plot.title = element_text(hjust = 0.5, size = 16)
    ) +
    
    # expand space for labels
    scale_y_continuous(expand = expansion(mult = c(0, 0.15)))
  
  return(p)
}


tau_corn = get_crop_kendall_tau(crop = "corn")

plot_feature_importance_tau(
  shap_imp = corn_shap_imp,
  tau_df = tau_corn,
  title = "Corn SHAP Importance (Colored by Kendall τ)"
)

for (i in 1: length(crop_names)){
  tau_temp_df = get_crop_kendall_tau(crop = tolower(crop_names[i]))
  plot_feature_importance_tau(shap_imp = get(paste0(tolower(crop_names[i]), "_shap_imp")), 
                              tau_df = tau_temp_df, title = crop_names[i])
  ggsave(paste0("./figs_model2/feature_importance_tau_colors/", crop_names[i], "_importance_shap_tau.png"), scale = 1.2, bg = "white", width = 10, height = 10)
}

#############################


####################
##### PLotting bubble plots containing shap importance and color based on tau

#using this in paper
bubble_shap_tau_df <- do.call(
  rbind,
  lapply(crop_names, function(cr) {
    
    shap_imp <- get(paste0(tolower(cr), "_shap_imp"), envir = .GlobalEnv)
    tau_df <- get_crop_kendall_tau(tolower(cr))
    
    df <- data.frame(
      Variable = names(shap_imp),
      shap_imp = shap_imp
    )
    
    df <- merge(df, tau_df[, c("Variable", "tau")], by = "Variable")
    
    df$Crop <- stringr::str_to_title(cr)
    
    df
  })
)

var_order_heatmap <- unlist(group_list, use.names = FALSE)
var_group_map <- data.frame(
  Variable = var_order_heatmap,
  Group = rep(names(group_list), lengths(group_list)),
  stringsAsFactors = FALSE
)


bubble_shap_tau_df <- bubble_shap_tau_df |>
  dplyr::left_join(var_group_map, by = "Variable") |>
  dplyr::mutate(
    Variable = factor(Variable, levels = var_order_heatmap)
  )


bubble_shap_tau_df <- bubble_shap_tau_df %>%
  mutate(
    Variable_full = recode(Variable, !!!var_name_mapping_new)
  )



p_bubble_shap_tau <- ggplot(bubble_shap_tau_df,
                            aes(x = Crop,
                                y = Variable_full,
                                size = shap_imp,
                                color = tau)) +
  
  geom_point(alpha = 0.9) +
  
  scale_size(
    range = c(2, 9),
    name = "SHAP Importance"
  ) +
  
  scale_color_gradient2(
    low = "#B2182B",
    mid = "white",
    high = "#2166AC",
    midpoint = 0,
    limits = c(-1,1),
    name = "Kendall τ"
  ) +
  
  scale_x_discrete(expand = c(0.02,0)) +
  
  theme_bw() +
  
  labs(
    x = NULL,
    y = NULL,
    title = ""
  ) +
  
  theme(
    axis.text.x = element_text(size = 20, angle = 90, vjust = 0.5, hjust = 1),
    axis.text.y = element_text(size = 15),
    panel.grid.major.x = element_line(color = "grey85", linewidth = 0.5),
    panel.grid.major.y = element_line(color = "grey85", linewidth = 0.5),
    
    panel.grid.minor = element_blank(),
    
    plot.title = element_text(hjust = 0.5)
  )

p_bubble_shap_tau

ggsave("./figs_model2//bubble_shap_imp_with_tau.png", p_bubble_shap_tau, width = 14, height = 14)


p_bubble_shap_tau_hist <- ggplot(bubble_shap_tau_df %>% filter(!Crop %in% stringr::str_to_title(crop_excluded_hist)) %>%
                                   mutate(
                                     Crop = recode(
                                       Crop,
                                       "Soy" = "Soybeans",
                                       "Fruitveg" = "Fruit-Vegetable")),
                            aes(x = Crop,
                                y = Variable_full,
                                size = shap_imp,
                                color = tau)) +
  
  geom_point(alpha = 0.9) +
  
  scale_size(
    range = c(2, 9),
    name = "SHAP Importance"
  ) +
  
  scale_color_gradient2(
    low = "#B2182B",
    mid = "white",
    high = "#2166AC",
    midpoint = 0,
    limits = c(-1,1),
    name = "Kendall τ"
  ) +
  
  scale_x_discrete(expand = c(0.02,0)) +
  
  theme_bw() +
  
  labs(
    x = NULL,
    y = NULL,
    title = ""
  ) +
  
  theme(
    axis.text.x = element_text(size = 20, angle = 90, vjust = 0.5, hjust = 1),
    axis.text.y = element_text(size = 15),
    panel.grid.major.x = element_line(color = "grey85", linewidth = 0.5),
    panel.grid.major.y = element_line(color = "grey85", linewidth = 0.5),
    
    panel.grid.minor = element_blank(),
    
    plot.title = element_text(hjust = 0.5)
  )

p_bubble_shap_tau_hist

ggsave("./figs_model2//bubble_shap_imp_with_tau_hist_crops1.png", p_bubble_shap_tau_hist, width = 14, height = 14)



p_bubble_shap_tau_hist_clim <- ggplot(bubble_shap_tau_df %>% filter(!Crop %in% stringr::str_to_title(crop_excluded_hist)) %>%
                                   filter(Variable %in% group_list$Climate),
                            aes(x = Crop,
                                y = Variable_full,
                                size = shap_imp,
                                color = tau)) +
  
  geom_point(alpha = 0.9) +
  
  scale_size(
    range = c(2, 9),
    name = "SHAP Importance"
  ) +
  
  scale_color_gradient2(
    low = "#B2182B",
    mid = "white",
    high = "#2166AC",
    midpoint = 0,
    limits = c(-1,1),
    name = "Kendall τ"
  ) +
  
  scale_x_discrete(expand = c(0.02,0)) +
  
  theme_bw() +
  
  labs(
    x = NULL,
    y = NULL,
    title = ""
  ) +
  
  theme(
    axis.text.x = element_text(size = 20, angle = 90, vjust = 0.5, hjust = 1),
    axis.text.y = element_text(size = 15),
    panel.grid.major.x = element_line(color = "grey85", linewidth = 0.5),
    panel.grid.major.y = element_line(color = "grey85", linewidth = 0.5),
    
    panel.grid.minor = element_blank(),
    
    plot.title = element_text(hjust = 0.5)
  )

p_bubble_shap_tau_hist_clim

ggsave("./figs_model2//bubble_shap_imp_with_tau_hist_crops_clim_only.png", p_bubble_shap_tau_hist_clim, width = 14, height = 14)





## THe low kendall tau instances either means low sensitivity or the kendall tau cant capture due to non-monotonicity of the relation
# Therefore, next I use Chatterjee coeff. to know if the sensitivity is high but the relationship is non-monotonic, that would mean
# the direction is dependent on the regions




############  #directionality and correlation part Over ###########

# BUBBLE PLOT & Combines importance
combined_shap_imp <- data.frame(
  mean_shap_value = c(barley_shap_imp, cotton_shap_imp, pecans_shap_imp, oats_shap_imp, peanuts_shap_imp, 
                      sorghum_shap_imp, fruitveg_shap_imp, rye_shap_imp, corn_shap_imp, 
                      soy_shap_imp, wheat_shap_imp, pasture_shap_imp, hay_shap_imp),
  varnames = c(names(barley_shap_imp), names(cotton_shap_imp), names(pecans_shap_imp), names(oats_shap_imp),
               names(peanuts_shap_imp), names(sorghum_shap_imp), names(fruitveg_shap_imp), names(rye_shap_imp),
          names(corn_shap_imp), names(soy_shap_imp), names(wheat_shap_imp), names(pasture_shap_imp),names(hay_shap_imp)),
  CROP = rep(c("BARLEY", "COTTON", "PECANS", "OATS", "PEANUTS", "SORGHUM", "FRUITVEG", "RYE", "CORN", "SOY",
               "WHEAT", "PASTURE", "HAY"),
             times = c(length(barley_shap_imp), length(cotton_shap_imp), length(pecans_shap_imp), length(oats_shap_imp), 
                       length(peanuts_shap_imp), length(sorghum_shap_imp), length(fruitveg_shap_imp), length(rye_shap_imp),
             length(corn_shap_imp), length(soy_shap_imp), length(wheat_shap_imp), length(pasture_shap_imp),length(hay_shap_imp)))
)


# group vars
names <- c("BV1_Annual_Mean_Temp", "BV2_Mean_Diurnal_Range", "BV4_Temp_Seasonality",
           "BV5_MaxTemp_Warm_Month", "BV6_MinTemp_Cold_Month", "BV8_MeanTemp_Wet_Quart",
           "BV9_MeanTemp_Driest_Quart", "BV10_MeanTemp_Warm_Quart", "BV11_MeanTemp_Cold_Quart",
           "BV12_Annual_Precip", "BV13_Precip_Wet_Month", "BV14_Precip_Dry_Month", "B15_CoV_Precip", 
           "B16_Precip_Wet_Quart", "B17_Precip_Dry_Quart", "B18_Precip_Warm_Quart", "B19_Precip_Cold_Quart")
combined_shap_imp$VARSET <- NA
combined_shap_imp$VARSET[combined_shap_imp$varnames %in% names] <- "Climate"
combined_shap_imp$VARSET[combined_shap_imp$varnames %in% c("T_BULK_DEN", "T_CEC_CLAY", "T_CLAY", "T_GRAVEL", "T_SAND", "T_SILT")] <- "Soil"
combined_shap_imp$VARSET[combined_shap_imp$varnames %in% c("NA_1KM_SLOPE", "NA_1KM")] <- "Topography"
combined_shap_imp$VARSET[combined_shap_imp$varnames %in% c("KONAR_GWW", "KONAR_SWW")] <- "Irrigation"
# Add IRRIG_MIRCA for all crops excepts- pasture, fruitveg, oats, and pecans
combined_shap_imp$VARSET[
  combined_shap_imp$varnames == "IRRIG_MIRCA" &
    !combined_shap_imp$CROP %in% c("FRUITVEG", "PASTURE", "OATS", "PECANS")
] <- "Irrigation"
combined_shap_imp$VARSET[
  combined_shap_imp$varnames == "IRRIG_std" &
    combined_shap_imp$CROP %in% c("FRUITVEG", "PASTURE", "OATS", "PECANS")
] <- "Irrigation"


combined_shap_imp$VARSET[combined_shap_imp$varnames %in% c("cover_crop_acre", "till_new_conservational_acre",
                               "tile_drain_acres", "CRP_ACRE","EQIP_ACRE",
                               "live_cattle_inventory","organic_number_operations")] <- "Management"
combined_shap_imp$VARSET[combined_shap_imp$varnames %in% c("fert_exp_usd", "chem_exp_usd", "N_manure_kg", "P_manure_kg", 
                               "N_fert_kg", "P_fert_kg", "labor_number", "machinery_usd","Cao_fert_N", "Cao_fert_P" )] <- "Inputs"
# ECONOMICS — exclude PRICE for PASTURE and FRUITVEG
combined_shap_imp$VARSET[combined_shap_imp$varnames %in% c(
                      "animal_sales_usd", "rented_fract", "no_ops_sales_lt_10k", "directsales_retail", "sales_usd_gt_500k", "ag_land_value_usd",
                      "crop_insurance_acre_rma")] <- "Economics"

# Add PRICE to Economics only for crops other than FRUITVEG and PASTURE
combined_shap_imp$VARSET[
  combined_shap_imp$varnames == "PRICE" &
    !combined_shap_imp$CROP %in% c("FRUITVEG", "PASTURE")
] <- "Economics"

combined_shap_imp$VARSET[combined_shap_imp$varnames %in% c("RUCC_2013", "Producer_female", "Producer_nonwhite", "median_farmsize",
                               "Producer_age_le_35", "producer_exp_lt_10")] <- "Demographics"   #panel does not have "producer_exp_lt_10", need to add it again

combined_shap_imp$VARSET[combined_shap_imp$varnames %in% c("mean_est_std", "biofuel_corn_percent_used", "biofuel_soy_percent_used")] <- "Infrastructure"

#sort(names(barley_shap_imp))
combined_shap_imps <- combined_shap_imp %>%
  group_by(VARSET, CROP, varnames) %>% # collapse across iterations
  summarize(MS = mean(mean_shap_value))

combined_shap_impmax <- combined_shap_imps %>%
  group_by(CROP) %>%
  summarize(MSG = max(MS))

combined_shap_imps <- merge(combined_shap_imps, combined_shap_impmax, by = "CROP") %>% mutate(MS_S = MS/MSG)

combined_shap_imps$VARSET <- factor(combined_shap_imps$VARSET, levels = c(
  "Climate", "Soil", "Topography", "Irrigation", "Management", 
  "Inputs", "Economics", "Demographics", "Infrastructure"
))

# Create a custom ordering of 'varnames' based on 'VARSET' categories
combined_shap_imps <- combined_shap_imps %>%
  arrange(VARSET, varnames)  # Sort data by category and then by variable name

# Update the 'varnames' factor levels to match the custom order
combined_shap_imps$varnames <- factor(combined_shap_imps$varnames, levels = unique(combined_shap_imps$varnames))

bubble <- ggplot(data = combined_shap_imps) +
  geom_point(aes(x = varnames, y = CROP, size = MS_S, alpha = MS_S, color = factor(VARSET))) +
  project_theme +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1),
  legend.text = element_text(size = 18))  +
  
  labs(x = "",
       y = "",
       color = NULL) +  # Remove legend title for colors
  coord_flip() +
  scale_color_manual(values = c(
    "dark green",   # Climate
    "yellow",       # Soil
    "blue",         # Topography
    "brown",        # Irrigation
    "orange",       # Management
    "turquoise",    # Inputs
    "black",        # Economics
    "purple",       # Demographics
    "cyan"          # Infrastructure
  )) +
  guides(
    size = "none",   # Suppress legend for size
    alpha = "none",  # Suppress legend for alpha
    color = guide_legend(override.aes = list(size = 5))  # Customize color legend appearance
  )

bubble
# ggsave("./figs/bubble_shap.png", bubble, width = 10, height = 14)
ggsave("./figs_model2//bubble_shap.png", bubble, width = 10, height = 14)

filtered_data <- combined_shap_imps %>% 
  filter(VARSET %in% c("Climate", "Inputs"))

# Create the plot
## The bubble size isnt relative; its based on all categories
bubble_climate <- ggplot(data = filtered_data) +
  geom_point(aes(
    x = varnames, 
    y = CROP, 
    size = MS_S, 
    alpha = MS_S, 
    color = factor(VARSET)
  )) +
  project_theme +
  theme(
    axis.text.x = element_text(size = 20,angle = 90, vjust = 0.5, hjust = 1),
    axis.text.y = element_text(size = 20)
  ) +
  labs(
    x = "",
    y = "",
    color = ""
  ) +
  coord_flip() +
  scale_color_manual(values = c("Climate" = "dark green", "Inputs" = "turquoise"))+   # Assign colors to VARSET
  guides(
    size = "none",   # Suppress legend for size
    alpha = "none",  # Suppress legend for alpha
    color = guide_legend(override.aes = list(size = 5))  # Customize color legend appearance
  )


bubble_climate
# ggsave("./figs/bubble_shap_climate_input.png", bubble_climate, width = 10, height = 14)
ggsave("./figs_model2//bubble_shap_climate_input.png", bubble_climate, width = 14, height = 14)

####################################################################################

## SPATIAL SHAP PLOTS

all_crop_shap_list <- list(
  CORN = corn_shap_vals_st,
  COTTON = cotton_shap_vals_st,
  SOY = soy_shap_vals_st,
  WHEAT = wheat_shap_vals_st,
  PEANUTS = peanuts_shap_vals_st,
  HAY = hay_shap_vals_st,
  PASTURE = pasture_shap_vals_st,
  FRUITVEG = fruitveg_shap_vals_st,
  PECANS = pecans_shap_vals_st,
  OATS = oats_shap_vals_st,
  BARLEY = barley_shap_vals_st,
  SORGHUM = sorghum_shap_vals_st,
  RYE = rye_shap_vals_st
)

crop_shap_all <- purrr::map2_df(all_crop_shap_list, names(all_crop_shap_list), ~mutate(.x, crop = .y))

plot_shap_spatial_facet <- function(data_sf, shap_col, states) {
  
  # Compute color limits symmetrically around 0
  lim <- max(abs(data_sf[[shap_col]]), na.rm = TRUE)
  
  # Create the plot
  p <- ggplot() +
    geom_sf(data = data_sf, aes_string(fill = shap_col), color = NA) +
    geom_sf(data = states, fill = NA, color = "black", size = 0.2) +  # <-- state outlines
    scale_fill_gradient2(
      low = "red", mid = "white", high = "blue",
      midpoint = 0, limits = c(-lim, lim),
      name = "SHAP value"
    ) +
    facet_wrap(~crop, ncol = 4) +
    theme_minimal(base_size = 11) +
    labs(
      title = paste("Spatial Distribution of SHAP Values:", shap_col),
      subtitle = "",
      x = NULL, y = NULL
    ) +
    theme(
      strip.text = element_text(face = "bold", size = 10),
      legend.position = "bottom",
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(size = 12)
    )
  
  return(p)
}

p1 <- plot_shap_spatial_facet(crop_shap_all, "N_fert_kg", states)

plot(p1)

for (col in colnames(barley_shap_vals)) {
  p_temp = plot_shap_spatial_facet(crop_shap_all, shap_col = col, states)
  ggsave(paste0("./figs_model2/shap_spatial_plots/", col, ".png"), p_temp, bg = "white", width = 10, height = 10)
  
}


####
# Spatial plots for aggregated categories (RAW aggregte so we have - ve and +ve)

# making aggregated_cat_shap_raw_barley_st type of dataframe

for (crop in crop_names) {
  shap_df <- get(paste0("aggregated_cat_shap_raw_", tolower(crop)))
  county_df <- get(paste0("county_agg_", tolower(crop)))
  
  # Bind GEOID and geometry
  shap_sf <- shap_df %>%
    mutate(GEOID = county_df$GEOID,
           geometry = county_df$geometry) %>%
    st_as_sf()
  
  assign(paste0("aggregated_cat_shap_raw_", tolower(crop), "_st"), shap_sf)
}

# making aggregated_cat_shap_barley_st type of dataframe
#makes no sense

# for (crop in crop_names) {
#   shap_df <- get(paste0("aggregated_cat_shap_", tolower(crop)))
#   county_df <- get(paste0("county_agg_", tolower(crop)))
#   
#   # Bind GEOID and geometry
#   shap_sf <- shap_df %>%
#     mutate(GEOID = county_df$GEOID,
#            geometry = county_df$geometry) %>%
#     st_as_sf()
#   
#   assign(paste0("aggregated_cat_shap_", tolower(crop), "_st"), shap_sf)
# }


#  Function to plot SHAP category map (9 facets)
#---------------------------
plot_shap_spatial_categories <- function(data_sf, crop_name, states) {
  
  # Reshape to long format for faceting
  df_long <- data_sf %>%
    tidyr::pivot_longer(cols = c("Climate", "Soil", "Topography", "Irrigation",
                                 "Management", "Inputs", "Economics",
                                 "Demographics", "Infrastructure"),
                        names_to = "Category", values_to = "SHAP")
  
  lim <- max(abs(df_long$SHAP), na.rm = TRUE)
  
  ggplot() +
    geom_sf(data = df_long, aes(fill = SHAP, geometry = geometry), color = NA) +
    geom_sf(data = states, fill = NA, color = "black", size = 0.2) +
    scale_fill_gradient2(
      low = "red", mid = "white", high = "blue",
      midpoint = 0, limits = c(-lim, lim), name = "SHAP"
    ) +
    facet_wrap(~Category, ncol = 3) +
    theme_minimal() +
    labs(
      title = paste("Aggregated SHAP Value:", crop_name),
      x = NULL, y = NULL
    ) +
    theme(
      legend.position = "bottom",
      strip.text = element_text(face = "bold", size = 10),
      plot.title = element_text(size = 14, face = "bold")
    )
}

# Testing
plot_shap_spatial_categories(aggregated_cat_shap_raw_corn_st, "CORN", states)
# plot_shap_spatial_categories(aggregated_cat_shap_corn_st, "CORN", states)  #for abs

for (crop in crop_names) {
  df_st <- get(paste0("aggregated_cat_shap_raw_", tolower(crop), "_st"))
  p <- plot_shap_spatial_categories(df_st, crop, states)
  print(p)
  
  ggsave(paste0("./figs_model2/shap_spatial_plots_cat/", crop, "_agg_raw_shap.png"), p, width = 10, height = 8, dpi = 300, bg = "white")
}

#only plot few columns

plot_shap_spatial_selected_categories <- function(data_sf, crop_name, states, selected_categories) {
  
  # Reshape only selected categories
  df_long <- data_sf %>%
    dplyr::select(dplyr::all_of(c(selected_categories, "geometry"))) %>%
    tidyr::pivot_longer(cols = all_of(selected_categories),
                        names_to = "Category", values_to = "SHAP")
  
  lim <- max(abs(df_long$SHAP), na.rm = TRUE)
  
  ggplot() +
    geom_sf(data = df_long, aes(fill = SHAP, geometry = geometry), color = NA) +
    geom_sf(data = states, fill = NA, color = "black", size = 0.2) +
    scale_fill_gradient2(
      low = "red", mid = "white", high = "blue",
      midpoint = 0, limits = c(-lim, lim), name = "SHAP"
    ) +
    facet_wrap(~Category, ncol = 2) +
    theme_minimal() +
    labs(
      title = paste("Aggregated SHAP Value:", crop_name),
      x = NULL, y = NULL
    ) +
    theme(
      legend.position = "bottom",
      strip.text = element_text(face = "bold", size = 10),
      plot.title = element_text(size = 14, face = "bold")
    )
}

plot_shap_spatial_selected_categories(aggregated_cat_shap_raw_corn_st, "CORN", states, selected_categories = c("Climate", "Inputs", "Management", "Economics"))

#Just plotting climate and inputs
for (crop in crop_names) {
  df_st <- get(paste0("aggregated_cat_shap_raw_", tolower(crop), "_st"))
  p <- plot_shap_spatial_selected_categories(df_st, crop, states, selected_categories = c("Climate", "Inputs", "Management", "Economics"))
  print(p)
  
  ggsave(paste0("./figs_model2/shap_spatial_plots_cat_selected_vars/", crop, "_agg_raw_shap_clim_inp_eco_mgmt.png"), p, width = 10, height = 8, dpi = 300, bg = "white")
}

##############
## Making biophysical vs human contorlled Spatial maps
plot_shap_spatial_bio_human <- function(data_sf, crop_name, states) {
  
  # Aggregate into two categories
  df_agg <- data_sf %>%
    mutate(
      Biophysical     = Climate + Soil + Topography,
      Human_controlled = Irrigation + Management + Inputs + Economics + Demographics + Infrastructure
    ) %>%
    dplyr::select(Biophysical, Human_controlled, geometry) %>%
    tidyr::pivot_longer(cols = c(Biophysical, Human_controlled),
                        names_to = "Category", values_to = "SHAP") %>%
    mutate(Category = factor(Category, levels = c("Biophysical", "Human_controlled"),
                             labels = c("Biophysical", "Human-controlled")))
  
  lim <- max(abs(df_agg$SHAP), na.rm = TRUE)
  
  ggplot() +
    geom_sf(data = df_agg, aes(fill = SHAP, geometry = geometry), color = NA) +
    geom_sf(data = states, fill = NA, color = "black", size = 0.2) +
    scale_fill_gradient2(
      low = "red", mid = "white", high = "blue",
      midpoint = 0, limits = c(-lim, lim), name = "SHAP"
    ) +
    facet_wrap(~Category, ncol = 2) +
    theme_minimal() +
    labs(
      title = paste("Biophysical vs Human-controlled SHAP:", crop_name),
      x = NULL, y = NULL
    ) +
    theme(
      legend.position  = "bottom",
      strip.text       = element_text(face = "bold", size = 12),
      plot.title       = element_text(size = 14, face = "bold")
    )
}

plot_shap_spatial_bio_human(aggregated_cat_shap_raw_corn_st, "CORN", states)

df_agg_shap_raw_bio_human_corn <- aggregated_cat_shap_raw_corn_st %>%
  mutate(
    Biophysical      = Climate + Soil + Topography,
    Human_controlled = Irrigation + Management + Inputs + Economics + Demographics + Infrastructure
  ) %>%
  st_join(states %>% select(STATE_ABBR, geometry), join = st_intersects) %>%
  st_drop_geometry() %>%
  group_by(STATE_ABBR) %>%
  summarise(
    Biophysical      = mean(Biophysical,      na.rm = TRUE),
    Human_controlled = mean(Human_controlled, na.rm = TRUE),
    .groups = "drop"
  )

df_agg_shap_raw_bio_human_corn %>%
  arrange(desc(Biophysical)) %>%
  slice_head(n = 7)

df_agg_shap_raw_bio_human_corn %>%
  arrange(desc(Human_controlled)) %>%
  slice_head(n = 7)
#--------------

## All crops contribution map human vs bio
# Build combined dataframe for all crops
df_agg_shap_raw_bio_human_all_crops <- map_dfr(crop_names_hist, function(crop) {
  
  df <- get(paste0("aggregated_cat_shap_raw_", tolower(crop), "_st"))
  
  df %>%
    mutate(
      Biophysical      = Climate + Soil + Topography,
      Human_controlled = Irrigation + Management + Inputs + Economics + Demographics + Infrastructure,
      Crop             = tools::toTitleCase(tolower(crop))
    ) %>%
    dplyr::select(Biophysical, Human_controlled, Crop, geometry)
})

# Pivot to long format
df_agg_shap_raw_bio_human_all_crops_long <- df_agg_shap_raw_bio_human_all_crops %>%
  tidyr::pivot_longer(cols = c(Biophysical, Human_controlled),
                      names_to = "Category", values_to = "SHAP") %>%
  mutate(Category = factor(Category, 
                           levels = c("Biophysical", "Human_controlled"),
                           labels = c("Biophysical", "Human-controlled")),
         Crop = factor(Crop, levels = tools::toTitleCase(tolower(crop_names_hist))))

lim <- max(abs(df_agg_shap_raw_bio_human_all_crops_long$SHAP), na.rm = TRUE)

# Plot
p_bio_human_all <- ggplot() +
  geom_sf(data = df_agg_shap_raw_bio_human_all_crops_long, aes(fill = SHAP, geometry = geometry), color = NA) +
  geom_sf(data = states, fill = NA, color = "black", linewidth = 0.2) +
  scale_fill_gradient2(
    low = "red", mid = "white", high = "blue",
    midpoint = 0, limits = c(-lim, lim), name = "SHAP"
  ) +
  facet_grid(Crop ~ Category) +
  theme_minimal() +
  labs(x = NULL, y = NULL) +
  theme(
    legend.position  = "bottom",
    strip.text       = element_text(face = "bold", size = 9),
    panel.spacing    = unit(0.2, "lines")
  )

p_bio_human_all
ggsave("./figs_model2/spatial_bio_human_all_crops.png", 
       p_bio_human_all, width = 10, height = 22, dpi = 300, bg = "white")

########### Listing top states with human vs biophysical contribution== note- only sums positive values
map(crop_names_hist, function(crop) {
  
  df <- get(paste0("aggregated_cat_shap_raw_", tolower(crop), "_st")) %>%
    mutate(
      Biophysical      = Climate + Soil + Topography,
      Human_controlled = Irrigation + Management + Inputs + Economics + Demographics + Infrastructure
    ) %>%
    st_join(states %>% select(STATE_ABBR, geometry), join = st_intersects) %>%
    st_drop_geometry() %>%
    group_by(STATE_ABBR) %>%
    summarise(
      Biophysical      = sum(pmax(Biophysical,      0), na.rm = TRUE),
      Human_controlled = sum(pmax(Human_controlled, 0), na.rm = TRUE),
      .groups = "drop"
    )
  
  top5_bio   <- df %>% arrange(desc(Biophysical))      %>% slice_head(n = 5) %>% pull(STATE_ABBR)
  top5_human <- df %>% arrange(desc(Human_controlled)) %>% slice_head(n = 5) %>% pull(STATE_ABBR)
  
  cat(crop, "\n")
  cat("  Bio:   ", paste(top5_bio,   collapse = ", "), "\n")
  cat("  Human: ", paste(top5_human, collapse = ", "), "\n\n")
  
}) %>% invisible()
