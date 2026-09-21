## =============================================================================
## Ural Saiga RRUI-NDVI Analysis (Version 1.3.0)
## =============================================================================
## Full reproducible pipeline: raw-scale RRUI models, compositional (CLR)
## transformation, and all robustness checks reported in the manuscript.
##
## Changes from v1.2.1:
##   - Wild cluster bootstrap now uses EXACT enumeration of all 2^G (Rademacher)
##     or 6^G (Webb) cluster-weight combinations, not Monte Carlo sampling with
##     B=9999. At G=5 both spaces are small enough to enumerate fully (32 and
##     7,776 combinations respectively), which is both more efficient and
##     exact rather than approximate. This also fixes a floating-point
##     comparison bug in the Monte Carlo version: the all-ones weight vector
##     exactly reproduces the original sample, so its bootstrap statistic must
##     tie the observed one, but ~1e-16 rounding could spuriously exclude this
##     tie; a small tolerance now handles this correctly.
##   - WCB (Webb and Rademacher) is now also computed for the CLR-scale M1-M3
##     models (previously only for the raw-scale M3 model). This was the
##     single most important missing check before submission: it confirms
##     that Webb WCB (the primary variant) is significant at all three CLR
##     specifications (p=0.0249, 0.0152, 0.0054 for M1-M3), while Rademacher
##     (secondary) is capped at its coarse resolution floor of 2/32=0.0625 for
##     all three - a mechanical property of G=5, not evidence against the
##     effect, and part of why Webb is designated primary.
##
## Changes from v1.2.0:
##   - Removed a leftover dead-code fragment at the end of Section 5e that
##     still ran the old arbitrary "top-7" Cook's-distance exclusion and
##     re-fit the model on it, even though this had already been superseded
##     by the formal three-threshold sensitivity analysis in Section 5d. The
##     script now goes straight from saving the influence diagnostic CSV to
##     Section 6.
##   - Placebo-test empirical p-value now uses the standard finite-sample
##     (add-one) correction, p = (1 + #{|t_perm| >= |t_obs|}) / (B+1), instead
##     of the plain mean. This avoids a p-value of exactly zero and reflects
##     that the observed statistic is itself one of the B+1 possible draws
##     under the null; minimum attainable value at B=9999 is 1/10000 = 0.0001
##     rather than 0.
##
## Changes from v1.1.0:
##   - CR2 (Satterthwaite) is now treated as the primary inference procedure
##     throughout, with conventional cluster-robust SEs reported alongside as
##     a secondary reference (more defensible at G=5 clusters).
##   - Wild cluster bootstrap: Webb weights are now the primary variant,
##     Rademacher weights the secondary check.
##   - Placebo test increased from 200 to 9999 replications; now reports an
##     explicit empirical p-value, not only the maximum |t| under the null.
##   - District-exclusion robustness check now recomputes CLR as a genuine
##     4-part composition on the remaining districts (re-closed to sum to 1),
##     rather than dropping rows from the already-computed 5-part CLR values.
##   - Influence diagnostics now use three formal Cook's-distance thresholds
##     (4/n, 4/(n-k-1), and the classical D>1 cutoff) instead of an arbitrary
##     fixed "top-7" cutoff.
##   - Delta-sensitivity table (Table 13) now also reports CR2 SE and
##     Satterthwaite df, not only the p-value; its cluster-robust p-value
##     column was also fixed to use fixest consistently (an earlier version
##     mixed in sandwich::vcovCL here, which gives a materially different,
##     far more extreme p-value at this small cluster count).
##   - Diagnostic tables (which district-years have RRUI=0; which
##     observations are flagged as influential) are now explicitly printed
##     and saved to CSV for transparency.
##   - Removed the wildboottest Python-package dependency in favour of a
##     manual R implementation of the wild cluster bootstrap (see run_wcb()),
##     avoiding a cross-language dependency in an R script.
##
## Input : Panel_RRUI_NDVI_Climate_Livestock_SoilMoisture_AprOct.xlsx
##         (exported once to panel.csv - see "Data preparation" note below)
## Output: console tables reproducing every coefficient/SE/p-value reported
##         in Tables 3-13 of the manuscript, plus two diagnostic CSV files.
##
## Required packages (all on CRAN):
##   zCompositions, compositions, sandwich, lmtest, clubSandwich, fixest
## =============================================================================

## ---- 0. Setup ---------------------------------------------------------------

required_pkgs <- c("zCompositions", "compositions", "sandwich", "lmtest", "clubSandwich", "fixest")
invisible(lapply(required_pkgs, library, character.only = TRUE))

set.seed(12345)  # fixes zero-replacement draws, placebo test, and bootstrap replications

## Data preparation note:
## The panel is distributed as Panel_RRUI_NDVI_Climate_Livestock_SoilMoisture_AprOct.xlsx.
## Export the "Panel" sheet to panel.csv (e.g. via `openpyxl`/`pandas.read_excel(...).to_csv(...)`
## or Excel's "Save As > CSV") before running this script, to avoid an additional
## Excel-reading dependency in this repository.

df <- read.csv("panel.csv", stringsAsFactors = FALSE)
df$ADM2_PCODE <- factor(df$ADM2_PCODE)
df$Year_f     <- factor(df$Year)

cat("N rows:", nrow(df), " | N districts:", nlevels(df$ADM2_PCODE),
    " | N years:", nlevels(df$Year_f), "\n")

## ---- 1. Livestock variable: Eurostat LSU coefficients (unadjusted) -----------
## Cattle = 1.0, Sheep/goats = 0.1, Horses = 0.8 (Eurostat Glossary: Livestock unit).
## No author adjustment is applied (see Methods, Section 2.2).

df$Livestock_LSU <- df$Cattle_thous * 1.0 + df$SheepGoats_thous * 0.1 + df$Horses_thous * 0.8

stopifnot(max(abs(df$Livestock_LSU - df$LSU_EurostatBased_thous)) < 1e-9)  # sanity check
cat("\nTable 3 (livestock row): mean=", round(mean(df$Livestock_LSU), 3),
    " sd=", round(sd(df$Livestock_LSU), 3),
    " min=", round(min(df$Livestock_LSU), 3),
    " max=", round(max(df$Livestock_LSU), 3), "\n")

## ---- 2. Raw-scale TWFE models (Tables 6-11) ----------------------------------
## Point estimates and conventional cluster-robust SEs are computed with fixest
## (matching the manuscript's stated software, Section 2.5); CR2 is computed
## separately with clubSandwich, since fixest does not implement CR2 natively.

fit_twfe <- function(formula_str, data) lm(as.formula(formula_str), data = data)  # LSDV equivalent, for clubSandwich CR2 only

report_inference <- function(model_fixest, model_lm, data, varname) {
  fx <- summary(model_fixest, vcov = ~ADM2_PCODE)
  ct_fx <- fx$coeftable[varname, ]
  cr2 <- coef_test(model_lm, vcov = vcovCR(model_lm, cluster = data$ADM2_PCODE, type = "CR2"),
                    test = "Satterthwaite", coefs = varname)
  ## CR2/Satterthwaite is treated as the primary inference procedure throughout (most defensible
  ## at G=5); conventional cluster-robust SEs are reported alongside as a secondary reference.
  cat(sprintf("  %-16s beta=%9.5f  |  CR2 (primary): SE=%.5f df=%.2f p=%.4f  |  cluster-robust (secondary): SE=%.5f p=%.3f\n",
              varname, ct_fx["Estimate"],
              cr2$SE, cr2$df, cr2$p_Satt,
              ct_fx["Std. Error"], ct_fx["Pr(>|t|)"]))
}

cat("\n=== Raw-scale RRUI: M1 (base) ===\n")
m1_fx  <- feols(NDVI ~ RRUI | ADM2_PCODE + Year, data = df, vcov = ~ADM2_PCODE)
m1_raw <- fit_twfe("NDVI ~ RRUI + ADM2_PCODE + Year_f", df)  # LSDV equivalent, for clubSandwich CR2
report_inference(m1_fx, m1_raw, df, "RRUI")

cat("\n=== Raw-scale RRUI: M2 (+ climate) ===\n")
m2_fx  <- feols(NDVI ~ RRUI + precip_mm + temp_c | ADM2_PCODE + Year, data = df, vcov = ~ADM2_PCODE)
m2_raw <- fit_twfe("NDVI ~ RRUI + precip_mm + temp_c + ADM2_PCODE + Year_f", df)
for (v in c("RRUI", "precip_mm", "temp_c")) report_inference(m2_fx, m2_raw, df, v)

cat("\n=== Raw-scale RRUI: M3 (+ livestock) [Tables 9-11] ===\n")
m3_fx  <- feols(NDVI ~ RRUI + precip_mm + temp_c + Livestock_LSU | ADM2_PCODE + Year, data = df, vcov = ~ADM2_PCODE)
m3_raw <- fit_twfe("NDVI ~ RRUI + precip_mm + temp_c + Livestock_LSU + ADM2_PCODE + Year_f", df)
for (v in c("RRUI", "precip_mm", "temp_c", "Livestock_LSU")) report_inference(m3_fx, m3_raw, df, v)

## Wild cluster bootstrap for the final raw-scale model (Table 11), and reused for the CLR-scale
## models below. Implemented via EXACT enumeration of all possible cluster-weight combinations
## (Cameron, Gelbach & Miller 2008; MacKinnon & Webb 2017), not Monte Carlo sampling: with G=5
## clusters there are only 2^5=32 Rademacher combinations and 6^5=7,776 Webb combinations, both
## small enough to enumerate exactly. This is both more efficient (32 or 7,776 fits vs. 9,999
## random draws) and avoids Monte Carlo sampling noise entirely - the p-value is exact given the
## null-imposed residuals, not an approximation. A small tolerance is used when comparing |t|
## values because the all-ones (or all-minus-ones) weight vector exactly reproduces the original
## sample algebraically, so its bootstrap t-statistic must tie the observed statistic; without the
## tolerance, floating-point rounding (~1e-16) can spuriously exclude this exact tie.
run_wcb <- function(model, data, varname, weights_type = c("rademacher", "webb")) {
  weights_type <- match.arg(weights_type)
  form <- formula(model)
  restricted_form <- update(form, as.formula(paste(". ~ . -", varname)))
  m_restricted <- lm(restricted_form, data = data)
  resid_r <- residuals(m_restricted)
  fitted_r <- fitted(m_restricted)
  cl <- data$ADM2_PCODE
  clusters <- levels(cl)
  G <- length(clusters)

  obs_t <- coeftest(model, vcov = vcovCL(model, cluster = cl, type = "HC1"))[varname, 3]

  weight_set <- if (weights_type == "rademacher") c(-1, 1) else c(-sqrt(1.5), -1, -sqrt(0.5), sqrt(0.5), 1, sqrt(1.5))
  combos <- expand.grid(rep(list(weight_set), G))

  t_all <- numeric(nrow(combos))
  for (i in seq_len(nrow(combos))) {
    w <- as.numeric(combos[i, ]); names(w) <- clusters
    y_boot <- fitted_r + resid_r * w[as.character(cl)]
    df_boot <- data
    df_boot[[as.character(form[[2]])]] <- y_boot
    m_boot <- lm(form, data = df_boot)
    t_all[i] <- coeftest(m_boot, vcov = vcovCL(m_boot, cluster = cl, type = "HC1"))[varname, 3]
  }
  tol <- 1e-8
  mean(abs(t_all) >= abs(obs_t) - tol)
}
## Webb weights are treated as the primary wild-cluster-bootstrap variant (the recommended default
## in Webb 2014/MacKinnon & Webb 2017 for small G); Rademacher weights are reported as a secondary
## check. Note that with only G=5 clusters, Rademacher's 32 discrete combinations impose a coarse
## resolution floor of 1/32 = 0.03125 on the smallest attainable p-value, and results near this
## floor (e.g. 2/32 = 0.0625) should not be read as evidence against an effect - it is a mechanical
## property of the weight scheme at this cluster count, not a statement about effect size.
cat(sprintf("\n  WCB (Webb, primary, exact):        p=%.4f\n", run_wcb(m3_raw, df, "RRUI", "webb")))
cat(sprintf("  WCB (Rademacher, secondary, exact): p=%.4f\n", run_wcb(m3_raw, df, "RRUI", "rademacher")))

## ---- 3. Compositional (CLR) transformation (Section 2.6) ---------------------

wide <- reshape(df[, c("Year", "ADM2_PCODE", "RRUI")],
                idvar = "Year", timevar = "ADM2_PCODE", direction = "wide")
comp_mat <- as.matrix(wide[, -1])
colnames(comp_mat) <- sub("RRUI\\.", "", colnames(comp_mat))
years_vec <- as.integer(wide$Year)

stopifnot(all(abs(rowSums(comp_mat) - 1) < 1e-9))  # composition is closed (sums to 1)
cat("\nShare of exact zeros in RRUI:", round(mean(comp_mat == 0), 3), "\n")

## Zero replacement: multiplicative simple replacement (Martin-Fernandez et al. 2003),
## delta = 0.001. lrEM (model-based EM) was attempted first but fails ("singular
## initial covariance matrix") given only 13 year-rows with up to 3 simultaneous
## zeros per row; multRepl is the documented fallback for this situation.
DELTA <- 0.001
comp_repl <- multRepl(comp_mat, label = 0, dl = rep(DELTA, ncol(comp_mat)))
stopifnot(all(abs(rowSums(comp_repl) - 1) < 1e-6))

clr_mat <- compositions::clr(compositions::acomp(comp_repl))
clr_df  <- as.data.frame(unclass(clr_mat))
clr_long <- do.call(rbind, lapply(seq_len(nrow(clr_df)), function(i)
  data.frame(Year = years_vec[i], ADM2_PCODE = colnames(clr_df),
             RRUI_clr = as.numeric(clr_df[i, ]))))
df <- merge(df, clr_long, by = c("Year", "ADM2_PCODE"))
df$ADM2_PCODE <- factor(df$ADM2_PCODE); df$Year_f <- factor(df$Year)

## ---- 4. CLR-scale TWFE models (Table 12) -------------------------------------

cat("\n=== CLR-scale RRUI: M1 (base) ===\n")
m1_clr_fx <- feols(NDVI ~ RRUI_clr | ADM2_PCODE + Year, data = df, vcov = ~ADM2_PCODE)
m1_clr    <- fit_twfe("NDVI ~ RRUI_clr + ADM2_PCODE + Year_f", df)
report_inference(m1_clr_fx, m1_clr, df, "RRUI_clr")
cat(sprintf("  WCB (Webb, primary, exact):        p=%.4f\n", run_wcb(m1_clr, df, "RRUI_clr", "webb")))
cat(sprintf("  WCB (Rademacher, secondary, exact): p=%.4f\n", run_wcb(m1_clr, df, "RRUI_clr", "rademacher")))

cat("\n=== CLR-scale RRUI: M2 (+ climate) ===\n")
m2_clr_fx <- feols(NDVI ~ RRUI_clr + precip_mm + temp_c | ADM2_PCODE + Year, data = df, vcov = ~ADM2_PCODE)
m2_clr    <- fit_twfe("NDVI ~ RRUI_clr + precip_mm + temp_c + ADM2_PCODE + Year_f", df)
report_inference(m2_clr_fx, m2_clr, df, "RRUI_clr")
cat(sprintf("  WCB (Webb, primary, exact):        p=%.4f\n", run_wcb(m2_clr, df, "RRUI_clr", "webb")))
cat(sprintf("  WCB (Rademacher, secondary, exact): p=%.4f\n", run_wcb(m2_clr, df, "RRUI_clr", "rademacher")))

cat("\n=== CLR-scale RRUI: M3 (+ livestock) [main result, Table 12] ===\n")
m3_clr_fx <- feols(NDVI ~ RRUI_clr + precip_mm + temp_c + Livestock_LSU | ADM2_PCODE + Year, data = df, vcov = ~ADM2_PCODE)
m3_clr    <- fit_twfe("NDVI ~ RRUI_clr + precip_mm + temp_c + Livestock_LSU + ADM2_PCODE + Year_f", df)
report_inference(m3_clr_fx, m3_clr, df, "RRUI_clr")
cat(sprintf("  WCB (Webb, primary, exact):        p=%.4f\n", run_wcb(m3_clr, df, "RRUI_clr", "webb")))
cat(sprintf("  WCB (Rademacher, secondary, exact): p=%.4f\n", run_wcb(m3_clr, df, "RRUI_clr", "rademacher")))

## ---- 5. Robustness checks (Section 3.6, Table 13) ----------------------------

## 5a. Delta sensitivity: re-run M3 (CLR) across a 200x range of the zero-replacement constant.
## Now reports CR2 SE and Satterthwaite df alongside the p-value, not just the p-value.
cat("\n=== 5a. Table 13: sensitivity to delta ===\n")
cat(sprintf("  %-8s %-10s %-12s %-10s %-8s %-10s\n", "delta", "beta", "cluster_p", "CR2_SE", "CR2_df", "CR2_p"))
for (delta in c(0.0001, 0.0005, 0.001, 0.005, 0.01, 0.02)) {
  cr <- multRepl(comp_mat, label = 0, dl = rep(delta, ncol(comp_mat)))
  cl <- compositions::clr(compositions::acomp(cr))
  cld <- as.data.frame(unclass(cl))
  cll <- do.call(rbind, lapply(seq_len(nrow(cld)), function(i)
    data.frame(Year = years_vec[i], ADM2_PCODE = colnames(cld), RRUI_clr_d = as.numeric(cld[i, ]))))
  dfd <- merge(df, cll, by = c("Year", "ADM2_PCODE"))
  dfd$ADM2_PCODE <- factor(dfd$ADM2_PCODE); dfd$Year_f <- factor(dfd$Year)
  ## Cluster-robust p uses fixest (CRV1), matching the convention used everywhere else in this
  ## script (report_inference). An earlier version of this loop used sandwich::vcovCL here, which
  ## gives a materially different (and far more extreme) p-value at this small cluster count -
  ## e.g. p=3.5e-22 from sandwich vs p=4.4e-05 from fixest for the same delta=0.001 model. Mixing
  ## the two conventions within one script would be internally inconsistent, so fixest is used
  ## uniformly for every "cluster-robust" figure reported.
  md_fx <- feols(NDVI ~ RRUI_clr_d + precip_mm + temp_c + Livestock_LSU | ADM2_PCODE + Year,
                 data = dfd, vcov = ~ADM2_PCODE)
  ct_fx <- summary(md_fx)$coeftable["RRUI_clr_d", ]
  md_lm <- fit_twfe("NDVI ~ RRUI_clr_d + precip_mm + temp_c + Livestock_LSU + ADM2_PCODE + Year_f", dfd)
  cr2 <- coef_test(md_lm, vcov = vcovCR(md_lm, cluster = dfd$ADM2_PCODE, type = "CR2"),
                    test = "Satterthwaite", coefs = "RRUI_clr_d")
  cat(sprintf("  %-8.4f %-10.5f %-12.3g %-10.5f %-8.2f %-10.4f\n",
              delta, ct_fx["Estimate"], ct_fx["Pr(>|t|)"], cr2$SE, cr2$df, cr2$p_Satt))
}

## 5b. Placebo test: shuffle NDVI within year. Increased from 200 to 9999 replications and now
## reports an explicit empirical p-value (share of placebo |t| at least as extreme as observed),
## not only the maximum |t| under the null.
cat("\n=== 5b. Placebo test (NDVI shuffled within year, 9999 reps) ===\n")
set.seed(12345)
B_placebo <- 9999
placebo_t <- numeric(B_placebo)
for (i in seq_len(B_placebo)) {
  df$NDVI_shuffled <- ave(df$NDVI, df$Year_f, FUN = sample)
  mp <- lm(NDVI_shuffled ~ RRUI_clr + precip_mm + temp_c + Livestock_LSU + ADM2_PCODE + Year_f, data = df)
  placebo_t[i] <- coeftest(mp, vcov = vcovCL(mp, cluster = df$ADM2_PCODE, type = "HC1"))["RRUI_clr", 3]
}
obs_t_placebo <- coeftest(m3_clr, vcov = vcovCL(m3_clr, cluster = df$ADM2_PCODE, type = "HC1"))["RRUI_clr", 3]
## Finite-sample (add-one) correction (Davison & Hinkley 1997; Phipson & Smyth 2010): avoids an
## artificial p-value of exactly zero and correctly reflects that the observed statistic is itself
## one of the B_placebo+1 possible draws under the null. Minimum attainable value at B=9999 is
## 1/10000 = 0.0001 rather than 0.
p_placebo <- (1 + sum(abs(placebo_t) >= abs(obs_t_placebo))) / (B_placebo + 1)
cat(sprintf("  Observed t = %.2f | Max |t| under placebo = %.2f | Empirical placebo p-value = %.4f\n",
            obs_t_placebo, max(abs(placebo_t)), p_placebo))

## 5c. Observation-robustness check: exclude the most zero-heavy district. CLR is now recomputed
## as a genuine 4-part composition on the remaining districts (re-closed to sum to 1), rather than
## simply dropping rows from the 5-part CLR values, which would leave the geometric-mean reference
## contaminated by a district that is no longer part of the analysed composition.
cat("\n=== 5c. Observation-robustness check: excluding the most zero-heavy district ===\n")
zero_share <- tapply(df$RRUI, df$ADM2_PCODE, function(x) mean(x == 0))
worst_district <- names(which.max(zero_share))
cat("  Excluded district:", worst_district, "(zero share =", round(max(zero_share), 3), ")\n")

comp_mat4 <- comp_mat[, colnames(comp_mat) != worst_district, drop = FALSE]
comp_mat4_closed <- comp_mat4 / rowSums(comp_mat4)  # re-close remaining 4 parts to sum to 1
comp_repl4 <- multRepl(comp_mat4_closed, label = 0, dl = rep(DELTA, ncol(comp_mat4_closed)))
clr_mat4 <- compositions::clr(compositions::acomp(comp_repl4))
clr_df4  <- as.data.frame(unclass(clr_mat4))
clr_long4 <- do.call(rbind, lapply(seq_len(nrow(clr_df4)), function(i)
  data.frame(Year = years_vec[i], ADM2_PCODE = colnames(clr_df4), RRUI_clr4 = as.numeric(clr_df4[i, ]))))

df_trim1 <- merge(subset(df, ADM2_PCODE != worst_district), clr_long4, by = c("Year", "ADM2_PCODE"))
df_trim1$ADM2_PCODE <- droplevels(factor(df_trim1$ADM2_PCODE)); df_trim1$Year_f <- factor(df_trim1$Year)

m_trim1_fx <- feols(NDVI ~ RRUI_clr4 + precip_mm + temp_c + Livestock_LSU | ADM2_PCODE + Year,
                     data = df_trim1, vcov = ~ADM2_PCODE)
m_trim1_lm <- fit_twfe("NDVI ~ RRUI_clr4 + precip_mm + temp_c + Livestock_LSU + ADM2_PCODE + Year_f", df_trim1)
report_inference(m_trim1_fx, m_trim1_lm, df_trim1, "RRUI_clr4")

## 5d. Influence diagnostics: formal Cook's distance thresholds instead of an arbitrary "top-7" cutoff.
## Reports results under three common thresholds as sensitivity variants.
cat("\n=== 5d. Influence diagnostics (Cook's distance): threshold sensitivity ===\n")
cooksd <- cooks.distance(m3_clr)
n_obs <- length(cooksd)
k_params <- length(coef(m3_clr))

thresholds <- list(
  "4/n (standard rule of thumb)"      = 4 / n_obs,
  "4/(n-k-1) (small-sample adjusted)" = 4 / (n_obs - k_params - 1),
  "Cook's D > 1 (classical cutoff)"   = 1
)

for (label in names(thresholds)) {
  thr <- thresholds[[label]]
  flagged <- which(cooksd > thr)
  cat(sprintf("\n  Threshold: %s (%.4f) - N flagged = %d\n", label, thr, length(flagged)))
  if (length(flagged) == 0) {
    cat("    No observations exceed this threshold; original M3 (CLR) result applies unchanged.\n")
    next
  }
  df_trim2 <- droplevels(df[-flagged, ])
  m_trim2_fx <- feols(NDVI ~ RRUI_clr + precip_mm + temp_c + Livestock_LSU | ADM2_PCODE + Year,
                       data = df_trim2, vcov = ~ADM2_PCODE)
  m_trim2_lm <- fit_twfe("NDVI ~ RRUI_clr + precip_mm + temp_c + Livestock_LSU + ADM2_PCODE + Year_f", df_trim2)
  report_inference(m_trim2_fx, m_trim2_lm, df_trim2, "RRUI_clr")
}

## 5e. Diagnostic tables: explicit record of which district-years have RRUI = 0, and which
## observations are flagged as influential under the standard 4/n Cook's-distance rule.
## Saved to disk for transparency and reuse (e.g. in a Supplementary Table).
cat("\n=== 5e. Diagnostic table: district-years with RRUI = 0 ===\n")
zero_dt <- df[df$RRUI == 0, c("Year", "ADM2_PCODE")]
zero_dt <- zero_dt[order(zero_dt$ADM2_PCODE, zero_dt$Year), ]
print(zero_dt, row.names = FALSE)
write.csv(zero_dt, "diagnostic_zero_district_years.csv", row.names = FALSE)

cat(sprintf("\n=== 5e. Diagnostic table: observations flagged as influential (Cook's D > 4/n = %.4f) ===\n",
            4 / n_obs))
influential_dt <- data.frame(Year = df$Year, ADM2_PCODE = df$ADM2_PCODE, CooksD = round(cooksd, 4))
influential_dt <- influential_dt[influential_dt$CooksD > 4 / n_obs, ]
influential_dt <- influential_dt[order(-influential_dt$CooksD), ]
print(influential_dt, row.names = FALSE)
write.csv(influential_dt, "diagnostic_influential_observations.csv", row.names = FALSE)

## ---- 6. Save merged panel with CLR variable for downstream use --------------
write.csv(df, "panel_with_clr.csv", row.names = FALSE)
cat("\nDone. Merged panel with CLR saved to panel_with_clr.csv\n")
