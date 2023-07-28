# from https://mran.revolutionanalytics.com/web/packages/checkpoint/vignettes/using-checkpoint-with-knitr.html
# if you don't need a package, remove it from here (commenting is probably not sufficient)

## Install and load required packages
if (!require(pacman)) install.packages('pacman')

devtools:::install_github("gearslaboratory/gdalUtils")

p_load(rstudioapi,
       tidyverse, # ggplot2, dplyr, tidyr, readr, purrr, tibble, magrittr
       lintr, # code linting
       sf, # spatial data handling
       raster, # raster handling (needed for relief)
       viridis, # viridis color scale
       cowplot, # stack ggplots
       rmarkdown,
       gdalUtils, # raster handling (needed for relief)
       jsonlite, # for JSON formatted data
       httr) # api web scraping

# Define the API endpoint and parameters
url <- "https://api.census.gov/data/2019/acs/acs5"
params <- list(
  get = "B19083_001E,B19025_001E,B11001_001E",
  `for` = "county:*",
  `in` = "state:*",
  key = "c7ee6f67c29580be9bab87f2fa9396fea65517a3"
)

# Make the API request
response <- GET(url, query = params)

# Check the status of the response
print(status_code(response))

# Parse the response to JSON
data <- fromJSON(content(response, "text"), simplifyDataFrame = TRUE)

# Define the WMS server URL
url <- "https://basemap.nationalmap.gov:443/arcgis/services/USGSShadedReliefOnly/MapServer/WmsServer?"

# Define the WMS parameters
params <- list(
  service = "WMS",
  version = "1.3.0",
  request = "GetMap",
  layers = "0",  # the layer name is "0"
  styles = "",
  crs = "EPSG:4326",  # use the EPSG:4326 CRS
  bbox = c(-179.999989, -88.261376, 179.999996, 83.999861),  # use the provided bounding box coordinates
  width = 250,  # reduce the width
  height = 125,  # reduce the height
  format = "image/png",
  transparent = "FALSE"
)

# Create the full URL with parameters
full_url <- paste0(url, paste(names(params), params, sep = "=", collapse = "&"))

# Download the map image
raster_image <- raster(full_url)

# Plot the raster image
plot(raster_image)


# Convert the data to a data frame
# Assuming df is your data frame
df <- as.data.frame(data) 
df1 <- df |>
  setNames(df[1, ]) |>
  slice(-1) |> # Remove the first row
  rename(gini_index = B19083_001E,
         agg_income = B19025_001E,
         num_households = B11001_001E) |>
  mutate(mean_income = as.numeric(agg_income)/as.numeric(num_households))
  

# read cantonal borders
states_geo <- read_sf("slides/19/data/ak/states.shp")

# read country borders
country_geo <- read_sf("slides/19/data/ne_10m_admin_0_countries.shx")

# read lakes
lake_geo <- read_sf("input/g2s15.shp")

# read productive area (2324 municipalities)
municipality_prod_geo <- read_sf("input/gde-1-1-15.shp")

# read in raster of relief
relief <- raster("slides/19/data/srgy48i200l.tif") %>%
  # hide relief outside of Switzerland by masking with country borders
  mask(country_geo) %>%
  as("SpatialPixelsDataFrame") %>%
  as.data.frame() %>%
  rename(value = `X02.relief.ascii`)

# clean up
rm(country_geo)

# Join Geodata with Thematic Data
municipality_prod_geo %<>%
  left_join(data, by = c("BFS_ID" = "bfs_id"))
class(municipality_prod_geo)
