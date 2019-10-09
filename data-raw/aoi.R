## Create `aoi` dataset

# Country boundaries
countries <- sf::st_read(
  "https://raw.githubusercontent.com/datasets/geo-countries/master/data/countries.geojson"
)

# Select Areas of Interest (AOIs)
aoi <- countries[countries$ISO_A2 %in% c("CH", "LI"), ]
aoi$name <- c("Switzerland", "Liechtenstein")
aoi$code <- c("CH", "LI")
aoi$ADMIN <- aoi$ISO_A3 <- aoi$ISO_A2 <- NULL

# Save AOIs
usethis::use_data(aoi, overwrite = TRUE)
