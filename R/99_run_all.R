# ============================================================
# 99_run_all.R
# Full reproducibility run
# ============================================================

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
  "20_final_diagnostics.R"
)

cat("\n========================================\n")
cat("FULL REPRODUCIBILITY RUN\n")
cat("========================================\n\n")

start_time <- Sys.time()

for (s in scripts) {
  
  cat("\n\n")
  cat("========================================\n")
  cat("RUNNING:", s, "\n")
  cat("========================================\n\n")
  
  source(file.path("R", s), echo = FALSE)
  
  cat("\nPASSED:", s, "\n")
}

end_time <- Sys.time()

cat("\n\n========================================\n")
cat("ALL SCRIPTS COMPLETED SUCCESSFULLY\n")
cat("========================================\n")

cat("\nStart:", format(start_time), "\n")
cat("End:  ", format(end_time), "\n")
cat(
  "Duration:",
  round(as.numeric(difftime(end_time, start_time, units = "mins")), 2),
  "minutes\n"
)

cat("\nR version:\n")
print(R.version.string)

cat("\nrenv status:\n")
renv::status()