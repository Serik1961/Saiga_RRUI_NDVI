# ============================================================
# SAIGA RRUI-NDVI PROJECT
# 22_selfcheck.R   (new in v1.3.1)
#
# Internal consistency checks that would have caught the v1.3.0 problems.
# ============================================================

library(dplyr)
library(readr)
library(fixest)

source("R/helpers_inference.R")

p3 <- read_panel("data/processed/Panel_RRUI_NDVI_MaySep_Climate_AprOct_Livestock.csv")
ok <- function(cond, msg) {
  cat(sprintf("%-78s %s\n", msg, if (isTRUE(cond)) "PASS" else "FAIL"))
  if (!isTRUE(cond)) stop("Self-check failed: ", msg, call. = FALSE)
}

# 1. Design
ok(nrow(p3) == 65 && n_distinct(p3$ADM2_PCODE) == 5 && n_distinct(p3$Year) == 13,
   "Balanced 5 x 13 panel")
ok(all(abs(tapply(p3$RRUI, p3$Year, sum) - 1) < 1e-9),
   "RRUI sums to 1 across the five districts in every year")

# 1b. District-name crosswalk matches the panel
cw <- read_csv("data/district_crosswalk.csv", show_col_types = FALSE)
pn <- p3 %>% distinct(ADM2_PCODE, ADM2_EN) %>% arrange(ADM2_PCODE)
ok(identical(sort(cw$ADM2_PCODE), sort(pn$ADM2_PCODE)) &&
     all(cw$ADM2_EN_unhcr_shapefile[match(pn$ADM2_PCODE, cw$ADM2_PCODE)] == pn$ADM2_EN),
   "District crosswalk (data/district_crosswalk.csv) matches the panel codes and names")

# 2. Livestock units use the Eurostat coefficients stated in the manuscript
lu <- readxl::read_excel(list.files("data/raw/livestock", pattern = "xlsx$", full.names = TRUE)[1], sheet = 1)
names(lu)[1:6] <- c("district", "Date", "cattle", "sheep_goats", "horses", "LU_file")
lu <- lu %>% mutate(Year = as.integer(format(as.Date(Date), "%Y"))) %>% filter(Year >= 2012, Year <= 2024)
ok(abs(sum(lu$cattle + 0.1 * lu$sheep_goats + 0.8 * lu$horses) - sum(p3$Livestock_units)) < 1e-6,
   "Panel livestock units = cattle + 0.1*sheep/goats + 0.8*horses (thousand LSU)")

# 3. fixest (absorbed FE) and explicit-dummy coefficients coincide
m_abs <- feols(NDVI ~ RRUI + precip_mm + temp_c + Livestock_units | ADM2_PCODE + Year, data = p3)
m_lm  <- lm(twfe_formula(c("RRUI", "precip_mm", "temp_c", "Livestock_units")), data = p3)
ok(abs(coef(m_abs)["RRUI"] - coef(m_lm)["RRUI"]) < 1e-10,
   "RRUI coefficient identical: absorbed-FE vs. explicit-dummy model")

# 4. CR2: Satterthwaite df plausible (not ~1.0)
cr2 <- cr2_lsdv(p3, c("RRUI", "precip_mm", "temp_c", "Livestock_units"))
ok(all(cr2$df_Satt > 1.05 & cr2$df_Satt < 4),
   "CR2 Satterthwaite df between 1.05 and 4 for all coefficients")
ok(cr2$SE[cr2$Variable == "temp_c"] < 5 * sqrt(vcov(m_abs, vcov = ~ADM2_PCODE)["temp_c", "temp_c"]),
   "CR2 SE of temperature within 5x of cluster-robust SE (v1.3.0: 25x)")

# 5. Exact WCB: full enumeration and exact ties
w <- wcb_exact(p3, c("RRUI", "precip_mm", "temp_c", "Livestock_units"))
ok(w$N_draws[1] == 32 && w$N_draws[2] == 7776, "WCB draws: 2^5 = 32 and 6^5 = 7,776")
ok(all(w$N_ties == c(2, 6)), "Constant weight vectors tie with observed statistic (2 Rademacher, 6 Webb)")
ok(all(w$P_value >= w$P_value_strict), "Tie-inclusive p >= strict p")

# 6. Results tables are in sync with the analysis
art <- read_csv("results/tables/19_article_RRUI_table.csv", show_col_types = FALSE)
ok(abs(art$CR2_p[3] - cr2$p_Satt[1]) < 1e-9 && abs(art$WCB_Webb_p[3] - w$P_value[2]) < 1e-9,
   "Table 7 (M3) equals a fresh recomputation")

cat("\nAll self-checks passed.\n")
