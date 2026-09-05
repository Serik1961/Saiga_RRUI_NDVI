# ============================================================
# SAIGA RRUI–NDVI PROJECT
# 06_twfe_rrui_ndvi.R
#
# Baseline TWFE model
#
# NDVI_it = alpha_i + lambda_t + beta * RRUI_it + error_it
#
# Sample:
# 5 districts × 13 years (2012–2024) = 65 observations
#
# NOTE:
# 2020 is INCLUDED because GPS routes and NDVI are available.
# The absence of aerial population census data in 2020
# is irrelevant for this RRUI–NDVI specification.
# ============================================================


# ------------------------------------------------------------
# 1. Packages
# ------------------------------------------------------------

library(dplyr)
library(readr)
library(fixest)


# ------------------------------------------------------------
# 2. Read processed RRUI–NDVI panel
# ------------------------------------------------------------

panel <- read_csv(
  "data/processed/Panel_RRUI_NDVI_AprOct.csv",
  show_col_types = FALSE
) %>%
  mutate(
    Year = as.integer(Year),
    ADM2_PCODE = as.character(ADM2_PCODE),
    ADM2_EN = as.character(ADM2_EN),
    RRUI = as.numeric(RRUI),
    NDVI = as.numeric(NDVI)
  )


# ------------------------------------------------------------
# 3. Basic panel checks
# ------------------------------------------------------------

cat("\n===== ANALYTICAL SAMPLE =====\n")

cat(
  "Observations:",
  nrow(panel),
  "\n"
)

cat(
  "Districts:",
  n_distinct(panel$ADM2_PCODE),
  "\n"
)

cat(
  "Years:",
  n_distinct(panel$Year),
  "\n"
)

cat("\nYears included:\n")

print(
  sort(unique(panel$Year))
)


# ------------------------------------------------------------
# 4. Check observations per year
# ------------------------------------------------------------

observations_by_year <- panel %>%
  count(
    Year,
    name = "N_observations"
  )

cat("\n===== OBSERVATIONS BY YEAR =====\n")

print(observations_by_year)


# ------------------------------------------------------------
# 5. Check observations per district
# ------------------------------------------------------------

observations_by_district <- panel %>%
  count(
    ADM2_PCODE,
    ADM2_EN,
    name = "N_years"
  )

cat("\n===== OBSERVATIONS BY DISTRICT =====\n")

print(observations_by_district)


# ------------------------------------------------------------
# 6. Missing values
# ------------------------------------------------------------

cat("\n===== MISSING VALUES =====\n")

cat(
  "Missing RRUI:",
  sum(is.na(panel$RRUI)),
  "\n"
)

cat(
  "Missing NDVI:",
  sum(is.na(panel$NDVI)),
  "\n"
)


# ------------------------------------------------------------
# 7. Duplicate district-year observations
# ------------------------------------------------------------

duplicates <- panel %>%
  count(
    Year,
    ADM2_PCODE,
    name = "n"
  ) %>%
  filter(n > 1)

cat("\n===== DUPLICATES =====\n")

print(duplicates)


# ------------------------------------------------------------
# 8. Hard validation of analytical panel
# ------------------------------------------------------------

stopifnot(
  nrow(panel) == 65,
  n_distinct(panel$ADM2_PCODE) == 5,
  n_distinct(panel$Year) == 13,
  all(sort(unique(panel$Year)) == 2012:2024),
  all(observations_by_year$N_observations == 5),
  all(observations_by_district$N_years == 13),
  nrow(duplicates) == 0,
  !anyNA(panel$RRUI),
  !anyNA(panel$NDVI)
)

cat("\nAnalytical panel validation completed successfully.\n")


# ------------------------------------------------------------
# 9. Descriptive statistics
# ------------------------------------------------------------

descriptive <- panel %>%
  summarise(
    N = n(),
    
    RRUI_mean = mean(RRUI),
    RRUI_sd = sd(RRUI),
    RRUI_min = min(RRUI),
    RRUI_max = max(RRUI),
    
    NDVI_mean = mean(NDVI),
    NDVI_sd = sd(NDVI),
    NDVI_min = min(NDVI),
    NDVI_max = max(NDVI)
  )

cat("\n===== DESCRIPTIVE STATISTICS =====\n")

print(descriptive)


# ------------------------------------------------------------
# 10. Baseline TWFE model
#
# District fixed effects: ADM2_PCODE
# Year fixed effects: Year
#
# Standard errors clustered at district level
# ------------------------------------------------------------

m_twfe <- feols(
  NDVI ~ RRUI | ADM2_PCODE + Year,
  data = panel,
  cluster = ~ ADM2_PCODE
)


# ------------------------------------------------------------
# 11. Full TWFE output
# ------------------------------------------------------------

cat("\n===== TWFE MODEL =====\n")

print(
  summary(m_twfe)
)


# ------------------------------------------------------------
# 12. Extract RRUI coefficient
# ------------------------------------------------------------

rrui_beta <- unname(
  coef(m_twfe)["RRUI"]
)

rrui_se <- unname(
  se(m_twfe)["RRUI"]
)

rrui_p <- unname(
  pvalue(m_twfe)["RRUI"]
)


cat("\n===== RRUI COEFFICIENT =====\n")

cat(
  "Beta:",
  rrui_beta,
  "\n"
)

cat(
  "Clustered SE:",
  rrui_se,
  "\n"
)

cat(
  "p-value:",
  rrui_p,
  "\n"
)


# ------------------------------------------------------------
# 13. 95% confidence interval
# ------------------------------------------------------------

rrui_ci <- confint(
  m_twfe,
  parm = "RRUI",
  level = 0.95
)

cat("\n===== 95% CONFIDENCE INTERVAL =====\n")

print(rrui_ci)


# ------------------------------------------------------------
# 14. Model information
# ------------------------------------------------------------

cat("\n===== MODEL INFORMATION =====\n")

cat(
  "Number of observations:",
  nobs(m_twfe),
  "\n"
)

cat(
  "Number of district clusters:",
  n_distinct(panel$ADM2_PCODE),
  "\n"
)

cat(
  "Number of years:",
  n_distinct(panel$Year),
  "\n"
)


# ------------------------------------------------------------
# 15. Final model checks
# ------------------------------------------------------------

stopifnot(
  nobs(m_twfe) == 65,
  is.finite(rrui_beta),
  is.finite(rrui_se),
  is.finite(rrui_p)
)

cat("\nBaseline TWFE estimation completed successfully.\n")