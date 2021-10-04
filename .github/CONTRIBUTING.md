# How to contribute?

This document contains guidelines for the collaboration in the **hereR** R package.

## Getting started

Ready to contribute? Here's how to set up **hereR** for local development.

1. Fork the repository to your GitHub account and clone the forked repository locally.
2. Install the dependencies (check the `DESCRIPTION` file).
3. Create a feature or bugfix branch as appropriate: `git checkout -b feature/<feature-description> develop` or `git checkout -b bugfix/<bugfix-description> develop`
4. Work locally on the feature, make sure to add or adjust:
    - entries in `NEWS.md`
    - function documentation (run `devtools::document()` before commit)
    - tests for the feature (run `export HERE_API_KEY="<YOUR-KEY>" && Rscript data-raw/internal.R && unset HERE_API_KEY` to recreate package example data and API mocks)
    - vignettes
5. Push changes to the new branch.
6. If CI tests are passing, create a pull request on GitHub of your `feature/...` or `bugfix/...` branch into the `develop` branch of the original repository.

## Gitflow workflow

### Master and develop

The [gitflow workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow) uses two branches to
record the history of the project. The `master` branch stores the official release history, and the `develop` branch serves
as an integration branch for features. It's also convenient to tag all commits in the `master` branch with a version number.

### Features

Each new feature should reside in its own branch. But, instead of branching off of `master`, feature branches use
`develop` as their parent branch. When a feature is complete, it gets merged back into `develop`. Features should never interact directly with `master`.

### Release

This packages uses [semantic versions](https://semver.org/). Once `develop` has aquired enough features for a release,
fork a release (`release/v<major>.<minor>.<patch>)` branch off of `develop`. When CRAN has accepted the package submission,
the release branch gets merged into `master` and tagged with a version number. In addition, it should be merged back into `develop`,
which may have progressed since the release was initiated.

## Documentation and coding style

### Naming convention

Use `snake_case` for variable, argument and function name definitions and avoid capital letters.
Dots (`.`) in function definitions are reserved for the functions and method dispatch in the S3 object system (e.g. `print.my_class`) or as prefix to hide functions (e.g. `.my_hidden_function`).

### Package documentation

This packages uses [roxygen2](https://cran.r-project.org/web/packages/roxygen2/vignettes/roxygen2.html) for the package documentation. 

Example:

``` r
#' Add together two numbers
#'
#' @param x A number
#' @param y A number
#' @return The sum of \code{x} and \code{y}
#' @examples
#' add(1, 1)
#' add(10, 1)
add <- function(x, y) {
  x + y
}
```

### Script header template

Add a header to CLI scripts according to the following template:

``` r
#!/usr/bin/env Rscript
# -----------------------------------------------------------------------------
# Name          :example_script.R
# Description   :Short description of the scripts purpose.
# Author        :Name <your@email.ch>
# Date          :YYYY-MM-DD
# Version       :0.1.0
# Usage         :./example_script.R
# Notes         :Is there something important to consider when executing the
#                script?
# =============================================================================
```

## Credits

Add your GitHub username to the bugfix or feature entry in the `NEWS.md` to ensure credits are given correctly:

```
# version x.x.x.9000

* Added <feature description> (@<github_username>, [#1](https://github.com/munterfi/hereR/pull/1)).
* Bugfix: <description> (@<github_username>, closes [#2](https://github.com/munterfi/hereR/issues/2)).
```

## Code of conduct

Please note that this project is released with a
[Contributor Code of Conduct](CODE_OF_CONDUCT.md). By contributing to this
project you agree to abide by its terms.
