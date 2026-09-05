# Ural Saiga RRUI–NDVI Analysis

This repository contains the reproducible R code used to analyse the relationship between spatial use by the Ural saiga population and vegetation dynamics in West Kazakhstan during 2012–2024.

The workflow integrates GPS-derived annual animal routes, MODIS NDVI, climate variables, and livestock data into a district-year panel. Spatial use is represented by the Relative Route Utilization Index (RRUI).

## Study design

The analysis covers five districts of West Kazakhstan Region:

- Akzhaik
- Bokey Orda
- Kaztal
- Zhanakala
- Zhanybek

The study period is 2012–2024, producing a balanced panel of 65 district-year observations (5 districts × 13 years).

The GPS dataset contains 184 spatial route records. Records belonging to the same animal and year are merged using `IndYear`, resulting in 113 unique animal-year routes from 56 tracked animals.

## Relative Route Utilization Index (RRUI)

For animal \(j\), district \(i\), and year \(t\), the proportion of its annual route located within a district is calculated as

\[
p_{ijt} =
\frac{L_{ijt}}
{\sum_{i=1}^{5} L_{ijt}},
\]

where \(L_{ijt}\) is the length of the animal-year route within district \(i\).

RRUI is then calculated as

\[
RRUI_{it} =
\frac{1}{N_t}
\sum_{j=1}^{N_t} p_{ijt},
\]

where \(N_t\) is the number of tracked animal-year routes in year \(t\).

RRUI therefore measures the average proportional use of each study district by tracked animals. It is a relative spatial-use index and should not be interpreted as population abundance or density.

By construction,

\[
\sum_{i=1}^{5} RRUI_{it}=1
\]

for every year.

## Environmental and livestock data

Vegetation dynamics are represented by mean growing-season NDVI (April–October) derived from MODIS MOD13Q1 Version 6.1.

Climate controls include:

- April–October cumulative precipitation;
- April–October mean air temperature.

The final specification additionally includes district-level livestock pressure expressed in conditional livestock units.

## Statistical analysis

The analysis uses two-way fixed-effects (TWFE) models with district and year fixed effects.

Three nested specifications are estimated:

1. RRUI;
2. RRUI + climate controls;
3. RRUI + climate controls + livestock.

Standard errors are clustered by district.

Because the analysis contains only five district clusters, small-cluster inference is additionally evaluated using:

- CR2 cluster-robust variance estimation with Satterthwaite degrees of freedom;
- wild cluster bootstrap with Rademacher weights;
- wild cluster bootstrap with Webb weights.

## Repository structure

```text
Saiga_RRUI_NDVI/
├── R/
│   ├── 00_setup.R
│   ├── 01_gps_preprocessing.R
│   ├── 02_boundaries_preprocessing.R
│   ├── 03_calculate_rrui.R
│   ├── 04_ndvi_preprocessing.R
│   ├── 05_build_panel.R
│   ├── 06_twfe_rrui_ndvi.R
│   ├── 07_cr2.R
│   ├── 08_wild_cluster_bootstrap.R
│   ├── 09_climate_preprocessing.R
│   ├── 10_build_panel_climate.R
│   ├── 11_twfe_climate.R
│   ├── 12_cr2_climate.R
│   ├── 13_wcb_climate.R
│   ├── 14_livestock_preprocessing.R
│   ├── 15_build_final_panel.R
│   ├── 16_twfe_final.R
│   ├── 17_cr2_final.R
│   ├── 18_wcb_final.R
│   ├── 19_final_results_table.R
│   ├── 20_final_diagnostics.R
│   └── 99_run_all.R
├── data/
├── results/
├── logs/
├── renv/
├── .Rprofile
├── renv.lock
└── Saiga_RRUI_NDVI.Rproj
```

## Reproducing the analysis

The analysis was developed using R 4.6.1.

Package versions are recorded in `renv.lock`.

After cloning or downloading the repository, open `Saiga_RRUI_NDVI.Rproj` and restore the R environment:

```r
renv::restore()
```

The complete analysis can then be reproduced with:

```r
source("R/99_run_all.R")
```

The master script sequentially executes all analysis scripts from data preprocessing through final statistical inference and diagnostics.

## Reproducibility

Random procedures use a fixed seed:

```r
set.seed(12345)
dqrng::dqset.seed(12345)
```

The computational environment is recorded in:

```text
logs/sessionInfo.txt
```

A successful complete run ends with:

```text
ALL SCRIPTS COMPLETED SUCCESSFULLY
```

## Outputs

Processed analytical datasets are written to:

```text
data/processed/
```

Intermediate spatial and analytical files are written to:

```text
data/intermediate/
```

Statistical results are written to:

```text
results/tables/
```

Diagnostic outputs are written to:

```text
results/diagnostics/
```

## Software

The workflow uses R packages including:

- `sf`
- `dplyr`
- `tidyr`
- `readr`
- `readxl`
- `openxlsx`
- `ggplot2`
- `fixest`
- `clubSandwich`
- `fwildclusterboot`
- `dqrng`
- `modelsummary`

Exact package versions are recorded in `renv.lock`.

## Data sources

The analysis integrates:

- GPS telemetry of the Ural saiga population;
- administrative district boundaries;
- MODIS MOD13Q1.061 NDVI;
- precipitation data;
- air-temperature data;
- official district-level livestock statistics.

Detailed data provenance, citations, and access information should accompany the public release of the repository.

## Citation

Citation information for the associated article will be added after publication.

## License

License information will be added before the public release of the repository.