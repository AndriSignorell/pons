
#' Capture Output from Evaluated Expressions
#'
#' Evaluates one or more expressions and captures their printed output,
#' closely mimicking the behavior of the R console. Only visibly returned
#' results are printed.
#'
#' @param ... Expressions to be evaluated. Each expression is evaluated in the
#'   calling environment, and its visible result is printed.
#' @param file Optional destination for the output. If \code{NULL} (default),
#'   output is captured and returned as a character vector. If a character
#'   string, output is written to the specified file. If a connection, output
#'   is written to the connection.
#' @param append Logical; if \code{TRUE}, output is appended to \code{file}
#'   when a file path or connection is provided.
#' @param width Integer; line width used during evaluation (temporarily sets
#'   \code{options(width)}).
#'
#' @return
#' If \code{file = NULL}, a character vector containing the captured output.
#' Otherwise, the output is written to \code{file} and the function returns
#' \code{invisible(NULL)}.
#'
#' @details
#' This function evaluates each expression in \code{...} using
#' \code{\link{withVisible}}, ensuring that only visible results are printed,
#' similar to interactive R sessions. Output is captured via \code{\link{sink}}.
#'
#' Unlike \code{\link{capture.output}}, this function supports multiple
#' expressions and reproduces console-like evaluation semantics.
#'
#' @examples
#' # Capture output as character vector
#' \dontrun{
#' .captOut(1 + 1, sqrt(4))
#'
#' # Write output to file
#' .captOut(1:5, summary(1:5), file = "output.txt")
#'
#' # Use with expressions
#' .captOut({ x <- 1:3; x * 2 })
#' }
#'
#' @seealso \code{\link{capture.output}}, \code{\link{sink}}, \code{\link{withVisible}}
#'
#' 

#' @keywords internal
.captOut <- function(..., file = NULL, append = FALSE, width = 150) {
  
  old_opt <- options(width = width)
  on.exit(options(old_opt), add = TRUE)
  
  args <- as.list(substitute(list(...)))[-1L]
  pf <- parent.frame()
  
  closeit <- TRUE
  
  
  con <- if (is.null(file)) {
    rval <- character()
    textConnection("rval", "w", local = TRUE)
  } else if (is.character(file)) {
    file(file, if (append) "a" else "w")
  } else if (inherits(file, "connection")) {
    if (!isOpen(file)) {
      open(file, if (append) "a" else "w")
    } else {
      closeit <- FALSE
    }
    file
  } else {
    stop("'file' must be NULL, a character string or a connection")
  }
  
  sink(con)
  on.exit({
    sink()
    if (closeit) close(con)
  }, add = TRUE)
  
  evalVis <- function(expr) withVisible(eval(expr, pf))
  
  for (expr in args) {
    
    tmp <- if (is.expression(expr)) {
      lapply(expr, evalVis)
    } else {
      # calls, names and constants (a literal is its own, visible value)
      list(evalVis(expr))
    }
    
    for (item in tmp) {
      if (item$visible) {
        print(item$value)
      }
    }
  }
  
  if (is.null(file)) rval else invisible(NULL)
}

