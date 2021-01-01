#!/usr/bin/env Rscript
# -----------------------------------------------------------------------------
# Name          :aoi.R
# Description   :Create `aoi` example dataset.
# Author        :Merlin Unterfinger <info@munterfinger.ch>
# Date          :2020-12-23
# Version       :0.1.0
# Usage         :./data-raw/aoi.R
# Notes         :
# R             :4.0.3
# =============================================================================

# Country boundaries
countries <- sf::st_read(
  "https://raw.githubusercontent.com/datasets/geo-countries/master/data/countries.geojson"
)

# Select Areas of Interest (AOIs)
aoi <- countries[countries$ISO_A2 %in% c("CH", "LI"), ]
aoi$name <- c("Switzerland", "Liechtenstein")
aoi$code <- c("CH", "LI")
aoi$ADMIN <- aoi$ISO_A3 <- aoi$ISO_A2 <- NULL
rownames(aoi) <- NULL
aoi <- sf::st_as_sf(as.data.frame(aoi))

# Save AOIs
usethis::use_data(aoi, overwrite = TRUE)
