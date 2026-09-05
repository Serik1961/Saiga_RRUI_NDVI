# ============================================================
# SAIGA RRUI–NDVI PROJECT
# 09_climate_preprocessing.R
#
# Climate data preprocessing
# April–October, 2012–2024
# ============================================================


# ------------------------------------------------------------
# 1. Packages
# ------------------------------------------------------------

library(dplyr)
library(readr)


# ------------------------------------------------------------
# 2. Read climate data
# ------------------------------------------------------------

climate_raw <- read_csv(
  "data/raw/climate/climate_by_district_year.csv",
  show_col_types = FALSE
)


# ------------------------------------------------------------
# 3. Initial structure
# ------------------------------------------------------------

cat("\n===== CLIMATE DIMENSIONS =====\n")
cat("Rows:", nrow(climate_raw), "\n")
cat("Columns:", ncol(climate_raw), "\n")

cat("\n===== COLUMN NAMES =====\n")
print(names(climate_raw))

cat("\n===== STRUCTURE =====\n")
str(climate_raw)

cat("\n===== FIRST 10 ROWS =====\n")
print(head(climate_raw, 10))


# ------------------------------------------------------------
# 4. Standardize variables
# ------------------------------------------------------------

climate <- climate_raw %>%
  mutate(
    year = as.integer(year),
    precip_mm = as.numeric(precip_mm),
    temp_c = as.numeric(temp_c)
  )


# ------------------------------------------------------------
# 5. District names
# ------------------------------------------------------------

cat("\n===== DISTRICT NAMES =====\n")

print(
  sort(unique(climate$district))
)


# ------------------------------------------------------------
# 6. Years
# ------------------------------------------------------------

cat("\n===== YEARS =====\n")

print(
  sort(unique(climate$year))
)

cat(
  "Year range:",
  min(climate$year),
  "-",
  max(climate$year),
  "\n"
)


# ------------------------------------------------------------
# 7. Observations per year
# ------------------------------------------------------------

climate_by_year <- climate %>%
  count(
    year,
    name = "N_districts"
  )

cat("\n===== DISTRICTS BY YEAR =====\n")

print(climate_by_year)


# ------------------------------------------------------------
# 8. Observations per district
# ------------------------------------------------------------

climate_by_district <- climate %>%
  count(
    district,
    name = "N_years"
  )

cat("\n===== YEARS BY DISTRICT =====\n")

print(climate_by_district)


# ------------------------------------------------------------
# 9. Duplicate district-year cells
# ------------------------------------------------------------

duplicates <- climate %>%
  count(
    district,
    year,
    name = "n"
  ) %>%
  filter(n > 1)

cat("\n===== DUPLICATES =====\n")

print(duplicates)

cat(
  "Number of duplicate district-year cells:",
  nrow(duplicates),
  "\n"
)


# ------------------------------------------------------------
# 10. Missing values
# ------------------------------------------------------------

cat("\n===== MISSING VALUES =====\n")

cat(
  "Missing district:",
  sum(is.na(climate$district)),
  "\n"
)

cat(
  "Missing year:",
  sum(is.na(climate$year)),
  "\n"
)

cat(
  "Missing precipitation:",
  sum(is.na(climate$precip_mm)),
  "\n"
)

cat(
  "Missing temperature:",
  sum(is.na(climate$temp_c)),
  "\n"
)


# ------------------------------------------------------------
# 11. Climate summaries
# ------------------------------------------------------------

cat("\n===== PRECIPITATION SUMMARY =====\n")
print(summary(climate$precip_mm))

cat("\n===== TEMPERATURE SUMMARY =====\n")
print(summary(climate$temp_c))


# ------------------------------------------------------------
# 12. Hard validation
# ------------------------------------------------------------

stopifnot(
  nrow(climate) == 65,
  n_distinct(climate$district) == 5,
  n_distinct(climate$year) == 13,
  all(sort(unique(climate$year)) == 2012:2024),
  all(climate_by_year$N_districts == 5),
  all(climate_by_district$N_years == 13),
  nrow(duplicates) == 0,
  !anyNA(climate$precip_mm),
  !anyNA(climate$temp_c)
)

cat("\nClimate panel validation completed successfully.\n")