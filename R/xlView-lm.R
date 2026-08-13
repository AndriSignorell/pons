
#' @param conf.level confidence level for the coefficient intervals, or
#'   \code{NA} (default) to omit them
#' @param anova logical; if \code{TRUE}, the sequential analysis of variance
#'   table is appended
#' @param fitted logical; if \code{TRUE}, the model frame together with fitted
#'   values and residuals is appended
#'
#' @rdname xlView
#' @export
xlView.lm <- function(x,
                      sheet = NULL,
                      conf.level = NA,
                      anova = FALSE,
                      fitted = FALSE,
                      autofit = TRUE,
                      gap = 2L,
                      xl = NULL,
                      ...) {

  if (is.null(sheet)) {
    sheet <- deparse(substitute(x))[1L]
  }

  res <- list(
    Call = paste(deparse(x$call), collapse = " "),
    Coefficients = .lmCoefBlock(x, conf.level = conf.level),
    "Model fit" = .lmFitBlock(x)
  )

  if (anova) {
    res[["Analysis of variance"]] <- as.data.frame(stats::anova(x))
  }

  if (fitted) {

    mf <- stats::model.frame(x)

    res[["Data"]] <- data.frame(
      mf,
      .fitted = stats::fitted(x),
      .resid = stats::resid(x),
      check.names = FALSE,
      stringsAsFactors = FALSE
    )
  }

  xlView.list(
    res,
    sheet = sheet,
    rowNames = NA,
    autofit = autofit,
    gap = gap,
    titles = TRUE,
    xl = xl
  )
}




# ================================================================
# Internal helpers
# ================================================================


#' Coefficient table, optionally with confidence bounds
#'
#' @keywords internal
#' @noRd
.lmCoefBlock <- function(x, conf.level = NA) {

  cf <- stats::coef(summary(x))

  if (!is.na(conf.level)) {

    ci <- stats::confint(x, level = conf.level)

    # confint() drops aliased coefficients, so match by name
    ci <- ci[match(rownames(cf), rownames(ci)), , drop = FALSE]

    colnames(ci) <- c("lci", "uci")

    cf <- cbind(cf, ci)
  }

  cf
}




#' One-number summaries of the fit, as a named vector
#'
#' @keywords internal
#' @noRd
.lmFitBlock <- function(x) {

  s <- summary(x)

  z <- c(
    n = length(stats::residuals(x)),
    "df (model)" = x$rank - attr(stats::terms(x), "intercept"),
    "df (residual)" = x$df.residual,
    sigma = s$sigma,
    "R squared" = s$r.squared,
    "adj. R squared" = s$adj.r.squared
  )

  if (!is.null(s$fstatistic)) {

    f <- s$fstatistic

    z <- c(
      z,
      F = unname(f[1L]),
      df1 = unname(f[2L]),
      df2 = unname(f[3L]),
      "p value" = stats::pf(f[1L], f[2L], f[3L], lower.tail = FALSE)
    )
  }

  c(
    z,
    AIC = stats::AIC(x),
    BIC = stats::BIC(x)
  )
}
