# ============================================================
# SAIGA RRUI–NDVI PROJECT
# 02_boundaries_preprocessing.R
# Initial inspection of ADM2 boundaries
# ============================================================

library(sf)
library(dplyr)

# ------------------------------------------------------------
# 1. Чтение исходных ADM2
# ------------------------------------------------------------

districts_raw <- st_read(
  "data/raw/boundaries/kaz_admbnda_adm2_unhcr_2023.shp",
  quiet = TRUE
)


# ------------------------------------------------------------
# 2. Основная структура
# ------------------------------------------------------------

cat("\n===== NUMBER OF ADM2 FEATURES =====\n")
print(nrow(districts_raw))

cat("\n===== COLUMN NAMES =====\n")
print(names(districts_raw))

cat("\n===== CRS =====\n")
print(st_crs(districts_raw))

cat("\n===== GEOMETRY TYPES =====\n")
print(table(st_geometry_type(districts_raw)))

cat("\n===== VALID GEOMETRIES =====\n")
print(table(st_is_valid(districts_raw)))


# ------------------------------------------------------------
# 3. Атрибутивные данные
# ------------------------------------------------------------

cat("\n===== DATA STRUCTURE =====\n")
str(st_drop_geometry(districts_raw))

cat("\n===== FIRST 10 RECORDS =====\n")
print(
  head(
    st_drop_geometry(districts_raw),
    10
  )
)
# ------------------------------------------------------------
# 4. Районы Западно-Казахстанской области
# ------------------------------------------------------------

wko_districts <- districts_raw %>%
  filter(ADM1_EN == "West Kazakhstan Region") %>%
  st_drop_geometry() %>%
  select(
    ADM1_EN,
    ADM2_EN,
    ADM2_PCODE
  ) %>%
  arrange(ADM2_EN)

cat("\n===== WEST KAZAKHSTAN REGION: ADM2 =====\n")
print(wko_districts)
# ------------------------------------------------------------
# 5. Выбор пяти исследуемых районов
# ------------------------------------------------------------

study_pcodes <- c(
  "KAZ020001",  # Akzhaik
  "KAZ020002",  # Bokey Orda
  "KAZ020005",  # Kaztal
  "KAZ020012",  # Zhanakala
  "KAZ020013"   # Zhanybek
)

districts_5 <- districts_raw %>%
  filter(ADM2_PCODE %in% study_pcodes) %>%
  select(
    ADM2_PCODE,
    ADM2_EN,
    geometry
  ) %>%
  arrange(ADM2_PCODE)


# ------------------------------------------------------------
# 6. Контроль выбора
# ------------------------------------------------------------

cat("\n===== FIVE STUDY DISTRICTS =====\n")
print(st_drop_geometry(districts_5))

cat("\nNumber of districts:", nrow(districts_5), "\n")

cat("\nAll requested PCODEs found:",
    setequal(districts_5$ADM2_PCODE, study_pcodes),
    "\n")

cat("\nValid geometries:\n")
print(table(st_is_valid(districts_5)))
# ------------------------------------------------------------
# 7. Чтение подготовленных animal-year routes
# ------------------------------------------------------------

routes_indyear <- st_read(
  "data/intermediate/gps_routes_indyear.gpkg",
  quiet = TRUE
)

cat("\n===== ROUTES READ FROM INTERMEDIATE FILE =====\n")
cat("Number of routes:", nrow(routes_indyear), "\n")


# ------------------------------------------------------------
# 8. Приведение GPS и районов к единой метрической CRS
# ------------------------------------------------------------

# Исходные GPS-маршруты имеют координаты
# WGS 84 / UTM zone 38N.
# Присваиваем стандартный идентификатор EPSG:32638.
# Координаты при этом НЕ пересчитываются.

routes_utm <- st_set_crs(
  routes_indyear,
  32638
)

# Исходные границы районов находятся в EPSG:3857.
# Здесь координаты действительно преобразуются в EPSG:32638.

districts_5_utm <- st_transform(
  districts_5,
  32638
)


# ------------------------------------------------------------
# 9. Проверка CRS
# ------------------------------------------------------------

cat("\n===== CRS CHECK =====\n")

cat(
  "GPS EPSG:",
  st_crs(routes_utm)$epsg,
  "\n"
)

cat(
  "District EPSG:",
  st_crs(districts_5_utm)$epsg,
  "\n"
)

cat(
  "Same CRS:",
  st_crs(routes_utm) == st_crs(districts_5_utm),
  "\n"
)


# ------------------------------------------------------------
# 10. Проверка пространственного диапазона
# ------------------------------------------------------------

cat("\n===== GPS BOUNDING BOX =====\n")
print(st_bbox(routes_utm))

cat("\n===== DISTRICTS BOUNDING BOX =====\n")
print(st_bbox(districts_5_utm))


# ------------------------------------------------------------
# 11. Проверка пересечения маршрутов с 5 районами
# ------------------------------------------------------------

inside_check <- lengths(
  st_intersects(
    routes_utm,
    districts_5_utm
  )
) > 0


cat("\n===== ROUTE COVERAGE =====\n")

cat(
  "Total animal-year routes:",
  nrow(routes_utm),
  "\n"
)

cat(
  "Routes intersecting 5 districts:",
  sum(inside_check),
  "\n"
)

cat(
  "Routes completely outside:",
  sum(!inside_check),
  "\n"
)


# ------------------------------------------------------------
# 12. Проверка покрытия по годам
# ------------------------------------------------------------

coverage_by_year <- routes_utm %>%
  mutate(
    inside_study_area = inside_check
  ) %>%
  st_drop_geometry() %>%
  group_by(Year) %>%
  summarise(
    N_total   = n(),
    N_inside  = sum(inside_study_area),
    N_outside = sum(!inside_study_area),
    .groups = "drop"
  )

cat("\n===== COVERAGE BY YEAR =====\n")
print(coverage_by_year)


# ------------------------------------------------------------
# 13. Список маршрутов полностью вне 5 районов
# ------------------------------------------------------------

routes_outside <- routes_utm %>%
  mutate(
    inside_study_area = inside_check
  ) %>%
  filter(!inside_study_area) %>%
  st_drop_geometry() %>%
  select(
    ID,
    IndYear,
    Year
  ) %>%
  arrange(
    Year,
    ID
  )

cat("\n===== ROUTES COMPLETELY OUTSIDE =====\n")
print(routes_outside)