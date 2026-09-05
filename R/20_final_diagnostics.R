# ============================================================
# SAIGA RRUI–NDVI PROJECT
# 20_final_diagnostics.R
#
# Diagnostics for final TWFE specification
# ============================================================

library(dplyr)
library(readr)
library(fixest)
library(openxlsx)


# ------------------------------------------------------------
# 1. Read data
# ------------------------------------------------------------

panel <- read_csv(
  "data/processed/Panel_RRUI_NDVI_Climate_Livestock_AprOct.csv",
  show_col_types = FALSE
)


# ------------------------------------------------------------
# 2. Overall descriptive statistics
# ------------------------------------------------------------

vars <- c(
  "NDVI",
  "RRUI",
  "precip_mm",
  "temp_c",
  "Livestock_units"
)

descriptive <- data.frame(
  Variable = vars,
  Mean = sapply(panel[vars], mean),
  SD = sapply(panel[vars], sd),
  Min = sapply(panel[vars], min),
  Max = sapply(panel[vars], max)
)

cat("\n===== DESCRIPTIVE STATISTICS =====\n")
print(descriptive, row.names = FALSE)


# ------------------------------------------------------------
# 3. Within-district variation
# ------------------------------------------------------------

within_variation <- panel %>%
  group_by(ADM2_PCODE) %>%
  summarise(
    N = n(),
    
    RRUI_SD = sd(RRUI),
    
    Precip_SD = sd(precip_mm),
    
    Temp_SD = sd(temp_c),
    
    Livestock_SD = sd(Livestock_units),
    
    .groups = "drop"
  )

cat("\n===== WITHIN-DISTRICT VARIATION =====\n")
print(within_variation)


# ------------------------------------------------------------
# 4. Livestock range by district
# ------------------------------------------------------------

livestock_range <- panel %>%
  group_by(
    ADM2_PCODE,
    ADM2_EN
  ) %>%
  summarise(
    Min = min(Livestock_units),
    Mean = mean(Livestock_units),
    Max = max(Livestock_units),
    SD = sd(Livestock_units),
    .groups = "drop"
  )

cat("\n===== LIVESTOCK BY DISTRICT =====\n")
print(livestock_range)


# ------------------------------------------------------------
# 5. Two-way demean variables
# ------------------------------------------------------------

tw_demean <- function(x, district, year) {
  
  x -
    ave(x, district, FUN = mean) -
    ave(x, year, FUN = mean) +
    mean(x)
}


panel_within <- panel %>%
  mutate(
    RRUI_within =
      tw_demean(
        RRUI,
        ADM2_PCODE,
        Year
      ),
    
    precip_within =
      tw_demean(
        precip_mm,
        ADM2_PCODE,
        Year
      ),
    
    temp_within =
      tw_demean(
        temp_c,
        ADM2_PCODE,
        Year
      ),
    
    livestock_within =
      tw_demean(
        Livestock_units,
        ADM2_PCODE,
        Year
      )
  )


# ------------------------------------------------------------
# 6. Correlations after removing district and year FE
# ------------------------------------------------------------

within_cor <- panel_within %>%
  select(
    RRUI_within,
    precip_within,
    temp_within,
    livestock_within
  ) %>%
  cor()


cat("\n===== TWO-WAY WITHIN CORRELATIONS =====\n")
print(round(within_cor, 4))


# ------------------------------------------------------------
# 7. Final model
# ------------------------------------------------------------

m_final <- feols(
  NDVI ~
    RRUI +
    precip_mm +
    temp_c +
    Livestock_units |
    ADM2_PCODE + Year,
  data = panel
)


# ------------------------------------------------------------
# 8. Collinearity diagnostic
# ------------------------------------------------------------

cat("\n===== FIXEST COLLINEARITY CHECK =====\n")

collin_result <- collinearity(m_final)

print(collin_result)


# ------------------------------------------------------------
# 9. Save diagnostics
# ------------------------------------------------------------

dir.create(
  "results/diagnostics",
  recursive = TRUE,
  showWarnings = FALSE
)

write_csv(
  descriptive,
  "results/diagnostics/20_descriptive_statistics.csv"
)

write_csv(
  within_variation,
  "results/diagnostics/20_within_district_variation.csv"
)

write_csv(
  livestock_range,
  "results/diagnostics/20_livestock_by_district.csv"
)

write.csv(
  within_cor,
  "results/diagnostics/20_two_way_within_correlations.csv"
)


# ------------------------------------------------------------
# 10. Excel
# ------------------------------------------------------------

wb <- createWorkbook()

addWorksheet(wb, "Descriptive")
writeData(
  wb,
  "Descriptive",
  descriptive
)

addWorksheet(wb, "Within_variation")
writeData(
  wb,
  "Within_variation",
  within_variation
)

addWorksheet(wb, "Livestock")
writeData(
  wb,
  "Livestock",
  livestock_range
)

addWorksheet(wb, "Within_correlations")
writeData(
  wb,
  "Within_correlations",
  within_cor,
  rowNames = TRUE
)

saveWorkbook(
  wb,
  "results/diagnostics/20_FINAL_DIAGNOSTICS.xlsx",
  overwrite = TRUE
)


# ------------------------------------------------------------
# 11. Verify
# ------------------------------------------------------------

cat("\n===== DIAGNOSTICS SAVED =====\n")

cat(
  "Excel:",
  file.exists(
    "results/diagnostics/20_FINAL_DIAGNOSTICS.xlsx"
  ),
  "\n"
)

cat(
  "\nFinal diagnostics completed successfully.\n"
)
renv::snapshot()
.libPaths()
c(
  clubSandwich     = requireNamespace("clubSandwich", quietly = TRUE),
  dplyr            = requireNamespace("dplyr", quietly = TRUE),
  fixest           = requireNamespace("fixest", quietly = TRUE),
  fwildclusterboot = requireNamespace("fwildclusterboot", quietly = TRUE),
  openxlsx         = requireNamespace("openxlsx", quietly = TRUE),
  readr            = requireNamespace("readr", quietly = TRUE),
  readxl           = requireNamespace("readxl", quietly = TRUE),
  sf               = requireNamespace("sf", quietly = TRUE),
  tidyr            = requireNamespace("tidyr", quietly = TRUE)
)
c(
  clubSandwich     = requireNamespace("clubSandwich", quietly = TRUE),
  dplyr            = requireNamespace("dplyr", quietly = TRUE),
  fixest           = requireNamespace("fixest", quietly = TRUE),
  fwildclusterboot = requireNamespace("fwildclusterboot", quietly = TRUE),
  openxlsx         = requireNamespace("openxlsx", quietly = TRUE),
  readr            = requireNamespace("readr", quietly = TRUE),
  readxl           = requireNamespace("readxl", quietly = TRUE),
  sf               = requireNamespace("sf", quietly = TRUE),
  tidyr            = requireNamespace("tidyr", quietly = TRUE)
)
renv::snapshot()
renv::status()
