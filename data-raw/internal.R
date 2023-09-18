#!/usr/bin/env Rscript
# -----------------------------------------------------------------------------
# Name          :internal.R
# Description   :Create internal `mock` and `example` dataset.
# Author        :Merlin Unterfinger <info@munterfinger.ch>
# Date          :2023-07-18
# Version       :0.2.0
# Usage         :export HERE_API_KEY="<KEY>" && ./data-raw/internal.R
# Notes         :Export API key before executing: export HERE_API_KEY=<KEY>
#                and unset after recreation of data: unset HERE_API_KEY.
# R             :4.3.1
# =============================================================================

library(sf)
library(hereR)
set_verbose(TRUE)

## URLs
url_geocode <-
  geocode(address = poi$city, url_only = TRUE)
url_autosuggest <-
  autosuggest(address = poi$city, results = 3, url_only = TRUE)
url_reverse_geocode <-
  reverse_geocode(poi = poi, results = 3, url_only = TRUE)
url_route <-
  route(origin = poi[1:2, ], destination = poi[3:4, ], url_only = TRUE)
url_route_matrix <-
  route_matrix(origin = poi, url_only = TRUE)
url_intermodal_route <-
  intermodal_route(origin = poi[1:3, ], destination = poi[4:6, ], url_only = TRUE)
url_isoline <-
  isoline(poi = poi, url_only = TRUE)
url_weather_observation <-
  weather(poi = poi, product = "observation", url_only = TRUE)
url_weather_forecast_hourly <-
  weather(poi = poi, product = "forecastHourly", url_only = TRUE)
url_weather_forecast_astronomy <-
  weather(poi = poi, product = "forecastAstronomy", url_only = TRUE)
url_weather_alerts <-
  weather(poi = poi, product = "alerts", url_only = TRUE)
url_flow <-
  flow(aoi = aoi[1, ], url_only = TRUE)
url_incident <-
  incident(aoi = aoi[1, ], url_only = TRUE)
url_connection <-
  connection(origin = poi[3:4, ], destination = poi[5:6, ], results = 2, url_only = TRUE)
url_station <-
  station(poi = poi, url_only = TRUE)

## Get response mocks
mock <- list(
  geocode_response = hereR:::.async_request(url_geocode, 5),
  autosuggest_response = hereR:::.async_request(url_autosuggest, 5),
  reverse_geocode_response = hereR:::.async_request(url_reverse_geocode, 5),
  route_response = hereR:::.async_request(url_route, 10),
  route_matrix_response = hereR:::.async_request(url_route_matrix, 1),
  intermodal_route_response = hereR:::.async_request(url_intermodal_route, 1),
  isoline_response = hereR:::.async_request(url_isoline, 1),
  weather_observation_response = hereR:::.async_request(url_weather_observation, 2),
  weather_forecast_hourly_response = hereR:::.async_request(url_weather_forecast_hourly, 2),
  weather_forecast_astronomy_response = hereR:::.async_request(url_weather_forecast_astronomy, 2),
  weather_alerts_response = hereR:::.async_request(url_weather_alerts, 2),
  flow_response = hereR:::.async_request(url_flow, 10),
  incident_response = hereR:::.async_request(url_incident, 10),
  connection_response = hereR:::.async_request(url_connection, 10),
  station_response = hereR:::.async_request(url_station, 10)
)

## Get examples
example <- list(
  geocode = geocode(address = poi$city),
  autosuggest = autosuggest(address = poi$city, results = 3),
  reverse_geocode = reverse_geocode(poi = poi, results = 3),
  route = route(origin = poi[1:2, ], destination = poi[3:4, ]),
  route_matrix = route_matrix(origin = poi),
  intermodal_route = intermodal_route(origin = poi[1:3, ], destination = poi[4:6, ]),
  isoline = isoline(poi = poi),
  weather_observation = weather(poi = poi, product = "observation"),
  weather_forecast_hourly = weather(poi = poi, product = "forecastHourly"),
  weather_forecast_astronomy = weather(poi = poi, product = "forecastAstronomy"),
  weather_alerts = weather(poi = poi, product = "alerts"),
  flow = flow(aoi = aoi[1, ]),
  incident = incident(aoi = aoi[1, ]),
  connection_section = connection(origin = poi[3:4, ], destination = poi[5:6, ], results = 2, summary = FALSE),
  connection_summary = connection(origin = poi[3:4, ], destination = poi[5:6, ], results = 2, summary = TRUE),
  station = station(poi)
)

## Save as internal package data
usethis::use_data(mock, example, overwrite = TRUE, internal = TRUE)
