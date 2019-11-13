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
