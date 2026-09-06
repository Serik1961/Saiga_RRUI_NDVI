# ============================================================
# SAIGA RRUI–NDVI PROJECT
# 07_cr2.R
#
# Small-sample cluster-robust inference:
# CR2 + Satterthwaite degrees of freedom
#
# Model:
# NDVI_it = alpha_i + lambda_t + beta * RRUI_it + error_it
#
# Clusters: ADM2 district (G = 5)
# ============================================================


# ------------------------------------------------------------
# 1. Packages
# ------------------------------------------------------------

library(dplyr)
library(readr)
library(fixest)
library(clubSandwich)


# ------------------------------------------------------------
# 2. Read analytical panel
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
# 3. Validate sample
# ------------------------------------------------------------

stopifnot(
  nrow(panel) == 65,
  dplyr::n_distinct(panel$ADM2_PCODE) == 5,
  dplyr::n_distinct(panel$Year) == 13,
  !anyNA(panel$RRUI),
  !anyNA(panel$NDVI)
)

cat("\n===== SAMPLE =====\n")

cat("Observations:", nrow(panel), "\n")
cat(
  "Clusters:",
  n_distinct(panel$ADM2_PCODE),
  "\n"
)


# ------------------------------------------------------------
# 4. Estimate TWFE
#
# We estimate the same coefficient as before.
# CR2 inference is calculated separately below.
# ------------------------------------------------------------

m_twfe <- feols(
  NDVI ~ RRUI | ADM2_PCODE + Year,
  data = panel
)


cat("\n===== TWFE COEFFICIENT =====\n")

cat(
  "Beta RRUI:",
  unname(coef(m_twfe)["RRUI"]),
  "\n"
)


# ------------------------------------------------------------
# 5. CR2 variance-covariance matrix
#
# Cluster = district
# type = CR2
# ------------------------------------------------------------

vcov_cr2 <- vcovCR(
  m_twfe,
  cluster = panel$ADM2_PCODE,
  type = "CR2"
)


# ------------------------------------------------------------
# 6. CR2 coefficient test
#
# Satterthwaite small-sample correction
# ------------------------------------------------------------

cr2_test <- coef_test(
  m_twfe,
  vcov = vcov_cr2,
  test = "Satterthwaite"
)


cat("\n===== CR2 RESULTS =====\n")

print(cr2_test)


# ------------------------------------------------------------
# 7. Extract RRUI row
# ------------------------------------------------------------

cr2_rrui <- cr2_test[
  rownames(cr2_test) == "RRUI",
  ,
  drop = FALSE
]


cat("\n===== RRUI CR2 =====\n")

print(cr2_rrui)


# ------------------------------------------------------------
# 8. Basic validation
# ------------------------------------------------------------

stopifnot(
  nrow(cr2_rrui) == 1
)

cat("\nCR2 estimation completed successfully.\n")