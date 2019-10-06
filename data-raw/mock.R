## Create `mock_` datasets

## Geocode
url_geocode <- geocode(addresses = example_addresses,
                       url_only = TRUE)
mock_geocode <- hereR:::.get_content(url_geocode)
usethis::use_data(mock_geocode)

## Route
url_route <- route(start = example_geocode[1:2, ],
                   destination = example_geocode[3:4, ],
                   url_only = TRUE)
mock_route <- hereR:::.get_content(url_route)
usethis::use_data(mock_route)

## Route matrix
url_route_matrix <- route_matrix(start = example_geocode,
                                 url_only = TRUE)
mock_route_matrix <- hereR:::.get_content(url_route_matrix)
usethis::use_data(mock_route_matrix)

## Isoline
url_isoline <- isoline(poi = example_geocode,
                       url_only = TRUE)
mock_isoline <- hereR:::.get_content(url_isoline)
usethis::use_data(mock_isoline)

## Weather observation
url_weather_observation <- weather(poi = example_geocode,
                                   product = "observation",
                                   url_only = TRUE)
mock_weather_observation <- hereR:::.get_content(url_weather_observation)
usethis::use_data(mock_weather_observation)
