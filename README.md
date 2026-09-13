# Ural Saiga RRUI–NDVI Analysis — Version 1.3.0

Changes from v1.2.0:

1. **Wild cluster bootstrap now uses exact enumeration**, not Monte Carlo
   sampling with B=9999. At G=5 clusters, both the Rademacher (2⁵=32) and
   Webb (6⁵=7,776) weight spaces are small enough to enumerate fully, which
   is both more efficient and exact rather than approximate. This also fixes
   a floating-point comparison bug in the Monte Carlo version: the all-ones
   weight vector exactly reproduces the original sample, so its bootstrap
   statistic must tie the observed one, but ~1e-16 rounding could spuriously
   exclude this tie; a small tolerance now handles this correctly.
2. **WCB is now also computed for the CLR-scale M1–M3 models**, not only the
   raw-scale M3 model — this was the single most important check missing
   before submission. Result: Webb WCB (primary variant) is significant at
   all three CLR specifications (p = 0.0249, 0.0152, 0.0054 for M1–M3, with
   monotonic strengthening as covariates are added), while Rademacher
   (secondary) is capped at its coarse resolution floor of 2/32 = 0.0625 for
   all three — a mechanical property of only having 32 possible sign
   combinations at G=5, not evidence against the effect, and part of why
   Webb is designated primary.
3. **Removed leftover dead code** at the end of Section 5e that still ran the
   old arbitrary "top-7" Cook's-distance exclusion, even though this had
   already been superseded by the formal three-threshold analysis in
   Section 5d.
4. **Placebo-test p-value now uses the standard finite-sample (add-one)
   correction**, p = (1 + k) / (B+1) instead of the plain mean, where k is
   the number of permutations at least as extreme as observed. This avoids
   a p-value of exactly zero and reflects that the observed statistic is
   itself one of the B+1 possible draws under the null. Result for the main
   CLR specification: p = 0.0002 (previously reported as 0.0001 under the
   uncorrected formula).

Changes from v1.1.0 (retained from v1.2.0):

1. **CR2 (Satterthwaite) is now the primary inference procedure** throughout,
   with conventional cluster-robust SEs reported as a secondary reference.
2. **Placebo test strengthened**: 200 → 9999 replications, reporting an
   explicit empirical p-value rather than only the maximum |t| under the null.
3. **District-exclusion check corrected**: CLR is recomputed as a genuine
   4-part composition on the remaining districts (re-closed to sum to 1),
   rather than dropping rows from the already-computed 5-part CLR values.
4. **Influence diagnostics generalized**: three formal Cook's-distance
   thresholds (4/n, 4/(n−k−1), and the classical D > 1 cutoff) replace the
   earlier arbitrary fixed "top-7" cutoff.
5. **Table 13 (delta-sensitivity) expanded and corrected**: now reports CR2
   SE and Satterthwaite df; its cluster-robust p-value column is fixed to
   use `fixest` consistently (an earlier version mixed in `sandwich::vcovCL`,
   giving a materially different and internally inconsistent p-value).
6. **Diagnostic tables added**: which district-years have RRUI = 0, and
   which observations are flagged as influential, are printed and saved to
   `diagnostic_zero_district_years.csv` and
   `diagnostic_influential_observations.csv`.
7. Dropped the `wildboottest` Python-package dependency in favour of a pure-R
   implementation of the wild cluster bootstrap (see `run_wcb()`).

Changes from v1.0.1:

- **Livestock coefficient corrected**: sheep/goats now use the unadjusted
  Eurostat LSU coefficient (0.1) instead of the earlier author-adjusted
  value (0.2). This changed Table 3 (descriptive statistics), Tables 4–5
  (correlations), and Tables 9–11 (final raw-scale model) relative to v1.0.1.
- **Compositional (CLR) analysis** added (Section 2.6 / 3.6 of the
  manuscript): RRUI is closed within each year (sums to 1 across the 5
  districts); zeros (23% of observations) are replaced via multiplicative
  simple replacement (`zCompositions::multRepl`, δ = 0.001) and the
  composition is transformed with centered log-ratio (`compositions::clr`).
  The three TWFE specifications are re-estimated on this scale (Table 12).

## Requirements

R (>= 4.0) and the packages: `zCompositions`, `compositions`, `sandwich`,
`lmtest`, `clubSandwich`, `fixest`. All are on CRAN.

## Usage

```r
# 1. Export the "Panel" sheet of Panel_RRUI_NDVI_Climate_Livestock_SoilMoisture_AprOct.xlsx
#    to panel.csv (same folder as analysis.R)
# 2. Run:
source("analysis.R")
```

Console output reproduces every coefficient, standard error, and p-value
reported in Tables 3, 4, 5, 6, 8, 9, 10, 12, and 13 of the manuscript, and
writes two diagnostic CSV files (see point 6 above).

## Note on cluster-robust standard errors

Point estimates and "cluster-robust" SEs/p-values (as reported in the main
result rows of each table) use `fixest::feols` with `vcov = ~ADM2_PCODE`,
matching the software stated in Methods, Section 2.5, and are used
**consistently throughout the entire script**, including the delta-sensitivity
loop. CR2 (Bell–McCaffrey) is computed separately with
`clubSandwich::vcovCR(..., type = "CR2")`, since `fixest` does not implement
CR2 natively. `sandwich::vcovCL` (a commonly used alternative) gives
numerically different — and at this small cluster count (G = 5), far more
extreme — cluster-robust SEs/p-values, and must not be mixed with the
fixest-based numbers reported anywhere in this script or in the manuscript.

## Note on the wild cluster bootstrap

WCB p-values are computed by **exact enumeration** of all possible
cluster-weight combinations (32 for Rademacher, 7,776 for Webb at G=5), not
Monte Carlo sampling. This is both more efficient and gives an exact rather
than approximate p-value. A small numerical tolerance (1e-8) is used when
comparing |t| values to correctly count the exact tie produced by the
all-ones (or all-minus-ones) weight vector, which algebraically reproduces
the original sample.

