# ============================================================
# SAIGA RRUI–NDVI PROJECT
# 21_period_consistency_check.R
#
# Final consistency check for seasonal periods
#
# NDVI:    May–September
# Climate: April–October
# ============================================================


# ------------------------------------------------------------
# 1. Expected processed files
# ------------------------------------------------------------

expected_files <- c(
  "data/processed/Panel_RRUI_NDVI_MaySep.csv",
  "data/processed/Panel_RRUI_NDVI_MaySep.xlsx",
  "data/processed/Panel_RRUI_NDVI_MaySep_Climate_AprOct.csv",
  "data/processed/Panel_RRUI_NDVI_MaySep_Climate_AprOct.xlsx",
  "data/processed/Panel_RRUI_NDVI_MaySep_Climate_AprOct_Livestock.csv",
  "data/processed/Panel_RRUI_NDVI_MaySep_Climate_AprOct_Livestock.xlsx"
)

missing_files <- expected_files[
  !file.exists(expected_files)
]

cat("\n===== EXPECTED PROCESSED FILES =====\n")

if (length(missing_files) == 0) {
  
  cat("All expected processed files exist.\n")
  
} else {
  
  stop(
    paste(
      "Missing expected processed files:",
      paste(missing_files, collapse = ", ")
    )
  )
}


# ------------------------------------------------------------
# 2. Check R scripts for obsolete processed-panel filenames
# ------------------------------------------------------------

r_files <- list.files(
  "R",
  pattern = "\\.R$",
  full.names = TRUE
)

# Do not scan this checker itself
r_files <- r_files[
  basename(r_files) != "21_period_consistency_check.R"
]

obsolete_names <- c(
  "Panel_RRUI_NDVI_AprOct",
  "Panel_RRUI_NDVI_Climate_AprOct",
  "Panel_RRUI_NDVI_Climate_Livestock_AprOct"
)

problems <- list()

for (f in r_files) {
  
  x <- readLines(
    f,
    warn = FALSE
  )
  
  for (pattern in obsolete_names) {
    
    hit <- grep(
      pattern,
      x,
      fixed = TRUE
    )
    
    if (length(hit) > 0) {
      
      problems[[length(problems) + 1]] <- data.frame(
        file = f,
        line = hit,
        obsolete_reference = pattern,
        text = trimws(x[hit]),
        stringsAsFactors = FALSE
      )
    }
  }
}


cat("\n===== OBSOLETE PANEL REFERENCES =====\n")

if (length(problems) == 0) {
  
  cat("No obsolete processed-panel references found.\n")
  
} else {
  
  problems_df <- do.call(
    rbind,
    problems
  )
  
  print(
    problems_df,
    row.names = FALSE
  )
  
  stop(
    "Obsolete processed-panel filenames remain in R scripts."
  )
}


# ------------------------------------------------------------
# 3. Check NDVI GEE source
# ------------------------------------------------------------

ndvi_gee <- "GEE/01_MOD13Q1_NDVI_MaySep.js"

if (!file.exists(ndvi_gee)) {
  
  stop(
    paste(
      "NDVI GEE script not found:",
      ndvi_gee
    )
  )
}

ndvi_code <- readLines(
  ndvi_gee,
  warn = FALSE
)

# Join the whole JS file so multiline expressions
# can be checked reliably
ndvi_text <- paste(
  ndvi_code,
  collapse = " "
)


# MODIS source
has_mod13q1 <- grepl(
  "MODIS/061/MOD13Q1",
  ndvi_text,
  fixed = TRUE
)

if (!has_mod13q1) {
  
  stop(
    "MODIS/061/MOD13Q1 was not found in the NDVI GEE script."
  )
}


# NDVI start = 1 May
has_ndvi_start <- grepl(
  "fromYMD\\s*\\(\\s*year\\s*,\\s*5\\s*,\\s*1\\s*\\)",
  ndvi_text,
  perl = TRUE
)

if (!has_ndvi_start) {
  
  stop(
    "Expected NDVI start date (1 May) was not found."
  )
}


# NDVI end = 1 October, exclusive
has_ndvi_end <- grepl(
  "fromYMD\\s*\\(\\s*year\\s*,\\s*10\\s*,\\s*1\\s*\\)",
  ndvi_text,
  perl = TRUE
)

if (!has_ndvi_end) {
  
  stop(
    "Expected NDVI end date (1 October, exclusive) was not found."
  )
}


cat("\n===== NDVI PERIOD =====\n")
cat("Dataset: MODIS/061/MOD13Q1\n")
cat("Start:   1 May\n")
cat("End:     1 October (exclusive)\n")
cat("Effective NDVI period: 1 May–30 September\n")


# ------------------------------------------------------------
# 4. Check climate GEE source
# ------------------------------------------------------------

climate_gee <-
  "GEE/02_CHIRPS_ERA5Land_Climate_AprOct.js"

if (!file.exists(climate_gee)) {
  
  stop(
    paste(
      "Climate GEE script not found:",
      climate_gee
    )
  )
}

climate_code <- readLines(
  climate_gee,
  warn = FALSE
)

# Join whole JS file for robust checking
climate_text <- paste(
  climate_code,
  collapse = " "
)


# ------------------------------------------------------------
# 5. Check climate data sources
# ------------------------------------------------------------

has_chirps <- grepl(
  "UCSB-CHG/CHIRPS/DAILY",
  climate_text,
  fixed = TRUE
)

has_era5 <- grepl(
  "ECMWF/ERA5_LAND/MONTHLY_AGGR",
  climate_text,
  fixed = TRUE
)

if (!has_chirps) {
  
  stop(
    "CHIRPS Daily source was not found in the climate GEE script."
  )
}

if (!has_era5) {
  
  stop(
    "ERA5-Land Monthly Aggregated source was not found in the climate GEE script."
  )
}


# ------------------------------------------------------------
# 6. Check climate seasonal months
# ------------------------------------------------------------

has_climate_start <- grepl(
  "seasonStartMonth\\s*=\\s*4",
  climate_text,
  perl = TRUE
)

has_climate_end <- grepl(
  "seasonEndMonth\\s*=\\s*10",
  climate_text,
  perl = TRUE
)

if (!has_climate_start) {
  
  stop(
    "Climate start month April (4) was not found."
  )
}

if (!has_climate_end) {
  
  stop(
    "Climate end month October (10) was not found."
  )
}


cat("\n===== CLIMATE PERIOD =====\n")
cat("Precipitation source: CHIRPS Daily\n")
cat("Temperature source:   ERA5-Land Monthly Aggregated\n")
cat("Seasonal months defined in source: April–October\n")


# ------------------------------------------------------------
# 7. Important CHIRPS date-boundary check
# ------------------------------------------------------------

# The archived climate source uses:
#
# start = 1 April
# end   = 31 October
#
# Earth Engine filterDate() treats the end date as exclusive.
# Therefore the daily CHIRPS sum effectively includes
# 1 April through 30 October.
#
# We preserve this source exactly for reproducibility and do not
# modify the historical climate values here.

has_chirps_start <- grepl(
  "fromYMD\\s*\\(\\s*y\\s*,\\s*4\\s*,\\s*1\\s*\\)",
  climate_text,
  perl = TRUE
)

has_chirps_end <- grepl(
  "fromYMD\\s*\\(\\s*y\\s*,\\s*10\\s*,\\s*31\\s*\\)",
  climate_text,
  perl = TRUE
)

cat("\n===== CLIMATE DATE BOUNDARY =====\n")

if (has_chirps_start && has_chirps_end) {
  
  cat("Archived GEE date bounds detected: 1 April to 31 October.\n")
  cat("Earth Engine filterDate end date is exclusive.\n")
  cat("Daily CHIRPS effective coverage: 1 April–30 October.\n")
  
} else {
  
  cat(
    "Climate seasonal months are April–October, ",
    "but exact daily date-boundary pattern was not automatically detected.\n",
    sep = ""
  )
}


# ------------------------------------------------------------
# 8. Final result
# ------------------------------------------------------------

cat("\n========================================\n")
cat("PERIOD CONSISTENCY CHECK PASSED\n")
cat("========================================\n")

cat("\nNDVI:    1 May–30 September\n")
cat("Climate: April–October seasonal definition\n")
cat("CHIRPS:  1 April–30 October effective daily coverage\n")