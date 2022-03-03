## script for downloading the free ECMWF reanalysis (ra) data. There are two variations shown below, downloading the 'land' (9km2) and the 'single layer' (30km2)

library(dplyr)
library(sf)
library(ncdf4)
library(ecmwfr)
library(rnaturalearth)
library(rnaturalearthdata)

##define coordinate systems
latlong = "+init=epsg:4326"
rdnew = "+init=epsg:28992"

## load in shape file of metropoliton counties in England
MAs <- st_read("https://opendata.arcgis.com/datasets/389f538f35ef4eeb84965dfd7c0a0b47_0.geojson")

## lpick out shape file of Greater Manchester
GM <- filter(MAs, mcty18nm == "Greater Manchester")

  ## ecmwf requires a max and min lat lon - define this
  min_lon <- floor(min(st_coordinates(GM)[,1]))
  max_lon <- ceiling(max(st_coordinates(GM)[,1]))
  min_lat <- floor(min(st_coordinates(GM)[,2]))
  max_lat <- ceiling(max(st_coordinates(GM)[,2]))

 ##define the max and min domain for the ecmwf request
  ecmwf_land_area <- paste0(min_lat, "/", min_lon, "/", max_lat, "/", max_lon)
  
  ##output path, don't put a / at the end or will return an error
  path_out <- "C:/Users/xxxx/Downloads"
  
  ##input ecmwf user id
  user = "xxx@xxxx.nl" ## ecmwf username
  
  ## specify user ID and key
  wf_set_key(user = "5 digits", ## user id
             key = "36 character key", ## key
             service = "cds") ##service (cds = 'climate data store')
  
  ##define variables to download. list is available here: https://confluence.ecmwf.int/display/CKB/ERA5-Land%3A+data+documentation#ERA5Land:datadocumentation-parameterlistingParameterlistings
  variables <- c("surface_solar_radiation_downwards", "2m_temperature", "10m_u_component_of_wind",
                 "10m_v_component_of_wind", "total_precipitation")

  yrz <- c("2021")
  
  ##downloads to a directory 'data' at the same level as the script is saved
  
  ##ECMWF data
    for(v in unique(variables)){
      
      for (y in yrz){
      
        ## request function, can be adjusted to remove months etc..
      
      request_BLD <- list(dataset_short_name = "reanalysis-era5-land",
                          product_type   = "reanalysis",
                          variable       = v,
                          year = y,
                          month = c("01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"),
                          day = c("01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31"),
                          time = c("00:00", "01:00", "02:00", "03:00", "04:00", "05:00", "06:00", "07:00", "08:00", "09:00", "10:00", "11:00", "12:00", "13:00", "14:00", "15:00", "16:00", "17:00", "18:00", "19:00", "20:00", "21:00", "22:00", "23:00"),
                          area           = ecmwf_land_area,
                          format         = "netcdf",
                          target         = paste0(v, "_", y, ".nc"))
      
      
      nc_BLD <- wf_request(user = "59954",
                           request = request_BLD,
                           transfer = TRUE,
                           path = path_out,
                           verbose = TRUE)
      
    }

    }
  
  ##ERA variable (0.25 degree)
  
  ecmwf_main_area <- paste0(min_lat, "/", min_lon, "/", max_lat, "/", max_lon)

  ##for list of variables visit https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-era5-single-levels?tab=form create a query and click
  ## 'show API request' next to the variable with the the variable text to paste into the list of strings below
  variables_main <- c("boundary_layer_height", "total_cloud_cover")
  
  ##ECMWF data
  
  for(v in unique(variables_main)){
    
    for (y in yrz){
    
    request_BLD <- list(dataset_short_name = "reanalysis-era5-single-levels",
                        product_type   = "reanalysis",
                        variable       = v,
                        year = c("2018"),
                        month = c("01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"),
                        day = c("01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31"),
                        time = c("00:00", "01:00", "02:00", "03:00", "04:00", "05:00", "06:00", "07:00", "08:00", "09:00", "10:00", "11:00", "12:00", "13:00", "14:00", "15:00", "16:00", "17:00", "18:00", "19:00", "20:00", "21:00", "22:00", "23:00"),
                        area           = ecmwf_main_area,
                        format         = "netcdf",
                        target         = paste0(v, "_", y, ".nc"))
    
    
    nc_BLD <- wf_request(user = "59954",
                         request = request_BLD,
                         transfer = TRUE,
                         path = path_out,
                         verbose = TRUE)
    
  }
  }
 