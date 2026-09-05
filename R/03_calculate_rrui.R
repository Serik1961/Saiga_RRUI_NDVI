# ============================================================
# SAIGA RRUI–NDVI PROJECT
# 03_calculate_rrui.R
# Calculation of Relative Route Use Index (RRUI)
# ============================================================

library(sf)
library(dplyr)
library(tidyr)


# ------------------------------------------------------------
# 1. Чтение подготовленных animal-year routes
# ------------------------------------------------------------

routes <- st_read(
  "data/intermediate/gps_routes_indyear.gpkg",
  quiet = TRUE
)

# GPS coordinates are WGS84 / UTM zone 38N
routes <- st_set_crs(routes, 32638)


# ------------------------------------------------------------
# 2. Чтение исходных ADM2
# ------------------------------------------------------------

districts_raw <- st_read(
  "data/raw/boundaries/kaz_admbnda_adm2_unhcr_2023.shp",
  quiet = TRUE
)


# ------------------------------------------------------------
# 3. Выбор пяти районов
# ------------------------------------------------------------

study_pcodes <- c(
  "KAZ020001",  # Akzhaik
  "KAZ020002",  # Bokey Orda
  "KAZ020005",  # Kaztal
  "KAZ020012",  # Zhanakala
  "KAZ020013"   # Zhanybek
)

districts <- districts_raw %>%
  filter(ADM2_PCODE %in% study_pcodes) %>%
  select(
    ADM2_PCODE,
    ADM2_EN,
    geometry
  ) %>%
  st_transform(32638)


# ------------------------------------------------------------
# 4. Контроль входных данных
# ------------------------------------------------------------

stopifnot(nrow(routes) == 113)
stopifnot(nrow(districts) == 5)
stopifnot(st_crs(routes) == st_crs(districts))
stopifnot(all(st_is_valid(routes)))
stopifnot(all(st_is_valid(districts)))

cat("\n===== INPUT CHECK =====\n")
cat("Animal-year routes:", nrow(routes), "\n")
cat("Study districts:", nrow(districts), "\n")
cat("CRS:", st_crs(routes)$epsg, "\n")
# ------------------------------------------------------------
# 5. Пересечение маршрутов с районами
# ------------------------------------------------------------

route_district_segments <- st_intersection(
  routes,
  districts
)

cat("\n===== INTERSECTION =====\n")
cat(
  "Route-district segments:",
  nrow(route_district_segments),
  "\n"
)

cat(
  "Unique IndYear after intersection:",
  n_distinct(route_district_segments$IndYear),
  "\n"
)
# ------------------------------------------------------------
# 6. Длина маршрута внутри каждого района
# ------------------------------------------------------------

route_district_segments$length_m <- as.numeric(
  st_length(route_district_segments)
)

cat("\n===== LENGTH CHECK =====\n")

print(
  summary(route_district_segments$length_m)
)

cat(
  "\nZero-length segments:",
  sum(route_district_segments$length_m <= 0),
  "\n"
)
# ------------------------------------------------------------
# 7. L_ijt:
# длина animal-year route j в районе i в году t
# ------------------------------------------------------------

L_ijt <- route_district_segments %>%
  st_drop_geometry() %>%
  group_by(
    Year,
    IndYear,
    ADM2_PCODE,
    ADM2_EN
  ) %>%
  summarise(
    L_ijt_m = sum(length_m),
    .groups = "drop"
  )

cat("\n===== L_ijt =====\n")

cat(
  "Number of route-district combinations:",
  nrow(L_ijt),
  "\n"
)

print(head(L_ijt, 20))
# ------------------------------------------------------------
# 8. Общая длина маршрута j в пределах study area
#    L_study_jt = sum_i L_ijt
# ------------------------------------------------------------

L_jt <- L_ijt %>%
  group_by(
    Year,
    IndYear
  ) %>%
  summarise(
    L_study_jt_m = sum(L_ijt_m),
    .groups = "drop"
  )

cat("\n===== L_study_jt =====\n")
cat("Number of animal-year routes:", nrow(L_jt), "\n")

print(summary(L_jt$L_study_jt_m))


# ------------------------------------------------------------
# 9. Индивидуальная доля маршрута p_ijt
# ------------------------------------------------------------

p_ijt <- L_ijt %>%
  left_join(
    L_jt,
    by = c("Year", "IndYear")
  ) %>%
  mutate(
    p_ijt = L_ijt_m / L_study_jt_m
  )


# ------------------------------------------------------------
# 10. Базовая проверка p_ijt
# ------------------------------------------------------------

cat("\n===== p_ijt RANGE =====\n")
print(summary(p_ijt$p_ijt))

cat(
  "\nAny p_ijt < 0:",
  any(p_ijt$p_ijt < 0),
  "\n"
)

cat(
  "Any p_ijt > 1:",
  any(p_ijt$p_ijt > 1),
  "\n"
)


# ------------------------------------------------------------
# 11. Проверка:
#     для каждого IndYear сумма p_ijt должна быть равна 1
# ------------------------------------------------------------

p_check <- p_ijt %>%
  group_by(
    Year,
    IndYear
  ) %>%
  summarise(
    sum_p = sum(p_ijt),
    .groups = "drop"
  ) %>%
  mutate(
    deviation_from_1 = abs(sum_p - 1)
  )

cat("\n===== INDIVIDUAL SHARE SUM CHECK =====\n")

print(
  summary(p_check$sum_p)
)

cat(
  "\nMaximum deviation from 1:",
  max(p_check$deviation_from_1),
  "\n"
)

cat(
  "Routes failing tolerance 1e-10:",
  sum(p_check$deviation_from_1 > 1e-10),
  "\n"
)


# ------------------------------------------------------------
# 12. Жёсткая проверка
# ------------------------------------------------------------

stopifnot(
  all(p_ijt$p_ijt >= 0),
  all(p_ijt$p_ijt <= 1),
  all(p_check$deviation_from_1 < 1e-10),
  nrow(p_check) == 113
)

cat("\nIndividual route shares validated successfully.\n")
# ------------------------------------------------------------
# 13. Полная матрица animal-year × district
#
# Для непосещённых районов p_ijt = 0.
# Это необходимо, поскольку RRUI усредняется по ВСЕМ
# животным с доступным маршрутом в соответствующем году.
# ------------------------------------------------------------

animal_years <- routes %>%
  st_drop_geometry() %>%
  select(
    Year,
    IndYear
  ) %>%
  distinct()

district_list <- districts %>%
  st_drop_geometry() %>%
  select(
    ADM2_PCODE,
    ADM2_EN
  ) %>%
  distinct()


p_ijt_complete <- tidyr::crossing(
  animal_years,
  district_list
) %>%
  left_join(
    p_ijt %>%
      select(
        Year,
        IndYear,
        ADM2_PCODE,
        p_ijt
      ),
    by = c(
      "Year",
      "IndYear",
      "ADM2_PCODE"
    )
  ) %>%
  mutate(
    p_ijt = replace_na(p_ijt, 0)
  )


# ------------------------------------------------------------
# 14. Проверка полной матрицы
# ------------------------------------------------------------

cat("\n===== COMPLETE ANIMAL × DISTRICT MATRIX =====\n")

cat(
  "Expected rows:",
  113 * 5,
  "\n"
)

cat(
  "Actual rows:",
  nrow(p_ijt_complete),
  "\n"
)

cat(
  "Missing p_ijt:",
  sum(is.na(p_ijt_complete$p_ijt)),
  "\n"
)


# ------------------------------------------------------------
# 15. Повторная проверка суммы индивидуальных долей
# ------------------------------------------------------------

complete_check <- p_ijt_complete %>%
  group_by(
    Year,
    IndYear
  ) %>%
  summarise(
    sum_p = sum(p_ijt),
    .groups = "drop"
  )

cat("\n===== COMPLETE SHARE CHECK =====\n")

print(summary(complete_check$sum_p))

cat(
  "Maximum deviation from 1:",
  max(abs(complete_check$sum_p - 1)),
  "\n"
)

stopifnot(
  nrow(p_ijt_complete) == 565,
  all(abs(complete_check$sum_p - 1) < 1e-10)
)
# ------------------------------------------------------------
# 16. Расчёт RRUI_it
#
# RRUI_it = (1 / N_t) * sum_j(p_ijt)
# ------------------------------------------------------------

rrui <- p_ijt_complete %>%
  group_by(
    Year,
    ADM2_PCODE,
    ADM2_EN
  ) %>%
  summarise(
    N_t = n(),
    RRUI = mean(p_ijt),
    .groups = "drop"
  ) %>%
  arrange(
    Year,
    ADM2_PCODE
  )


cat("\n===== RRUI RESULTS =====\n")
print(rrui)


# ------------------------------------------------------------
# 17. Проверка N_t по годам
# ------------------------------------------------------------

N_check <- rrui %>%
  group_by(Year) %>%
  summarise(
    N_t_min = min(N_t),
    N_t_max = max(N_t),
    .groups = "drop"
  )

cat("\n===== N_t BY YEAR =====\n")
print(N_check)


# ------------------------------------------------------------
# 18. Проверка суммы RRUI по пяти районам
# ------------------------------------------------------------

rrui_check <- rrui %>%
  group_by(Year) %>%
  summarise(
    Sum_RRUI = sum(RRUI),
    .groups = "drop"
  ) %>%
  mutate(
    deviation_from_1 = abs(Sum_RRUI - 1)
  )

cat("\n===== RRUI SUM CHECK =====\n")
print(rrui_check)


# ------------------------------------------------------------
# 19. Финальная автоматическая проверка
# ------------------------------------------------------------

stopifnot(
  nrow(rrui) == 65,
  all(rrui$RRUI >= 0),
  all(rrui$RRUI <= 1),
  all(rrui_check$deviation_from_1 < 1e-10)
)
cat("\nRRUI validation completed successfully.\n")
# ------------------------------------------------------------
# 20. Сохранение итогового RRUI
# ------------------------------------------------------------

dir.create(
  "data/processed",
  recursive = TRUE,
  showWarnings = FALSE
)

write.csv(
  rrui,
  "data/processed/RRUI_2012_2024.csv",
  row.names = FALSE
)

openxlsx::write.xlsx(
  rrui,
  "data/processed/RRUI_2012_2024.xlsx",
  overwrite = TRUE
)

cat("\n===== RRUI FILES SAVED =====\n")

cat(
  "CSV:",
  file.exists("data/processed/RRUI_2012_2024.csv"),
  "\n"
)

cat(
  "XLSX:",
  file.exists("data/processed/RRUI_2012_2024.xlsx"),
  "\n"
)

cat(
  "Rows saved:",
  nrow(rrui),
  "\n"
)
