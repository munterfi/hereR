# How to contribute?

This document contains guidelines for the collaboration in the **hereR** R package.

## Getting started

Ready to contribute? Here's how to set up **hereR** for local development.

1. Fork the repository to your GitHub account and clone the forked repository locally.
2. Install the dependencies (check the `DESCRIPTION` file).
3. Create a feature or bugfix branch as appropriate: `git checkout -b feature/<feature-description> master` or `git checkout -b bugfix/<bugfix-description> master`
4. Work locally on the feature, make sure to add or adjust:
   - entries in `NEWS.md`
   - function documentation (run `devtools::document()` before commit)
   - tests for the feature (run `export HERE_API_KEY="<YOUR-KEY>" && Rscript data-raw/internal.R && unset HERE_API_KEY` to recreate package example data and API mocks)
   - vignettes
5. Push changes to the new branch.
6. If CI tests are passing, create a pull request on GitHub of your `feature/...` or `bugfix/...` branch into the `master` branch of the original repository.

## Trunk-based Development Workflow

The [trunk-based development workflow](https://trunkbaseddevelopment.com) uses one branch `master` to record the history of the project. In addition to the mainline short-lived feature or bugfix branches are used to develop new features or fix bugs.

### Features

Each new feature should reside in its own short-lived branch. Branch off of a `feature/<feature-description>` branch from `master`. When a feature is complete, it gets merged back into `master` and the feature branch is deleted.

### Bugfix

Each bugfix should reside in its own short-lived branch. Branch off of a `bugfix/<bugfix-description>` branch from `master`. When the fix is complete, it gets merged back into `master` and the bugfix branch is deleted.

### Release

This packages uses [semantic versions](https://semver.org/). Once `master` has aquired enough features for a release, set the new version number in the `DESCRIPTION` and `NEWS.md` files and submit the package to CRAN. When CRAN has accepted the package submission, the `master` branch is tagged with the version number, which triggers the build of the documentation site using `pkgdown`.

## Documentation and coding style

### Naming convention

Use `snake_case` for variable, argument and function name definitions and avoid capital letters.
Dots (`.`) in function definitions are reserved for the functions and method dispatch in the S3 object system (e.g. `print.my_class`) or as prefix to hide functions (e.g. `.my_hidden_function`).

### Package documentation

This packages uses [roxygen2](https://cran.r-project.org/web/packages/roxygen2/vignettes/roxygen2.html) for the package documentation.

Example:

```r
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

```r
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
