# ============================================================
# SAIGA RRUI–NDVI PROJECT
# 15_build_final_panel.R
#
# Final analytical panel:
# RRUI + NDVI + climate + livestock
#
# NDVI period: May–September
# Climate period: April–October
# Study period: 2012–2024
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
#
# NDVI: May–September
# Climate: April–October
# ------------------------------------------------------------

panel <- read_csv(
  "data/processed/Panel_RRUI_NDVI_MaySep_Climate_AprOct.csv",
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

# NOTE: columns are addressed by position, not by their Cyrillic names, so
# that the script also runs in non-UTF-8 locales (v1.3.1).
# Column order in the file:
#   1 district | 2 date | 3 cattle | 4 sheep and goats | 5 horses | 6 LU (file)
livestock_raw <- read_excel(
  livestock_file,
  sheet = 1
)

stopifnot(ncol(livestock_raw) >= 6)

names(livestock_raw)[1:6] <- c(
  "district", "Date", "cattle", "sheep_goats", "horses", "LU_file"
)


# ------------------------------------------------------------
# 5. Prepare livestock data
# ------------------------------------------------------------

# Livestock units (LSU) are RECALCULATED from the three headcounts with the
# unadjusted Eurostat coefficients stated in the manuscript (Methods, 2.2):
#   cattle 1.0, sheep and goats 0.1, horses 0.8.
# The ready-made LU column of the Excel file (LU_file) uses 0.2 for sheep and
# goats and is therefore NOT used for analysis (it is kept only for a check).
LSU_CATTLE      <- 1.0
LSU_SHEEP_GOATS <- 0.1
LSU_HORSES      <- 0.8

livestock <- livestock_raw %>%
  transmute(
    district = as.character(district),
    Year = as.integer(format(as.Date(Date), "%Y")),
    cattle = as.numeric(cattle),
    sheep_goats = as.numeric(sheep_goats),
    horses = as.numeric(horses),
    LU_file = as.numeric(LU_file)
  ) %>%
  filter(
    Year >= 2012,
    Year <= 2024
  ) %>%
  mutate(
    Livestock_units =
      LSU_CATTLE * cattle +
      LSU_SHEEP_GOATS * sheep_goats +
      LSU_HORSES * horses
  )

cat("\n===== LSU CHECK vs. LU column in the Excel file =====\n")
cat(
  "Max |LSU(0.1) - LU_file|:",
  max(abs(livestock$Livestock_units - livestock$LU_file)),
  "(non-zero by construction: the file uses 0.2 for sheep/goats)\n"
)
cat(
  "Max |LSU(0.2) - LU_file|:",
  max(abs(
    livestock$cattle + 0.2 * livestock$sheep_goats + 0.8 * livestock$horses -
      livestock$LU_file
  )),
  "(confirms the file coefficient)\n"
)


# ------------------------------------------------------------
# 6. Map districts to ADM2 PCODE
# ------------------------------------------------------------

livestock <- livestock %>%
  mutate(
    ADM2_PCODE = case_when(
      district == "\u0410\u043a\u0436\u0430\u0438\u043a"    ~ "KAZ020001",  # Akzhaik
      district == "\u0411\u043e\u043a\u0435\u0439\u043e\u0440\u0434\u0430" ~ "KAZ020002",  # Bokey Orda
      district == "\u041a\u0430\u0437\u0442\u0430\u043b\u043e\u0432"  ~ "KAZ020005",  # Kaztal
      district == "\u0416\u0430\u043d\u0430\u043a\u0430\u043b\u0430"  ~ "KAZ020012",  # Zhanakala
      district == "\u0416\u0430\u043d\u0438\u0431\u0435\u043a"   ~ "KAZ020013",  # Zhanybek
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

cat(
  "Rows:",
  nrow(final_panel),
  "\n"
)

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
#
# NDVI = May–September
# Climate = April–October
# ------------------------------------------------------------

output_csv <-
  "data/processed/Panel_RRUI_NDVI_MaySep_Climate_AprOct_Livestock.csv"

output_xlsx <-
  "data/processed/Panel_RRUI_NDVI_MaySep_Climate_AprOct_Livestock.xlsx"

write_csv(
  final_panel,
  output_csv
)

write.xlsx(
  final_panel,
  output_xlsx,
  overwrite = TRUE
)


# ------------------------------------------------------------
# 17. Verify saved files
# ------------------------------------------------------------

cat("\n===== FILES SAVED =====\n")

cat(
  "CSV:",
  file.exists(output_csv),
  "\n"
)

cat(
  "XLSX:",
  file.exists(output_xlsx),
  "\n"
)

stopifnot(
  file.exists(output_csv),
  file.exists(output_xlsx)
)

cat(
  "\n15_build_final_panel.R completed successfully.\n"
)