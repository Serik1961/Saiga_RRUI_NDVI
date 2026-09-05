# ============================================================
# SAIGA RRUI–NDVI PROJECT
# 17_cr2_final.R
#
# CR2 small-sample correction
# Final TWFE model
# ============================================================

library(dplyr)
library(readr)
library(fixest)
library(clubSandwich)
library(openxlsx)


# ------------------------------------------------------------
# 1. Read data
# ------------------------------------------------------------

panel <- read_csv(
  "data/processed/Panel_RRUI_NDVI_Climate_Livestock_AprOct.csv",
  show_col_types = FALSE
)


# ------------------------------------------------------------
# 2. Final TWFE model
# ------------------------------------------------------------

m_final <- feols(
  NDVI ~ RRUI +
    precip_mm +
    temp_c +
    Livestock_units |
    ADM2_PCODE + Year,
  data = panel
)


# ------------------------------------------------------------
# 3. CR2 variance-covariance matrix
# ------------------------------------------------------------

V_CR2 <- vcovCR(
  m_final,
  cluster = panel$ADM2_PCODE,
  type = "CR2"
)


# ------------------------------------------------------------
# 4. Satterthwaite tests
# ------------------------------------------------------------

cr2_results <- coef_test(
  m_final,
  vcov = V_CR2,
  test = "Satterthwaite"
)


cat("\n===== FINAL MODEL: CR2 =====\n")
print(cr2_results)


# ------------------------------------------------------------
# 5. Convert to data frame
# ------------------------------------------------------------

cr2_table <- as.data.frame(
  cr2_results
)

cr2_table$Variable <- rownames(cr2_table)
rownames(cr2_table) <- NULL

cr2_table <- cr2_table %>%
  select(
    Variable,
    everything()
  )


cat("\n===== CR2 TABLE =====\n")
print(cr2_table)


# ------------------------------------------------------------
# 6. RRUI result
# ------------------------------------------------------------

cat("\n===== RRUI CR2 =====\n")

print(
  cr2_table %>%
    filter(Variable == "RRUI")
)


# ------------------------------------------------------------
# 7. Save
# ------------------------------------------------------------

write_csv(
  cr2_table,
  "results/tables/17_final_CR2.csv"
)

write.xlsx(
  cr2_table,
  "results/tables/17_final_CR2.xlsx",
  overwrite = TRUE
)


# ------------------------------------------------------------
# 8. Verify
# ------------------------------------------------------------

cat("\n===== RESULTS SAVED =====\n")

cat(
  "CSV:",
  file.exists(
    "results/tables/17_final_CR2.csv"
  ),
  "\n"
)

cat(
  "XLSX:",
  file.exists(
    "results/tables/17_final_CR2.xlsx"
  ),
  "\n"
)

cat(
  "\nFinal CR2 estimation completed successfully.\n"
)