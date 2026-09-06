# ============================================================
# SAIGA RRUI–NDVI PROJECT
# 08_wild_cluster_bootstrap.R
#
# Wild Cluster Bootstrap for baseline TWFE model
#
# NDVI_it = alpha_i + lambda_t + beta * RRUI_it + error_it
#
# District and year fixed effects are represented explicitly
# by factor dummies for compatibility with boottest().
# ============================================================


# ------------------------------------------------------------
# 1. Packages
# ------------------------------------------------------------

library(dplyr)
library(readr)
library(fixest)
library(fwildclusterboot)
library(dqrng)


# ------------------------------------------------------------
# 2. Reproducibility
# ------------------------------------------------------------

set.seed(12345)
dqrng::dqset.seed(12345)


# ------------------------------------------------------------
# 3. Read panel
# ------------------------------------------------------------

panel <- read_csv(
  "data/processed/Panel_RRUI_NDVI_MaySep.csv",
  show_col_types = FALSE
) %>%
  mutate(
    Year = as.integer(Year),
    ADM2_PCODE = as.character(ADM2_PCODE),
    RRUI = as.numeric(RRUI),
    NDVI = as.numeric(NDVI)
  )


# ------------------------------------------------------------
# 4. Validate sample
# ------------------------------------------------------------

stopifnot(
  nrow(panel) == 65,
  n_distinct(panel$ADM2_PCODE) == 5,
  n_distinct(panel$Year) == 13,
  !anyNA(panel$RRUI),
  !anyNA(panel$NDVI)
)

cat("\n===== SAMPLE =====\n")
cat("Observations:", nrow(panel), "\n")
cat("Clusters:", n_distinct(panel$ADM2_PCODE), "\n")


# ------------------------------------------------------------
# 5. Original absorbed-FE model
#    Used as reference
# ------------------------------------------------------------

m_reference <- feols(
  NDVI ~ RRUI | ADM2_PCODE + Year,
  data = panel
)

beta_reference <- unname(
  coef(m_reference)["RRUI"]
)

cat("\n===== REFERENCE TWFE =====\n")
cat("Beta RRUI:", beta_reference, "\n")


# ------------------------------------------------------------
# 6. Equivalent TWFE model using explicit FE dummies
#
# factor(ADM2_PCODE) = district FE
# factor(Year)       = year FE
#
# This representation is used for boottest compatibility.
# ------------------------------------------------------------

m_wcb <- feols(
  NDVI ~ RRUI + factor(ADM2_PCODE) + factor(Year),
  data = panel
)

beta_wcb_model <- unname(
  coef(m_wcb)["RRUI"]
)

cat("\n===== EXPLICIT-DUMMY TWFE =====\n")
cat("Beta RRUI:", beta_wcb_model, "\n")

cat(
  "Difference from reference:",
  beta_wcb_model - beta_reference,
  "\n"
)


# ------------------------------------------------------------
# 7. Verify mathematical equivalence
# ------------------------------------------------------------

stopifnot(
  abs(beta_wcb_model - beta_reference) < 1e-10
)

cat("\nTWFE coefficient equivalence confirmed.\n")


# ------------------------------------------------------------
# 8. Wild Cluster Bootstrap
#
# H0: beta_RRUI = 0
# Cluster: district
# B = 9999
# ------------------------------------------------------------

wcb <- boottest(
  m_wcb,
  clustid = "ADM2_PCODE",
  param = "RRUI",
  B = 9999,
  type = "rademacher",
  impose_null = TRUE
)


# ------------------------------------------------------------
# 9. Results
# ------------------------------------------------------------

cat("\n===== WILD CLUSTER BOOTSTRAP =====\n")

print(wcb)


# ------------------------------------------------------------
# 10. Object structure
#     Useful for reproducible extraction of p-value
# ------------------------------------------------------------

cat("\n===== WCB OBJECT NAMES =====\n")

print(names(wcb))


cat("\nWild Cluster Bootstrap completed successfully.\n")
wcb$p_val
wcb$t_stat
wcb$conf_int
set.seed(12345)
dqrng::dqset.seed(12345)

wcb_webb <- boottest(
  m_wcb,
  clustid = "ADM2_PCODE",
  param = "RRUI",
  B = 9999,
  type = "webb",
  impose_null = TRUE
)

cat("\n===== WCB WEBB =====\n")
print(wcb_webb)

cat("\nWebb p-value:", wcb_webb$p_val, "\n")
cat("Webb t-stat:", wcb_webb$t_stat, "\n")
cat("Webb 95% CI:\n")
print(wcb_webb$conf_int)