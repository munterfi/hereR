## Create `poi` dataset

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
poi[6,]$city <- "Zurich"

# Save POIs
usethis::use_data(poi, overwrite = TRUE)
