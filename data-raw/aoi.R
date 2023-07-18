#!/usr/bin/env Rscript
# -----------------------------------------------------------------------------
# Name          :aoi.R
# Description   :Create `aoi` example dataset.
# Author        :Merlin Unterfinger <info@munterfinger.ch>
# Date          :2023-07-18
# Version       :0.2.0
# Usage         :./data-raw/aoi.R
# Notes         :
# R             :4.3.0
# =============================================================================

# https://www.geocat.ch/geonetwork/srv/eng/catalog.search#/metadata/64091dfe-2785-4b8d-ab01-4ae291c1054a/formatters/xsl-view?root=div&view=advanced
# https://www.ogd.stadt-zuerich.ch/wfs/geoportal/Stadtkreise?service=WFS&version=1.1.0&request=GetFeature&outputFormat=GeoJSON&typename=adm_stadtkreise_v
file_url <- "https://www.ogd.stadt-zuerich.ch/wfs/geoportal/Stadtkreise?service=WFS&version=1.1.0&request=GetFeature&outputFormat=GeoJSON&typename=adm_stadtkreise_v"

# Read file
sf::sf_use_s2(FALSE)
aoi <- file_url |>
  sf::st_read() |>
  sf::st_make_valid()

# Format columns
aoi$id <- aoi$knr
aoi$objid <- aoi$knr <- aoi$objid <- NULL
aoi$name <- aoi$kname
aoi$kname <- NULL
aoi <- sf::st_as_sf(as.data.frame(aoi[order(aoi$id), ]))

# Simplify geometry to reduce file size
aoi <- aoi |>
  sf::st_transform(crs = 2056) |>
  sf::st_simplify(dTolerance = 10, preserveTopology = TRUE)

# Remove sliver polygons
aoi <- aoi |>
  sf::st_snap(aoi, tolerance = 20) |>
  sf::st_transform(4326) |>
  sf::st_make_valid()
sf::sf_use_s2(TRUE)

# Save AOIs
usethis::use_data(aoi, overwrite = TRUE)
