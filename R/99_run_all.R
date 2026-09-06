# ============================================================
# SAIGA RRUI–NDVI PROJECT
# 99_run_all.R
#
# Full reproducibility run
# ============================================================


# ------------------------------------------------------------
# 1. Scripts
# ------------------------------------------------------------

scripts <- c(
  "00_setup.R",
  "01_gps_preprocessing.R",
  "02_boundaries_preprocessing.R",
  "03_calculate_rrui.R",
  "04_ndvi_preprocessing.R",
  "05_build_panel.R",
  "06_twfe_rrui_ndvi.R",
  "07_cr2.R",
  "08_wild_cluster_bootstrap.R",
  "09_climate_preprocessing.R",
  "10_build_panel_climate.R",
  "11_twfe_climate.R",
  "12_cr2_climate.R",
  "13_wcb_climate.R",
  "14_livestock_preprocessing.R",
  "15_build_final_panel.R",
  "16_twfe_final.R",
  "17_cr2_final.R",
  "18_wcb_final.R",
  "19_final_results_table.R",
  "20_final_diagnostics.R",
  "21_period_consistency_check.R"
)


# ------------------------------------------------------------
# 2. Check that all scripts exist
# ------------------------------------------------------------

script_paths <- file.path("R", scripts)

missing_scripts <- script_paths[
  !file.exists(script_paths)
]

if (length(missing_scripts) > 0) {
  stop(
    paste(
      "Missing scripts:",
      paste(missing_scripts, collapse = ", ")
    )
  )
}


# ------------------------------------------------------------
# 3. Start reproducibility run
# ------------------------------------------------------------

cat("\n========================================\n")
cat("FULL REPRODUCIBILITY RUN\n")
cat("========================================\n\n")

cat("Scripts:", length(scripts), "\n")

start_time <- Sys.time()


# ------------------------------------------------------------
# 4. Run scripts sequentially
# ------------------------------------------------------------

for (s in scripts) {
  
  cat("\n\n")
  cat("========================================\n")
  cat("RUNNING:", s, "\n")
  cat("========================================\n\n")
  
  source(
    file.path("R", s),
    echo = FALSE
  )
  
  cat("\nPASSED:", s, "\n")
}


# ------------------------------------------------------------
# 5. Finish
# ------------------------------------------------------------

end_time <- Sys.time()

duration_minutes <- as.numeric(
  difftime(
    end_time,
    start_time,
    units = "mins"
  )
)

cat("\n\n========================================\n")
cat("ALL SCRIPTS COMPLETED SUCCESSFULLY\n")
cat("========================================\n")

cat("\nStart:", format(start_time), "\n")
cat("End:  ", format(end_time), "\n")

cat(
  "Duration:",
  round(duration_minutes, 2),
  "minutes\n"
)


# ------------------------------------------------------------
# 6. Environment information
# ------------------------------------------------------------

cat("\nR version:\n")
print(R.version.string)

cat("\nrenv status:\n")
renv::status()

cat("\n========================================\n")
cat("FULL REPRODUCIBILITY RUN COMPLETED\n")
cat("========================================\n")