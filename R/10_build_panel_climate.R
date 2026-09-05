# ============================================================
# SAIGA RRUI–NDVI PROJECT
# 10_build_panel_climate.R
#
# Merge:
# RRUI + NDVI + climate
#
# Period: 2012–2024
# 5 districts × 13 years = 65 observations
# ============================================================


# ------------------------------------------------------------
# 1. Packages
# ------------------------------------------------------------

library(dplyr)
library(readr)
library(openxlsx)


# ------------------------------------------------------------
# 2. Read RRUI–NDVI panel
# ------------------------------------------------------------

panel <- read_csv(
  "data/processed/Panel_RRUI_NDVI_AprOct.csv",
  show_col_types = FALSE
) %>%
  mutate(
    Year = as.integer(Year),
    ADM2_PCODE = as.character(ADM2_PCODE)
  )


# ------------------------------------------------------------
# 3. Read climate data
# ------------------------------------------------------------

climate <- read_csv(
  "data/raw/climate/climate_by_district_year.csv",
  show_col_types = FALSE
) %>%
  mutate(
    year = as.integer(year),
    precip_mm = as.numeric(precip_mm),
    temp_c = as.numeric(temp_c)
  )


# ------------------------------------------------------------
# 4. Convert climate district names to ADM2 PCODE
# ------------------------------------------------------------

climate <- climate %>%
  mutate(
    ADM2_PCODE = case_when(
      district == "Akzhaiyk" ~ "KAZ020001",
      district == "Urda"     ~ "KAZ020002",
      district == "Kaztalov" ~ "KAZ020005",
      district == "Zhangala" ~ "KAZ020012",
      district == "Zhanybek" ~ "KAZ020013",
      TRUE ~ NA_character_
    )
  )


# ------------------------------------------------------------
# 5. Check mapping
# ------------------------------------------------------------

cat("\n===== DISTRICT MAPPING =====\n")

mapping_check <- climate %>%
  distinct(
    district,
    ADM2_PCODE
  ) %>%
  arrange(ADM2_PCODE)

print(mapping_check)

cat(
  "\nUnmatched climate districts:",
  sum(is.na(climate$ADM2_PCODE)),
  "\n"
)

stopifnot(
  !anyNA(climate$ADM2_PCODE)
)


# ------------------------------------------------------------
# 6. Prepare climate panel
# ------------------------------------------------------------

climate_clean <- climate %>%
  transmute(
    Year = year,
    ADM2_PCODE,
    precip_mm,
    temp_c
  )


# ------------------------------------------------------------
# 7. Merge climate with RRUI–NDVI
# ------------------------------------------------------------

panel_climate <- panel %>%
  left_join(
    climate_clean,
    by = c(
      "Year",
      "ADM2_PCODE"
    )
  ) %>%
  arrange(
    Year,
    ADM2_PCODE
  )


# ------------------------------------------------------------
# 8. Check merged panel
# ------------------------------------------------------------

cat("\n===== MERGED PANEL =====\n")

cat(
  "Rows:",
  nrow(panel_climate),
  "\n"
)

cat(
  "Districts:",
  n_distinct(panel_climate$ADM2_PCODE),
  "\n"
)

cat(
  "Years:",
  n_distinct(panel_climate$Year),
  "\n"
)

cat(
  "Missing RRUI:",
  sum(is.na(panel_climate$RRUI)),
  "\n"
)

cat(
  "Missing NDVI:",
  sum(is.na(panel_climate$NDVI)),
  "\n"
)

cat(
  "Missing precipitation:",
  sum(is.na(panel_climate$precip_mm)),
  "\n"
)

cat(
  "Missing temperature:",
  sum(is.na(panel_climate$temp_c)),
  "\n"
)


# ------------------------------------------------------------
# 9. First rows
# ------------------------------------------------------------

cat("\n===== FIRST 15 ROWS =====\n")

print(
  head(panel_climate, 15)
)


# ------------------------------------------------------------
# 10. Duplicate check
# ------------------------------------------------------------

duplicates <- panel_climate %>%
  count(
    Year,
    ADM2_PCODE,
    name = "n"
  ) %>%
  filter(n > 1)

cat("\n===== DUPLICATES =====\n")

print(duplicates)


# ------------------------------------------------------------
# 11. Hard validation
# ------------------------------------------------------------

stopifnot(
  nrow(panel_climate) == 65,
  n_distinct(panel_climate$ADM2_PCODE) == 5,
  n_distinct(panel_climate$Year) == 13,
  nrow(duplicates) == 0,
  !anyNA(panel_climate$RRUI),
  !anyNA(panel_climate$NDVI),
  !anyNA(panel_climate$precip_mm),
  !anyNA(panel_climate$temp_c)
)

cat(
  "\nRRUI-NDVI-climate panel validated successfully.\n"
)


# ------------------------------------------------------------
# 12. Save processed panel
# ------------------------------------------------------------

write_csv(
  panel_climate,
  "data/processed/Panel_RRUI_NDVI_Climate_AprOct.csv"
)

write.xlsx(
  panel_climate,
  "data/processed/Panel_RRUI_NDVI_Climate_AprOct.xlsx",
  overwrite = TRUE
)


cat("\n===== FILES SAVED =====\n")

cat(
  "CSV:",
  file.exists(
    "data/processed/Panel_RRUI_NDVI_Climate_AprOct.csv"
  ),
  "\n"
)

cat(
  "XLSX:",
  file.exists(
    "data/processed/Panel_RRUI_NDVI_Climate_AprOct.xlsx"
  ),
  "\n"
)