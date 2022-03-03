Open Data Manchester have installed two Earthsense Zephyr solar-powered air quality sensors to measure air quality at selected locations in Chorlton and Chorlton Park during 2021 as part of the Our Streets Chorlton project.

The sensors will be measuring Nitrous Oxide (NO), Nitrous Dioxide (NO2), Ozone (O3) and other microscopic particles that come from industry, traffic and fires, all of which are known to have an impact on our health if we are exposed to high concentrations.

One unit will be permanently located at Chorlton’s ‘Four Banks’ crossroad of Wilbraham Road and Barlow Moor Road, with the other rotated between the three chosen ‘mini project’ locations of a school, a trading area and a residential street.

All data collected will be made openly available for everyone to access, explore, use and share.

The sensors only measure air-quality data and do not collect personally identifiable information.

**Data collected**

- Temperature (C)
- Humidity (%RH)
- NO2 (ug/m3)
- O3 (ug/m3)
- NO (ug/m3)
- PM1 (ug/m3)
- PM2.5 (ug/m3)
- PM10 (ug/m3)
- Ambient temp (C)
- Ambient humidity (%RH)
- Ambient pressure (hPa)

NO2 = Nitrogen Dioxide | O3 = Ozone | NO = Nitric Oxide | PM = Particulate Matter

**R Scripts for analysis**

The R scripts enable someone cloning the Air Quality folder to generate some plots of the data using the R package Openair, also matching with meteo data for the area.

All the scripts should be able to be run by downloading R and R studio, installing the packages at the top of the script (newer versions of Rstudio prompt the user to do this and can install for you).

The script openair_NOAA.R uses the nearest NOAA meteorological station to define the meteo conditions for each time step. In the case of the Chorlton sites this is Manchester Airport. The section of the script for retreiving this data has been written in a way that can be applied to any monitoring site.

The script openair_ECMWF.R uses the ECMWF reanalysis data to perform the same analysis, with the benefit that more parameters are available. However, users should be aware that the ECMWF is a model that is based on satelitte and surface observations (fixed meteo stations).

To run openair_ECMWF, the script ecmwf_ra_download.R must be run first. This requires an account and API key.

Instructions on creating an account can be found here: https://bluegreen-labs.github.io/ecmwfr/ once created this can be saved in the script and you shouldn't have to visit the website again except to see the queue if interested https://cds.climate.copernicus.eu/live/queue

Once run, data will be saved as a .nc file in the data folder and can then be accessed by the openair_ECMWF script for joining with AQ data.
