# version 0.2.1

* Enhanced `traffic()`: Clarified that `from_dt` and `to_dt` have no effect on the traffic flow (`product = "flow"`). Traffic flow is always real-time. Detailed documentation of the variables in the return value.
* Improved coverage of `testthat`.
* Added an `"id"` column to the output of `geocode()` and removed the id ordered `row.names` in order to be consistent with other functions of the package. Using the `"id"` column the addresses to geocode can be joined to the coordinates after geocoding (see [#9](https://github.com/munterfinger/hereR/issues/9)).
* Added an `"id"` column also to `autocomplete()`, `reverse_geocode()`, `route()`, `isoline()`, `traffic()` and `weather()`. Using the `"id"` column the result can be joined to the input.
* Fixed the handling of failing requests in `.get_content()`. The `"id"` column is still in correct order, even if there are failing requests in a function call (see [#17](https://github.com/munterfinger/hereR/issues/17)).
* Added `rownames() <- NULL` to all functions before returning the result.
* Renamed the `"city"` column in the returned object of `weather()` to `"station"`, as it stands for the name of the nearest meteorological station.
* Test for empty geometries in the input POIs and AOIs and throw an error if some are found (see [#16](https://github.com/munterfinger/hereR/issues/16)).

# version 0.2.0

* Enhanced `geocode()`: In the case of empty responses the row names match the index of the geocoded addresses. Improved input checks. Option to use autocomplete by setting `autocomplete = TRUE`.
* **Geocoder API: Autocomplete** The new feature `autocomplete()` allows autocompleting addresses.
* **Geocoder API: Reverse geocode** The new feature `reverse_geocode()` implements reverse geocoding POIs in order to retrieve suggestions for addresses or landmarks.

# version 0.1.0

First release of the `hereR` package, an `sf`-based interface to the **HERE REST APIs**.
The packages binds to the following HERE APIs:

* **Geocoder API:** Get coordinates (lng, lat) from addresses.
* **Routing API:** Routing directions, isolines and travel distance or time matrices, optionally incorporating the current traffic situation.
* **Traffic API:** Real-time traffic flow and incident information.
* **Destination Weather API:** Weather forecasts, reports on current weather conditions, astronomical information and weather alerts at a specific location.

Locations and routes are returned as `sf` objects and tables as `data.table` objects.
