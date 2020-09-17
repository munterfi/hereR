# hereR <img src="man/figures/logo.svg" align="right" alt="" width="120" />
<!-- badges: start -->
[![CRAN status](https://www.r-pkg.org/badges/version/hereR)](https://CRAN.R-project.org/package=hereR)
[![CRAN checks](https://cranchecks.info/badges/worst/hereR)](https://cran.r-project.org/web/checks/check_results_hereR.html)
[![CRAN downloads](https://cranlogs.r-pkg.org/badges/last-month/hereR?color=brightgreen)](https://CRAN.R-project.org/package=hereR)
[![R build status](https://github.com/munterfinger/hereR/workflows/R-CMD-check/badge.svg)](https://github.com/munterfinger/hereR/actions)
[![Codecov test coverage](https://codecov.io/gh/munterfinger/hereR/branch/master/graph/badge.svg)](https://codecov.io/gh/munterfinger/hereR?branch=master)
[![CodeFactor](https://www.codefactor.io/repository/github/munterfinger/hereR/badge)](https://www.codefactor.io/repository/github/munterfinger/hereR)
<!-- badges: end -->

The **hereR** package provides an interface to the **HERE REST APIs** for R:
(1) geocode and autosuggest addresses or reverse geocode POIs using the **Geocoder API**;
(2) route directions, travel distance or time matrices and isolines using the **Routing API**;
(3) request real-time traffic flow and incident information from the **Traffic API**;
(4) find public transport connections and nearby stations using the **Public Transit API**;
(5) request intermodal routes using the **Intermodal Routing API**;
(6) get weather forecasts, reports on current weather conditions and astronomical information at a specific location from the **Destination Weather API**.

Locations, routes and isolines are returned as `sf` objects.

## Installation

You can install the released version of **hereR** from
[CRAN](https://CRAN.R-project.org/package=hereR/) with:

``` r
install.packages("hereR")
```

Install the development version from [GitHub](https://github.com/munterfinger/hereR/) with:

``` r
remotes::install_github("munterfinger/hereR")
```

## Usage
This package requires an API key for a HERE project. The key is set for the current R session and is used to authenticate in the requests to the APIs. A free login and project can be created on [developer.here.com](https://developer.here.com/). In order to obtain the API key navigate to a project of your choice in the developer portal, select '**REST: Generate APP**' and then '**Create API Key**'.

To set the API key, please use:
``` r
library(hereR)
set_key("<YOUR API KEY>")
```

Once valid application credentials are created and the key is set in the R session, the APIs can be addressed using the functions shown in the following examples. A more detailed description can be found in the documentation of the functions and the package vignettes.

**Geocoder API:** Autocomplete and geocode addresses or reverse geocode POIs.
``` r
geocode(c("Schweighofstrasse 190, Zurich, Switzerland", "Hardstrasse 48, Zurich, Switzerland"))

autosuggest(c("Schweighofstrasse", "Hardstrasse"))

reverse_geocode(poi)
```

**Routing API:** Construct a route, create a route matrix or request an isochrone around points.
``` r
route(poi[1:2, ], poi[3:4, ], mode = "car")

route_matrix(poi, mode = "car")

isoline(poi, rangetype = "time", mode = "car")
```

**Traffic API:** Get real-time traffic flow or incidents in a specific area.
``` r
flow(aoi[2, ])

incident(aoi, from = as.POSIXct("2018-01-01 00:00:00"))
```

**Public Transit API:** Request public transport connections between points or find stations nearby.
``` r
connection(poi[1:2, ], poi[3:4, ])

station(poi, radius = 500)
```

**Intermodal Routing API:** Get routes with various combinations of transport modes.
``` r
intermodal_route(poi[1:2, ], poi[3:4, ])
```

**Destination Weather API:** Request weather observations, forecasts, astronomical information or alerts at specific locations.
``` r
weather(poi, product = "observation")

weather(poi, product = "forecast_hourly")

weather(poi, product = "forecast_astronomy")

weather(poi, product = "alerts")
```

## References

* [Geocoder API](https://developer.here.com/documentation/geocoding-search-api/dev_guide/index.html)
* [Routing API](https://developer.here.com/documentation/routing/dev_guide/topics/introduction.html)
* [Traffic API](https://developer.here.com/documentation/traffic/dev_guide/topics/incident-data.html)
* [Public Transit API](https://developer.here.com/documentation/public-transit/dev_guide/index.html)
* [Intermodal Routing API](https://developer.here.com/documentation/intermodal-routing/dev_guide/index.html)
* [Destination Weather API](https://developer.here.com/documentation/destination-weather/dev_guide/topics/overview.html)
