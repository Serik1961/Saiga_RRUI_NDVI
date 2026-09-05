# ============================================================
# SAIGA RRUI–NDVI PROJECT
# 05_build_panel.R
# Merge RRUI and NDVI panel
# ============================================================

library(dplyr)
library(readr)
library(openxlsx)


# ------------------------------------------------------------
# 1. Чтение RRUI
# ------------------------------------------------------------

rrui <- read_csv(
  "data/processed/RRUI_2012_2024.csv",
  show_col_types = FALSE
) %>%
  mutate(
    Year = as.integer(Year)
  )


# ------------------------------------------------------------
# 2. Чтение NDVI April–October
# ------------------------------------------------------------

ndvi <- read_csv(
  "data/raw/ndvi/Saiga_NDVI_MOD13Q1_2012_2024_okt.csv",
  show_col_types = FALSE
) %>%
  mutate(
    Year = as.integer(Year)
  )


# ------------------------------------------------------------
# 3. Проверка ключей перед объединением
# ------------------------------------------------------------

stopifnot(
  nrow(rrui) == 65,
  nrow(ndvi) == 65
)

cat("\n===== INPUT =====\n")
cat("RRUI rows:", nrow(rrui), "\n")
cat("NDVI rows:", nrow(ndvi), "\n")


# ------------------------------------------------------------
# 4. Объединение
# ------------------------------------------------------------

panel <- rrui %>%
  select(
    Year,
    ADM2_PCODE,
    ADM2_EN,
    N_t,
    RRUI
  ) %>%
  left_join(
    ndvi %>%
      select(
        Year,
        ADM2_PCODE,
        NDVI
      ),
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
# 5. Проверка результата
# ------------------------------------------------------------

cat("\n===== MERGED PANEL =====\n")
cat("Rows:", nrow(panel), "\n")
cat("Districts:", n_distinct(panel$ADM2_PCODE), "\n")
cat("Years:", n_distinct(panel$Year), "\n")

cat("\nMissing RRUI:", sum(is.na(panel$RRUI)), "\n")
cat("Missing NDVI:", sum(is.na(panel$NDVI)), "\n")

print(head(panel, 15))


# ------------------------------------------------------------
# 6. Проверка уникальности district-year
# ------------------------------------------------------------

duplicates <- panel %>%
  count(
    Year,
    ADM2_PCODE
  ) %>%
  filter(n > 1)

cat("\n===== DUPLICATES =====\n")
print(duplicates)


# ------------------------------------------------------------
# 7. Проверка суммы RRUI
# ------------------------------------------------------------

rrui_check <- panel %>%
  group_by(Year) %>%
  summarise(
    Sum_RRUI = sum(RRUI),
    .groups = "drop"
  )

cat("\n===== RRUI SUM CHECK =====\n")
print(rrui_check)


# ------------------------------------------------------------
# 8. Финальная проверка
# ------------------------------------------------------------

stopifnot(
  nrow(panel) == 65,
  n_distinct(panel$ADM2_PCODE) == 5,
  n_distinct(panel$Year) == 13,
  nrow(duplicates) == 0,
  !anyNA(panel$RRUI),
  !anyNA(panel$NDVI),
  all(abs(rrui_check$Sum_RRUI - 1) < 1e-10)
)

cat("\nBase RRUI-NDVI panel validated successfully.\n")


# ------------------------------------------------------------
# 9. Сохранение панели
# ------------------------------------------------------------

write_csv(
  panel,
  "data/processed/Panel_RRUI_NDVI_AprOct.csv"
)

write.xlsx(
  panel,
  "data/processed/Panel_RRUI_NDVI_AprOct.xlsx",
  overwrite = TRUE
)

cat("\n===== PANEL FILES SAVED =====\n")

cat(
  "CSV:",
  file.exists("data/processed/Panel_RRUI_NDVI_AprOct.csv"),
  "\n"
)

cat(
  "XLSX:",
  file.exists("data/processed/Panel_RRUI_NDVI_AprOct.xlsx"),
  "\n"
)
