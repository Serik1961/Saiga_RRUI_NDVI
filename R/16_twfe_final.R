# ============================================================
# SAIGA RRUI–NDVI PROJECT
# 16_twfe_final.R
#
# Final TWFE model:
# NDVI ~ RRUI + precipitation + temperature + livestock
#
# District FE + Year FE
# Clustered SE by district
# ============================================================


# ------------------------------------------------------------
# 1. Packages
# ------------------------------------------------------------

library(dplyr)
library(readr)
library(fixest)
library(openxlsx)


# ------------------------------------------------------------
# 2. Read final panel
# ------------------------------------------------------------

panel <- read_csv(
  "data/processed/Panel_RRUI_NDVI_MaySep_Climate_AprOct_Livestock.csv",
  show_col_types = FALSE
) %>%
  mutate(
    Year = as.integer(Year),
    ADM2_PCODE = as.character(ADM2_PCODE),
    RRUI = as.numeric(RRUI),
    NDVI = as.numeric(NDVI),
    precip_mm = as.numeric(precip_mm),
    temp_c = as.numeric(temp_c),
    Livestock_units = as.numeric(Livestock_units)
  )


# ------------------------------------------------------------
# 3. Validate sample
# ------------------------------------------------------------

stopifnot(
  nrow(panel) == 65,
  n_distinct(panel$ADM2_PCODE) == 5,
  n_distinct(panel$Year) == 13,
  !anyNA(panel$RRUI),
  !anyNA(panel$NDVI),
  !anyNA(panel$precip_mm),
  !anyNA(panel$temp_c),
  !anyNA(panel$Livestock_units)
)

cat("\n===== ANALYTICAL SAMPLE =====\n")
cat("Observations:", nrow(panel), "\n")
cat("Districts:", n_distinct(panel$ADM2_PCODE), "\n")
cat("Years:", n_distinct(panel$Year), "\n")


# ------------------------------------------------------------
# 4. Correlations
# ------------------------------------------------------------

cor_matrix <- panel %>%
  select(
    RRUI,
    precip_mm,
    temp_c,
    Livestock_units
  ) %>%
  cor(use = "complete.obs")

cat("\n===== CORRELATIONS =====\n")
print(round(cor_matrix, 4))


# ------------------------------------------------------------
# 5. Baseline model
# ------------------------------------------------------------

m_baseline <- feols(
  NDVI ~ RRUI |
    ADM2_PCODE + Year,
  data = panel,
  cluster = ~ ADM2_PCODE
)


# ------------------------------------------------------------
# 6. Climate model
# ------------------------------------------------------------

m_climate <- feols(
  NDVI ~ RRUI + precip_mm + temp_c |
    ADM2_PCODE + Year,
  data = panel,
  cluster = ~ ADM2_PCODE
)


# ------------------------------------------------------------
# 7. Final model
# ------------------------------------------------------------

m_final <- feols(
  NDVI ~ RRUI +
    precip_mm +
    temp_c +
    Livestock_units |
    ADM2_PCODE + Year,
  data = panel,
  cluster = ~ ADM2_PCODE
)


# ------------------------------------------------------------
# 8. Print final model
# ------------------------------------------------------------

cat("\n===== FINAL TWFE =====\n")
print(summary(m_final))


# ------------------------------------------------------------
# 9. Compare RRUI coefficient across specifications
# ------------------------------------------------------------

rrui_comparison <- data.frame(
  
  Model = c(
    "Baseline",
    "Climate controls",
    "Climate + livestock"
  ),
  
  Beta_RRUI = c(
    unname(coef(m_baseline)["RRUI"]),
    unname(coef(m_climate)["RRUI"]),
    unname(coef(m_final)["RRUI"])
  ),
  
  Clustered_SE = c(
    unname(se(m_baseline)["RRUI"]),
    unname(se(m_climate)["RRUI"]),
    unname(se(m_final)["RRUI"])
  ),
  
  P_value = c(
    unname(pvalue(m_baseline)["RRUI"]),
    unname(pvalue(m_climate)["RRUI"]),
    unname(pvalue(m_final)["RRUI"])
  ),
  
  N = c(
    nobs(m_baseline),
    nobs(m_climate),
    nobs(m_final)
  )
)


cat("\n===== RRUI ACROSS SPECIFICATIONS =====\n")
print(rrui_comparison)


# ------------------------------------------------------------
# 10. Final coefficient table
# ------------------------------------------------------------

final_table <- as.data.frame(
  coeftable(m_final)
)

final_table$Variable <- rownames(final_table)
rownames(final_table) <- NULL

final_table <- final_table %>%
  select(
    Variable,
    everything()
  )


cat("\n===== FINAL COEFFICIENT TABLE =====\n")
print(final_table)


# ------------------------------------------------------------
# 11. Model fit
# ------------------------------------------------------------

model_fit <- data.frame(
  
  Model = c(
    "Baseline",
    "Climate controls",
    "Climate + livestock"
  ),
  
  Adjusted_R2 = c(
    fitstat(m_baseline, "ar2")$ar2,
    fitstat(m_climate, "ar2")$ar2,
    fitstat(m_final, "ar2")$ar2
  ),
  
  Within_R2 = c(
    fitstat(m_baseline, "wr2")$wr2,
    fitstat(m_climate, "wr2")$wr2,
    fitstat(m_final, "wr2")$wr2
  )
)


cat("\n===== MODEL FIT =====\n")
print(model_fit)


# ------------------------------------------------------------
# 12. Save results
# ------------------------------------------------------------

dir.create(
  "results/tables",
  recursive = TRUE,
  showWarnings = FALSE
)

write_csv(
  final_table,
  "results/tables/16_final_twfe_clustered.csv"
)

write_csv(
  rrui_comparison,
  "results/tables/16_rrui_specification_comparison.csv"
)

write_csv(
  model_fit,
  "results/tables/16_model_fit_comparison.csv"
)


# ------------------------------------------------------------
# 13. Excel workbook
# ------------------------------------------------------------

wb <- createWorkbook()

addWorksheet(wb, "Final_TWFE")
writeData(
  wb,
  "Final_TWFE",
  final_table
)

addWorksheet(wb, "RRUI_comparison")
writeData(
  wb,
  "RRUI_comparison",
  rrui_comparison
)

addWorksheet(wb, "Model_fit")
writeData(
  wb,
  "Model_fit",
  model_fit
)

addWorksheet(wb, "Correlations")
writeData(
  wb,
  "Correlations",
  cor_matrix,
  rowNames = TRUE
)

saveWorkbook(
  wb,
  "results/tables/16_final_TWFE_results.xlsx",
  overwrite = TRUE
)


# ------------------------------------------------------------
# 14. Verify files
# ------------------------------------------------------------

cat("\n===== RESULTS SAVED =====\n")

cat(
  "Final coefficients CSV:",
  file.exists(
    "results/tables/16_final_twfe_clustered.csv"
  ),
  "\n"
)

cat(
  "RRUI comparison CSV:",
  file.exists(
    "results/tables/16_rrui_specification_comparison.csv"
  ),
  "\n"
)

cat(
  "Excel workbook:",
  file.exists(
    "results/tables/16_final_TWFE_results.xlsx"
  ),
  "\n"
)

cat(
  "\nFinal TWFE estimation completed successfully.\n"
)