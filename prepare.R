

Rcpp::compileAttributes()
devtools::clean_dll()
devtools::document()
devtools::check()
devtools::install()
devtools::build_manual(pkg = "C:/temp/DescToolsX")
devtools::build_manual(pkg = "C:/temp/lumen")
devtools::build_manual(pkg = "C:/temp/pharos")
devtools::build_manual(pkg = "C:/temp/bedrock")


devtools::document()
devtools::load_all()


devtools::check()


pkgdown::build_home()
pkgdown::build_site()
usethis::use_pkgdown_github_pages()

pkgdown::build_reference_index()
pkgdown::build_favicons(overwrite = TRUE)




install.packages("remotes")
remotes::install_github("omegahat/RDCOMClient")

pkgdown::build_site()

pons:::dlgBookmark()

xlView(mtcars)
mtcars

dat <- data.frame(chars=c("some text", 
                          "with also äoöie", 
                          "c'est la çédile"), 
                  vals=runif(3))


dat

xlView(dat)


library(pons)
library(RDCOMClient)
getWrdHwnd()

debug(pons:::getWrdHwnd)

