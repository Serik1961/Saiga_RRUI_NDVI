# ============================================================
# SAIGA RRUI–NDVI PROJECT
# 14_livestock_preprocessing.R
#
# Livestock data preprocessing
# ============================================================


# ------------------------------------------------------------
# 1. Packages
# ------------------------------------------------------------

library(dplyr)
library(readxl)


# ------------------------------------------------------------
# 2. Find livestock file
# ------------------------------------------------------------

livestock_files <- list.files(
  "data/raw/livestock",
  full.names = TRUE
)

cat("\n===== LIVESTOCK FILES =====\n")
print(livestock_files)

stopifnot(
  length(livestock_files) >= 1
)

livestock_file <- livestock_files[1]

cat("\nFile used:\n")
cat(livestock_file, "\n")


# ------------------------------------------------------------
# 3. Excel sheets
# ------------------------------------------------------------

cat("\n===== EXCEL SHEETS =====\n")

sheets <- excel_sheets(
  livestock_file
)

print(sheets)


# ------------------------------------------------------------
# 4. Read first sheet
# ------------------------------------------------------------

livestock_raw <- read_excel(
  livestock_file,
  sheet = sheets[1]
)


# ------------------------------------------------------------
# 5. Dimensions
# ------------------------------------------------------------

cat("\n===== LIVESTOCK DIMENSIONS =====\n")

cat(
  "Rows:",
  nrow(livestock_raw),
  "\n"
)

cat(
  "Columns:",
  ncol(livestock_raw),
  "\n"
)


# ------------------------------------------------------------
# 6. Column names
# ------------------------------------------------------------

cat("\n===== COLUMN NAMES =====\n")

print(
  names(livestock_raw)
)


# ------------------------------------------------------------
# 7. Structure
# ------------------------------------------------------------

cat("\n===== STRUCTURE =====\n")

str(livestock_raw)


# ------------------------------------------------------------
# 8. First rows
# ------------------------------------------------------------

cat("\n===== FIRST 20 ROWS =====\n")

print(
  head(livestock_raw, 20)
)
# ------------------------------------------------------------
# 9. Подготовка года и названий переменных
# ------------------------------------------------------------

livestock <- livestock_raw %>%
  transmute(
    district = район,
    Year = as.integer(format(Дата, "%Y")),
    
    cattle_thousand =
      as.numeric(`крупный рогатый скот`),
    
    sheep_goats_thousand =
      as.numeric(`овцы и козы`),
    
    horses_thousand =
      as.numeric(лошади),
    
    livestock_units_thousand =
      as.numeric(`УсловГолов тыс. ед`)
  )


# ------------------------------------------------------------
# 10. Названия районов
# ------------------------------------------------------------

cat("\n===== DISTRICTS =====\n")
print(sort(unique(livestock$district)))


# ------------------------------------------------------------
# 11. Полный диапазон годов
# ------------------------------------------------------------

cat("\n===== FULL YEAR RANGE =====\n")

cat(
  min(livestock$Year),
  "-",
  max(livestock$Year),
  "\n"
)


# ------------------------------------------------------------
# 12. Выбор периода исследования
# ------------------------------------------------------------

livestock_study <- livestock %>%
  filter(
    Year >= 2012,
    Year <= 2024
  )


cat("\n===== STUDY PERIOD =====\n")

cat(
  "Rows:",
  nrow(livestock_study),
  "\n"
)

cat(
  "Districts:",
  n_distinct(livestock_study$district),
  "\n"
)

cat(
  "Years:",
  n_distinct(livestock_study$Year),
  "\n"
)

print(
  sort(unique(livestock_study$Year))
)


# ------------------------------------------------------------
# 13. Число лет по районам
# ------------------------------------------------------------

livestock_by_district <- livestock_study %>%
  count(
    district,
    name = "N_years"
  )

cat("\n===== YEARS BY DISTRICT =====\n")
print(livestock_by_district)


# ------------------------------------------------------------
# 14. Число районов по годам
# ------------------------------------------------------------

livestock_by_year <- livestock_study %>%
  count(
    Year,
    name = "N_districts"
  )

cat("\n===== DISTRICTS BY YEAR =====\n")
print(livestock_by_year)


# ------------------------------------------------------------
# 15. Проверка пропусков
# ------------------------------------------------------------

cat("\n===== MISSING VALUES =====\n")

cat(
  "Cattle:",
  sum(is.na(livestock_study$cattle_thousand)),
  "\n"
)

cat(
  "Sheep/goats:",
  sum(is.na(livestock_study$sheep_goats_thousand)),
  "\n"
)

cat(
  "Horses:",
  sum(is.na(livestock_study$horses_thousand)),
  "\n"
)

cat(
  "Livestock units:",
  sum(is.na(livestock_study$livestock_units_thousand)),
  "\n"
)


# ------------------------------------------------------------
# 16. Проверка дублей
# ------------------------------------------------------------

duplicates <- livestock_study %>%
  count(
    district,
    Year,
    name = "n"
  ) %>%
  filter(n > 1)

cat("\n===== DUPLICATES =====\n")
print(duplicates)


# ------------------------------------------------------------
# 17. Summary условного поголовья
# ------------------------------------------------------------

cat("\n===== LIVESTOCK UNITS SUMMARY =====\n")

print(
  summary(
    livestock_study$livestock_units_thousand
  )
)