# Ural Saiga RRUI–NDVI Analysis

This repository contains the reproducible R code and analytical workflow used to examine the relationship between spatial use by the Ural saiga population and vegetation dynamics in West Kazakhstan during 2012–2024.

The workflow integrates GPS-derived annual animal routes, MODIS NDVI, climate variables, and livestock data into a district-year panel. Spatial use is represented by the **Relative Route Utilization Index (RRUI)**.

## Study Design

The analysis covers five districts of West Kazakhstan Region:

- Akzhaik
- Bokey Orda
- Kaztal
- Zhanakala
- Zhanybek

The study period covers 2012–2024, producing a balanced panel of **65 district-year observations** (5 districts × 13 years).

The GPS dataset contains **184 spatial route records**. Records belonging to the same animal and year are merged using `IndYear`, resulting in **113 unique animal-year routes from 56 tracked animals**.

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

RRUI therefore measures the average proportional use of each study district by tracked animals. It is a **relative spatial-use index** and should not be interpreted as population abundance or density.

By construction,

\[
\sum_{i=1}^{5} RRUI_{it}=1
\]

for every year.

Consequently, changes in RRUI represent redistribution of relative spatial use among the five study districts rather than independent changes in absolute use intensity.

## Environmental and Livestock Data

Vegetation dynamics are represented by mean **April–October NDVI** derived from **MODIS MOD13Q1 Version 6.1**.

Climate controls include:

- April–October cumulative precipitation;
- April–October mean air temperature.

The final specification additionally includes district-level livestock pressure expressed in standardized livestock units.

## Statistical Analysis

The analysis uses **two-way fixed-effects (TWFE)** models with district and year fixed effects.

Three nested specifications are estimated:

1. RRUI;
2. RRUI + climate controls;
3. RRUI + climate controls + livestock.

Standard errors are clustered by district.

Because the analysis contains only five district clusters, small-cluster inference is additionally evaluated using:

- CR2 cluster-robust variance estimation with Satterthwaite degrees of freedom;
- wild cluster bootstrap with Rademacher weights;
- wild cluster bootstrap with Webb weights.

The estimated RRUI coefficients are interpreted as **conditional associations rather than causal effects**.

## Repository Structure

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
│   ├── raw/
│   ├── intermediate/
│   └── processed/
├── results/
│   ├── tables/
│   └── diagnostics/
├── logs/
├── renv/
├── .Rprofile
├── .gitignore
├── CITATION.cff
├── LICENSE
├── README.md
├── renv.lock
└── Saiga_RRUI_NDVI.Rproj
```

## Reproducing the Analysis

The analysis was developed and tested using **R 4.6.1**.

Exact package versions are recorded in `renv.lock`.

After cloning or downloading the repository, open `Saiga_RRUI_NDVI.Rproj` and restore the R environment:

```r
renv::restore()
```

### Required GPS Data

The original Ural saiga GPS spatial files are **not redistributed through this repository**.

Before running the complete workflow, obtain the required Ural saiga GPS dataset from the **Atlas of Ungulate Migration** and place the required files in:

```text
data/raw/gps/
```

The required filenames and additional instructions are provided in:

```text
data/raw/gps/README.md
```

After the GPS files have been added, the complete analysis can be reproduced with:

```r
source("R/99_run_all.R")
```

The master script sequentially executes the complete analytical workflow, from GPS preprocessing and RRUI construction through panel assembly, statistical inference, and final diagnostics.

## Reproducibility

Random procedures use a fixed seed:

```r
set.seed(12345)
dqrng::dqset.seed(12345)
```

Information about the computational environment is recorded in:

```text
logs/sessionInfo.txt
```

A successful complete run ends with:

```text
ALL SCRIPTS COMPLETED SUCCESSFULLY
```

## Outputs

- Processed analytical datasets: `data/processed/`
- Intermediate spatial and analytical files: `data/intermediate/`
- Statistical results: `results/tables/`
- Diagnostic outputs: `results/diagnostics/`

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

## Data Sources

The analysis integrates GPS telemetry, administrative boundaries, satellite-derived vegetation and climate data, and official livestock statistics.

### GPS Telemetry

GPS-derived movement data for the Ural saiga population were obtained from the **Atlas of Ungulate Migration**, developed by the **Global Initiative on Ungulate Migration (GIUM)** under the **Convention on the Conservation of Migratory Species of Wild Animals (CMS)**.

Population: **Saiga antelope: Ural, Kazakhstan**  
Scientific name: *Saiga tatarica tatarica*

Data providers:

- Albert Salemgareyev — Altyn Dala Conservation Initiative and Association for the Conservation of Biodiversity of Kazakhstan (ACBK);
- Steffen Zuther — Frankfurt Zoological Society.

The original GPS spatial files are **not redistributed in this repository**. Instructions for obtaining and placing the required files are provided in `data/raw/gps/README.md`.

Atlas of Ungulate Migration:  
https://www.cms.int/gium/migration-atlas

### Administrative Boundaries

Administrative district boundaries were obtained from the **UNHCR GIS administrative boundary dataset for Kazakhstan (2023)**.

UNHCR GIS services:  
https://im.unhcr.org/geoservices/

The boundary files used in the analysis are included in `data/raw/boundaries/`.

### NDVI

Vegetation dynamics were derived from **MODIS MOD13Q1 Version 6.1**, a 16-day vegetation-index product at 250 m spatial resolution.

District-level mean NDVI for April–October was calculated using **Google Earth Engine**.

MOD13Q1.061 dataset documentation:  
https://developers.google.com/earth-engine/datasets/catalog/MODIS_061_MOD13Q1

The derived district-year dataset used in the analysis is included in `data/raw/ndvi/`.

### Precipitation

Precipitation data were derived from the **Climate Hazards Group InfraRed Precipitation with Station data (CHIRPS)**.

April–October precipitation totals were aggregated to the district-year level.

The derived analytical dataset used in the workflow is included in `data/raw/climate/`.

### Air Temperature

Air temperature data were derived from **ERA5-Land**, produced by the **Copernicus Climate Change Service**.

Mean April–October 2 m air temperature was aggregated to the district-year level.

ERA5-Land DOI:  
https://doi.org/10.24381/cds.e2161bac

### Livestock Statistics

District-level livestock data for 2012–2024 were compiled from official statistics of the **Bureau of National Statistics of the Republic of Kazakhstan**.

Cattle, sheep and goats, and horses were converted to standardized livestock units for the analysis.

The input dataset used by the reproducible workflow is included in `data/raw/livestock/`.

### Data Redistribution

Original Ural saiga GPS spatial files are excluded from this repository and must be obtained directly from the original data provider.

The repository contains derived district-year analytical datasets required to reproduce the statistical models.

Users should cite the original data providers and comply with the applicable terms of use and attribution requirements for each source.

## Citation

Citation metadata for this repository are provided in `CITATION.cff`.

Citation information for the associated research article will be added after publication.

## License

The original code in this repository is released under the **MIT License**. See `LICENSE` for details.

The MIT License applies to the original code developed for this repository. It does not supersede the licenses, terms of use, or attribution requirements of third-party datasets.
