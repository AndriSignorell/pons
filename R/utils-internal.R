

# utils-internal


.packageName <- function() {
  getNamespaceName(environment(sys.function(0)))
}


# internal getOption wrapper for DescToolsX options
.getOptionLocal <- function(name, default = NULL) {
  getOption(gettextf("%s.%s", .packageName(), name), default)
}


#' @noRd
.setOptionLocal <- function(...) {
  opts <- list(...)
  stopifnot(length(opts) > 0)
  names(opts) <- gettextf("%s.%s", .packageName(), names(opts))
  options(opts)
}



