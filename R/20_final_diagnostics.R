# ============================================================
# SAIGA RRUI–NDVI PROJECT
# 20_final_diagnostics.R
#
# Final diagnostics for the analytical panel
#
# NDVI: May–September
# Climate: April–October
# ============================================================


# ------------------------------------------------------------
# 1. Packages
# ------------------------------------------------------------

required_packages <- c(
  "dplyr",
  "readr",
  "openxlsx"
)

missing_packages <- required_packages[
  !vapply(
    required_packages,
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
]

if (length(missing_packages) > 0) {
  stop(
    paste(
      "Missing packages:",
      paste(missing_packages, collapse = ", ")
    )
  )
}


# ------------------------------------------------------------
# 2. Input file
# ------------------------------------------------------------

panel_file <-
  "data/processed/Panel_RRUI_NDVI_MaySep_Climate_AprOct_Livestock.csv"

if (!file.exists(panel_file)) {
  stop(
    paste(
      "Final panel not found:",
      panel_file
    )
  )
}

panel <- readr::read_csv(
  panel_file,
  show_col_types = FALSE
)


# ------------------------------------------------------------
# 3. Required variables
# ------------------------------------------------------------

required_columns <- c(
  "Year",
  "ADM2_PCODE",
  "ADM2_EN",
  "RRUI",
  "NDVI",
  "precip_mm",
  "temp_c",
  "Livestock_units"
)

missing_columns <- setdiff(
  required_columns,
  names(panel)
)

if (length(missing_columns) > 0) {
  stop(
    paste(
      "Missing required columns:",
      paste(missing_columns, collapse = ", ")
    )
  )
}


# ------------------------------------------------------------
# 4. Panel structure
# ------------------------------------------------------------

cat("\n===== FINAL PANEL STRUCTURE =====\n")

cat("Observations:", nrow(panel), "\n")
cat(
  "Districts:",
  dplyr::n_distinct(panel$ADM2_PCODE),
  "\n"
)
cat(
  "Years:",
  dplyr::n_distinct(panel$Year),
  "\n"
)

cat(
  "Year range:",
  min(panel$Year),
  "-",
  max(panel$Year),
  "\n"
)


# ------------------------------------------------------------
# 5. Missing values
# ------------------------------------------------------------

cat("\n===== MISSING VALUES =====\n")

missing_summary <- data.frame(
  Variable = required_columns,
  Missing = vapply(
    panel[required_columns],
    function(x) sum(is.na(x)),
    numeric(1)
  )
)

print(
  missing_summary,
  row.names = FALSE
)

if (any(missing_summary$Missing > 0)) {
  stop(
    "Missing values detected in the final analytical panel."
  )
}


# ------------------------------------------------------------
# 6. Duplicate district-year cells
# ------------------------------------------------------------

duplicates <- panel %>%
  dplyr::count(
    ADM2_PCODE,
    Year,
    name = "n"
  ) %>%
  dplyr::filter(n > 1)

cat("\n===== DUPLICATES =====\n")
print(duplicates)

if (nrow(duplicates) > 0) {
  stop(
    "Duplicate district-year observations detected."
  )
}


# ------------------------------------------------------------
# 7. Balanced-panel check
# ------------------------------------------------------------

balance_by_district <- panel %>%
  dplyr::group_by(
    ADM2_PCODE,
    ADM2_EN
  ) %>%
  dplyr::summarise(
    N_years = dplyr::n_distinct(Year),
    .groups = "drop"
  )

cat("\n===== YEARS BY DISTRICT =====\n")
print(balance_by_district)

if (
  nrow(panel) != 65 ||
  dplyr::n_distinct(panel$ADM2_PCODE) != 5 ||
  dplyr::n_distinct(panel$Year) != 13 ||
  any(balance_by_district$N_years != 13)
) {
  stop(
    "Final panel is not the expected balanced 5 × 13 panel."
  )
}

cat("\nBalanced panel check passed.\n")


# ------------------------------------------------------------
# 8. Descriptive statistics
# ------------------------------------------------------------

variables <- c(
  "RRUI",
  "NDVI",
  "precip_mm",
  "temp_c",
  "Livestock_units"
)

descriptive_statistics <- data.frame(
  Variable = variables,
  N = vapply(
    panel[variables],
    function(x) sum(!is.na(x)),
    numeric(1)
  ),
  Mean = vapply(
    panel[variables],
    mean,
    numeric(1),
    na.rm = TRUE
  ),
  SD = vapply(
    panel[variables],
    stats::sd,
    numeric(1),
    na.rm = TRUE
  ),
  Min = vapply(
    panel[variables],
    min,
    numeric(1),
    na.rm = TRUE
  ),
  Max = vapply(
    panel[variables],
    max,
    numeric(1),
    na.rm = TRUE
  )
)

cat("\n===== DESCRIPTIVE STATISTICS =====\n")
print(
  descriptive_statistics,
  row.names = FALSE
)


# ------------------------------------------------------------
# 9. Raw correlations
# ------------------------------------------------------------

correlation_variables <- c(
  "RRUI",
  "precip_mm",
  "temp_c",
  "Livestock_units"
)

raw_correlations <- stats::cor(
  panel[correlation_variables],
  use = "complete.obs"
)

cat("\n===== RAW CORRELATIONS =====\n")
print(
  round(
    raw_correlations,
    4
  )
)


# ------------------------------------------------------------
# 10. Two-way demean variables
# ------------------------------------------------------------

two_way_demean <- function(data, variable) {
  
  x <- data[[variable]]
  
  district_mean <- ave(
    x,
    data$ADM2_PCODE,
    FUN = function(z) mean(z, na.rm = TRUE)
  )
  
  year_mean <- ave(
    x,
    data$Year,
    FUN = function(z) mean(z, na.rm = TRUE)
  )
  
  overall_mean <- mean(
    x,
    na.rm = TRUE
  )
  
  x - district_mean - year_mean + overall_mean
}


panel_tw <- panel

for (v in correlation_variables) {
  
  panel_tw[[paste0(v, "_tw")]] <-
    two_way_demean(
      panel,
      v
    )
}


tw_variables <- paste0(
  correlation_variables,
  "_tw"
)

two_way_within_correlations <- stats::cor(
  panel_tw[tw_variables],
  use = "complete.obs"
)

rownames(two_way_within_correlations) <-
  correlation_variables

colnames(two_way_within_correlations) <-
  correlation_variables


cat("\n===== TWO-WAY WITHIN CORRELATIONS =====\n")

print(
  round(
    two_way_within_correlations,
    4
  )
)


# ------------------------------------------------------------
# 11. Within-district temporal variation
# ------------------------------------------------------------

within_district_variation <- panel %>%
  dplyr::group_by(
    ADM2_PCODE,
    ADM2_EN
  ) %>%
  dplyr::summarise(
    RRUI_SD = stats::sd(
      RRUI,
      na.rm = TRUE
    ),
    NDVI_SD = stats::sd(
      NDVI,
      na.rm = TRUE
    ),
    Precip_SD = stats::sd(
      precip_mm,
      na.rm = TRUE
    ),
    Temp_SD = stats::sd(
      temp_c,
      na.rm = TRUE
    ),
    Livestock_SD = stats::sd(
      Livestock_units,
      na.rm = TRUE
    ),
    .groups = "drop"
  )


cat("\n===== WITHIN-DISTRICT TEMPORAL VARIATION =====\n")

print(within_district_variation)


if (
  any(within_district_variation$RRUI_SD == 0) ||
  any(within_district_variation$Precip_SD == 0) ||
  any(within_district_variation$Temp_SD == 0) ||
  any(within_district_variation$Livestock_SD == 0)
) {
  stop(
    "At least one regressor has zero within-district variation."
  )
}


# ------------------------------------------------------------
# 12. Simple collinearity diagnostic
# ------------------------------------------------------------

max_abs_within_correlation <- max(
  abs(
    two_way_within_correlations[
      upper.tri(
        two_way_within_correlations
      )
    ]
  ),
  na.rm = TRUE
)

cat("\n===== COLLINEARITY CHECK =====\n")

cat(
  "Maximum absolute two-way within correlation:",
  round(max_abs_within_correlation, 4),
  "\n"
)

if (max_abs_within_correlation >= 0.90) {
  
  warning(
    "Very high two-way within correlation detected."
  )
  
} else {
  
  cat(
    "No pairwise two-way within correlation >= 0.90 detected.\n"
  )
}


# ------------------------------------------------------------
# 13. Output directories
# ------------------------------------------------------------

dir.create(
  "results/diagnostics",
  recursive = TRUE,
  showWarnings = FALSE
)


# ------------------------------------------------------------
# 14. Save CSV diagnostics
# ------------------------------------------------------------

readr::write_csv(
  descriptive_statistics,
  "results/diagnostics/20_descriptive_statistics.csv"
)

readr::write_csv(
  within_district_variation,
  "results/diagnostics/20_within_district_variation.csv"
)


two_way_cor_df <- data.frame(
  Variable = rownames(
    two_way_within_correlations
  ),
  two_way_within_correlations,
  row.names = NULL,
  check.names = FALSE
)

readr::write_csv(
  two_way_cor_df,
  "results/diagnostics/20_two_way_within_correlations.csv"
)


# ------------------------------------------------------------
# 15. Excel workbook
# ------------------------------------------------------------

xlsx_file <-
  "results/diagnostics/20_FINAL_DIAGNOSTICS.xlsx"

wb <- openxlsx::createWorkbook()

openxlsx::addWorksheet(
  wb,
  "Descriptive statistics"
)

openxlsx::writeData(
  wb,
  "Descriptive statistics",
  descriptive_statistics
)


openxlsx::addWorksheet(
  wb,
  "Raw correlations"
)

raw_cor_df <- data.frame(
  Variable = rownames(raw_correlations),
  raw_correlations,
  row.names = NULL,
  check.names = FALSE
)

openxlsx::writeData(
  wb,
  "Raw correlations",
  raw_cor_df
)


openxlsx::addWorksheet(
  wb,
  "Two-way correlations"
)

openxlsx::writeData(
  wb,
  "Two-way correlations",
  two_way_cor_df
)


openxlsx::addWorksheet(
  wb,
  "Within variation"
)

openxlsx::writeData(
  wb,
  "Within variation",
  within_district_variation
)


openxlsx::saveWorkbook(
  wb,
  xlsx_file,
  overwrite = TRUE
)


# ------------------------------------------------------------
# 16. Output validation
# ------------------------------------------------------------

output_files <- c(
  "results/diagnostics/20_descriptive_statistics.csv",
  "results/diagnostics/20_within_district_variation.csv",
  "results/diagnostics/20_two_way_within_correlations.csv",
  xlsx_file
)

missing_outputs <- output_files[
  !file.exists(output_files)
]

if (length(missing_outputs) > 0) {
  stop(
    paste(
      "Diagnostic output files were not created:",
      paste(
        missing_outputs,
        collapse = ", "
      )
    )
  )
}


cat("\n===== DIAGNOSTIC FILES SAVED =====\n")

for (f in output_files) {
  cat(
    basename(f),
    ":",
    file.exists(f),
    "\n"
  )
}


# ------------------------------------------------------------
# 17. renv status
# ------------------------------------------------------------

cat("\n===== RENV STATUS =====\n")

if (requireNamespace(
  "renv",
  quietly = TRUE
)) {
  
  renv::status()
  
} else {
  
  warning(
    "Package 'renv' is not available."
  )
}


# ------------------------------------------------------------
# 18. Final message
# ------------------------------------------------------------

cat("\n========================================\n")
cat("FINAL DIAGNOSTICS COMPLETED SUCCESSFULLY\n")
cat("========================================\n")
