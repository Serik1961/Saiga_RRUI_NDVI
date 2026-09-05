# ============================================================
# SAIGA RRUI–NDVI PROJECT
# 19_final_results_table.R
#
# Consolidated results table
# Baseline -> Climate -> Climate + Livestock
# Clustered SE + CR2 + WCB
# ============================================================

library(dplyr)
library(readr)
library(openxlsx)


# ------------------------------------------------------------
# 1. Final RRUI results
# ------------------------------------------------------------

results <- data.frame(
  
  Model = c(
    "Baseline",
    "Baseline",
    "Baseline",
    "Baseline",
    
    "Climate",
    "Climate",
    "Climate",
    "Climate",
    
    "Climate + livestock",
    "Climate + livestock",
    "Climate + livestock",
    "Climate + livestock"
  ),
  
  Inference = c(
    "Clustered",
    "CR2",
    "WCB Rademacher",
    "WCB Webb",
    
    "Clustered",
    "CR2",
    "WCB Rademacher",
    "WCB Webb",
    
    "Clustered",
    "CR2",
    "WCB Rademacher",
    "WCB Webb"
  ),
  
  Beta_RRUI = c(
    -0.01839590,
    -0.01839590,
    -0.01839590,
    -0.01839590,
    
    -0.01626098,
    -0.01626098,
    -0.01626098,
    -0.01626098,
    
    -0.01791425,
    -0.01791425,
    -0.01791425,
    -0.01791425
  ),
  
  SE = c(
    0.01110761,
    0.0101,
    NA,
    NA,
    
    0.008922566,
    0.00915,
    NA,
    NA,
    
    0.010618058,
    0.018852245,
    NA,
    NA
  ),
  
  P_value = c(
    0.1730322,
    0.258,
    0.1875,
    0.2042,
    
    0.1424702,
    0.326,
    0.0625,
    0.1083108,
    
    0.1668497,
    0.5162379,
    0.0625,
    0.1194119
  ),
  
  CI_lower = c(
    -0.04923556,
    NA,
    -0.08442475,
    -0.0984,
    
    NA,
    NA,
    -0.07638674,
    -0.07432589,
    
    NA,
    NA,
    -0.04805527,
    -0.05846618
  ),
  
  CI_upper = c(
    0.01244376,
    NA,
    0.01554846,
    0.0168,
    
    NA,
    NA,
    0.007041601,
    0.006831563,
    
    NA,
    NA,
    0.005300286,
    0.005885138
  ),
  
  N = 65,
  
  Clusters = 5
)


# ------------------------------------------------------------
# 2. Print
# ------------------------------------------------------------

cat("\n===== CONSOLIDATED RRUI RESULTS =====\n")

print(
  results,
  row.names = FALSE
)


# ------------------------------------------------------------
# 3. Compact article table
# ------------------------------------------------------------

article_table <- data.frame(
  
  Specification = c(
    "RRUI",
    "RRUI + climate",
    "RRUI + climate + livestock"
  ),
  
  Beta_RRUI = c(
    -0.01839590,
    -0.01626098,
    -0.01791425
  ),
  
  Clustered_SE = c(
    0.01110761,
    0.008922566,
    0.010618058
  ),
  
  Clustered_p = c(
    0.1730322,
    0.1424702,
    0.1668497
  ),
  
  CR2_p = c(
    0.258,
    0.326,
    0.5162379
  ),
  
  WCB_Rademacher_p = c(
    0.1875,
    0.0625,
    0.0625
  ),
  
  WCB_Webb_p = c(
    0.2042,
    0.1083108,
    0.1194119
  ),
  
  N = c(
    65,
    65,
    65
  ),
  
  Clusters = c(
    5,
    5,
    5
  )
)


cat("\n===== ARTICLE TABLE =====\n")

print(
  article_table,
  row.names = FALSE
)


# ------------------------------------------------------------
# 4. Final model coefficients
# ------------------------------------------------------------

final_coefficients <- data.frame(
  
  Variable = c(
    "RRUI",
    "Precipitation",
    "Temperature",
    "Livestock units"
  ),
  
  Estimate = c(
    -0.01791425,
    0.0006270414,
    -0.05585412,
    -0.00009970014
  ),
  
  Clustered_SE = c(
    0.010618058,
    0.0002528048,
    0.0101486915,
    0.0002564033
  ),
  
  Clustered_p = c(
    0.1668497,
    0.0681864,
    0.0053156,
    0.7172050
  ),
  
  CR2_SE = c(
    0.018852245,
    0.002231333,
    0.256391894,
    0.000855344
  ),
  
  CR2_p = c(
    0.5162379,
    0.8255973,
    0.8634479,
    0.9261280
  )
)


cat("\n===== FINAL MODEL COEFFICIENTS =====\n")

print(
  final_coefficients,
  row.names = FALSE
)


# ------------------------------------------------------------
# 5. Save CSV files
# ------------------------------------------------------------

write_csv(
  results,
  "results/tables/19_all_RRUI_inference_results.csv"
)

write_csv(
  article_table,
  "results/tables/19_article_RRUI_table.csv"
)

write_csv(
  final_coefficients,
  "results/tables/19_final_model_coefficients.csv"
)


# ------------------------------------------------------------
# 6. Save Excel workbook
# ------------------------------------------------------------

wb <- createWorkbook()


addWorksheet(
  wb,
  "RRUI_all_inference"
)

writeData(
  wb,
  "RRUI_all_inference",
  results
)


addWorksheet(
  wb,
  "Article_table"
)

writeData(
  wb,
  "Article_table",
  article_table
)


addWorksheet(
  wb,
  "Final_coefficients"
)

writeData(
  wb,
  "Final_coefficients",
  final_coefficients
)


saveWorkbook(
  wb,
  "results/tables/19_FINAL_RESULTS.xlsx",
  overwrite = TRUE
)


# ------------------------------------------------------------
# 7. Verify files
# ------------------------------------------------------------

cat("\n===== FILES SAVED =====\n")

cat(
  "All inference CSV:",
  file.exists(
    "results/tables/19_all_RRUI_inference_results.csv"
  ),
  "\n"
)

cat(
  "Article table CSV:",
  file.exists(
    "results/tables/19_article_RRUI_table.csv"
  ),
  "\n"
)

cat(
  "Final coefficients CSV:",
  file.exists(
    "results/tables/19_final_model_coefficients.csv"
  ),
  "\n"
)

cat(
  "Final Excel:",
  file.exists(
    "results/tables/19_FINAL_RESULTS.xlsx"
  ),
  "\n"
)

cat(
  "\nFinal results tables created successfully.\n"
)