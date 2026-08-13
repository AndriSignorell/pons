
#' @param method the procedure for the coefficient intervals, either
#'   \code{"profile"} (profile likelihood, the default of \code{confint.glm})
#'   or \code{"wald"}
#' @param exponentiate logical; if \code{TRUE}, the estimates and their
#'   interval bounds are additionally reported on the exponentiated scale
#'   (odds ratios for a logit link, rate ratios for a log link)
#'
#' @rdname xlView
#' @export
xlView.glm <- function(x,
                       sheet = NULL,
                       conf.level = NA,
                       method = c("profile", "wald"),
                       exponentiate = FALSE,
                       anova = FALSE,
                       fitted = FALSE,
                       autofit = TRUE,
                       gap = 2L,
                       xl = NULL,
                       ...) {

  if (is.null(sheet)) {
    sheet <- deparse(substitute(x))[1L]
  }

  method <- match.arg(method)

  res <- list(
    Model = c(
      Call = paste(deparse(x$call), collapse = " "),
      Family = x$family$family,
      Link = x$family$link
    ),
    Coefficients = .glmCoefBlock(
      x,
      conf.level = conf.level,
      method = method,
      exponentiate = exponentiate
    ),
    "Model fit" = .glmFitBlock(x)
  )

  if (anova) {

    # deviance differences are chi squared only where the dispersion is fixed
    test <- if (.hasFixedDispersion(x)) "Chisq" else "F"

    res[[paste0("Analysis of deviance (", test, ")")]] <-
      as.data.frame(stats::anova(x, test = test))
  }

  if (fitted) {

    mf <- stats::model.frame(x)

    res[["Data"]] <- data.frame(
      mf,
      .fitted = stats::fitted(x),
      .eta = stats::predict(x, type = "link"),
      .residDeviance = stats::residuals(x, type = "deviance"),
      .residPearson = stats::residuals(x, type = "pearson"),
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


#' Coefficient table, optionally with intervals and on the exponentiated scale
#'
#' @keywords internal
#' @noRd
.glmCoefBlock <- function(x,
                          conf.level = NA,
                          method = "profile",
                          exponentiate = FALSE) {

  cf <- stats::coef(summary(x))

  if (!is.na(conf.level)) {

    ci <- switch(
      method,
      profile = suppressMessages(stats::confint(x, level = conf.level)),
      wald = stats::confint.default(x, level = conf.level)
    )

    # a single coefficient comes back as a plain vector
    if (is.null(dim(ci))) {
      ci <- matrix(ci, nrow = 1L,
                   dimnames = list(names(stats::coef(x)), NULL))
    }

    ci <- ci[match(rownames(cf), rownames(ci)), , drop = FALSE]

    colnames(ci) <- c("lci", "uci")

    cf <- cbind(cf, ci)
  }

  if (exponentiate) {

    cols <- intersect(c("Estimate", "lci", "uci"), colnames(cf))

    ex <- exp(cf[, cols, drop = FALSE])

    colnames(ex) <- paste0("exp(", cols, ")")

    cf <- cbind(cf, ex)
  }

  cf
}




#' One-number summaries of the fit, as a named vector
#'
#' @keywords internal
#' @noRd
.glmFitBlock <- function(x) {

  s <- summary(x)

  z <- c(
    n = length(stats::residuals(x)),
    "df (null)" = x$df.null,
    "df (residual)" = x$df.residual,
    "null deviance" = x$null.deviance,
    "residual deviance" = x$deviance,
    dispersion = s$dispersion
  )

  # overall likelihood ratio test, only with a fixed dispersion
  if (.hasFixedDispersion(x)) {

    lr <- x$null.deviance - x$deviance
    df <- x$df.null - x$df.residual

    if (df > 0L) {

      z <- c(
        z,
        "LR chisq" = lr,
        "LR df" = df,
        "p value" = stats::pchisq(lr, df, lower.tail = FALSE)
      )
    }
  }

  c(
    z,
    .glmPseudoR2(x),
    AIC = stats::AIC(x),
    BIC = stats::BIC(x)
  )
}




#' Pseudo R squared measures from the log likelihoods
#'
#' The null model is refitted, so this is computed from the log likelihoods and
#' not from the deviance ratio, which coincides with McFadden's measure only
#' where the saturated log likelihood vanishes.
#'
#' @keywords internal
#' @noRd
.glmPseudoR2 <- function(x) {

  tryCatch({

    l1 <- as.numeric(stats::logLik(x))

    l0 <- as.numeric(
      stats::logLik(
        stats::update(x, . ~ 1, data = stats::model.frame(x))
      )
    )

    n <- length(stats::residuals(x))

    coxSnell <- 1 - exp((2 / n) * (l0 - l1))

    c(
      "McFadden R2" = 1 - l1 / l0,
      "Cox-Snell R2" = coxSnell,
      "Nagelkerke R2" = coxSnell / (1 - exp((2 / n) * l0))
    )

  }, error = function(e) NULL)
}




#' Is the dispersion fixed by the family, rather than estimated?
#'
#' @keywords internal
#' @noRd
.hasFixedDispersion <- function(x) {
  x$family$family %in% c("binomial", "poisson")
}
