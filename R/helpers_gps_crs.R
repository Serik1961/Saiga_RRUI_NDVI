# ============================================================
# helpers_gps_crs.R   (new in v1.3.1)
#
# The GPS route layer is stored in WGS 84 / UTM zone 38N but carries a
# non-standard CRS identifier. Instead of blindly overwriting the CRS with
# st_set_crs(), the layer is checked and, if necessary, transformed.
# ============================================================

standardise_route_crs <- function(routes, target_epsg = 32638) {

  crs_src <- sf::st_crs(routes)

  if (is.na(crs_src)) {
    stop(
      "The GPS route layer has no CRS. Add the .prj file of the source ",
      "shapefile; a CRS must not be assumed.",
      call. = FALSE
    )
  }

  is_target <- isTRUE(crs_src$epsg == target_epsg) ||
    grepl("UTM zone 38N", crs_src$wkt, ignore.case = TRUE)

  if (is_target) {
    # Coordinates are already in WGS 84 / UTM 38N: only the identifier is
    # standardised (no coordinate change), after checking the CRS metadata.
    message("GPS routes: source CRS is WGS 84 / UTM zone 38N; identifier set to EPSG:", target_epsg)
    routes <- sf::st_set_crs(routes, target_epsg)
  } else {
    message("GPS routes: source CRS differs from EPSG:", target_epsg, "; transforming.")
    routes <- sf::st_transform(routes, target_epsg)
  }

  # Plausibility check of the coordinates (metres, West Kazakhstan)
  bb <- sf::st_bbox(routes)
  ok <- bb["xmin"] > 1e5 && bb["xmax"] < 1.5e6 &&
        bb["ymin"] > 4.8e6 && bb["ymax"] < 6.0e6
  if (!isTRUE(ok)) {
    stop(
      "GPS route coordinates are outside the plausible UTM 38N range for ",
      "West Kazakhstan; check the source CRS.",
      call. = FALSE
    )
  }

  routes
}
