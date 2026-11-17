library(tidyverse)
library(sf)
library(terra)
library(stars)
library(viridis)
library(randomForest)
library(caret)
library(rasterVis)
library(ggplot2)

setwd(Sys.getenv("DISES_FOREB", "."))   # model-input folder (Zenodo data record)

#setwd("G:/")
select <- dplyr::select

project_theme <- theme_bw() +
  theme(text = element_text(size = 12))

map_theme <- project_theme +
  theme(axis.text.x = element_blank(),
        axis.text.y = element_blank(),
        axis.ticks = element_blank(),
        rect = element_blank(),
        legend.position = "bottom")

# project projection, based on CDL FAQ reference projection
epsg <- 5070 
wc_epsg <- "GEOGCRS[\"WGS 84\",\n    ENSEMBLE[\"World Geodetic System 1984 ensemble\",\n        MEMBER[\"World Geodetic System 1984 (Transit)\"],\n        MEMBER[\"World Geodetic System 1984 (G730)\"],\n        MEMBER[\"World Geodetic System 1984 (G873)\"],\n        MEMBER[\"World Geodetic System 1984 (G1150)\"],\n        MEMBER[\"World Geodetic System 1984 (G1674)\"],\n        MEMBER[\"World Geodetic System 1984 (G1762)\"],\n        MEMBER[\"World Geodetic System 1984 (G2139)\"],\n        ELLIPSOID[\"WGS 84\",6378137,298.257223563,\n            LENGTHUNIT[\"metre\",1]],\n        ENSEMBLEACCURACY[2.0]],\n    PRIMEM[\"Greenwich\",0,\n        ANGLEUNIT[\"degree\",0.0174532925199433]],\n    CS[ellipsoidal,2],\n        AXIS[\"geodetic latitude (Lat)\",north,\n            ORDER[1],\n            ANGLEUNIT[\"degree\",0.0174532925199433]],\n        AXIS[\"geodetic longitude (Lon)\",east,\n            ORDER[2],\n            ANGLEUNIT[\"degree\",0.0174532925199433]],\n    USAGE[\n        SCOPE[\"Horizontal component of 3D system.\"],\n        AREA[\"World.\"],\n        BBOX[-90,-180,90,180]],\n    ID[\"EPSG\",4326]]"

# load shapefiles
state_list <- c("ME", "NH", "VT", "MA", "RI", "CT", "NY", "PA", "NJ", "DE", "MD", "WV", "VA", "NC", "SC", "KY",
                "OH", "MI", "WI", "IA", "MN", "MO", "TN", "GA", "AL", "MS", "LA", "AR", "KS", "OK", 
                "TX", "ND", "NE", "SD", "IL", "IN", "FL", "DC")
states <- st_read("./data/states.shp") %>% filter(STATE_ABBR %in% state_list)
states <- st_transform(states, epsg)
roi <- st_union(states)
counties <- st_read("./data/county.shp") %>% filter(STATEFP %in% unique(states$STATE_FIPS))
counties <- st_transform(counties, epsg)

# mask to exclude non-agricultural CDL categories from analysis
# based on this metadata: https://www.nass.usda.gov/Research_and_Science/Cropland/metadata/metadata_Cultivated-Layer-2023.htm
# we include Other Hay/Non Alfalfa (37), Sod/Grass Seed (59), Grass/Pasture (176)
non_ag <- c(0, 60, 63, 64, 65, 81, 82, 83, 87, 88, 92, 111, 112, 121, 122, 123, 124, 131, 141, 142, 143, 152, 190, 195)

# set up crop list infrastructure
cdl_key <- read.csv("./data/cdl_key_fv_nut.csv")
fv_mask_cdl <- unique(cdl_key %>% filter(FV_MASK_CDL == 0) %>% pull(CDL_CODE)) # CDL categories TO MASK that are NOT fruit and veg

cdl_list <- list(c(1, 225, 226, 228, 237, 241), # corn  
                 c(2, 232, 238, 239), # cotton
                 c(5, 239, 240, 241, 26, 254), # soy
                 c(24, 225, 236, 238, 26), # (winter) wheat
                 c(10), # peanuts
                 c(37, 36), # Other Hay/Non Alfalfa and alfalfa 
                 c(176), # grass/pasture - possibly drop this
                 fv_mask_cdl,# fruit/veg
                 c(74), # pecans
                 c(28, 226, 240), # oats
                 c(254, 233, 21, 235, 237), # barley
                 c(234, 236, 4, 235), # sorghum
                 c(27) # rye
                 ) 

clean_crop_names <- c("Corn", "Cotton", "Soy", "Wheat", "Peanuts", "Hay", "Pasture", "Fruit and veg", "Pecans", "Oats", "Barley",
                      "Sorghum", "Rye")
crop_names <- c("CORN", "COTTON", "SOY", "WHEAT", "PEANUTS", "HAY", "PASTURE", "FRUITVEG", "PECANS", "OATS", "BARLEY", "SORGHUM", "RYE")
crop_names_new <- c("CORN", "COTTON", "SOY", "WHEAT", "PEANUTS", "HAY", "FRUITVEG", "OATS", "BARLEY", "SORGHUM", "RYE") # NO pasture & Pecans

crop_names2 <- c("CORN", "COTTON", "SOYBEANS", "WHEAT", "PEANUTS", "HAY", "PECANS", "OATS", "BARLEY", "SORGHUM", "RYE") #No pasture or fruitveg

names(cdl_list) <- crop_names

names <- c("BV1_Annual_Mean_Temp", "BV2_Mean_Diurnal_Range", "BV3_Isothermality", "BV4_Temp_Seasonality",
           "BV5_MaxTemp_Warm_Month", "BV6_MinTemp_Cold_Month", "BV7_Temp_Annual_Range", "BV8_MeanTemp_Wet_Quart",
           "BV9_MeanTemp_Driest_Quart", "BV10_MeanTemp_Warm_Quart", "BV11_MeanTemp_Cold_Quart",
           "BV12_Annual_Precip", "BV13_Precip_Wet_Month", "BV14_Precip_Dry_Month", "B15_CoV_Precip", 
           "B16_Precip_Wet_Quart", "B17_Precip_Dry_Quart", "B18_Precip_Warm_Quart", "B19_Precip_Cold_Quart")
