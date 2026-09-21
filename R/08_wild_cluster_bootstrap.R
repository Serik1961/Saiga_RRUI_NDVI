# ============================================================
# SAIGA RRUI-NDVI PROJECT
# 08_wild_cluster_bootstrap.R  (rewritten in v1.3.1)
#
# Baseline model (M1)
# Restricted wild cluster bootstrap, EXACT enumeration
# (Rademacher 2^5 = 32 draws; Webb 6^5 = 7,776 draws). Deterministic:
# no seeds, no Monte Carlo error. See helpers_inference.R for the tie rule.
# ============================================================

library(dplyr)
library(readr)
library(openxlsx)

source("R/helpers_inference.R")

panel <- read_panel("data/processed/Panel_RRUI_NDVI_MaySep.csv")

stopifnot(
  nrow(panel) == 65,
  n_distinct(panel$ADM2_PCODE) == 5,
  n_distinct(panel$Year) == 13
)

wcb <- wcb_exact(panel, c("RRUI"))

cat("\n===== Baseline model (M1): exact WCB =====\n")
print(wcb, digits = 5)

# Structural checks: constant weight vectors tie with the observed statistic
# (2 for Rademacher, 6 for Webb).
stopifnot(wcb$N_draws[1] == 32, wcb$N_draws[2] == 7776, wcb$N_ties == c(2, 6))

dir.create("results/tables", recursive = TRUE, showWarnings = FALSE)
write_csv(wcb, "results/tables/08_baseline_WCB.csv")

cat("\nSaved: results/tables/08_baseline_WCB.csv\n")
