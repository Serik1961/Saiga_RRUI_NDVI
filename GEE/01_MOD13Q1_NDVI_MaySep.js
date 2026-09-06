// ============================================================
// FINAL NDVI PANEL — URAL SAIGA STUDY
// West Kazakhstan Region
//
// MODIS product: MOD13Q1.061
// Spatial resolution: 250 m
// Growing season: 1 May – 30 September (inclusive)
// Study period: 2012–2024
//
// Output:
// 1) District × year NDVI panel (CSV)
// 2) NDVI GeoTIFF rasters for 2016, 2018 and 2024
// ============================================================


// ============================================================
// 1. STUDY DISTRICTS
// ============================================================

var districts = ee.FeatureCollection(
  'projects/powerful-host-499406-d6/assets/5RAIONOV'
);

var studyArea = districts.geometry();

Map.centerObject(districts, 7);

print('Study districts:', districts);
print('Number of districts:', districts.size());


// ============================================================
// 2. STUDY YEARS
// ============================================================

var years = ee.List.sequence(2012, 2024);

print('Study years:', years);


// ============================================================
// 3. MODIS MOD13Q1 COLLECTION
// ============================================================

var modis = ee.ImageCollection(
  'MODIS/061/MOD13Q1'
);


// ============================================================
// 4. FUNCTION: GROWING-SEASON NDVI
//
// Growing season:
// 1 May – 30 September, inclusive
//
// IMPORTANT:
// Earth Engine filterDate(start, end) includes the start date
// but excludes the end date.
//
// Therefore:
// start = 1 May
// end   = 1 October (exclusive)
//
// This corresponds to the complete period
// 1 May – 30 September.
// ============================================================

function growingSeasonNDVI(year) {

  year = ee.Number(year);

  // 1 May — INCLUDED
  var startDate = ee.Date.fromYMD(
    year,
    5,
    1
  );

  // 1 October — EXCLUDED
  // Therefore 30 September is included
  var endDate = ee.Date.fromYMD(
    year,
    10,
    1
  );

  var ndvi = modis

    .filterDate(
      startDate,
      endDate
    )

    .select('NDVI')

    // Mean of all MOD13Q1 16-day composites
    // falling within 1 May–30 September
    .mean()

    // MOD13Q1 NDVI scale factor
    .multiply(0.0001)

    .rename('NDVI')

    .set('Year', year);

  return ndvi;
}


// ============================================================
// 5. CREATE DISTRICT × YEAR PANEL
// ============================================================

var panel = ee.FeatureCollection(

  years.map(function(year) {

    year = ee.Number(year);

    var ndviImage = growingSeasonNDVI(year);

    var districtStats = ndviImage.reduceRegions({

      collection: districts,

      reducer: ee.Reducer.mean(),

      scale: 250

    });

    return districtStats.map(function(feature) {

      return ee.Feature(
        null,
        {

          ADM2_EN:
            feature.get('ADM2_EN'),

          ADM2_PCODE:
            feature.get('ADM2_PCODE'),

          Year:
            year,

          NDVI:
            feature.get('mean')

        }
      );

    });

  })

).flatten();


// ============================================================
// 6. PANEL CHECK
// ============================================================

print(
  'FINAL NDVI PANEL:',
  panel
);

print(
  'Number of observations:',
  panel.size()
);

// Expected:
// 5 districts × 13 years = 65 observations


// ============================================================
// 7. CHECK DISTRICTS
// ============================================================

print(
  'District names:',
  panel.aggregate_array('ADM2_EN').distinct()
);


// ============================================================
// 8. CHECK YEARS
// ============================================================

print(
  'Years:',
  panel.aggregate_array('Year').distinct().sort()
);


// ============================================================
// 9. CHECK 2016 VALUES
// ============================================================

var check2016 = panel
  .filter(
    ee.Filter.eq('Year', 2016)
  )
  .sort('ADM2_EN');

print(
  'NDVI — 2016:',
  check2016
);


// ============================================================
// 10. EXPORT FINAL PANEL TO CSV
// ============================================================

Export.table.toDrive({

  collection: panel,

  description:
    'Saiga_NDVI_MOD13Q1_2012_2024_FINAL',

  folder:
    'Saiga_NDVI',

  fileNamePrefix:
    'Saiga_NDVI_MOD13Q1_2012_2024_FINAL',

  fileFormat:
    'CSV',

  selectors: [
    'ADM2_EN',
    'ADM2_PCODE',
    'Year',
    'NDVI'
  ]

});


// ============================================================
// 11. CREATE NDVI RASTERS FOR SPATIAL FIGURE
// ============================================================

var ndvi2016 =
  growingSeasonNDVI(2016)
    .clip(studyArea);

var ndvi2018 =
  growingSeasonNDVI(2018)
    .clip(studyArea);

var ndvi2024 =
  growingSeasonNDVI(2024)
    .clip(studyArea);


// ============================================================
// 12. COMMON VISUALIZATION SCALE
// ============================================================

var ndviVis = {

  min: 0.10,

  max: 0.60,

  palette: [
    '8c510a',
    'd8b365',
    'f6e8c3',
    'c7eae5',
    '5ab4ac',
    '01665e'
  ]

};


// ============================================================
// 13. DISPLAY NDVI RASTERS
// ============================================================

Map.addLayer(
  ndvi2016,
  ndviVis,
  'Growing-season NDVI — 2016',
  false
);

Map.addLayer(
  ndvi2018,
  ndviVis,
  'Growing-season NDVI — 2018',
  false
);

Map.addLayer(
  ndvi2024,
  ndviVis,
  'Growing-season NDVI — 2024',
  true
);


// ============================================================
// 14. ADM2 BOUNDARIES
// ============================================================

var boundaries = ee.Image()
  .byte()
  .paint({

    featureCollection: districts,

    color: 1,

    width: 2

  });

Map.addLayer(
  boundaries,
  {
    palette: ['000000']
  },
  'ADM2 boundaries',
  true
);


// ============================================================
// 15. EXPORT 2016 NDVI RASTER
// ============================================================

Export.image.toDrive({

  image: ndvi2016,

  description:
    'MOD13Q1_GrowingSeason_NDVI_2016',

  folder:
    'Saiga_NDVI',

  fileNamePrefix:
    'MOD13Q1_GrowingSeason_NDVI_2016',

  region:
    studyArea,

  scale:
    250,

  maxPixels:
    1e13,

  fileFormat:
    'GeoTIFF'

});


// ============================================================
// 16. EXPORT 2018 NDVI RASTER
// ============================================================

Export.image.toDrive({

  image: ndvi2018,

  description:
    'MOD13Q1_GrowingSeason_NDVI_2018',

  folder:
    'Saiga_NDVI',

  fileNamePrefix:
    'MOD13Q1_GrowingSeason_NDVI_2018',

  region:
    studyArea,

  scale:
    250,

  maxPixels:
    1e13,

  fileFormat:
    'GeoTIFF'

});


// ============================================================
// 17. EXPORT 2024 NDVI RASTER
// ============================================================

Export.image.toDrive({

  image: ndvi2024,

  description:
    'MOD13Q1_GrowingSeason_NDVI_2024',

  folder:
    'Saiga_NDVI',

  fileNamePrefix:
    'MOD13Q1_GrowingSeason_NDVI_2024',

  region:
    studyArea,

  scale:
    250,

  maxPixels:
    1e13,

  fileFormat:
    'GeoTIFF'

});


// ============================================================
// END
// ============================================================
// ============================================================
// ADDITIONAL EXPORT: NDVI 2020
// Minimum mean growing-season NDVI year
// Growing season: 1 May – 30 September
// ============================================================

var ndvi2020 =
  growingSeasonNDVI(2020)
    .clip(studyArea);


// Display on map
Map.addLayer(
  ndvi2020,
  ndviVis,
  'Growing-season NDVI — 2020',
  false
);


// Export 2020 NDVI raster
Export.image.toDrive({

  image: ndvi2020,

  description:
    'MOD13Q1_GrowingSeason_NDVI_2020',

  folder:
    'Saiga_NDVI',

  fileNamePrefix:
    'MOD13Q1_GrowingSeason_NDVI_2020',

  region:
    studyArea,

  scale:
    250,

  maxPixels:
    1e13,

  fileFormat:
    'GeoTIFF'

});
