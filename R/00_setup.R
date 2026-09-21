# ============================================================
# SAIGA RRUI-NDVI PROJECT
# 00_setup.R
# Reproducible analysis environment
# Developed with R 4.6.1; v1.3.1 needs no random numbers
# ============================================================

# R version
required_r <- "4.6.1"

if (as.character(getRversion()) != required_r) {
  warning(
    "This analysis was developed using R ", required_r,
    ". Current version: ", getRversion()
  )
}

# v1.3.1: all inference (CR2, exact wild cluster bootstrap) is deterministic.
# The seed is kept only for the optional GPS steps.
RNG_SEED <- 12345
set.seed(RNG_SEED)

# Required packages
# (fwildclusterboot, dqrng, ggplot2 and modelsummary are no longer used;
#  sf is needed only when the GPS shapefiles are available, steps 01-03)
gps_available <- file.exists("data/raw/gps/Kazakhstan_Saiga_Ural_Routes.shp")

packages <- c(
  "dplyr", "tidyr", "tibble", "readr", "readxl", "openxlsx",
  "fixest", "clubSandwich",
  if (gps_available) "sf"
)

missing_packages <- packages[
  !vapply(packages, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))
]

if (length(missing_packages) > 0) {
  stop(
    "Missing required package(s): ",
    paste(missing_packages, collapse = ", "),
    "\nRestore the project environment using renv::restore()."
  )
}

invisible(lapply(packages, library, character.only = TRUE))

# Required input directories
required_input_dirs <- c(
  "R",
  "data/raw/gps",
  "data/raw/boundaries",
  "data/raw/ndvi",
  "data/raw/climate",
  "data/raw/livestock"
)

missing_input_dirs <- required_input_dirs[!dir.exists(required_input_dirs)]

if (length(missing_input_dirs) > 0) {
  stop(
    "Missing required input directories:\n",
    paste(missing_input_dirs, collapse = "\n")
  )
}

# Output directories
output_dirs <- c(
  "data/intermediate",
  "data/processed",
  "results/tables",
  "results/figures",
  "results/diagnostics",
  "logs"
)

invisible(
  lapply(output_dirs, dir.create, recursive = TRUE, showWarnings = FALSE)
)

# Save session information
capture.output(sessionInfo(), file = "logs/sessionInfo.txt")

cat("\n========================================\n")
cat("SAIGA project setup completed\n")
cat("R version:", R.version.string, "\n")
cat("GPS shapefiles available:", gps_available, "\n")
cat("========================================\n")
