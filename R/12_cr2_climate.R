# ============================================================
# SAIGA RRUI-NDVI PROJECT
# 12_cr2_climate.R  (rewritten in v1.3.1)
#
# Model M2: + precipitation and temperature (April-October)
# CR2 + Satterthwaite degrees of freedom, computed on the explicit-dummy
# (LSDV) representation of the TWFE model (see helpers_inference.R).
# Clusters: ADM2 district (G = 5)
# ============================================================

library(dplyr)
library(readr)
library(clubSandwich)
library(openxlsx)

source("R/helpers_inference.R")

panel <- read_panel("data/processed/Panel_RRUI_NDVI_MaySep_Climate_AprOct.csv")

stopifnot(
  nrow(panel) == 65,
  n_distinct(panel$ADM2_PCODE) == 5,
  n_distinct(panel$Year) == 13
)

regressors <- c("RRUI", "precip_mm", "temp_c")

cr2 <- cr2_lsdv(panel, regressors)

cat("\n===== Model M2: + precipitation and temperature (April-October): CR2 (LSDV) =====\n")
print(cr2, digits = 5)

# Sanity check: with G = 5 clusters and two-way FE the Satterthwaite df must
# be small but clearly above 1; df ~ 1.000 signals the absorbed-FE error.
stopifnot(all(cr2$df_Satt > 1.05))

dir.create("results/tables", recursive = TRUE, showWarnings = FALSE)
write_csv(cr2, "results/tables/12_climate_CR2.csv")
write.xlsx(cr2, "results/tables/12_climate_CR2.xlsx", overwrite = TRUE)
cat("\nSaved: results/tables/12_climate_CR2.csv\n")
