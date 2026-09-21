# ============================================================
# SAIGA RRUI-NDVI PROJECT
# 13_wcb_climate.R  (rewritten in v1.3.1)
#
# Model M2 (+ climate)
# Restricted wild cluster bootstrap, EXACT enumeration
# (Rademacher 2^5 = 32 draws; Webb 6^5 = 7,776 draws). Deterministic:
# no seeds, no Monte Carlo error. See helpers_inference.R for the tie rule.
# ============================================================

library(dplyr)
library(readr)
library(openxlsx)

source("R/helpers_inference.R")

panel <- read_panel("data/processed/Panel_RRUI_NDVI_MaySep_Climate_AprOct.csv")

stopifnot(
  nrow(panel) == 65,
  n_distinct(panel$ADM2_PCODE) == 5,
  n_distinct(panel$Year) == 13
)

wcb <- wcb_exact(panel, c("RRUI", "precip_mm", "temp_c"))

cat("\n===== Model M2 (+ climate): exact WCB =====\n")
print(wcb, digits = 5)

# Structural checks: constant weight vectors tie with the observed statistic
# (2 for Rademacher, 6 for Webb).
stopifnot(wcb$N_draws[1] == 32, wcb$N_draws[2] == 7776, wcb$N_ties == c(2, 6))

dir.create("results/tables", recursive = TRUE, showWarnings = FALSE)
write_csv(wcb, "results/tables/13_climate_WCB.csv")
write.xlsx(wcb, "results/tables/13_climate_WCB.xlsx", overwrite = TRUE)

# Exact WCB for every coefficient of the model (v1.3.1)
vars_all <- c("RRUI", "precip_mm", "temp_c")
wcb_all <- dplyr::bind_rows(lapply(vars_all, function(v) {
  cbind(Variable = v, wcb_exact(panel, vars_all, test_var = v))
}))
cat("\n===== exact WCB, all coefficients =====\n")
print(wcb_all, digits = 4)
write_csv(wcb_all, "results/tables/13_climate_WCB_all_coefficients.csv")

cat("\nSaved: results/tables/13_climate_WCB.csv\n")
