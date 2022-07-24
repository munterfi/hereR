# version 0.9.0

* Allow transport modes `"scooter"`, `"taxi"`, `"bus"`, `"privateBus"` in `route()` and `route_matrix()`.
* Request tolls for routes with transport modes `"car"`, `"truck"`, `"taxi"` and `"bus"` in `route()`. The new boolean parameter `vignettes` defines if vignettes should be in inlcuded in the total toll cost of routes (closes [#151](https://github.com/munterfi/hereR/issues/151)).
* Add `set_currency()` to allow changing the currency used in toll requests to a currency code compliant to ISO 4217. The default currency is the current system locale setting. If the monetary formatting category `"LC_MONETARY"` of the C locale is not set, `"USD"` is set as default.
* Set `aggregate = FALSE` as default in `isoline()` (closes [#153](https://github.com/munterfi/hereR/issues/153)).
* Bugfix: Reduced RPS from 5 to 4 in calls to the Weather API in `weather()`, due to `Status 429; Too Many Requests;`.
* Bugfix: Do not convert columns `"visibility"` and `"snowCover"` to numeric in `weather(..., product = "observation")`, as they contain non numeric character values (`NAs introduced by coercion`).

# version 0.8.2

* Setting the arrival time is now supported by the Routing API, therefore `route(..., arrival = TRUE)` works.
* Since `sapply` is not type safe, replace its use with `vapply(..., FUN.VALUE = type)`.
* Add endpoint URL (without parameters) of failing requests to the warning message and print error message of the response.
* RPS limit for weather and traffic endpoints.
* Changed workflow from git flow to trunc-based development. Removed develop branch. New features are merged directly into `master` and releases are tagged after CRAN has accepted the package submission, which triggers the documentation build.
* Bugfix: Fix time / traffic independent requests in `isoline(..., traffic=FALSE)` (closes [#147](https://github.com/munterfi/hereR/issues/147)).
* Bugfix: Explicitly cast linestring in function `.connection_summary` to avoid error in `CPL_geos_union` (@panhypersebastos).

# version 0.8.1

* Adjust URLs to GitHub account due to renaming munterfinger to @munterfi.
* Bugfix: Add `set_freemium` topic to index in pkgdown.

# version 0.8.0

* Rename the rate-limit-related variable `HERE_RPS` to `HERE_FREEMIUM`, and the function `hereR::set_rate_limit()` to `hereR::set_freemium()`. Use the `HERE_FREEMIUM` environment variable to determine a plan-specific size of sub-matrices in the `hereR::route_matrix()` function (@szaboildi, [#138](https://github.com/munterfi/hereR/pull/138)).
* Deprecate `hereR::set_rate_limit()` (closes [#137](https://github.com/munterfi/hereR/issues/137)).
* Add option to use qualified queries in `geocode()` (closes [#136](https://github.com/munterfi/hereR/issues/136)).

# version 0.7.1

* Add parameter to allow filtering transport modes in `connection()` (closes [#130](https://github.com/munterfi/hereR/issues/130)).
* Bugfix: Swapped the origin and destination IDs in `route_matrix()`. Removed query optimization because switching the IDs results in reversed route information (closes [#129](https://github.com/munterfi/hereR/issues/129)).
* Update outdated URLs in package documentation. 

# version 0.7.0

* Enable `optimize` parameter to chose from "balanced", "quality" and "performance" in `isoline()` (closes [#119](https://github.com/munterfi/hereR/issues/119)).
* Remove deprecated parameters in `route()`, `route_matrix()` and `isoline()`.
* Add specific user-agent to the requests: `hereR/<version> R/<version> (<platform>)`.
* Add option to deactivate rate limits `set_rate_limit(FALSE)`.
* Bugfix: Add rate limits in RPS (requests per seconds) to async requests to the APIs; move dependency for requests from **curl** to **crul** package (closes [#122](https://github.com/munterfi/hereR/issues/122)).
* Bugfix: `isoline()` now handles multipart polygons (MULTIPOLYGON) if received by the API (closes [#121](https://github.com/munterfi/hereR/issues/121)).
* Add area and feature avoidance in `route()` (closes [#117](https://github.com/munterfi/hereR/issues/117)).

# version 0.6.1

* Use **styler** package and use `tyler::tidyverse_style()`to format the package.
* All **lintr** issues are solved, except from line length issues (limit of 80 characters).
* Avoid drop of the `sfc` class of the geometry column when there is only one geometry/row in a `data.table` (closes [#111](https://github.com/munterfi/hereR/issues/111)).
* Return `queryScore` in `geocode()` results as `score` column (closes [#109](https://github.com/munterfi/hereR/issues/109)).
* Silence **sf** messages of `sf::st_union` call in `connection(..., summary = TRUE)`.
* Added section id to `route()`, `intermodal_route()` and `connection()`.

# version 0.6.0

* Update `route_matrix()` from **Routing API v7.2** (calculatematrix) to **Matrix Routing API v8** (see [#87](https://github.com/munterfi/hereR/issues/87)).
* Update `isoline()` from **Routing API v7.2** (calculateisoline) to **Isoline Routing API v8** (see [#87](https://github.com/munterfi/hereR/issues/87)).
* Update `route()` from  **Routing API v7.2** (calculateroute) to **Routing API v8**, which brings the elevation to the route geometries (closes [#87](https://github.com/munterfi/hereR/issues/87)). **Note:** Currently arrival time is not yet supported.
* Return ISO state and country code in `geocode()` with the updated API v7.2 as it did with the previous API v6 (closes [#98](https://github.com/munterfi/hereR/issues/98)).
* Deprecate parameters `mode` and `type` in `route()`, `route_matrix()` and `isoline()`, use `transport_mode` and `routing_mode` instead.
* Fix parsing of timezones in `connection()` and `intermodal_route()` (closes [#94](https://github.com/munterfi/hereR/issues/94)).
* Fix not conditional use of suggested packages in vignettes (closes [#101](https://github.com/munterfi/hereR/issues/101)).
* Fix issue with delimiter for POST requests by changing it from a space `" "` to a space pipe combination `" | "` (closes [#102](https://github.com/munterfi/hereR/issues/102)).
* Added contribution guidelines, code of conduct and issue templates.

# version 0.5.2

* Send timezone offset in requests to the HERE APIs to avoid conversion to local timezone (closes [#85](https://github.com/munterfi/hereR/issues/85)).
* Added option to return alternative results in `geocode()`. The alternative locations are ranked according to the order from the Geocoder API (closes [#83](https://github.com/munterfi/hereR/issues/83) and [#81](https://github.com/munterfi/hereR/issues/81)).

# version 0.5.1

* Fix of the request generation for the Geocoder API: Removal of the `&` in front of the `apiKey` argument (closes [#73](https://github.com/munterfi/hereR/issues/73) and [#74](https://github.com/munterfi/hereR/issues/74)).

# version 0.5.0

* Upgrade Geocoder API version used in `geocode()` from v6.2 to v7 (closes [#52](https://github.com/munterfi/hereR/issues/52)). **Note:** The argument `autocomplete` is defunct and the argument `addresses` is deprecated, use `address` instead.
* Change default geometry in the return value of `geocode()` to position coordinates (display position) and return access coordinates (navigation position) as additional column in well-known text format (closes [#53](https://github.com/munterfi/hereR/issues/53)).
* Consistent columns in the return value of `geocode()` and `reverse_geocode()` independent of the input address level (closes [#58](https://github.com/munterfi/hereR/issues/58)).
* Upgrade Geocoder API version used in `reverse_geocode()` from v6.2 to v7. **Note:** The argument `landmarks` is defunct.
* Replace Geocoder API Autocomplete v6.2 with Geocoder API Autosuggest v7. **Note:** The function `autocomplete()` is defunct, please use `autosuggest()`.
* Upgrade Public Transit API version used in `connection()` and `station()` from v3 to v8 (closes [#62](https://github.com/munterfi/hereR/issues/62)). **Note:** Now the geometries (LINESTRING) of the pedestrian sections are also included in the public transport routes returned by `connection()`.
* Sign in to CodeFactor.io and add badge to track code quality.
* Defunct `set_proxy()` and `unset_proxy()`. Use a global proxy configuration for R in `~/.Renviron` instead.

# version 0.4.1

* Change example and API mock data for `intermodal_route()` from Berlin to Switzerland, as the service is now also available there.
* Force **mapview** to use 'classical' leaflet/htmlwidgets rendering (which embeds data directly in the html) and not the file format 'flatgeobuf' in vignette building (see [#54](https://github.com/munterfi/hereR/issues/54)).
* Temporarily deactivate all maps in the vignettes to solve the issues on CRAN (closes [#54](https://github.com/munterfi/hereR/issues/54)). With the next release of **mapview** >= v2.9.1 on CRAN the maps will be reactivated.

# version 0.4.0

* Changed CI from Travis to GitHub actions.
* Added automated pkgdown page build after pull requests and commits on master.
* Extended test coverage on defunct function calls.
* Added `sf` argument to `geocode()` function. If `TRUE`, the default, an {sf} object is returned, if `FALSE` a data.frame with `lng` and `lat` columns. (@dpprdan, [#44](https://github.com/munterfi/hereR/pull/44))
* **Intermodal Routing API: Routes** The new feature `intermodal_route()` adds support for requesting intermodal routes between given pairs of locations.

# version 0.3.3

* Added `set_verbose()` function to define (for the current R session) if the **hereR** package should message information about the number of requests sent and data received (default = `FALSE`).
* Reactivate maps with multiple layers since the **mapview** issue [#271](https://github.com/r-spatial/mapview/issues/271) is fixed.
* **lwgeom** no longer exports `st_make_valid()`, but **sf** does. Therefore `lwgeom` is moved from the package dependencies to the suggestions (see [#38](https://github.com/munterfi/hereR/issues/38)).

# version 0.3.2

* Defunct the deprecated `traffic()` function, which has been replaced by the functions `flow()` and `incident()`.
* Recreated package test data, api mocks and examples with **sf** 0.9-0 (see [#36](https://github.com/munterfi/hereR/issues/36)).
* Increased the dependency on the **sf** package to version 0.9-0 due to a different CRS handling (for more information about the changes in **sf**, see [here](https://r-spatial.org/r/2020/03/17/wkt.html)). **Note: Older versions of the sf package are no longer supported.**
* Temporarily deactivated maps with multiple layers until the **mapview** issue [#271](https://github.com/r-spatial/mapview/issues/271) is fixed.

# version 0.3.1

* There are no more missing M:N route combinations in the the edge list returned by `route_matrix()` (see [#30](https://github.com/munterfi/hereR/issues/30)).
* All lengths of `origin` and `destination` are now accepted as input in `route_matrix()` (see [#31](https://github.com/munterfi/hereR/issues/31)).
* Added two new functions `flow()` and `incident()` to access traffic flow and incidents from the Traffic API. Deprecated the `traffic()` function.
* Reduced the dependent version of R from 3.5.0 to 3.3.0 as the package is still functional but runs on more systems.

# version 0.3.0

* HERE has updated the authentication process and changed from APP_ID and APP_CODE to a single API_KEY. Therefore `set_auth()` and `unset_auth()` are defunct and replaced by `set_key()` and `unset_key()` (see [#23](https://github.com/munterfi/hereR/issues/23)).<br>**NOTE:** `.Deprecated()` was skipped because the API endpoints have also changed. After updating to a version greater than 0.2.1 **the authentication must be adjusted**.
* Added a minimum jam factor filter to `traffic(..., product = "flow")`. Now it is possible to only retrieve flow information of severe congestion with a jam factor greater than `min_jam_factor`, which speeds up requests.
* **Public Transit API: Transit route** The new feature `connection()` implements requesting the most efficient and relevant transit connections between given pairs of locations.
* **Public Transit API: Find stations nearby** The new feature `station()` retrieves nearby public transit stations with corresponding line information.
* Package cosmetics: Renamed the `start` parameter to `origin` and unified the utilization of the `datetime` and `arrival` parameters in `route()`, `route_matrix()`, `isoline()` and `connection()`.
* Adjusted the handling of datetime objects in the requests: All `c("POSIXct", "POSIXt")` inputs for the requests (mostly `departure`) are converted to UTC using `.encode_datetime()` and the responses are parsed and returned in the input timezone (or if missing: `Sys.timezone()`) using `.parse_datetime()` (see [#28](https://github.com/munterfi/hereR/issues/28)).
* Added `@import sf` to the package documentation to ensure `sf` objects are handled correctly.
* Added `departure` and `arrival` datetime column to the return value of `route()`, `route_matrix()` and `isoline()`.
* Removed `data.table` object type from function return values. New: Pure `data.frame` or `sf, data.frame` because this integrates better with other packages (e.g. the `overline2()` function from the `stplanr` package).

# version 0.2.1

* Enhanced `traffic()`: Clarified that `from_dt` and `to_dt` have no effect on the traffic flow (`product = "flow"`). Traffic flow is always real-time. Detailed documentation of the variables in the return value.
* Improved coverage of `testthat`.
* Added an `id` column to the output of `geocode()` and removed the id ordered `row.names` in order to be consistent with other functions of the package. Using the `id` column the addresses to geocode can be joined to the coordinates after geocoding (see [#9](https://github.com/munterfi/hereR/issues/9)).
* Added an `id` column also to `autocomplete()`, `reverse_geocode()`, `route()`, `isoline()`, `traffic()` and `weather()`. Using the `id` column the result can be joined to the input.
* Fixed the handling of failing requests in `.get_content()`. The `id` column is still in correct order, even if there are failing requests in a function call (see [#17](https://github.com/munterfi/hereR/issues/17)).
* Added `rownames() <- NULL` to all functions before returning the result.
* Renamed the `city` column in the returned object of `weather()` to `station`, as it stands for the name of the nearest meteorological station.
* Test for empty geometries in the input POIs and AOIs and throw an error if some are found (see [#16](https://github.com/munterfi/hereR/issues/16)).

# version 0.2.0

* Enhanced `geocode()`: In the case of empty responses the row names match the index of the geocoded addresses. Improved input checks. Option to use autocomplete by setting `autocomplete = TRUE`.
* **Geocoder API: Autocomplete** The new feature `autocomplete()` allows autocompleting addresses.
* **Geocoder API: Reverse geocode** The new feature `reverse_geocode()` implements reverse geocoding POIs in order to retrieve suggestions for addresses or landmarks.

# version 0.1.0

First release of the **hereR** package, an **sf**-based interface to the **HERE REST APIs**.
The packages binds to the following HERE APIs:

* **Geocoder API:** Get coordinates (lng, lat) from addresses.
* **Routing API:** Routing directions, isolines and travel distance or time matrices, optionally incorporating the current traffic situation.
* **Traffic API:** Real-time traffic flow and incident information.
* **Destination Weather API:** Weather forecasts, reports on current weather conditions, astronomical information and weather alerts at a specific location.

Locations and routes are returned as `sf` objects and tables as `data.table` objects.
