#!/usr/bin/env Rscript
# -----------------------------------------------------------------------------
# Name          :poi.R
# Description   :Create `poi` example dataset.
# Author        :Merlin Unterfinger <info@munterfinger.ch>
# Date          :2020-12-23
# Version       :0.1.0
# Usage         :./data-raw/poi.R
# Notes         :
# R             :4.0.3
# =============================================================================

# Country boundaries
cities <- sf::st_read(
  "https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_10m_populated_places_simple.geojson"
)

# Select Points of Interest (POIs)
poi <- cities[Reduce(c, sf::st_contains(aoi, cities)), ]
poi <- poi[poi$pop_max > 100000 | poi$name == "Vaduz", ]
poi <- poi[, c("name", "pop_max")]
colnames(poi) <- c("city", "population", "geometry")
poi$city <- as.character(poi$city)
poi$population <- as.numeric(poi$population)
rownames(poi) <- NULL

# Replace non ASCII
poi[6, ]$city <- "Zurich"

# Save POIs
usethis::use_data(poi, overwrite = TRUE)
