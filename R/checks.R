.check_addresses <- function(addresses) {
  if (!is.character(addresses)) {
    stop(sprintf(
      "'%s' must be a 'character' vector.",
      deparse(substitute(addresses))
    ))
  }
  if (any(is.na(addresses))) {
    stop(sprintf(
      "'%s' contains NAs.",
      deparse(substitute(addresses))
    ))
  }
  if ("" %in% gsub(" ", "", addresses)) {
    stop(sprintf(
      "'%s' contains empty strings.",
      deparse(substitute(addresses))
    ))
  }
}

.check_points <- function(points) {
  if (!"sf" %in% class(points)) {
    stop(sprintf(
      "'%s' must be an sf object.",
      deparse(substitute(points))
    ))
  }
  if (any(sf::st_is_empty(points))) {
    stop(sprintf(
      "'%s' has empty entries in the geometry column.",
      deparse(substitute(points))
    ))
  }
  if (any(sf::st_geometry_type(points) != "POINT")) {
    stop(sprintf(
      "'%s' must be an sf object with geometry type 'POINT'.",
      deparse(substitute(points))
    ))
  }
}

.check_polygon <- function(polygon) {
  if (!"sf" %in% class(polygon)) {
    stop(sprintf(
      "'%s' must be an sf object.",
      deparse(substitute(polygon))
    ))
  }
  if (any(sf::st_is_empty(polygon))) {
    stop(sprintf(
      "'%s' has empty entries in the geometry column.",
      deparse(substitute(polygon))
    ))
  }
  if (!"sf" %in% class(polygon) |
    any(!(
      sf::st_geometry_type(polygon) %in% c("POLYGON", "MULTIPOLYGON")
    ))) {
    stop(sprintf(
      "'%s' must be an sf object with geometry type 'POLYGON' or 'MULTIPOLYGON'.",
      deparse(substitute(polygon))
    ))
  }
}

.check_input_rows <- function(x, y) {
  if (nrow(x) != nrow(y))
    stop(
      sprintf(
        "'%s' must have the same number of rows as '%s'.",
        deparse(substitute(x)), deparse(substitute(y))
      )
    )
}

.check_bbox <- function(bbox) {
  if (any(c(bbox[3, ] - bbox[1, ], bbox[4, ] - bbox[2, ]) >= 10)) {
    stop("The polygons in 'aoi' must fit in a 10 x 10 degree bbox.")
  }
}

.check_boolean <- function(bool) {
  if (!bool %in% c(TRUE, FALSE)) {
    stop(sprintf("'%s' must be a 'boolean' value.", deparse(substitute(bool))))
  }
}

.check_datetime <- function(datetime) {
  if (!any(class(datetime) %in% c("POSIXct", "POSIXt")) &
    !is.null(datetime)) {
    stop(sprintf(
      "'%s' must be of type 'POSIXct', 'POSIXt'.",
      deparse(substitute(datetime))
    ))
  }
}

.check_transport_mode <- function(transport_mode, request) {
  modes <- c(
    "car", "truck", "pedestrian", "bicycle", "scooter"
  )
  if (request == "isoline") {
    modes <- modes[c(1, 2, 3)]
    if (!transport_mode %in% modes) {
      stop(.stop_print_transport_modes(mode = transport_mode, modes = modes, request = request))
    }
  } else if (request == "matrix") {
    modes <- modes[c(1, 2, 3, 4)]
    if (!transport_mode %in% modes) {
      stop(.stop_print_transport_modes(mode = transport_mode, modes = modes, request = request))
    }
  } else if (request == "route") {
    if (!transport_mode %in% modes) {
      stop(.stop_print_transport_modes(mode = transport_mode, modes = modes, request = request))
    }
  }
}

.stop_print_transport_modes <- function(mode, modes, request) {
  sprintf(
    "Transport mode '%s' not valid. For '%s' requests the mode must be in ('%s').",
    mode,
    request,
    paste(modes, collapse = "', '")
  )
}

.check_routing_mode <- function(routing_mode) {
  modes <- c("fast", "short")
  if (!routing_mode %in% modes) {
    stop(
        sprintf(
        "Routing mode '%s' not valid, must be in ('%s').",
        routing_mode,
        paste(modes, collapse = "', '")
      )
    )
  }
}

.check_range_type <- function(range_type) {
  range_types <- c("distance", "time", "consumption")
  if (!range_type %in% range_types) {
    stop(sprintf(
      "'range_type' must be '%s'.",
      paste(range_types, collapse = "', '")
    ))
  }
}

.check_key <- function(api_key) {
  if (!(is.character(api_key) & api_key != "")) {
    stop(
      "Please provide an 'API key' for a HERE project.
         Get your login here: https://developer.here.com/"
    )
  }
}

.check_weather_product <- function(product) {
  weather_product_types <-
    c(
      "observation",
      "forecast_hourly",
      "forecast_astronomy",
      "alerts"
    )
  if (!product %in% weather_product_types) {
    stop(sprintf(
      "'product' must be '%s'.",
      paste(weather_product_types, collapse = "', '")
    ))
  }
}

.check_min_jam_factor <- function(min_jam_factor) {
  if (!is.numeric(min_jam_factor)) {
    stop("'min_jam_factor' must be of type 'numeric'.")
  }
  if (min_jam_factor < 0 | min_jam_factor > 10) {
    stop("'min_jam_factor' must be in the valid range from 0 to 10.")
  }
}

.check_numeric_range <- function(num, lower, upper) {
  var_name <- deparse(substitute(num))
  if (!is.numeric(num)) {
    stop(sprintf("'%s' must be of type 'numeric'.", var_name))
  }
  if (num < lower | num > upper) {
    stop(sprintf(
      "'%s' must be in the valid range from %s to %s.",
      var_name,
      lower,
      upper
    ))
  }
}
