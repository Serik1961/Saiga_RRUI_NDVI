# ============================================================
# SAIGA RRUI-NDVI PROJECT
# helpers_inference.R   (new in v1.3.1)
#
# Small-sample inference for the TWFE models with G = 5 clusters.
#
#  * cr2_lsdv()   CR2 + Satterthwaite df, computed on the explicit-dummy
#                 (LSDV) representation of the TWFE model.
#                 clubSandwich::vcovCR() must NOT be applied to a fixest
#                 object with absorbed fixed effects: the absorbed FE are
#                 then ignored in the leverage adjustment, which gives
#                 Satterthwaite df of ~1.0 and inflated SEs (this was the
#                 behaviour of v1.3.0, scripts 07/12/17).
#
#  * wcb_exact()  Restricted wild cluster bootstrap (null imposed) by EXACT
#                 enumeration of all weight vectors: 2^5 = 32 (Rademacher)
#                 and 6^5 = 7,776 (Webb). No random numbers are used, so the
#                 p-values do not depend on seeds or RNG packages.
#                 Ties are counted: every constant weight vector (all-ones,
#                 all-minus-ones, and for Webb also the other four constant
#                 vectors) reproduces the observed |t| exactly, because the
#                 restricted-residual bootstrap statistic is scale-invariant.
#                 Hence p = #{|t*| >= |t|} / #draws, with a numerical
#                 tolerance of 1e-8. Expected ties: 2 (Rademacher), 6 (Webb). The strict-inequality p-value (ties not
#                 counted; the fwildclusterboot convention) is reported as
#                 P_value_strict for transparency only.
# ============================================================

twfe_formula <- function(regressors,
                         cluster_var = "ADM2_PCODE",
                         year_var = "Year") {
  stats::as.formula(
    paste0(
      "NDVI ~ ",
      paste(regressors, collapse = " + "),
      " + factor(", cluster_var, ") + factor(", year_var, ")"
    )
  )
}

pick_col <- function(df, candidates) {
  hit <- candidates[candidates %in% names(df)]
  if (length(hit) == 0) {
    stop("None of the columns found: ", paste(candidates, collapse = ", "))
  }
  df[[hit[1]]]
}

cr2_lsdv <- function(data, regressors, cluster_var = "ADM2_PCODE") {

  fit <- stats::lm(twfe_formula(regressors, cluster_var), data = data)

  V <- clubSandwich::vcovCR(
    fit,
    cluster = data[[cluster_var]],
    type = "CR2"
  )

  ct <- as.data.frame(
    clubSandwich::coef_test(fit, vcov = V, test = "Satterthwaite")
  )

  out <- data.frame(
    Variable = regressors,
    beta     = unname(stats::coef(fit)[regressors]),
    SE       = unname(sqrt(diag(V))[regressors]),
    stringsAsFactors = FALSE
  )

  idx <- match(regressors, rownames(stats::coef(summary(fit))))
  out$tstat   <- pick_col(ct, c("tstat", "t"))[idx]
  out$df_Satt <- pick_col(ct, c("df_Satt", "df"))[idx]
  out$p_Satt  <- pick_col(ct, c("p_Satt", "p_val"))[idx]

  rownames(out) <- NULL
  out
}

wcb_exact <- function(data,
                      regressors,
                      test_var = "RRUI",
                      cluster_var = "ADM2_PCODE",
                      tol = 1e-8) {

  X <- stats::model.matrix(twfe_formula(regressors, cluster_var), data = data)
  y <- data$NDVI
  N <- length(y)

  cl  <- factor(data[[cluster_var]])
  G   <- nlevels(cl)
  idx <- split(seq_len(N), cl)
  k   <- which(colnames(X) == test_var)
  stopifnot(length(k) == 1)

  # OLS operator: beta = P %*% y
  P <- solve(crossprod(X), t(X))

  # Restricted model (null imposed): drop the tested regressor
  Xr    <- X[, -k, drop = FALSE]
  fit_r <- drop(Xr %*% qr.solve(Xr, y))
  u     <- y - fit_r

  # Cluster-robust t statistic (CRV1-type G/(G-1) factor), vectorised over
  # bootstrap samples stored as columns of Ystar (N x B)
  tvec <- function(Ystar) {
    B <- P %*% Ystar
    E <- Ystar - X %*% B
    S <- vapply(
      idx,
      function(i) colSums(P[k, i] * E[i, , drop = FALSE]),
      numeric(ncol(Ystar))
    )
    S <- matrix(S, nrow = ncol(Ystar))
    V <- rowSums(S^2) * G / (G - 1)
    B[k, ] / sqrt(V)
  }

  t_obs  <- drop(tvec(matrix(y, ncol = 1)))
  beta   <- drop(P[k, ] %*% y)
  cl_int <- as.integer(cl)

  run <- function(values) {
    W <- as.matrix(expand.grid(rep(list(values), G)))       # B x G
    Wobs  <- t(W[, cl_int, drop = FALSE])                   # N x B
    Ystar <- fit_r + u * Wobs
    tb    <- tvec(Ystar)
    ties  <- sum(abs(abs(tb) - abs(t_obs)) < tol)
    list(
      p        = mean(abs(tb) >= abs(t_obs) - tol),
      p_strict = mean(abs(tb) >  abs(t_obs) + tol),
      n_draws  = length(tb),
      n_ties   = ties
    )
  }

  rad  <- run(c(-1, 1))
  webb <- run(c(-sqrt(1.5), -1, -sqrt(0.5), sqrt(0.5), 1, sqrt(1.5)))

  data.frame(
    Method         = c("Rademacher (exact, 2^G)", "Webb (exact, 6^G)"),
    Beta           = unname(beta),
    Test_statistic = unname(t_obs),
    P_value        = c(rad$p, webb$p),
    P_value_strict = c(rad$p_strict, webb$p_strict),
    N_draws        = c(rad$n_draws, webb$n_draws),
    N_ties         = c(rad$n_ties, webb$n_ties),
    stringsAsFactors = FALSE
  )
}

read_panel <- function(path) {
  readr::read_csv(path, show_col_types = FALSE) %>%
    dplyr::mutate(
      Year = as.integer(Year),
      ADM2_PCODE = as.character(ADM2_PCODE)
    )
}
