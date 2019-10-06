## Create `example_` datasets

## Adresses
example_addresses <- c("Bahnhofquai, Zürich, Schweiz",
                       "Bellevue, Zürich, Schweiz",
                       "Hardstrasse 48, Zürich, Schweiz",
                       "Irchelpark, Zürich, Schweiz",
                       "Kreuzplatz, Zürich, Schweiz",
                       "Schweighofstrasse 190, Zürich, Schweiz",
                       "Vulkanplatz, Zürich, Schweiz")
usethis::use_data(example_addresses)

## Geocode
example_geocode <- geocode(addresses = example_addresses)
usethis::use_data(example_geocode)

## Route
example_route <- route(start = example_geocode[1:2, ],
                       destination = example_geocode[3:4, ])
usethis::use_data(example_route)

## Route matrix
example_route_matrix <- route_matrix(start = example_geocode)
usethis::use_data(example_route_matrix)

## Isoline
example_isoline <- isoline(poi = example_geocode)
usethis::use_data(example_isoline)

## Weather
example_weather_observation <- weather(poi = example_geocode)
usethis::use_data(example_weather_observation)
