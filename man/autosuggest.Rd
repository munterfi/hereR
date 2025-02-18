% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/autosuggest.R
\name{autosuggest}
\alias{autosuggest}
\title{HERE Geocoding & Search API: Autosuggest}
\usage{
autosuggest(address, results = 5, url_only = FALSE)
}
\arguments{
\item{address}{character, address text to propose suggestions.}

\item{results}{numeric, maximum number of suggestions (Valid range: 1 and 100).}

\item{url_only}{boolean, only return the generated URLs (\code{default = FALSE})?}
}
\value{
A \code{data.frame} object, containing the suggestions for the input addresses.
}
\description{
Completes addresses using the HERE 'Geocoder Autosuggest' API.
}
\examples{
# Provide an API Key for a HERE project
set_key("<YOUR API KEY>")

suggestions <- autosuggest(address = poi$city, url_only = TRUE)
}
\references{
\href{https://www.here.com/docs/bundle/geocoding-and-search-api-v7-api-reference/page/index.html}{HERE Geocoder API: Autosuggest}
}
