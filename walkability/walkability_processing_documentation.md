# Walkability Analysis Processing Documentation

## Overview

This document outlines the GIS processing steps being conducted for a walkability analysis in Kelowna using QGIS. The processing focuses on converting vector data (building outlines) to raster format and performing various spatial analyses to assess walkability metrics.

## Processing Timeline

The log shows processing conducted between May 31 and June 4, 2025, with various attempts at rasterizing building outlines and creating buffer zones. These buffer zones were test to understand the possible area not mapped in the previous layers that could affect the walking time for the houses and services in Kelowna.

## Data Sources

- **Building Outlines**: kelowna_building_outline.gpkg
- **Mission Creek Data**: `/media/bndt/extrassd/2025_walkability/mission_creek/mission creek layer.gdb`
- **Alleys**: Alleys.tif

## Processing Steps

### 1. Rasterization of Vector Building Data

Multiple approaches were tested to convert building outlines to raster format, including:

```python
# Initial attempt
processing.run("gdal:rasterize", {
    'INPUT': '/media/bndt/extrassd/2025_walkability/kelowna_building_outline.gpkg|layername=building_outlines',
    'FIELD': '',
    'BURN': 1,
    'USE_Z': False,
    'UNITS': 0,
    'WIDTH': 19672,
    'HEIGHT': 27641,
    'EXTENT': '313648.347000000,333320.347000000,5516570.373100000,5544211.373100000 [EPSG:26911]',
    'NODATA': 0,
    'OPTIONS': '',
    'DATA_TYPE': 5,
    'INIT': None,
    'INVERT': False,
    'EXTRA': '',
    'OUTPUT': 'TEMPORARY_OUTPUT'
})
```

Various parameters were adjusted in subsequent attempts, including:
- Changing NODATA values (0 to 5)
- Modifying DATA_TYPE values
- Testing different INIT values
- Experimenting with GRASS GIS tools (v.to.rast)

### 2. Buffer Analysis

Buffer zones were created around building outlines to determine walkable areas:

```python
# 50m buffer around buildings
processing.run("native:buffer", {
    'INPUT': '/media/bndt/extrassd/2025_walkability/kelowna_building_outline.gpkg|layername=building_outlines',
    'DISTANCE': 50,
    'SEGMENTS': 5,
    'END_CAP_STYLE': 0,
    'JOIN_STYLE': 0,
    'MITER_LIMIT': 2,
    'DISSOLVE': True,
    'SEPARATE_DISJOINT': False,
    'OUTPUT': 'TEMPORARY_OUTPUT'
})
```

Also tested raster-based buffers:

```python
# Raster buffer using GRASS
processing.run("grass7:r.buffer", {
    'input': '/media/bndt/extrassd/2025_walkability/out_zero/out_zero_Stu_merged_compressed.tif',
    'distances': '50',
    'units': 0,
    '-z': False,
    'output': 'TEMPORARY_OUTPUT',
    'GRASS_REGION_PARAMETER': None,
    'GRASS_REGION_CELLSIZE_PARAMETER': 0,
    'GRASS_RASTER_FORMAT_OPT': '',
    'GRASS_RASTER_FORMAT_META': ''
})
```

### 3. Merging Raster Data

Multiple raster datasets were merged to create comprehensive coverage:

```python
processing.run("gdal:merge", {
    'INPUT': [
        '/media/bndt/extrassd/2025_walkability/out_zero/out_zero_Stu_merged_compressed.tif',
        '/media/bndt/extrassd/2025_walkability/out_zero/out_zero_merge_raster_stu_satellite_1only_v2.tif'
    ],
    'PCT': False,
    'SEPARATE': False,
    'NODATA_INPUT': None,
    'NODATA_OUTPUT': None,
    'OPTIONS': 'COMPRESS=DEFLATE|PREDICTOR=2|ZLEVEL=9',
    'EXTRA': '',
    'DATA_TYPE': 0,
    'OUTPUT': '/media/bndt/extrassd/2025_walkability/out_zero/out_zero_merge_raster_stu_satellite_1only_v4.tif'
})
```

### 4. Water Feature Processing (Mission Creek)

Processing was done to exclude water features from the walkability analysis:

```python
# Rasterize creek polygons
processing.run("gdal:rasterize", {
    'INPUT': '/media/bndt/extrassd/2025_walkability/mission_creek/mission creek layer.gdb|layername=Polygons',
    'FIELD': '',
    'BURN': 0,
    'USE_Z': False,
    'UNITS': 0,
    'WIDTH': 19672,
    'HEIGHT': 27641,
    'EXTENT': '313648.347000000,333320.347000000,5516570.373100000,5544211.373100000 [EPSG:26911]',
    'NODATA': 0,
    'OPTIONS': '',
    'DATA_TYPE': 0,
    'INIT': 1,
    'INVERT': False,
    'EXTRA': '',
    'OUTPUT': 'TEMPORARY_OUTPUT'
})

# Mask creek areas from the walkability surface
processing.run("grass7:r.mask.rast", {
    'raster': '/media/bndt/extrassd/2025_walkability/out_zero/creek_inverse.tif',
    'input': '/media/bndt/extrassd/2025_walkability/out_zero/out_zero_merge_raster_stu_satellite_1only_v4.tif',
    'maskcats': '1',
    '-i': False,
    'output': '/home/bndt/nocreek_out_zero_merge_raster_stu_sate_v4.tif',
    'GRASS_REGION_PARAMETER': None,
    'GRASS_REGION_CELLSIZE_PARAMETER': 0,
    'GRASS_RASTER_FORMAT_OPT': '',
    'GRASS_RASTER_FORMAT_META': ''
})
```

## Data Processing Workflow

1. **Vector to Raster Conversion**:
   - Convert building footprint polygons to raster
   - Experiment with different resolution and parameter settings

2. **Buffer Analysis**:
   - Create 50-80m buffers around buildings to represent walkability zones
   - Test both vector and raster buffer approaches

3. **Raster Integration**:
   - Merge multiple raster datasets to create comprehensive coverage
   - Apply compression and optimization for large raster datasets

4. **Natural Feature Processing**:
   - Identify and exclude water bodies (Mission Creek) from walkability analysis
   - Use masking techniques to refine walkable areas

## Output Files

The final outputs include:
- out_zero_merge_raster_stu_satellite_1only_v4.tif (merged raster)
- `/home/bndt/nocreek_out_zero_merge_raster_stu_sate_v4.tif` (final walkability surface excluding creek)

## Next Steps

1. Further analysis of walkability metrics using the processed data
2. Integration with demographic data for population-weighted walkability assessment
3. Visualization of results for urban planning applications

## Technical Considerations

- Coordinate Reference System: EPSG:26911 (NAD83 UTM Zone 11N)
- Raster Resolution: Working with a 19672×27641 pixel grid
- Compression: Using DEFLATE compression with predictor=2 and ZLEVEL=9 for optimized storage