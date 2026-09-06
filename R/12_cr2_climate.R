# ============================================================
# SAIGA RRUI–NDVI PROJECT
# 12_cr2_climate.R
#
# CR2 + Satterthwaite inference
# for TWFE model with climate controls
# ============================================================


# ------------------------------------------------------------
# 1. Packages
# ------------------------------------------------------------

library(dplyr)
library(readr)
library(fixest)
library(clubSandwich)
library(openxlsx)


# ------------------------------------------------------------
# 2. Read panel
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

cat("\n===== SAMPLE =====\n")
cat("Observations:", nrow(panel), "\n")
cat("Clusters:", n_distinct(panel$ADM2_PCODE), "\n")


# ------------------------------------------------------------
# 4. Estimate climate-controlled TWFE
# ------------------------------------------------------------

m_climate <- feols(
  NDVI ~ RRUI + precip_mm + temp_c |
    ADM2_PCODE + Year,
  data = panel
)

cat("\n===== TWFE COEFFICIENTS =====\n")
print(coef(m_climate))


# ------------------------------------------------------------
# 5. CR2 variance-covariance matrix
# ------------------------------------------------------------

vcov_cr2 <- vcovCR(
  m_climate,
  cluster = panel$ADM2_PCODE,
  type = "CR2"
)


# ------------------------------------------------------------
# 6. Satterthwaite tests
# ------------------------------------------------------------

cr2_test <- coef_test(
  m_climate,
  vcov = vcov_cr2,
  test = "Satterthwaite"
)

cat("\n===== CR2 RESULTS =====\n")
print(cr2_test)


# ------------------------------------------------------------
# 7. RRUI result
# ------------------------------------------------------------

cr2_rrui <- cr2_test[
  rownames(cr2_test) == "RRUI",
  ,
  drop = FALSE
]

cat("\n===== RRUI CR2 =====\n")
print(cr2_rrui)

stopifnot(
  nrow(cr2_rrui) == 1
)


# ------------------------------------------------------------
# 8. Convert result to data frame for saving
# ------------------------------------------------------------

cr2_table <- as.data.frame(cr2_test)

cr2_table$Variable <- rownames(cr2_table)
rownames(cr2_table) <- NULL

cr2_table <- cr2_table %>%
  select(
    Variable,
    everything()
  )


# ------------------------------------------------------------
# 9. Save results
# ------------------------------------------------------------

dir.create(
  "results/tables",
  recursive = TRUE,
  showWarnings = FALSE
)

write_csv(
  cr2_table,
  "results/tables/12_climate_CR2.csv"
)

write.xlsx(
  cr2_table,
  "results/tables/12_climate_CR2.xlsx",
  overwrite = TRUE
)


# ------------------------------------------------------------
# 10. Verify files
# ------------------------------------------------------------

cat("\n===== RESULTS SAVED =====\n")

cat(
  "CSV:",
  file.exists("results/tables/12_climate_CR2.csv"),
  "\n"
)

cat(
  "XLSX:",
  file.exists("results/tables/12_climate_CR2.xlsx"),
  "\n"
)

cat("\nClimate CR2 estimation completed successfully.\n")