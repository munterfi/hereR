## Create internal `mock` and `example` dataset
library(sf)

## URLs
url_geocode <-
  geocode(addresses = poi$city, url_only = TRUE)
url_autocomplete <-
  autocomplete(addresses = poi$city, results = 3, url_only = TRUE)
url_route <-
  route(start = poi[1:2, ], destination = poi[3:4, ], url_only = TRUE)
url_route_matrix <-
  route_matrix(start = poi, url_only = TRUE)
url_isoline <-
  isoline(poi = poi, url_only = TRUE)
url_weather_observation <-
  weather(poi = poi, product = "observation", url_only = TRUE)
url_weather_forecast_hourly <-
  weather(poi = poi, product = "forecast_hourly", url_only = TRUE)
url_weather_forecast_astronomy <-
  weather(poi = poi, product = "forecast_astronomy", url_only = TRUE)
url_weather_alerts <-
  weather(poi = poi, product = "alerts", url_only = TRUE)
url_traffic_flow <-
  traffic(aoi = aoi[aoi$code == "LI", ], product = "flow", url_only = TRUE)
url_traffic_incidents <-
  traffic(aoi = aoi, product = "incidents", from_dt = Sys.time()-60*60*1.5, url_only = TRUE)

## Get response mocks
mock <- list(
  geocode_response = hereR:::.get_content(url_geocode),
  autocomplete_response = hereR:::.get_content(url_autocomplete),
  route_response = hereR:::.get_content(url_route),
  route_matrix_response = hereR:::.get_content(url_route_matrix),
  isoline_response = hereR:::.get_content(url_isoline),
  weather_observation_response = hereR:::.get_content(url_weather_observation),
  weather_forecast_hourly_response = hereR:::.get_content(url_weather_forecast_hourly),
  weather_forecast_astronomy_response = hereR:::.get_content(url_weather_forecast_astronomy),
  weather_alerts_response = hereR:::.get_content(url_weather_alerts),
  traffic_flow_response = hereR:::.get_content(url_traffic_flow),
  traffic_incidents_response = hereR:::.get_content(url_traffic_incidents)
)

## Get examples
example <- list(
  geocode = geocode(addresses = poi$city),
  autocomplete = autocomplete(addresses = poi$city, results = 3),
  route = route(start = poi[1:2, ], destination = poi[3:4, ]),
  route_matrix = route_matrix(start = poi),
  isoline = isoline(poi = poi),
  weather_observation = weather(poi = poi, product = "observation"),
  weather_forecast_hourly = weather(poi = poi, product = "forecast_hourly"),
  weather_forecast_astronomy = weather(poi = poi, product = "forecast_astronomy"),
  weather_alerts = weather(poi = poi, product = "alerts"),
  traffic_flow = traffic(aoi = aoi[aoi$code == "LI", ], product = "flow"),
  traffic_incidents = traffic(aoi = aoi, product = "incidents", from_dt = Sys.time()-60*60*1.5)
)

## Save as internal package data
usethis::use_data(mock, example, overwrite = TRUE, internal = TRUE)
