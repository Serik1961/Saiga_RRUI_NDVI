# ============================================================
# SAIGA RRUI–NDVI PROJECT
# 11_twfe_climate.R
#
# TWFE with climate controls
#
# NDVI_it = alpha_i + lambda_t
#         + beta1 * RRUI_it
#         + beta2 * precip_mm_it
#         + beta3 * temp_c_it
#         + error_it
#
# 2012–2024, 5 districts, N = 65
# ============================================================


# ------------------------------------------------------------
# 1. Packages
# ------------------------------------------------------------

library(dplyr)
library(readr)
library(fixest)
library(openxlsx)


# ------------------------------------------------------------
# 2. Read processed panel
# ------------------------------------------------------------

panel <- read_csv(
  "data/processed/Panel_RRUI_NDVI_Climate_AprOct.csv",
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
# 3. Validate sample
# ------------------------------------------------------------

stopifnot(
  nrow(panel) == 65,
  n_distinct(panel$ADM2_PCODE) == 5,
  n_distinct(panel$Year) == 13,
  !anyNA(panel$RRUI),
  !anyNA(panel$NDVI),
  !anyNA(panel$precip_mm),
  !anyNA(panel$temp_c)
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
    temp_c
  ) %>%
  cor(
    use = "complete.obs"
  )

cat("\n===== CORRELATIONS =====\n")
print(round(cor_matrix, 4))


# ------------------------------------------------------------
# 5. Baseline TWFE
# ------------------------------------------------------------

m_baseline <- feols(
  NDVI ~ RRUI | ADM2_PCODE + Year,
  data = panel,
  cluster = ~ ADM2_PCODE
)


# ------------------------------------------------------------
# 6. Climate-controlled TWFE
# ------------------------------------------------------------

m_climate <- feols(
  NDVI ~ RRUI + precip_mm + temp_c |
    ADM2_PCODE + Year,
  data = panel,
  cluster = ~ ADM2_PCODE
)


# ------------------------------------------------------------
# 7. Print models
# ------------------------------------------------------------

cat("\n===== BASELINE TWFE =====\n")
print(summary(m_baseline))

cat("\n===== CLIMATE-CONTROLLED TWFE =====\n")
print(summary(m_climate))


# ------------------------------------------------------------
# 8. Extract coefficient tables
# ------------------------------------------------------------

baseline_table <- as.data.frame(
  coeftable(m_baseline)
)

baseline_table$Variable <- rownames(baseline_table)
rownames(baseline_table) <- NULL

baseline_table <- baseline_table %>%
  select(
    Variable,
    everything()
  )


climate_table <- as.data.frame(
  coeftable(m_climate)
)

climate_table$Variable <- rownames(climate_table)
rownames(climate_table) <- NULL

climate_table <- climate_table %>%
  select(
    Variable,
    everything()
  )


# ------------------------------------------------------------
# 9. RRUI comparison
# ------------------------------------------------------------

baseline_beta <- unname(
  coef(m_baseline)["RRUI"]
)

baseline_se <- unname(
  se(m_baseline)["RRUI"]
)

baseline_p <- unname(
  pvalue(m_baseline)["RRUI"]
)


climate_beta <- unname(
  coef(m_climate)["RRUI"]
)

climate_se <- unname(
  se(m_climate)["RRUI"]
)

climate_p <- unname(
  pvalue(m_climate)["RRUI"]
)


rrui_comparison <- data.frame(
  Model = c(
    "Baseline TWFE",
    "TWFE + climate controls"
  ),
  Beta_RRUI = c(
    baseline_beta,
    climate_beta
  ),
  Clustered_SE = c(
    baseline_se,
    climate_se
  ),
  P_value = c(
    baseline_p,
    climate_p
  ),
  N = c(
    nobs(m_baseline),
    nobs(m_climate)
  )
)


cat("\n===== RRUI COMPARISON =====\n")
print(rrui_comparison)


# ------------------------------------------------------------
# 10. Model fit statistics
# ------------------------------------------------------------

model_fit <- data.frame(
  Model = c(
    "Baseline TWFE",
    "TWFE + climate controls"
  ),
  N = c(
    nobs(m_baseline),
    nobs(m_climate)
  ),
  Adjusted_R2 = c(
    fitstat(m_baseline, "ar2")$ar2,
    fitstat(m_climate, "ar2")$ar2
  ),
  Within_R2 = c(
    fitstat(m_baseline, "wr2")$wr2,
    fitstat(m_climate, "wr2")$wr2
  )
)


cat("\n===== MODEL FIT =====\n")
print(model_fit)


# ------------------------------------------------------------
# 11. Create results folders if needed
# ------------------------------------------------------------

dir.create(
  "results/tables",
  recursive = TRUE,
  showWarnings = FALSE
)

dir.create(
  "results/diagnostics",
  recursive = TRUE,
  showWarnings = FALSE
)


# ------------------------------------------------------------
# 12. Save CSV tables
# ------------------------------------------------------------

write_csv(
  baseline_table,
  "results/tables/11_baseline_twfe_clustered.csv"
)

write_csv(
  climate_table,
  "results/tables/11_climate_twfe_clustered.csv"
)

write_csv(
  rrui_comparison,
  "results/tables/11_rrui_comparison.csv"
)

write_csv(
  model_fit,
  "results/diagnostics/11_model_fit.csv"
)


# ------------------------------------------------------------
# 13. Save one Excel workbook
# ------------------------------------------------------------

wb <- createWorkbook()

addWorksheet(
  wb,
  "Baseline_TWFE"
)

writeData(
  wb,
  "Baseline_TWFE",
  baseline_table
)


addWorksheet(
  wb,
  "Climate_TWFE"
)

writeData(
  wb,
  "Climate_TWFE",
  climate_table
)


addWorksheet(
  wb,
  "RRUI_comparison"
)

writeData(
  wb,
  "RRUI_comparison",
  rrui_comparison
)


addWorksheet(
  wb,
  "Model_fit"
)

writeData(
  wb,
  "Model_fit",
  model_fit
)


addWorksheet(
  wb,
  "Correlations"
)

writeData(
  wb,
  "Correlations",
  cor_matrix,
  rowNames = TRUE
)


saveWorkbook(
  wb,
  "results/tables/11_TWFE_climate_results.xlsx",
  overwrite = TRUE
)


# ------------------------------------------------------------
# 14. Check saved files
# ------------------------------------------------------------

cat("\n===== RESULTS SAVED =====\n")

cat(
  "Baseline CSV:",
  file.exists(
    "results/tables/11_baseline_twfe_clustered.csv"
  ),
  "\n"
)

cat(
  "Climate CSV:",
  file.exists(
    "results/tables/11_climate_twfe_clustered.csv"
  ),
  "\n"
)

cat(
  "Comparison CSV:",
  file.exists(
    "results/tables/11_rrui_comparison.csv"
  ),
  "\n"
)

cat(
  "Excel workbook:",
  file.exists(
    "results/tables/11_TWFE_climate_results.xlsx"
  ),
  "\n"
)


cat(
  "\nClimate-controlled TWFE estimation completed successfully.\n"
)