# ============================================================
# SAIGA RRUI–NDVI PROJECT
# 04_ndvi_preprocessing.R
# NDVI April–October, 2012–2024
# ============================================================

library(dplyr)
library(readr)


# ------------------------------------------------------------
# 1. Поиск NDVI-файла
# ------------------------------------------------------------

ndvi_files <- list.files(
  "data/raw/ndvi",
  full.names = TRUE
)

cat("\n===== NDVI FILES =====\n")
print(ndvi_files)


# ------------------------------------------------------------
# 2. Проверка количества файлов
# ------------------------------------------------------------

stopifnot(length(ndvi_files) == 1)

ndvi_file <- ndvi_files[1]

cat("\nFile used:\n")
cat(ndvi_file, "\n")


# ------------------------------------------------------------
# 3. Чтение файла
# ------------------------------------------------------------

ndvi_raw <- read_csv(
  ndvi_file,
  show_col_types = FALSE
)


# ------------------------------------------------------------
# 4. Первичная проверка
# ------------------------------------------------------------

cat("\n===== NDVI DIMENSIONS =====\n")
cat("Rows:", nrow(ndvi_raw), "\n")
cat("Columns:", ncol(ndvi_raw), "\n")

cat("\n===== NDVI COLUMN NAMES =====\n")
print(names(ndvi_raw))

cat("\n===== NDVI STRUCTURE =====\n")
str(ndvi_raw)

cat("\n===== FIRST 10 ROWS =====\n")
print(head(ndvi_raw, 10))
# ------------------------------------------------------------
# 5. Приведение типов
# ------------------------------------------------------------

ndvi <- ndvi_raw %>%
  mutate(
    Year = as.integer(Year),
    NDVI = as.numeric(NDVI)
  )


# ------------------------------------------------------------
# 6. Проверка годов
# ------------------------------------------------------------

cat("\n===== YEARS =====\n")
print(sort(unique(ndvi$Year)))

cat(
  "Year range:",
  min(ndvi$Year),
  "-",
  max(ndvi$Year),
  "\n"
)


# ------------------------------------------------------------
# 7. Число наблюдений по годам
# ------------------------------------------------------------

ndvi_by_year <- ndvi %>%
  count(Year, name = "N_districts")

cat("\n===== DISTRICTS BY YEAR =====\n")
print(ndvi_by_year)


# ------------------------------------------------------------
# 8. Число наблюдений по районам
# ------------------------------------------------------------

ndvi_by_district <- ndvi %>%
  count(
    ADM2_PCODE,
    ADM2_EN,
    name = "N_years"
  )

cat("\n===== YEARS BY DISTRICT =====\n")
print(ndvi_by_district)


# ------------------------------------------------------------
# 9. Проверка дублей district × year
# ------------------------------------------------------------

duplicates <- ndvi %>%
  count(
    Year,
    ADM2_PCODE,
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
# 10. Проверка пропущенных значений
# ------------------------------------------------------------

cat("\n===== MISSING VALUES =====\n")

cat(
  "Missing Year:",
  sum(is.na(ndvi$Year)),
  "\n"
)

cat(
  "Missing district PCODE:",
  sum(is.na(ndvi$ADM2_PCODE)),
  "\n"
)

cat(
  "Missing NDVI:",
  sum(is.na(ndvi$NDVI)),
  "\n"
)


# ------------------------------------------------------------
# 11. Диапазон NDVI
# ------------------------------------------------------------

cat("\n===== NDVI SUMMARY =====\n")
print(summary(ndvi$NDVI))

cat(
  "\nNDVI outside [-1, 1]:",
  sum(ndvi$NDVI < -1 | ndvi$NDVI > 1, na.rm = TRUE),
  "\n"
)


# ------------------------------------------------------------
# 12. Жёсткая проверка панели
# ------------------------------------------------------------

stopifnot(
  nrow(ndvi) == 65,
  n_distinct(ndvi$Year) == 13,
  n_distinct(ndvi$ADM2_PCODE) == 5,
  all(ndvi_by_year$N_districts == 5),
  all(ndvi_by_district$N_years == 13),
  nrow(duplicates) == 0,
  !anyNA(ndvi$NDVI),
  all(ndvi$NDVI >= -1 & ndvi$NDVI <= 1)
)

cat("\nNDVI panel validation completed successfully.\n")