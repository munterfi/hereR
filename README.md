
# hereR

<!-- badges: start -->
<!-- badges: end -->

Interface to the 'HERE REST APIs':

(1) geocode addresses based on the 'Geocoder API', returned as `sf` objects;
(2) routing directions, travel distance or time matrices based on the 'Routing API';
(3) real-time and predicted traffic information based on the 'Traffic API';
(4) weather forecasts, reports on current weather conditions and astronomical information at a specific location based on the 'Destination Weather API'.
  
## Installation

You can install the released version of hereR from [CRAN](https://cran.r-project.org/web/packages/hereR/) with:

``` r
install.packages("hereR")
```

... or install the development version from [GitHub](https://github.com/munterfinger/hereR/) with:
``` r
devtools::install_github("munterfinger/eRTG3D")
```

## Application credentials

In order to use the functionality of the `hereR` package, application credentials (APP ID and APP CODE) for a HERE project of type **'REST & XYZ HUB API/CLI'** have to be provided. These credentials will be set for the current R session and will be used to authenticate in the reqeusts to the **'HERE REST APIs'**.
To set the credentials, please use:
``` r
library(hereR)

set_auth(
  app_id = "<YOUR APP ID>",
  app_code = "<YOUR APP CODE>"
)
```
No login yet? Get your free login here: [klick](https://developer.here.com/)

## Examples

* **Geocode** addresses:<br>`locs <- geocode(addresses = c("Schweighofstrasse 190, Zürich, Schweiz", "Hardstrasse 48, Zürich, Schweiz"))`
* Construct a **route** between points:<br>`routes <- route(start = locs_start, destination = locs_dest)`
* Create a **route matrix** between points:<br>`route_matrix <- route_matrix(start = locs)`
* Request **weather** observations at specific locations:<br>`locs <- weather(poi = locs, product = "observation")`

