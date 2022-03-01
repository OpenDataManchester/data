
##tidyverse covers a number of common packages needed for basic data processing, if have any problems installing, 'dyplr' and 'purrr' (which are included in tidyverse) should suffice
library(tidyverse)
library(openair)
library(sf)
library(mapview)
library(stringr)
library(lubridate)
##to install unhash these lines
##install.packages("remotes")
#remotes::install_github("davidcarslaw/openairmaps")
library(openairmaps)
library(ncdf4)
library(birk)

latlong = "+init=epsg:4326"
ukgrid = "+init=epsg:27700"

read_in <- function(file){
  
  r1 <- read.csv(file)
  
  r <- r1 %>% 
    select(date = Timestamp.Local.)
  
  r$date <- gsub("T", " ", r$date)
  r$date <- str_sub(r$date, 0, -6)
  r$date <- ymd_hms(r$date)
  
  ndat <- r1[,4:14]
  ndat <- data.frame(sapply(ndat, as.numeric))
  
  r <- cbind(r, ndat)
  
}

##the two main monitoring networks in the UK are KCL (Kings College London) and AURN. Openair has a function to access them
# KCL <- openair::importMeta(source = "KCL", all = TRUE)
# AURN <- openair::importMeta(source = "AURN", all = TRUE)
# 
# mapview(AURN_manc)
# 
# KCL_sf <- KCL %>% 
#   filter(!is.na(latitude)) %>% 
#   st_as_sf(coords = c("longitude", "latitude"), crs = latlong)
# 
# AURN_sf <- AURN %>% 
#   filter(!is.na(latitude)) %>% 
#   st_as_sf(coords = c("longitude", "latitude"), crs = latlong)
# ##filter for sites called cromwell
# 
# https://geoportal.statistics.gov.uk/datasets/fef73aeaf13c417dadf2fc99abcf8eef?layer=0
# 
# #import the .shp files downloaded from https://geoportal.statistics.gov.uk/datasets/ae90afc385c04d869bc8cf8890bd1bcd_1
# LAs <- st_read("https://opendata.arcgis.com/datasets/ae90afc385c04d869bc8cf8890bd1bcd_1.geojson")
# 
# manc <- filter(LAs, lad17nm == "Manchester")
# st_geometry(manc) <- manc$geometry
# 
# AURN_manc <- AURN_sf[manc,]
# KCL_manc <- KCL_sf[manc,]
# 
# mapview(KCL_manc)
site_locations <- read.csv("data/site_locations.csv")
sites <- unique(site_locations$site_name)
AQ_dat <- list()
for (site in sites){
  
  site_fn <- gsub(" ", "_", site)
  
  dir.create(paste0("../plots/", site_fn))
  
  lat_lon <- filter(site_locations, site_name == site)
  lat <- lat_lon$lat
  lon <- lat_lon$lon

DA_files <- list.files("../AQ Data/", pattern = ".csv", recursive = TRUE, full.names = TRUE)
DA_files <- DA_files[grepl(site, DA_files)]

DA_dat <- map_dfr(DA_files, read_in)

names(DA_dat) <- c("date", "site_temp", "site_rh", "no2", "o3", "no", "pm1", "pm2.5", "pm10", "site_temp2", "site_rh2", "site_pressure")

DA_avg <- timeAverage(DA_dat, "min")

DA_30min <- timeAverage(DA_avg, "30 min")
DA_1hr <- timeAverage(DA_avg, "hour")

domain_1 <- readRDS("meteo/data/ecmwf_quarter_domain.RDS")
s_cell <- domain_1[site_sf,]
## Visualise the site location in within the domain
#mapview(domain_1)+mapview(s_cell, col.regions = "red")
da_location <- data.frame(site = "Darley Ave", lat, lon)
site_sf <- st_as_sf(da_location, coords = c("lon", "lat"), crs = latlong)

## import the ECMWF data for boundary layer height (have to have downloaded it using ecmwf_ra_download script)
ECMWF <- nc_open("data/boundary_layer_height_2021.nc")

##extract the lat lon coordinates of the ECMWF file
longitude <- ncvar_get(ECMWF, "longitude")
latitude <- ncvar_get(ECMWF, "latitude")
## extract the time series of the data
TIME <- ncvar_get(ECMWF, "time")
## generate a vector of indicies to find the nearest ecmwf grid to our site coords (lat lon)
lon_index <- which.closest(longitude, lon)
lat_index <- which.closest(latitude, lat)

## pick out the data for lat lon area and time range
blh <- ncvar_get(ECMWF, "blh", start = c(lon_index, lat_index, 1), count = c(1,1,NROW(TIME)))
## get date stamps for each time step
d8 <- lubridate::ymd("1900-01-01") + lubridate::hours(TIME)
##create a data frame of date and blh
d8_blh <- data.frame(date = d8, blh = blh)

## import the ECMWF data for ssrd (have to have downloaded it using ecmwf_ra_download script)
ECMWF <- nc_open("data/surface_solar_radiation_downwards_2021.nc")

longitude <- ncvar_get(ECMWF, "longitude")
latitude <- ncvar_get(ECMWF, "latitude")
TIME <- ncvar_get(ECMWF, "time")

lon_index <- which.closest(longitude, lon)
lat_index <- which.closest(latitude, lat)

## ssrd is a bit more complex in that the data is cumulative. So in order to convert to hourly absolute values
## some processing has to be done
ssrd <- ncvar_get(ECMWF, "ssrd", start = c(lon_index, lat_index, 1), count = c(1,1,NROW(TIME)))
d8_ssrd <- data.frame(d8, ssrd)
d8_ssrd$day <- yday(d8_ssrd$d8)
dayz <- unique(d8_ssrd$day)
ssrd_dayz <- list()
for (d in dayz){
  df <- filter(d8_ssrd, day == d)
  df$ssrd[1] <- 0
  ds <- diff(df$ssrd)/3600
  ds2 <- data.frame(d8 = df$d8[1:23], ssrd2 = ds)
  df_out <- df %>% 
    left_join(ds2, by = "d8") %>% 
    select(date = d8, ssrd = ssrd2)
  df_out[is.na(df_out)] <- 0
  nam <- as.character(d)
  ssrd_dayz[[nam]] <- df_out
  }

all_ssrd <- do.call(rbind, ssrd_dayz)

## get u component of wind
ECMWF <- nc_open("data/10m_u_component_of_wind_2021.nc")

longitude <- ncvar_get(ECMWF, "longitude")
latitude <- ncvar_get(ECMWF, "latitude")
TIME <- ncvar_get(ECMWF, "time")

lon_index <- which.closest(longitude, lon)
lat_index <- which.closest(latitude, lat)

u10 <- ncvar_get(ECMWF, "u10", start = c(lon_index, lat_index, 1), count = c(1,1,NROW(TIME)))

## get v component of wind
ECMWF <- nc_open("data/10m_v_component_of_wind_2021.nc")

longitude <- ncvar_get(ECMWF, "longitude")
latitude <- ncvar_get(ECMWF, "latitude")
TIME <- ncvar_get(ECMWF, "time")

lon_index <- which.closest(longitude, lon)
lat_index <- which.closest(latitude, lat)

v10 <- ncvar_get(ECMWF, "v10", start = c(lon_index, lat_index, 1), count = c(1,1,NROW(TIME)))

d8_wswd <- data.frame(d8, u10, v10)

## combine u and v elements to get wind speed and direction
ws_wd <- d8_wswd %>%
  mutate(wind_abs = sqrt(u10^2 + v10^2)) %>%
  mutate(wind_dir_trig_to = atan2(u10/wind_abs, v10/wind_abs)) %>% 
  mutate(wind_dir_trig_to_degrees = wind_dir_trig_to*180/pi) %>% 
  mutate(wind_dir_trig_from_degrees = wind_dir_trig_to_degrees + 180) %>% 
  #mutate(wd = 90 - wind_dir_trig_from_degrees) %>% ##wind direction cardinal
  mutate(wd = wind_dir_trig_from_degrees) %>%
  mutate(ws = sqrt(u10^2 + v10^2)) %>% 
  select(date = d8, ws, wd)

## generate a wind rose for the wind data at the meteo site
w1 <- windRose(ws_wd)
## export as a png
filename <- paste0("../plots/", site_fn, "/", "ECMWF_WR.png")
png(filename, width=15000, height=15000, units="px", res=1600)
print(w1)
dev.off()

## import the ECMWF data for boundary layer height (have to have downloaded it using ecmwf_ra_download script)
ECMWF <- nc_open("data/2m_temperature_2021.nc")

##extract the lat lon coordinates of the ECMWF file
longitude <- ncvar_get(ECMWF, "longitude")
latitude <- ncvar_get(ECMWF, "latitude")
## extract the time series of the data
TIME <- ncvar_get(ECMWF, "time")
## generate a vector of indicies to find the nearest ecmwf grid to our site coords (lat lon)
lon_index <- which.closest(longitude, lon)
lat_index <- which.closest(latitude, lat)

## pick out the data for lat lon area and time range
t2m <- ncvar_get(ECMWF, "t2m", start = c(lon_index, lat_index, 1), count = c(1,1,NROW(TIME)))
## get date stamps for each time step
d8 <- lubridate::ymd("1900-01-01") + lubridate::hours(TIME)
##create a data frame of date and 2m temperature - convert from kelvins to degrees celcius
d8_t2m <- data.frame(date = d8, t2m = t2m-273.15)

## import the ECMWF data for boundary layer height (have to have downloaded it using ecmwf_ra_download script)
ECMWF <- nc_open("data/total_cloud_cover_2021.nc")

##extract the lat lon coordinates of the ECMWF file
longitude <- ncvar_get(ECMWF, "longitude")
latitude <- ncvar_get(ECMWF, "latitude")
## extract the time series of the data
TIME <- ncvar_get(ECMWF, "time")
## generate a vector of indicies to find the nearest ecmwf grid to our site coords (lat lon)
lon_index <- which.closest(longitude, lon)
lat_index <- which.closest(latitude, lat)

## pick out the data for lat lon area and time range
tcc <- ncvar_get(ECMWF, "tcc", start = c(lon_index, lat_index, 1), count = c(1,1,NROW(TIME)))
## get date stamps for each time step
d8 <- lubridate::ymd("1900-01-01") + lubridate::hours(TIME)
##create a data frame of date and tcc as a fraction
d8_tcc <- data.frame(date = d8, tcc = tcc)

## import the ECMWF data for boundary layer height (have to have downloaded it using ecmwf_ra_download script)
ECMWF <- nc_open("data/total_precipitation_2021.nc")

##extract the lat lon coordinates of the ECMWF file
longitude <- ncvar_get(ECMWF, "longitude")
latitude <- ncvar_get(ECMWF, "latitude")
## extract the time series of the data
TIME <- ncvar_get(ECMWF, "time")
## generate a vector of indicies to find the nearest ecmwf grid to our site coords (lat lon)
lon_index <- which.closest(longitude, lon)
lat_index <- which.closest(latitude, lat)

## pick out the data for lat lon area and time range
tp <- ncvar_get(ECMWF, "tp", start = c(lon_index, lat_index, 1), count = c(1,1,NROW(TIME)))
## get date stamps for each time step
d8 <- lubridate::ymd("1900-01-01") + lubridate::hours(TIME)
##create a data frame of date and blh

d8_tp <- data.frame(d8, tp = tp*1000)

d8_tp$day <- yday(d8_tp$d8)
dayz <- unique(d8_tp$day)
tp_dayz <- list()
for (d in dayz){
  df <- filter(d8_tp, day == d)
  df$tp[1] <- 0
  ds <- diff(df$tp)
  ds2 <- data.frame(d8 = df$d8[1:23], tp2 = ds)
  df_out <- df %>% 
    left_join(ds2, by = "d8") %>% 
    select(date = d8, tp = tp2)
  df_out[is.na(df_out)] <- 0
  nam <- as.character(d)
  tp_dayz[[nam]] <- df_out
}

all_tp <- do.call(rbind, tp_dayz)


##Join AQ data with met
AQ_met <- DA_1hr %>% 
  left_join(d8_blh, by = "date") %>% 
  left_join(all_tp, by = "date") %>% 
  left_join(d8_tcc, by = "date") %>% 
  left_join(d8_t2m, by = "date") %>% 
  left_join(ws_wd, by = "date") %>% 
  left_join(all_ssrd, by = "date") %>% 
  filter(!is.na(site_temp)) %>% 
  select(date, no2, o3, no, pm1, pm2.5, pm10, blh, site_rh, total_precipitation = tp, tcc, air_temp = t2m, ws, wd, ssrd) %>% 
  mutate(lat, lon)

#plots based on pollutant 'p' (ensure format matches the column in the data)
## same as with NOAA but with ECMWF dayta
pollutants <- c("no2", "o3", "no", "pm1", "pm2.5", "pm10")
p <- pollutants[1]
for (p in pollutants){

  dir.create(paste0("../plots/", site_fn, "/", p))

##Filter to eliminate early part of 2007 due to sporadic/missing data
#AQ_met <- filter(AQ_met, !is.na(p))
##define units in correct markdown script for plots
unit_aq <- "ug/m-3"
var_aq <- toupper(p)
key_aq <- paste0(var_aq, " ", unit_aq)

## polar plot split by year
p1 <- polarPlot(AQ_met, p, col = "jet", main = paste0(p), key.footer = key_aq)

##polar plot for full period of monitored data
p2 <- polarPlot(AQ_met, p, col = "jet", main = paste0(p), type = "hour", key.footer = key_aq)
## polar plot for full time series split by season
p3 <- polarPlot(AQ_met, p, col = "jet", type = 'month', main = paste0(p), key.footer = key_aq)

## polar plot split by air temperature - maybe see if when wind blows from a certain direction and temp is cold e.g. woodburners
p4 <- polarPlot(AQ_met, p, col = "jet", type = 'air_temp', main = paste0(p), key.footer = key_aq)
##POLAR MAP - plots polar plot on an interactive html map - needs openairmaps which is not on CRAN

##polar plot for full time series
p5 <- polarMap(AQ_met, p, latitude = "lat", longitude = "lon", x = "ws", key = TRUE, key.footer = key_aq, iconWidth = 300, iconHeight = 300)

##time variation plots
##full time series
p6 <- timeVariation(AQ_met, pollutant = p,
                    ylab = p, main = paste0(p))


##split by year
p7 <- timeVariation(AQ_met, pollutant = p, group = "air_temp", key.columns = 5,
                    ylab = key_aq, main = paste0(p), conf.int = TRUE)
##split by air temp, removing confidence interval can clean it up a bit (although obviously lose info)
if(!p == "o3"){
  p8 <- timeVariation(AQ_met, pollutant = p, group = "o3", key.columns = 4,
                      ylab = key_aq, main = paste0(p), conf.int = FALSE)
} else {
  p8 <- timeVariation(AQ_met, pollutant = p, group = "no", key.columns = 4,
                      ylab = key_aq, main = paste0(p), conf.int = FALSE)
}
##CALENDAR PLOT - gets a bit messy for multiple years
p9 <- calendarPlot(AQ_met, p, year = "2021")
##can replace dates with wind info
p10 <- calendarPlot(AQ_met, p, year = "2021", annotate = "wd")

##save them all
filename <- paste0("../plots/", site_fn, "/", p, "/",  "ECMWF_p01.png")
png(filename, width=10500, height=10000, units="px", res=1200)
print(p1)
dev.off()

filename <- paste0("../plots/", site_fn, "/", p,"/",  "ECMWF_p02.png")
png(filename, width=10500, height=10000, units="px", res=1000)
print(p2)
dev.off()

filename <- paste0("../plots/", site_fn, "/", p,"/",  "ECMWF_p03.png")
png(filename, width=10500, height=10000, units="px", res=1200)
print(p3)
dev.off()

filename <- paste0("../plots/", site_fn, "/", p,"/",  "ECMWF_p04.png")
png(filename, width=10500, height=10000, units="px", res=1200)
print(p4)
dev.off()

##polar map saved with mapshot function, which is part of mapview package
mapshot(p5, paste0("../plots/", site_fn, "/", p,"/",  "ECMWF_p05.html"))

filename <- paste0("../plots/", site_fn, "/", p,"/",  "ECMWF_p06.png")
png(filename, width=15000, height=10000, units="px", res=1000)
print(p6)
dev.off()

filename <- paste0("../plots/", site_fn, "/", p,"/",  "ECMWF_p07.png")
png(filename, width=15000, height=10000, units="px", res=1000)
print(p7)
dev.off()

filename <- paste0("../plots/", site_fn, "/", p,"/",  "ECMWF_p08.png")
png(filename, width=15000, height=10000, units="px", res=1000)
print(p8)
dev.off()

filename <- paste0("../plots/", site_fn, "/", p,"/",  "ECMWF_p09.png")
png(filename, width=10000, height=12000, units="px", res=1000)
print(p9)
dev.off()

filename <- paste0("../plots/", site_fn, "/", p,"/",  "ECMWF_p10.png")
png(filename, width=10000, height=12000, units="px", res=1000)
print(p10)
dev.off()


##split by year
p17 <- timeVariation(AQ_met, pollutant = p, group = "blh", key.columns = 5,
                    ylab = key_aq, main = paste0(p), conf.int = TRUE)

## remove night time periods using cutData function in openair. As period with no irradiation skews the data
AQ_day <- AQ_met %>% 
  cutData(type = "daylight") %>% 
  filter(daylight == "daylight")

##split by year
p18 <- timeVariation(AQ_day, pollutant = p, group = "ssrd", key.columns = 5,
                     ylab = key_aq, main = paste0(p), conf.int = TRUE)

# filename <- paste0("../plots/", site_fn, "/", p,"/",  "p15.png")
# png(filename, width=15000, height=10000, units="px", res=1000)
# print(p15)
# dev.off()

filename <- paste0("../plots/", site_fn, "/", p,"/",  "ECMWF_p17.png")
png(filename, width=15000, height=10000, units="px", res=1400)
print(p17, subset = "hour")
dev.off()

filename <- paste0("../plots/", site_fn, "/", p,"/",  "ECMWF_p18.png")
png(filename, width=15000, height=10000, units="px", res=1400)
print(p18, subset = "hour")
dev.off()

# normalising no2 ---------------------------------------------------------------------

#Machine learning function to remove the effect of weather from the monitoring data and see the trend due to traffic more clearly
#applied in these papers https://www.sciencedirect.com/science/article/pii/S004896971834244X covid study https://acp.copernicus.org/articles/21/4169/2021/

library(rmweather)
library(threadr)

##RM WEATHER
##Rm weather works on daily averages (although one of the papers does it hourly) so data needs to be averaged
#AQ_met_day <- timeAverage(AQ_met, "day")

##Scatterplot to show per-normalised trend
p11 <- scatterPlot(AQ_met, x = "date", y = p, pch = 16, cex = 0.4, smooth = TRUE,
                   ylim = c(0,40), ylab = key_aq, xlab = "Month")


p14 <- timePlot(AQ_met, pollutant = c(p, "air_temp", "total_precipitation"), y.relation = "free")
#temp_thread <- time_dygraph(AQ_met, variable = p)

##Specify the number of 'trees' and 'samples' 34=00 is usually taken as a good balance
Trees <- 300
Samples <- 300

# Met normalisation, define the pollutant to focus on and the variables to consider. date_unix, weekday and day_julian are taken from the time and are not explicit columns in the dataframe
list_rm <- rmw_do_all(
  rmw_prepare_data(AQ_met, value = p),
  variables = c(
    "wd", "ws", "air_temp", "site_rh", "date_unix", "day_julian", "weekday", "hour", "blh", 
    "total_precipitation", "tcc", "ssrd"
  ),
  n_trees = Trees,
  n_samples = Samples,
  verbose = TRUE
)

# Check model object's performance
rmw_model_statistics(list_rm$model)

# Plot variable importances
p13 <- list_rm$model %>%
  rmw_model_importance() %>%
  rmw_plot_importance() +
  ggtitle(paste0(site, " ", p))

# Check if model has suffered from overfitting
rmw_predict_the_test_set(
  model = list_rm$model,
  df = list_rm$observations
) %>%
  rmw_plot_test_prediction()

# Check model
list_rm$model

rmw_predict_the_test_set(list_rm$model, list_rm$observations) %>%
  rmw_plot_test_prediction() +
  ggtitle(site)

# Plot normalised time series - manually defined information!
p12 <- rmw_plot_normalised(list_rm$normalised) +
  labs(subtitle=paste0("Monitoring site: ", site, ", Chorlton"),
       y=paste0(var_aq, " (?g/m3)"),
       x="Month",
       title=paste0("Weather normalised ", var_aq, " Concentrations"),
       caption = "Data source: Open Data Manchester, meteo from ECMWF reanalysis, Weather normalisation carried out using the RMweather R package")

##data frame of normalised daily averages that could be matched to traffic data
normalised_daily <- list_rm$normalised

filename <- paste0("../plots/", site_fn, "/", p,"/",  "ECMWF_p11.png")
png(filename, width=15000, height=10000, units="px", res=1000)
print(p11)
dev.off()

filename <- paste0("../plots/", site_fn, "/", p,"/",  "ECMWF_p12.png")
png(filename, width=15000, height=10000, units="px", res=1000)
print(p12)
dev.off()

filename <- paste0("../plots/", site_fn, "/", p,"/",  "ECMWF_p13.png")
png(filename, width=15000, height=10000, units="px", res=1000)
print(p13)
dev.off()

filename <- paste0("../plots/", site_fn, "/", p,"/",  "ECMWF_p14.png")
png(filename, width=15000, height=7500, units="px", res=1000)
print(p14)
dev.off()

}


}

