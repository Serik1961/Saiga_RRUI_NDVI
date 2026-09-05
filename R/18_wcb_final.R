# ============================================================
# SAIGA RRUI–NDVI PROJECT
# 18_wcb_final.R
#
# Wild Cluster Bootstrap
# Final model:
# NDVI ~ RRUI + precipitation + temperature + livestock
#
# Rademacher + Webb
# ============================================================

library(dplyr)
library(readr)
library(fixest)
library(fwildclusterboot)
library(openxlsx)
library(dqrng)


# ------------------------------------------------------------
# 1. Read data
# ------------------------------------------------------------

panel <- read_csv(
  "data/processed/Panel_RRUI_NDVI_Climate_Livestock_AprOct.csv",
  show_col_types = FALSE
)


# ------------------------------------------------------------
# 2. Reference absorbed-FE model
# ------------------------------------------------------------

m_reference <- feols(
  NDVI ~ RRUI +
    precip_mm +
    temp_c +
    Livestock_units |
    ADM2_PCODE + Year,
  data = panel
)


# ------------------------------------------------------------
# 3. Explicit dummy model for WCB
# ------------------------------------------------------------

m_wcb <- feols(
  NDVI ~ RRUI +
    precip_mm +
    temp_c +
    Livestock_units +
    factor(ADM2_PCODE) +
    factor(Year),
  data = panel
)


# ------------------------------------------------------------
# 4. Verify coefficient equivalence
# ------------------------------------------------------------

beta_reference <- unname(
  coef(m_reference)["RRUI"]
)

beta_dummy <- unname(
  coef(m_wcb)["RRUI"]
)

beta_difference <-
  beta_reference - beta_dummy


cat("\n===== MODEL EQUIVALENCE =====\n")

cat(
  "Reference RRUI beta:",
  beta_reference,
  "\n"
)

cat(
  "Dummy-model RRUI beta:",
  beta_dummy,
  "\n"
)

cat(
  "Difference:",
  beta_difference,
  "\n"
)


stopifnot(
  abs(beta_difference) < 1e-10
)


# ------------------------------------------------------------
# 5. Reproducible seeds
# ------------------------------------------------------------

set.seed(12345)
dqrng::dqset.seed(12345)


# ------------------------------------------------------------
# 6. Rademacher WCB
# ------------------------------------------------------------

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
# 7. Reset seeds before Webb
# ------------------------------------------------------------

set.seed(12345)
dqrng::dqset.seed(12345)


# ------------------------------------------------------------
# 8. Webb WCB
# ------------------------------------------------------------

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
# 9. Extract results
# ------------------------------------------------------------

wcb_table <- data.frame(
  
  Method = c(
    "Rademacher",
    "Webb"
  ),
  
  Beta_RRUI = c(
    beta_reference,
    beta_reference
  ),
  
  P_value = c(
    wcb_rademacher$p_val,
    wcb_webb$p_val
  ),
  
  CI_lower = c(
    wcb_rademacher$conf_int[1],
    wcb_webb$conf_int[1]
  ),
  
  CI_upper = c(
    wcb_rademacher$conf_int[2],
    wcb_webb$conf_int[2]
  )
)


cat("\n===== WCB SUMMARY =====\n")
print(wcb_table)


# ------------------------------------------------------------
# 10. Save
# ------------------------------------------------------------

write_csv(
  wcb_table,
  "results/tables/18_final_WCB.csv"
)

write.xlsx(
  wcb_table,
  "results/tables/18_final_WCB.xlsx",
  overwrite = TRUE
)


# ------------------------------------------------------------
# 11. Verify files
# ------------------------------------------------------------

cat("\n===== RESULTS SAVED =====\n")

cat(
  "CSV:",
  file.exists(
    "results/tables/18_final_WCB.csv"
  ),
  "\n"
)

cat(
  "XLSX:",
  file.exists(
    "results/tables/18_final_WCB.xlsx"
  ),
  "\n"
)

cat(
  "\nFinal WCB estimation completed successfully.\n"
)