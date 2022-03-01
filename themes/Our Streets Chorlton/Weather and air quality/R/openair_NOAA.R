
##tidyverse covers a number of common packages needed for basic data processing, if have any problems installing, 'dyplr' and 'purrr' (which are included in tidyverse) should suffice
library(tidyverse)
library(openair)
library(sf)
library(mapview)
library(stringr)
library(lubridate)
## load worldmet package for met data
library(worldmet)
##to install unhash these lines
##install.packages("remotes")
#remotes::install_github("davidcarslaw/openairmaps")
library(openairmaps)

latlong = "+init=epsg:4326"
ukgrid = "+init=epsg:27700"

##creates folder for plots to be saved in
dir.create(paste0("../plots/"))

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
site_locations <- read.csv("data/chorlton/site_locations.csv")
sites <- unique(site_locations$site_name)
all_sites <- 
AQ_dat <- list()
for (site in sites){
  
  site_fn <- gsub(" ", "_", site)
  
  ## adds a sub folder for the site specific plots
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
DA_5min <- timeAverage(DA_avg, "10 min")

da_location <- data.frame(site = "Darley Ave", lat, lon)
site_sf <- st_as_sf(da_location, coords = c("lon", "lat"), crs = latlong)

##find aq sites in the UK
UK_met <- getMeta(country = "UK")
##create sf object
UK_met_sf <- st_as_sf(UK_met, coords = c("longitude", "latitude"), crs = latlong)
##find nearest met station to AQ site
site_met <- UK_met_sf[st_nearest_feature(site_sf,UK_met_sf),]
site_dist <- st_distance(site_met, site_sf)
site_dist <- st_nearest_points(site_met, site_sf)

##plot met and aq site on same map
#mapview(site_sf)+site_met
# import met observations for site
data_met <- importNOAA(site_met$code, year = 2021:2021, hourly = FALSE)

## generate a wind rose for the wind data at the meteo site
w1 <- windRose(data_met)
## export as a png
filename <- paste0("../plots/", site_fn, "/", p,"/",  "WR.png")
png(filename, width=15000, height=15000, units="px", res=1600)
print(w1)
dev.off()

data_met2 <- timeAverage(data_met, "5 min", fill = TRUE)
##Join AQ data with met
AQ_met <- DA_avg %>% 
  left_join(data_met2, by = "date") %>% 
  select(-atmos_pres, -visibility) %>% 
  filter(!is.na(site_temp)) %>% 
  filter(!is.na(ws))

AQ_avg <- timeAverage(AQ_met, "hour")

#plots based on pollutant 'p' (ensure format matches the column in the data)

pollutants <- c("no2", "o3", "no", "pm1", "pm2.5", "pm10")

for (p in pollutants){

  dir.create(paste0("../plots/", site_fn, "/", p))

##Filter to eliminate early part of 2007 due to sporadic/missing data
#AQ_met <- filter(AQ_met, !is.na(p))
##define units in correct markdown script for plots
unit_aq <- "ug/m-3"
var_aq <- toupper(p)
key_aq <- paste0(var_aq, " ", unit_aq)

AQ_wday <- cutData(AQ_met, type = "weekday")
AQ_wday <- filter(AQ_wday, !weekday == "Saturday" & !weekday == "Sunday")

AQ_met_loc <- mutate(AQ_met, lat, lon)

## polar plot split by year
p1 <- polarPlot(AQ_met, p, col = "jet", main = paste0(p), key.footer = key_aq)

##polar plot for full period of monitored data
p2 <- polarPlot(AQ_wday, p, col = "jet", main = paste0(p), type = "hour", key.footer = key_aq)
## polar plot for full time series split by season
p3 <- polarPlot(AQ_met, p, col = "jet", type = 'month', main = paste0(p), key.footer = key_aq)

## polar plot split by air temperature - maybe see if when wind blows from a certain direction and temp is cold e.g. woodburners
p4 <- polarPlot(AQ_met, p, col = "jet", type = 'air_temp', main = paste0(p), key.footer = key_aq)
##POLAR MAP - plots polar plot on an interactive html map - needs openairmaps which is not on CRAN

##polar plot for full time series
p5 <- polarMap(AQ_met_loc, p, latitude = "lat", longitude = "lon", x = "ws", key = TRUE, key.footer = key_aq, iconWidth = 300, iconHeight = 300)

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
filename <- paste0("../plots/", site_fn, "/", p, "/",  "NOAA_p01.png")
png(filename, width=10500, height=10000, units="px", res=1200)
print(p1)
dev.off()

filename <- paste0("../plots/", site_fn, "/", p,"/",  "NOAA_p02.png")
png(filename, width=10500, height=10000, units="px", res=1000)
print(p2)
dev.off()

filename <- paste0("../plots/", site_fn, "/", p,"/",  "NOAA_p03.png")
png(filename, width=10500, height=10000, units="px", res=1200)
print(p3)
dev.off()

filename <- paste0("../plots/", site_fn, "/", p,"/",  "NOAA_p04.png")
png(filename, width=10500, height=10000, units="px", res=1200)
print(p4)
dev.off()

##polar map saved with mapshot function, which is part of mapview package
mapshot(p5, paste0("../plots/", site_fn, "/", p,"/",  "NOAA_p05.html"))

filename <- paste0("../plots/", site_fn, "/", p,"/",  "NOAA_p06.png")
png(filename, width=15000, height=10000, units="px", res=1000)
print(p6)
dev.off()

filename <- paste0("../plots/", site_fn, "/", p,"/",  "p07.png")
png(filename, width=15000, height=10000, units="px", res=1000)
print(p7)
dev.off()

filename <- paste0("../plots/", site_fn, "/", p,"/",  "NOAA_p08.png")
png(filename, width=15000, height=10000, units="px", res=1000)
print(p8)
dev.off()

filename <- paste0("../plots/", site_fn, "/", p,"/",  "NOAA_p09.png")
png(filename, width=10000, height=12000, units="px", res=1000)
print(p9)
dev.off()

filename <- paste0("../plots/", site_fn, "/", p,"/",  "NOAA_p10.png")
png(filename, width=10000, height=12000, units="px", res=1000)
print(p10)
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


p14 <- timePlot(AQ_met, pollutant = c(p, "air_temp", "RH"), y.relation = "free")
#temp_thread <- time_dygraph(AQ_met, variable = p)

##Specify the number of 'trees' and 'samples' 34=00 is usually taken as a good balance
Trees <- 300
Samples <- 300

# Met normalisation, define the pollutant to focus on and the variables to consider. date_unix, weekday and day_julian are taken from the time and are not explicit columns in the dataframe
list_rm <- rmw_do_all(
  rmw_prepare_data(AQ_met, value = p),
  variables = c(
    "wd", "ws", "air_temp", "RH", "date_unix", "day_julian", "weekday", "hour", "ceil_hgt"
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
       caption = "Data source: Open Data Manchester, meteo from NOAA surface observations accessed using the worldmet R package, Weather normalisation carried out using the RMweather R package")

##data frame of normalised daily averages that could be matched to traffic data
normalised_daily <- list_rm$normalised

filename <- paste0("../plots/", site_fn, "/", p,"/",  "NOAA_p11.png")
png(filename, width=15000, height=10000, units="px", res=1000)
print(p11)
dev.off()

filename <- paste0("../plots/", site_fn, "/", p,"/",  "NOAA_p12.png")
png(filename, width=15000, height=10000, units="px", res=1000)
print(p12)
dev.off()

filename <- paste0("../plots/", site_fn, "/", p,"/",  "NOAA_p13.png")
png(filename, width=15000, height=10000, units="px", res=1000)
print(p13)
dev.off()

filename <- paste0("../plots/", site_fn, "/", p,"/",  "NOAA_p14.png")
png(filename, width=15000, height=7500, units="px", res=1000)
print(p14)
dev.off()

}

AQ_out <- AQ_met %>% 
  timeAverage("hour") %>% 
  mutate(site = site)
AQ_dat[[site]] <- AQ_out

}



all_dat <- do.call(rbind, AQ_dat) 
saveRDS(all_dat, "../R_scripts/shiny/data/all_sites.RDS")
