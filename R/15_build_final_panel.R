# ============================================================
# SAIGA RRUI–NDVI PROJECT
# 15_build_final_panel.R
#
# Final analytical panel:
# RRUI + NDVI + climate + livestock
#
# 2012–2024
# 5 districts × 13 years = 65 observations
# ============================================================


# ------------------------------------------------------------
# 1. Packages
# ------------------------------------------------------------

library(dplyr)
library(readr)
library(readxl)
library(openxlsx)


# ------------------------------------------------------------
# 2. Read RRUI + NDVI + climate panel
# ------------------------------------------------------------

panel <- read_csv(
  "data/processed/Panel_RRUI_NDVI_Climate_AprOct.csv",
  show_col_types = FALSE
) %>%
  mutate(
    Year = as.integer(Year),
    ADM2_PCODE = as.character(ADM2_PCODE)
  )


# ------------------------------------------------------------
# 3. Find livestock Excel file
# ------------------------------------------------------------

livestock_files <- list.files(
  "data/raw/livestock",
  pattern = "\\.xlsx$",
  full.names = TRUE
)

stopifnot(
  length(livestock_files) == 1
)

livestock_file <- livestock_files[1]

cat("\n===== LIVESTOCK FILE =====\n")
cat(livestock_file, "\n")


# ------------------------------------------------------------
# 4. Read livestock
# ------------------------------------------------------------

livestock_raw <- read_excel(
  livestock_file,
  sheet = "скот"
)


# ------------------------------------------------------------
# 5. Prepare livestock data
# ------------------------------------------------------------

livestock <- livestock_raw %>%
  transmute(
    district = район,
    
    Year = as.integer(
      format(Дата, "%Y")
    ),
    
    Livestock_units = as.numeric(
      `УсловГолов тыс. ед`
    )
  ) %>%
  filter(
    Year >= 2012,
    Year <= 2024
  )


# ------------------------------------------------------------
# 6. Map districts to ADM2 PCODE
# ------------------------------------------------------------

livestock <- livestock %>%
  mutate(
    ADM2_PCODE = case_when(
      district == "Акжаик"    ~ "KAZ020001",
      district == "Бокейорда" ~ "KAZ020002",
      district == "Казталов"  ~ "KAZ020005",
      district == "Жанакала"  ~ "KAZ020012",
      district == "Жанибек"   ~ "KAZ020013",
      TRUE ~ NA_character_
    )
  )


# ------------------------------------------------------------
# 7. Check mapping
# ------------------------------------------------------------

cat("\n===== DISTRICT MAPPING =====\n")

mapping <- livestock %>%
  distinct(
    district,
    ADM2_PCODE
  ) %>%
  arrange(ADM2_PCODE)

print(mapping)

cat(
  "Unmatched districts:",
  sum(is.na(livestock$ADM2_PCODE)),
  "\n"
)

stopifnot(
  !anyNA(livestock$ADM2_PCODE)
)


# ------------------------------------------------------------
# 8. Prepare merge table
# ------------------------------------------------------------

livestock_clean <- livestock %>%
  select(
    Year,
    ADM2_PCODE,
    Livestock_units
  )


# ------------------------------------------------------------
# 9. Check uniqueness before merge
# ------------------------------------------------------------

livestock_duplicates <- livestock_clean %>%
  count(
    Year,
    ADM2_PCODE,
    name = "n"
  ) %>%
  filter(n > 1)

stopifnot(
  nrow(livestock_clean) == 65,
  nrow(livestock_duplicates) == 0
)


# ------------------------------------------------------------
# 10. Merge
# ------------------------------------------------------------

final_panel <- panel %>%
  left_join(
    livestock_clean,
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
# 11. Panel check
# ------------------------------------------------------------

cat("\n===== FINAL PANEL =====\n")

cat("Rows:", nrow(final_panel), "\n")

cat(
  "Districts:",
  n_distinct(final_panel$ADM2_PCODE),
  "\n"
)

cat(
  "Years:",
  n_distinct(final_panel$Year),
  "\n"
)

cat(
  "Missing Livestock_units:",
  sum(is.na(final_panel$Livestock_units)),
  "\n"
)


# ------------------------------------------------------------
# 12. First 15 observations
# ------------------------------------------------------------

cat("\n===== FIRST 15 ROWS =====\n")

print(
  head(final_panel, 15)
)


# ------------------------------------------------------------
# 13. Livestock summary
# ------------------------------------------------------------

cat("\n===== LIVESTOCK SUMMARY =====\n")

print(
  summary(final_panel$Livestock_units)
)


# ------------------------------------------------------------
# 14. Final duplicate check
# ------------------------------------------------------------

duplicates <- final_panel %>%
  count(
    Year,
    ADM2_PCODE,
    name = "n"
  ) %>%
  filter(n > 1)

cat("\n===== DUPLICATES =====\n")
print(duplicates)


# ------------------------------------------------------------
# 15. Hard validation
# ------------------------------------------------------------

stopifnot(
  nrow(final_panel) == 65,
  n_distinct(final_panel$ADM2_PCODE) == 5,
  n_distinct(final_panel$Year) == 13,
  
  nrow(duplicates) == 0,
  
  !anyNA(final_panel$RRUI),
  !anyNA(final_panel$NDVI),
  !anyNA(final_panel$precip_mm),
  !anyNA(final_panel$temp_c),
  !anyNA(final_panel$Livestock_units)
)

cat(
  "\nFinal analytical panel validated successfully.\n"
)


# ------------------------------------------------------------
# 16. Save final panel
# ------------------------------------------------------------

write_csv(
  final_panel,
  "data/processed/Panel_RRUI_NDVI_Climate_Livestock_AprOct.csv"
)

write.xlsx(
  final_panel,
  "data/processed/Panel_RRUI_NDVI_Climate_Livestock_AprOct.xlsx",
  overwrite = TRUE
)


# ------------------------------------------------------------
# 17. Verify saved files
# ------------------------------------------------------------

cat("\n===== FILES SAVED =====\n")

cat(
  "CSV:",
  file.exists(
    "data/processed/Panel_RRUI_NDVI_Climate_Livestock_AprOct.csv"
  ),
  "\n"
)

cat(
  "XLSX:",
  file.exists(
    "data/processed/Panel_RRUI_NDVI_Climate_Livestock_AprOct.xlsx"
  ),
  "\n"
)