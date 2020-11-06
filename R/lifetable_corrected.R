#' Calculates a corrected life table from a mortAAR life table
#'
#' It is generally assumed that most skeletal populations lack the
#' youngest age group. Life tables resulting from such populations
#' will necessarily be misleading as they lead to believe that the
#' mortality of younger children was lower than it actually was and
#' that life expectancy was higher. For correcting these missing
#' individuals, \emph{Bocquet-Appel and Masset} (1977; see also
#' \emph{Herrmann et al. 1990}, 307) conceived of several
#' calculations based on regression analyses of modern comparable
#' mortality data. However, the applicability of these indices
#' to archaeological data is highly debated and does not necessarily
#' lead to reliable results. Therefore, the correction needs to be
#' weighted carefully and ideally only after the representativity of the
#' base data has been checked with function lt.representativity.\cr
#' Building on the same regression analyses, Bocquet-Appel and Masset
#' also supplied estimates for the mortality rate m (which in
#' archaeological case necessarily is the same as the natality
#' rate n because it has to be assumed that the population is
#' stationary). A value of 0.01, for example, means that 1 among
#' 100 individuals died per year. The intrinsic growth rate r is
#' computed based on the proportion of subadults and might be
#' interesting to compare with the growth rate based on fertility
#' indices (function lt.reproduction).
#'
#' For the parameters see the documentation of \code{\link{life.table}}.
#'
#' @param life_table an object of class mortaar_life_table.
#' @param agecor logical, optional.
#' @param agecorfac numeric vector, optional.
#' @param option_spline integer, optional.
#'
#' @return a list containing a data.frame with indices e0, 1q0 and 5q0 as
#' well as mortality rate m and growth rate r according to Bocquet-Appel
#' and Masset showing the computed exact value as well as ranges and an
#' object of class mortaar_life_table with the corrected values.
#' \itemize{
#'   \item \bold{e0}:   Corrected life expectancy.
#'   \item \bold{1q0}:   Mortality of age group 0--1.
#'   \item \bold{5q0}:   Mortality of age group 0--5.
#'   \item \bold{m}:   Mortality rate (= natality rate n).
#'   \item \bold{r}:   Intrinsic growth rate.
#'}
#'
#'
#' @references
#' \insertRef{masset_bocquet_1977}{mortAAR}
#'
#' \insertRef{herrmann_prahistorische_1990}{mortAAR}
#'
#'
#' @examples
#' # Calculate a corrected life table from real life dataset.
#' schleswig <- life.table(schleswig_ma[c("a", "Dx")])
#' lt.correction(schleswig)
#'
#'
#' @rdname lt.correction
#' @export
lt.correction <- function(life_table, agecor = TRUE, agecorfac = c(), option_spline = NULL) {
  UseMethod("lt.correction")
}

#' @rdname lt.correction
#' @export
lt.correction.default <- function(life_table, agecor = TRUE, agecorfac = c(), option_spline = NULL) {
  stop("x is not an object of class mortaar_life_table.")
}

#' @rdname lt.correction
#' @export
lt.correction.mortaar_life_table_list <- function(life_table, agecor = TRUE, agecorfac = c(), option_spline = NULL) {
  lapply(life_table, lt.correction)
}

#' @rdname lt.correction
#' @export
#'
lt.correction.mortaar_life_table <- function(life_table, agecor = TRUE, agecorfac = c(), option_spline = NULL) {

  indx <- lt.indices(life_table)

  # corrected life expectancy at birth after Bocquet-Appel and Masset
  e0 <- 78.721 * log10(sqrt(1 / indx$juvenile_i)) - 3.384
  e0_range_start <- round(e0 - 1.503, 3)
  e0_range_end <- round(e0 + 1.503, 3)

  # corrected mortality for age group 1q0 after Bocquet-Appel and Masset
  q1_0 <- 0.568 * sqrt((log10(200 * indx$juvenile_i))) - 0.438
  q1_0_range_start <- round(q1_0 - 0.016,3)
  q1_0_range_end <- round(q1_0 + 0.016,3)

  # corrected mortality for age group 5q0 after Bocquet-Appel and Masset
  q5_0 <- 1.154 * sqrt((log10(200 * indx$juvenile_i))) - 1.014
  q5_0_range_start <- round(q5_0 - 0.041,3)
  q5_0_range_end <- round(q5_0 + 0.041,3)

  # mortality rate according to Bocquet/Masset 1977
  mortality_rate <- 0.127 * indx$juvenile_i + 0.016
  mortality_rate_range_start <- round(mortality_rate - 0.002, 3)
  mortality_rate_range_end <- round(mortality_rate + 0.002, 3)

  # growth rate according to Bocquet/Masset 1977
  growth_rate <- (1.484 * (log10(200 * indx$juvenile_i * indx$senility_i))**0.03 - 1.485)
  growth_rate_range_start <- round(growth_rate - 0.006, 3)
  growth_rate_range_end <- round(growth_rate + 0.006, 3)

  # calculation of life table correction
  Dx_sum_corrected <- (life_table$Dx %>% sum - life_table$Dx[1]) / (1 - q5_0)
  Dx5_0_corrected <- q5_0 * Dx_sum_corrected

  if (5 == life_table$a[1]) {
    life_table$Dx[[1]] <- Dx5_0_corrected
  } else if ((4 == life_table$a[2]) & (1 == life_table$a[1])) {
    Dx1_0_corrected <- q1_0 * Dx_sum_corrected
    life_table$Dx[[1]] <- Dx1_0_corrected
    life_table$Dx[[2]] <- Dx5_0_corrected - Dx1_0_corrected
  } else {
    stop("Life table correction works only with one 5-year-age class or 1- and 4-year classes
         for the first 5 years. Please take a look at ?life.table to determine how your
         input data should look like for accomplishing this.")
  }
  life_table_prep_corrected <- data.frame(cbind(a = life_table$a, Dx = life_table$Dx))
  life_table_corr <- life.table(life_table_prep_corrected, agecor = agecor,
                                agecorfac = agecorfac, option_spline = option_spline)

  # putting together the indices data.frame
  row_e0 <- c(round(e0, 3), e0_range_start, e0_range_end)
  row_q1_0 <- c(round(q1_0, 3), q1_0_range_start, q1_0_range_end)
  row_q5_0 <- c(round(q5_0, 3), q5_0_range_start, q5_0_range_end)
  row_mortality_rate <- c(round(mortality_rate, 3), mortality_rate_range_start, mortality_rate_range_end)
  row_growth_rate <- c(round(growth_rate, 3), growth_rate_range_start, growth_rate_range_end)
  e0_q5_0 <- data.frame(rbind(row_e0, row_q1_0, row_q5_0, row_mortality_rate, row_growth_rate))
  colnames(e0_q5_0) <- c("value", "range_start", "range_end")
  rownames(e0_q5_0) <- c("e0", "1q0", "5q0", "m", "r")

  # returning the indices data.frame as well as the corrected life table
  return(list(indices = e0_q5_0, life_table_corr = life_table_corr))
  }