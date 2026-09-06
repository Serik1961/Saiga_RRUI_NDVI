// ВАРИАНТ Б (запасной): FAO GAUL level 2, фильтр по Западно-Казахстанской области.
// Проверьте и при необходимости скорректируйте названия районов (ADM2_NAME) —
// в GAUL они могут отличаться транслитерацией от ваших исходных данных.
var districts = ee.FeatureCollection('FAO/GAUL/2015/level2')
  .filter(ee.Filter.eq('ADM1_NAME', 'Zapadno-kazachstanskaya'));
 
// Пять районов исследования (сопоставлены с Рисунком 1 статьи):
// Akzhaik, Bokeyordinsky (= Urda в GAUL), Zhangalinsky, Zhanybeksky, Kaztalovsky
var districtNames = ['Akzhaiyk', 'Urda', 'Zhangala', 'Zhanybek', 'Kaztalov'];
districts = districts.filter(ee.Filter.inList('ADM2_NAME', districtNames));
 
print('Districts:', districts);
print('Число найденных районов (должно быть 5):', districts.size());
Map.addLayer(districts, {color: 'red'}, 'Study districts');
 
// ============================================================================
// БЛОК 2. Параметры периода
// ============================================================================
 
var years = ee.List.sequence(2012, 2024);
var seasonStartMonth = 4;  // апрель
var seasonEndMonth = 10;   // октябрь (включительно, как в тексте статьи)
 
// ============================================================================
// БЛОК 3. Осадки — CHIRPS Daily (сумма за сезон, мм)
// ============================================================================
 
var chirps = ee.ImageCollection('UCSB-CHG/CHIRPS/DAILY')
  .select('precipitation');
 
var precipByYear = ee.FeatureCollection(years.map(function(y) {
  y = ee.Number(y);
  var start = ee.Date.fromYMD(y, seasonStartMonth, 1);
  var end = ee.Date.fromYMD(y, seasonEndMonth, 31);
 
  var seasonalSum = chirps.filterDate(start, end).sum();
 
  var stats = seasonalSum.reduceRegions({
    collection: districts,
    reducer: ee.Reducer.mean(),
    scale: 5500  // нативное разрешение CHIRPS ~5.5 км
  });
 
  return stats.map(function(f) {
    return f.set('year', y);
  });
})).flatten();
 
// ============================================================================
// БЛОК 4. Температура — ERA5-Land Monthly (среднее за сезон, °C)
// ============================================================================
 
var era5 = ee.ImageCollection('ECMWF/ERA5_LAND/MONTHLY_AGGR')
  .select('temperature_2m');
 
var tempByYear = ee.FeatureCollection(years.map(function(y) {
  y = ee.Number(y);
  var start = ee.Date.fromYMD(y, seasonStartMonth, 1);
  var end = ee.Date.fromYMD(y, seasonEndMonth, 31);
 
  // ERA5-Land температура в Кельвинах — переводим в °C
  var seasonalMeanK = era5.filterDate(start, end).mean();
  var seasonalMeanC = seasonalMeanK.subtract(273.15);
 
  var stats = seasonalMeanC.reduceRegions({
    collection: districts,
    reducer: ee.Reducer.mean(),
    scale: 11132  // нативное разрешение ERA5-Land ~11 км
  });
 
  return stats.map(function(f) {
    return f.set('year', y);
  });
})).flatten();
 
// ============================================================================
// БЛОК 5. Объединение осадков и температуры в одну таблицу район-год
// ============================================================================
// Используем district-year как ключ соединения через простое сопоставление
// по индексу — оба FeatureCollection построены в одинаковом порядке
// (districts x years), поэтому можно объединить через zip по позиции.
// Для надёжности сравнения делаем join по ADM2_NAME + year.
 
var districtNameField = 'ADM2_NAME'; // поменяйте на имя поля в вашем ассете,
                                       // если используете Вариант А
 
var precipRenamed = precipByYear.map(function(f) {
  return f.set('precip_mm', f.get('mean'))
          .set('district', f.get(districtNameField));
});
 
var tempRenamed = tempByYear.map(function(f) {
  return f.set('temp_c', f.get('mean'))
          .set('district', f.get(districtNameField));
});
 
var filter = ee.Filter.and(
  ee.Filter.equals({leftField: 'district', rightField: 'district'}),
  ee.Filter.equals({leftField: 'year', rightField: 'year'})
);
 
var joined = ee.Join.inner().apply(precipRenamed, tempRenamed, filter);
 
var climateTable = joined.map(function(pair) {
  var p = ee.Feature(ee.Feature(pair).get('primary'));
  var t = ee.Feature(ee.Feature(pair).get('secondary'));
  return ee.Feature(null, {
    'district': p.get('district'),
    'year': p.get('year'),
    'precip_mm': p.get('precip_mm'),
    'temp_c': t.get('temp_c')
  });
});
 
// print() полной таблицы убран намеренно — вычисление занимает много времени
// в интерактивном режиме и может привести к таймауту консоли. Экспорт ниже
// выполняется на сервере и не имеет этого ограничения.
 
// ============================================================================
// БЛОК 6. Экспорт в Google Drive
// ============================================================================
 
Export.table.toDrive({
  collection: climateTable,
  description: 'climate_by_district_year',
  folder: 'GEE_exports',
  fileNamePrefix: 'climate_by_district_year',
  fileFormat: 'CSV',
  selectors: ['district', 'year', 'precip_mm', 'temp_c']
});
 
/*
 * ПРИМЕЧАНИЯ:
 *
 * 1. Если для NDVI вы использовали НЕ MOD13Q1, а другой источник границ
 *    (свой шейп-файл районов) — обязательно замените Блок 1, иначе площади
 *    осреднения не будут точно совпадать с теми, что использовались для NDVI,
 *    и панель будет несопоставима.
 *
 * 2. ERA5-Land имеет задержку публикации ~2-3 месяца, но данные с 2012 по
 *    2024 год должны быть полностью доступны на момент запуска.
 *
 * 3. Альтернатива ERA5-Land для температуры — MODIS LST (MOD11A2, 8-дневная,
 *    1 км), если нужно более высокое пространственное разрешение, но она
 *    измеряет температуру поверхности (LST), а не приземного воздуха (2m) —
 *    для экологической интерпретации ERA5-Land обычно предпочтительнее.
 *
 * 4. После экспорта проверьте файл: должно быть 65 строк (5 районов x 13 лет),
 *    без пропусков NA — если есть пропуски, вероятно, граница района не
 *    пересекается с пикселями CHIRPS/ERA5 в этом месте (редко, но проверьте
 *    визуально на карте (Map.addLayer выше)).
 */
