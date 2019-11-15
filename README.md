# hereR <img src="man/figures/logo.svg" align="right" alt="" width="120" />
<!-- badges: start -->
[![CRAN status](https://www.r-pkg.org/badges/version/hereR)](https://CRAN.R-project.org/package=hereR)
[![CRAN downloads](https://cranlogs.r-pkg.org/badges/last-month/hereR?color=brightgreen)](https://CRAN.R-project.org/package=hereR)
[![Travis build status](https://travis-ci.org/munterfinger/hereR.svg?branch=master)](https://travis-ci.org/munterfinger/hereR)
[![Codecov test coverage](https://codecov.io/gh/munterfinger/hereR/branch/master/graph/badge.svg)](https://codecov.io/gh/munterfinger/hereR?branch=master)
<!-- badges: end -->

R interface to the **HERE REST APIs**:
(1) geocode and autocomplete addresses or reverse geocode POIs using the **Geocoder API**;
(2) routing directions, travel distance or time matrices and isolines using the **Routing API**;
(3) real-time traffic flow and incident information from the **Traffic API**;
(4) weather forecasts, reports on current weather conditions and astronomical information at a specific location from the **Destination Weather API**.

Locations, routes and isolines are returned as `sf` objects and tables as `data.table` objects.

## Installation

You can install the released version of `hereR` from [CRAN](https://CRAN.R-project.org/package=hereR/) with:

``` r
install.packages("hereR")
```

... or install the development version from [GitHub](https://github.com/munterfinger/hereR/) with:

``` r
devtools::install_github("munterfinger/hereR")
```

## Application credentials

In order to use the functionality of the `hereR` package, application credentials (APP ID and APP CODE) for a HERE project of type **REST & XYZ HUB API/CLI** have to be provided. These credentials will be set for the current R session and will be used to authenticate in the reqeusts to the **HERE REST APIs**.
To set the credentials, please use:
``` r
library(hereR)

set_auth(
  app_id = "<YOUR APP ID>",
  app_code = "<YOUR APP CODE>"
)
```
No login yet? Get your free login here: [developer.here.com](https://developer.here.com/)

## Examples

* **Geocode** addresses:<br>`locs <- geocode(addresses = c("Schweighofstrasse 190, Zürich, Schweiz", "Hardstrasse 48, Zürich, Schweiz"))`<br><br>
* **Autocomplete** addresses:<br>`suggestions <- autocomplete(addresses = c("Schweighofstrasse", "Hardstrasse"))`<br><br>
* **Reverse geocode** POIs:<br>`addresses <- reverse_geocode(poi = locs)`<br><br>
* Construct a **route** between points:<br>`routes <- route(start = locs_start, destination = locs_dest, mode = "car")`<br><br>
* Create a **route matrix** between points:<br>`route_matrix <- route_matrix(start = locs, mode = "car")`<br><br>
* Request **weather observations** at specific locations:<br>`observations <- weather(poi = locs, product = "observation")`<br><br>
* Request **weather forecast** at specific locations:<br>`forecast <- weather(poi = locs, product = "forecast_hourly")`<br><br>
* Request **astronomical information** at specific locations:<br>`astronomy <- weather(poi = locs, product = "forecast_astronomy")`<br><br>
* Request **weather alerts** at specific locations:<br>`alerts <- weather(poi = locs, product = "alerts")`<br><br>
* Get real-time **traffic flow** in a specific area:<br>`flow <- traffic(aoi = area, product = "flow")`<br><br>
* Get **traffic incidents** in a specific area:<br>`incidents <- traffic(aoi = area, product = "incidents")`

