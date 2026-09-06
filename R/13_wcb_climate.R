# ============================================================
# SAIGA RRUI–NDVI PROJECT
# 13_wcb_climate.R
#
# Wild Cluster Bootstrap
# Climate-controlled TWFE
#
# Rademacher + Webb weights
# ============================================================


# ------------------------------------------------------------
# 1. Packages
# ------------------------------------------------------------

library(dplyr)
library(readr)
library(fixest)
library(fwildclusterboot)
library(dqrng)
library(openxlsx)


# ------------------------------------------------------------
# 2. Reproducibility
# ------------------------------------------------------------

set.seed(12345)
dqrng::dqset.seed(12345)


# ------------------------------------------------------------
# 3. Read panel
# ------------------------------------------------------------

panel <- read_csv(
  "data/processed/Panel_RRUI_NDVI_MaySep_Climate_AprOct.csv",
  show_col_types = FALSE
) %>%
  mutate(
    Year = as.integer(Year),
    ADM2_PCODE = as.character(ADM2_PCODE),
    RRUI = as.numeric(RRUI),
    NDVI = as.numeric(NDVI),
    precip_mm = as.numeric(precip_mm),
    temp_c = as.numeric(temp_c)
  )


# ------------------------------------------------------------
# 4. Validate sample
# ------------------------------------------------------------

stopifnot(
  nrow(panel) == 65,
  n_distinct(panel$ADM2_PCODE) == 5,
  n_distinct(panel$Year) == 13
)

cat("\n===== SAMPLE =====\n")
cat("Observations:", nrow(panel), "\n")
cat("Clusters:", n_distinct(panel$ADM2_PCODE), "\n")


# ------------------------------------------------------------
# 5. Reference absorbed-FE model
# ------------------------------------------------------------

m_reference <- feols(
  NDVI ~ RRUI + precip_mm + temp_c |
    ADM2_PCODE + Year,
  data = panel
)

beta_reference <- unname(
  coef(m_reference)["RRUI"]
)


# ------------------------------------------------------------
# 6. Equivalent explicit-dummy model
#    for boottest compatibility
# ------------------------------------------------------------

m_wcb <- feols(
  NDVI ~
    RRUI +
    precip_mm +
    temp_c +
    factor(ADM2_PCODE) +
    factor(Year),
  data = panel
)

beta_dummy <- unname(
  coef(m_wcb)["RRUI"]
)


cat("\n===== MODEL EQUIVALENCE =====\n")

cat(
  "Reference beta:",
  beta_reference,
  "\n"
)

cat(
  "Explicit-dummy beta:",
  beta_dummy,
  "\n"
)

cat(
  "Difference:",
  beta_dummy - beta_reference,
  "\n"
)

stopifnot(
  abs(beta_dummy - beta_reference) < 1e-10
)

cat("Coefficient equivalence confirmed.\n")


# ------------------------------------------------------------
# 7. Rademacher WCB
# ------------------------------------------------------------

set.seed(12345)
dqrng::dqset.seed(12345)

wcb_rademacher <- boottest(
  m_wcb,
  clustid = "ADM2_PCODE",
  param = "RRUI",
  B = 9999,
  type = "rademacher",
  impose_null = TRUE
)


cat("\n===== WCB RADEMACHER =====\n")
print(wcb_rademacher)


# ------------------------------------------------------------
# 8. Webb WCB
# ------------------------------------------------------------

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


# ------------------------------------------------------------
# 9. Collect results
# ------------------------------------------------------------

wcb_results <- data.frame(
  Method = c(
    "WCB Rademacher",
    "WCB Webb"
  ),
  
  Beta_RRUI = c(
    beta_reference,
    beta_reference
  ),
  
  Test_statistic = c(
    wcb_rademacher$t_stat,
    wcb_webb$t_stat
  ),
  
  P_value = c(
    wcb_rademacher$p_val,
    wcb_webb$p_val
  ),
  
  CI_low = c(
    wcb_rademacher$conf_int[1],
    wcb_webb$conf_int[1]
  ),
  
  CI_high = c(
    wcb_rademacher$conf_int[2],
    wcb_webb$conf_int[2]
  )
)


cat("\n===== WCB SUMMARY =====\n")
print(wcb_results)


# ------------------------------------------------------------
# 10. Save results
# ------------------------------------------------------------

dir.create(
  "results/tables",
  recursive = TRUE,
  showWarnings = FALSE
)

write_csv(
  wcb_results,
  "results/tables/13_climate_WCB.csv"
)

write.xlsx(
  wcb_results,
  "results/tables/13_climate_WCB.xlsx",
  overwrite = TRUE
)


# ------------------------------------------------------------
# 11. Verify saved files
# ------------------------------------------------------------

cat("\n===== RESULTS SAVED =====\n")

cat(
  "CSV:",
  file.exists("results/tables/13_climate_WCB.csv"),
  "\n"
)

cat(
  "XLSX:",
  file.exists("results/tables/13_climate_WCB.xlsx"),
  "\n"
)

cat(
  "\nClimate Wild Cluster Bootstrap completed successfully.\n"
)