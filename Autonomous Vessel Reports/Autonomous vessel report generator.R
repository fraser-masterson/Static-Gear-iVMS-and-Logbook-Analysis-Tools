
require(sf)
require(readr)
require(dplyr)
require(knitr)
require(rmarkdown)
require(ggplot2)
require(raster)
require(concaveman)
require(tidyr)
require(ggspatial)
require(stringr)
require(tinytex)
require(xtable)
require(kableExtra)
require(viridis)
require(ggspatial)
require(lubridate)

# tinytex::install_tinytex() # Need to install this if it's the first time running this file on a device

# Columns required in Joined datasets -------------------------------------------

# uniqueID: RSS/VesselID concatenated with date (e.g., M055_01/04/2023)
# Vessel.Name: name of vessel (e.g., Whisky Galore)
# Departure.Date: date of departure in YYYY-mm-dd format (e.g., 2023-05-13)
# LE_KG_CRE: kg of crab landed during a trip
# LE_KG_LBE: kg of lobster landed during a trip
# LE_KG_WHE: kg of whelk landed during a trip
# Pot_No_CRE: number of crab pots hauled during a trip
# Pot_No_LBE: number of lobster pots hauled during a trip
# Pot_No_WHE: number of whelk pots hauled during a trip
# SI_Month: month of trip
# LE_YEAR: year of trip
# VE_REF: Vessel reference/ID (e.g., M055)
# SI_DATE: date of vms record in dd-mm-YYYY format
# SI_LONG: longitude of vms record
# SI_LATI: latitude of vms record

# -----------------------------------------------------------------------------


# Input parameters ------------------------------------------------------------
start_date = '01/01/2023' # Input start date of the report here in 'dd/mm/YYYY' format
end_date = '31/12/2023' # Input end date of the report here in 'dd/mm/YYYY' format

all_vessels = FALSE
vessel_ID = 'M210' # if all_vessels is FALSE, choose vessel ID for report (e.g., 'M151')

reports_dir = "~/Documents/IoM 2025/Autonomous vessel reports/" # Directory of this code and report code files

joined_data_dir = "~/Documents/IoM 2025/Data/Cleaned/Joined data/" # Directory for Join csv files (e.g., Join5.csv)
cleaned_data_dir = "~/Documents/IoM 2025/Data/Cleaned/" # Directory for cleaned VMS, logbook, and XCheck/comments data

shapefiles_dir = "~/Documents/IoM 2025/Data/Raw/Shapefiles/" # Directory for shapefiles and bathymetry raster
# -----------------------------------------------------------------------------

# add option to load in raw data and clean within script (make more generalisable)

######################################
{ # Run this line to create the report
######################################
  
  
  
  # Load in the data ------------------------------------------------------------
  dir.create(paste0(reports_dir, " Reports"))
  
  start_date = as.POSIXct(start_date, format = '%d/%m/%Y', tz = 'UTC')
  end_date = as.POSIXct(end_date, format = '%d/%m/%Y', tz = 'UTC')
  
  bathy = read_csv(paste0(shapefiles_dir, 'Bathymetry/Mean depth in multi colour (no land).csv'))
  
  bathy = bathy[, -4:-9]
  bathy = bathy[-1, ]
  bathy$latitude = as.numeric(bathy$latitude)
  bathy$longitude = as.numeric(bathy$longitude)
  bathy$elevation = as.numeric(bathy$elevation)
  
  bathy = filter(bathy, elevation > -125)
  
  nm12 <- st_read(paste0(shapefiles_dir, "Base/IoM_12nm_marbdy_arc_bng.shp"))
  nm3 <- st_read(paste0(shapefiles_dir, "Base/IoM_3nm_marbdy_arc_bng.shp"))
  IoM <- st_read(paste0(shapefiles_dir, "Base/IOM_WGS.shp"))
  nm12 = st_transform(nm12, crs = 4326)
  nm3 = st_transform(nm3, crs = 4326)
  IoM = st_transform(IoM, crs = 4326)
  
  IOM12NM = concaveman(nm12)
  IOM3NM = concaveman(nm3)
  
  IOM12NM.USE<- st_difference(IOM12NM, IOM3NM)
  
  Join5 = read_csv(paste0(joined_data_dir, "Join5.csv"))
  Join5$Departure.Date = as.POSIXct(Join5$Departure.Date, format = '%d/%m/%Y', tz = 'UTC')
  Join10s.4 = read_csv(paste0(joined_data_dir, "Join10s_4.csv"))
  Join10m.5 = read_csv(paste0(joined_data_dir, "Join10m_5.csv"))
  logbook = read.csv(paste0(cleaned_data_dir, 'LB_ALL/combinedlog_O10_U10m.csv'))
  vms = read.csv(paste0(cleaned_data_dir, 'iVMS/ivms_cleaned.csv'))
  check = read.csv(paste0(cleaned_data_dir, 'XCheckSummary.csv'))
  check$uniqueID = paste(check$RSS.No, check$date, sep = '_')
  check = check[, -c(1:4)]
  logbook = logbook %>%
    left_join(check, by = 'uniqueID')
  logbook <- logbook %>%
    mutate(Exclude.IVMS = replace_na(Exclude.IVMS, 0))
  Join5 = Join5 %>%
    left_join(check, by = 'uniqueID')
  Join5 <- Join5 %>%
    mutate(Exclude.IVMS = replace_na(Exclude.IVMS, 0))
  vms = vms %>%
    left_join(check, by = 'uniqueID')
  vms <- vms %>%
    mutate(Exclude.IVMS = replace_na(Exclude.IVMS, 0))
  # -----------------------------------------------------------------------------
  
  # Creates vessel index with species type --------------------------------------
  vindex_m = Join10m.5 %>%
    group_by(Vessel.Name) %>%
    summarise(n.trips = length(unique(uniqueID)),
              "species" = "Mixed")
  vindex_s = Join10s.4 %>%
    group_by(Vessel.Name) %>%
    summarise(n.trips = length(unique(uniqueID)),
              "species" = "Single")
  
  vindex = rbind(vindex_s, vindex_m)
  #------------------------------------------------------------------------------
  
  add_suffix <- function(n) {
    if (n %% 100 %in% 11:13) return("th")
    switch(as.character(n %% 10),
           "1" = "st",
           "2" = "nd",
           "3" = "rd",
           "th")
  }
  
  format_with_suffix <- function(x) {
    day <- as.integer(format(x, "%d"))
    suffix <- add_suffix(day)
    paste0(day, suffix, format(x, " %B %Y"))
  }
  
  # Generate report -------------------------------------------------------------
  if (all_vessels == TRUE) {
    for (i in 1:nrow(vindex)) {
      vessel_name = vindex$Vessel.Name[i]
      print(vessel_name)
      params = list(vessel_name = vessel_name,
                    start_date = start_date,
                    end_date = end_date) 
      render(input = paste0(reports_dir, "Autonomous-vessel-report.Rmd"),
             output_file = paste0(reports_dir, "Reports/", vessel_name, '_', gsub('/', '-', start_date), '_', gsub('/', '-', end_date), ".pdf"),
             params = list(vessel_name = vessel_name))
    } 
  }
  else if (all_vessels == FALSE) {
    vessel_name = Join5[Join5$VE_REF == vessel_ID, ]$Vessel.Name[1]
    print(vessel_name)
    params = list(vessel_name = vessel_name,
                  start_date = start_date,
                  end_date = end_date) 
    render(input = paste0(reports_dir, "Autonomous-vessel-report.Rmd"),
           output_file = paste0(reports_dir, "Reports/", vessel_name, '_', gsub('/', '-', start_date), '_', gsub('/', '-', end_date), ".pdf"),
           params = list(vessel_name = vessel_name))
  }
  
  # -----------------------------------------------------------------------------
  
}


