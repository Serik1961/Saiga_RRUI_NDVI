# ============================================================
# SAIGA RRUI–NDVI PROJECT
# 01_gps_preprocessing.R
# Initial inspection of GPS route data
# ============================================================

library(sf)
library(dplyr)

# ------------------------------------------------------------
# 1. Чтение исходных маршрутов
# ------------------------------------------------------------

routes <- st_read(
  "data/raw/gps/Kazakhstan_Saiga_Ural_Routes.shp",
  quiet = TRUE
)

# ------------------------------------------------------------
# 2. Основная структура
# ------------------------------------------------------------

cat("\n===== NUMBER OF SPATIAL RECORDS =====\n")
print(nrow(routes))

cat("\n===== COLUMN NAMES =====\n")
print(names(routes))

cat("\n===== CRS =====\n")
print(st_crs(routes))

cat("\n===== GEOMETRY TYPES =====\n")
print(table(st_geometry_type(routes)))

cat("\n===== DATA STRUCTURE =====\n")
print(str(st_drop_geometry(routes)))

# ------------------------------------------------------------
# 3. Первые записи
# ------------------------------------------------------------

cat("\n===== FIRST 10 RECORDS =====\n")
print(
  head(
    st_drop_geometry(routes),
    10
  )
)
# ------------------------------------------------------------
# 4. Проверка ID и IndYear
# ------------------------------------------------------------

cat("\n===== UNIQUE ANIMAL IDs =====\n")
print(n_distinct(routes$ID))

cat("\n===== UNIQUE IndYear =====\n")
print(n_distinct(routes$IndYear))


# ------------------------------------------------------------
# 5. Извлекаем год из IndYear
# ------------------------------------------------------------

routes_check <- routes %>%
  mutate(
    Year = as.integer(sub(".*_", "", IndYear))
  )


# ------------------------------------------------------------
# 6. Диапазон лет
# ------------------------------------------------------------

cat("\n===== YEAR RANGE =====\n")
print(range(routes_check$Year, na.rm = TRUE))

cat("\n===== YEARS PRESENT =====\n")
print(sort(unique(routes_check$Year)))


# ------------------------------------------------------------
# 7. Число spatial records по годам
# ------------------------------------------------------------

records_by_year <- routes_check %>%
  st_drop_geometry() %>%
  count(Year, name = "N_records")

cat("\n===== SPATIAL RECORDS BY YEAR =====\n")
print(records_by_year)


# ------------------------------------------------------------
# 8. Число уникальных IndYear по годам
# ------------------------------------------------------------

indyear_by_year <- routes_check %>%
  st_drop_geometry() %>%
  group_by(Year) %>%
  summarise(
    N_IndYear = n_distinct(IndYear),
    .groups = "drop"
  )

cat("\n===== UNIQUE IndYear BY YEAR =====\n")
print(indyear_by_year)


# ------------------------------------------------------------
# 9. Сравниваем records и IndYear
# ------------------------------------------------------------

year_check <- left_join(
  records_by_year,
  indyear_by_year,
  by = "Year"
) %>%
  mutate(
    Difference = N_records - N_IndYear
  )

cat("\n===== RECORDS vs IndYear =====\n")
print(year_check)
# ------------------------------------------------------------
# 10. Объединение сегментов одного animal-year route
# ------------------------------------------------------------

routes_indyear <- routes_check %>%
  group_by(ID, IndYear, Year) %>%
  summarise(
    geometry = st_union(geometry),
    .groups = "drop"
  )


# ------------------------------------------------------------
# 11. Проверка результата
# ------------------------------------------------------------

cat("\n===== ROUTES AFTER DISSOLVE BY IndYear =====\n")
cat("Number of routes:", nrow(routes_indyear), "\n")
cat("Unique IndYear:", n_distinct(routes_indyear$IndYear), "\n")
cat("Unique animals:", n_distinct(routes_indyear$ID), "\n")

cat("\n===== ROUTES BY YEAR AFTER DISSOLVE =====\n")

routes_after_dissolve <- routes_indyear %>%
  st_drop_geometry() %>%
  count(Year, name = "N_routes")

print(routes_after_dissolve)


# ------------------------------------------------------------
# 12. Проверка геометрии
# ------------------------------------------------------------

cat("\n===== GEOMETRY TYPES AFTER DISSOLVE =====\n")
print(table(st_geometry_type(routes_indyear)))

cat("\n===== VALID GEOMETRIES =====\n")
print(table(st_is_valid(routes_indyear)))
# ------------------------------------------------------------
# 13. Сохранение подготовленных animal-year routes
# ------------------------------------------------------------

st_write(
  routes_indyear,
  "data/intermediate/gps_routes_indyear.gpkg",
  delete_dsn = TRUE,
  quiet = TRUE
)

cat("\n===== FILE SAVED =====\n")
cat("data/intermediate/gps_routes_indyear.gpkg\n")

# Проверяем, что файл действительно создан
cat(
  "File exists:",
  file.exists("data/intermediate/gps_routes_indyear.gpkg"),
  "\n"
)