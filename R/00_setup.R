# ============================================================
# SAIGA RRUI–NDVI PROJECT
# 00_setup.R
# Reproducible analysis environment
# Developed with R 4.6.1
# ============================================================

# R version
required_r <- "4.6.1"

if (as.character(getRversion()) != required_r) {
  warning(
    "This analysis was developed using R ", required_r,
    ". Current version: ", getRversion()
  )
}

# Random seeds
RNG_SEED <- 12345

set.seed(RNG_SEED)

if (!requireNamespace("dqrng", quietly = TRUE)) {
  stop(
    "Package 'dqrng' is required. ",
    "Restore the project environment with renv::restore()."
  )
}

dqrng::dqset.seed(RNG_SEED)

# Required packages
packages <- c(
  "sf",
  "dplyr",
  "tidyr",
  "readr",
  "readxl",
  "openxlsx",
  "ggplot2",
  "fixest",
  "clubSandwich",
  "fwildclusterboot",
  "dqrng",
  "modelsummary"
)

missing_packages <- packages[
  !vapply(
    packages,
    requireNamespace,
    quietly = TRUE,
    FUN.VALUE = logical(1)
  )
]

if (length(missing_packages) > 0) {
  stop(
    "Missing required package(s): ",
    paste(missing_packages, collapse = ", "),
    "\nRestore the project environment using renv::restore()."
  )
}

invisible(
  lapply(
    packages,
    library,
    character.only = TRUE
  )
)

# Required input directories
required_input_dirs <- c(
  "R",
  "data/raw/gps",
  "data/raw/boundaries",
  "data/raw/ndvi",
  "data/raw/climate",
  "data/raw/livestock"
)

missing_input_dirs <- required_input_dirs[
  !dir.exists(required_input_dirs)
]

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
  lapply(
    output_dirs,
    dir.create,
    recursive = TRUE,
    showWarnings = FALSE
  )
)

# Save session information
capture.output(
  sessionInfo(),
  file = "logs/sessionInfo.txt"
)

cat("\n========================================\n")
cat("SAIGA project setup completed\n")
cat("R version:", R.version.string, "\n")
cat("Random seed:", RNG_SEED, "\n")
cat("========================================\n")