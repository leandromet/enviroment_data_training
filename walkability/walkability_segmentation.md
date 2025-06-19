
# Walkability Data Processing Pipeline

## Table of Contents
<!-- TOC generated automatically -->

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Step 01: Orthoimage Resampling](#step-01-orthoimage-resampling)
    - [Objective](#objective)
    - [Methodology](#methodology)
    - [Technical Notes](#technical-notes)
4. [Step 02: Image Segmentation](#step-02-image-segmentation)
    - [Objective](#objective-1)
    - [Algorithm: OTB Mean Shift Segmentation](#algorithm-otb-mean-shift-segmentation)
    - [Parameter Configuration](#parameter-configuration)
    - [Output Specifications](#output-specifications)
5. [Step 03: Zonal Statistics Extraction](#step-03-zonal-statistics-extraction)
    - [Objective](#objective-2)
    - [3.1 Primary Zonal Statistics](#31-primary-zonal-statistics)
    - [3.2 Multi-Layer Integration](#32-multi-layer-integration)
    - [Data Products](#data-products)
6. [Step 04: Building Footprint Removal](#step-04-building-footprint-removal)
    - [Objective](#objective-3)
    - [4.1 Geometry Validation](#41-geometry-validation)
    - [4.2 Spatial Difference Operation](#42-spatial-difference-operation)
    - [Applications](#applications)
7. [Step 05: Vector-to-Raster Conversion](#step-05-vector-to-raster-conversion)
    - [Objective](#objective-4)
    - [Implementation](#implementation)
    - [Parameter Specifications](#parameter-specifications)
    - [Output Applications](#output-applications)
8. [Step 06: Comprehensive Raster Layer Integration and Export](#step-06-comprehensive-raster-layer-integration-and-export)
    - [Objective](#objective-5)
    - [6.1 Raster Layer Merging](#61-raster-layer-merging)
    - [6.2 Vector to Raster Standardization](#62-vector-to-raster-standardization)
    - [6.3 Compression and Optimization Standards](#63-compression-and-optimization-standards)
    - [6.4 Individual Layer Export for Google Drive](#64-individual-layer-export-for-google-drive)
    - [6.5 Batch Processing Script](#65-batch-processing-script)
    - [6.6 File Size Optimization Results](#66-file-size-optimization-results)
    - [6.7 Cloud Storage Organization](#67-cloud-storage-organization)
    - [6.8 Quality Control and Validation](#68-quality-control-and-validation)
9. [Quality Assurance - Recommended](#quality-assurance---recommended)
    - [Validation Checkpoints](#validation-checkpoints)
    - [Expected Outputs](#expected-outputs)
10. [Technical Requirements](#technical-requirements)
    - [Software Dependencies](#software-dependencies)
    - [Hardware Recommendations](#hardware-recommendations)
    - [Data Management](#data-management)
11. [Walkability Buffer Analysis and Creek processing](#walkability-buffer-analysis-and-creek-processing)
    - [Overview](#overview-1)
    - [Processing Timeline](#processing-timeline)
    - [Data Sources](#data-sources)
    - [Processing Steps](#processing-steps)
    - [Data Processing Workflow](#data-processing-workflow)
    - [Output Files](#output-files)
    - [Next Steps](#next-steps)
    - [Technical Considerations](#technical-considerations)

<!-- /TOC -->

## Overview

This document outlines the complete data processing pipeline for walkability analysis in urban environments. The workflow transforms high-resolution orthophotos into segmented vector datasets suitable for walkability assessment and spatial analysis.

## Prerequisites

- QGIS 3.x with Processing Toolbox
- Orfeo Toolbox (OTB) plugin
- GDAL/OGR tools
- Input data: High-resolution orthophotos (10cm GSD)
- Building footprint vector data

---

## Step 01: Orthoimage Resampling

### Objective
Resample high-resolution orthophotos from 10cm to 30cm ground sampling distance (GSD) to optimize processing efficiency while maintaining sufficient detail for walkability analysis.

### Methodology
The resampling process uses GDAL's translate algorithm with target resolution parameters to standardize pixel size across all input imagery.

```python
processing.run("gdal:translate", {
    'INPUT': '/mnt/8ECE5AF8CE5AD853/2025_dina_kelowna/kelowna_ort1.tif',
    'TARGET_CRS': None,
    'NODATA': None,
    'COPY_SUBDATASETS': False,
    'OPTIONS': 'COMPRESS=DEFLATE|PREDICTOR=2|ZLEVEL=9',
    'EXTRA': '',
    'DATA_TYPE': 0,
    'OUTPUT': '/mnt/8ECE5AF8CE5AD853/2025_dina_kelowna/30cm_ortho/0p3_kelowna_ort01.tif',
    'TR': [0.3, 0.3]  # Target resolution: 0.3m x 0.3m pixels
})
```

### Technical Notes
- **Critical**: Ensure input raster CRS uses meters as units (e.g., UTM projection)
- For degree-based coordinate systems, reproject to meter-based CRS before resampling
- Compression settings optimize file size while preserving data quality

---

## Step 02: Image Segmentation

### Objective
Perform object-based image segmentation to identify homogeneous image regions representing distinct urban features (buildings, vegetation, pavement, etc.).

### Algorithm: OTB Mean Shift Segmentation
The Orfeo Toolbox Mean Shift algorithm groups pixels based on spectral similarity and spatial proximity, creating meaningful object boundaries for subsequent analysis.

```python
processing.run("otb:Segmentation", {
    'in': '/srv/extrassd/2025_walkability/kelowna_orto7_0p3m.tif',
    'filter': 'meanshift',
    'filter.meanshift.spatialr': 10,
    'filter.meanshift.ranger': 20,
    'filter.meanshift.thres': 0.1,
    'filter.meanshift.maxiter': 40,
    'filter.meanshift.minsize': 200,
    'mode': 'vector',
    'mode.vector.out': '/srv/extrassd/2025_walkability/segmentation_ort7_0p3m.sqlite',
    'mode.vector.outmode': 'ulco',
    'mode.vector.inmask': None,
    'mode.vector.neighbor': False,
    'mode.vector.stitch': True,
    'mode.vector.minsize': 4,
    'mode.vector.simplify': 0.1,
    'mode.vector.layername': '',
    'mode.vector.fieldname': '',
    'mode.vector.tilesize': 1024,
    'mode.vector.startlabel': 1,
    'mode.vector.ogroptions': '',
    'outputpixeltype': 3
})
```

### Parameter Configuration

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `spatialr` | 10 | Spatial search radius (pixels) |
| `ranger` | 20 | Spectral range threshold |
| `thres` | 0.1 | Convergence threshold |
| `minsize` | 200 | Minimum segment size (pixels) |
| `tilesize` | 1024 | Processing tile size for memory efficiency |
| `simplify` | 0.1 | Polygon simplification tolerance |

### Output Specifications
- **Format**: SQLite/GeoPackage vector polygons
- **Labeling**: Unique identifier per segment
- **Quality**: Optimized for 30cm GSD urban imagery analysis

---

## Step 03: Zonal Statistics Extraction

### Objective
Calculate spectral statistics (mean, min, max, standard deviation) for each image segment to characterize surface properties relevant to walkability assessment.

### 3.1 Primary Zonal Statistics

```python
processing.run("otb:ZonalStatistics", {
    'in': '/mnt/8ECE5AF8CE5AD853/2025_dina_kelowna/kelowna_ort7.tif',
    'inbv': 0,  # Band selection (0=Red, 1=Green, 2=Blue)
    'inzone': 'vector',
    'inzone.vector.in': '/srv/extrassd/2025_walkability/segmentation_ort7_0p3m.sqlite|layername=layer',
    'inzone.vector.reproject': False,
    'out': 'vector',
    'out.vector.filename': '/srv/extrassd/2025_walkability/segment0p3_zonal_data_ort7_0p1.gpkg',
    'outputpixeltype': 5
})
```

### 3.2 Multi-Layer Integration

For large study areas processed in tiles, merge individual segment layers:

```python
processing.run("native:mergevectorlayers", {
    'LAYERS': [
        '/srv/extrassd/2025_walkability/ortho0p3_segments/ortho0p3_seg_zonalStat1.gpkg',
        '/srv/extrassd/2025_walkability/ortho0p3_segments/ortho0p3_seg_zonalStat2.gpkg',
        # ... additional tiles
        '/srv/extrassd/2025_walkability/ortho0p3_segments/ortho0p3_seg_zonalStat19.gpkg'
    ],
    'CRS': None,
    'OUTPUT': 'ogr:dbname=\'/srv/extrassd/2025_walkability/walkability_segment_zonal_stats.gpkg\' table="full_seg" (geom)',
    'ADD_SOURCE_FIELDS': True
})
```

### Data Products
- **Statistical measures**: Mean, min, max, standard deviation per segment
- **Source tracking**: Tile origin identification for quality control
- **Format**: Consolidated GeoPackage for analysis-ready datasets

---

## Step 04: Building Footprint Removal

### Objective
Isolate non-building areas within image segments to focus walkability analysis on accessible public spaces (sidewalks, plazas, parking areas, green spaces).

### 4.1 Geometry Validation

Ensure topological correctness before spatial operations:

```bash
qgis_process run native:fixgeometries \
    --distance_units=meters \
    --area_units=m2 \
    --ellipsoid=EPSG:7030 \
    --INPUT='/srv/extrassd/2025_walkability/kelowna_building_outline.gpkg|layername=building_outlines' \
    --METHOD=1 \
    --OUTPUT=TEMPORARY_OUTPUT
```

### 4.2 Spatial Difference Operation

Remove building geometries from segmented areas:

```python
processing.run("native:difference", {
    'INPUT': QgsProcessingFeatureSourceDefinition(
        '/srv/extrassd/2025_walkability/walkability_segment_zonal_stats.gpkg|layername=full_seg',
        selectedFeaturesOnly=True,
        featureLimit=-1,
        geometryCheck=QgsFeatureRequest.GeometryAbortOnInvalid
    ),
    'OVERLAY': 'memory://MultiPolygon?crs=EPSG:26911&...',  # Fixed building geometries
    'OUTPUT': 'ogr:dbname=\'/srv/extrassd/2025_walkability/walkability_450_650_nobuilding.gpkg\' table="parking" (geom)',
    'GRID_SIZE': None
})
```

### Applications
- **Walkable surface identification**: Sidewalks, crosswalks, public squares
- **Green space analysis**: Parks, tree canopy areas
- **Infrastructure assessment**: Parking lots, transit stops

---

## Step 05: Vector-to-Raster Conversion

### Objective
Convert processed vector polygons to raster format for integration with other geospatial datasets and raster-based modeling workflows.

### Implementation

```bash
gdal_rasterize \
    -l parking \
    -burn 1.0 \
    -tr 1.0 1.0 \
    -a_nodata 0.0 \
    -te 313648.347 5516570.3731 333320.347 5544211.3731 \
    -ot Float32 \
    -of GTiff \
    /srv/extrassd/2025_walkability/walkability_450_650_nobuilding.gpkg \
    /tmp/processing_SkOkbp/83b909634ad4476c9bca2633971be20e/OUTPUT.tif
```

### Parameter Specifications

| Parameter | Value | Function |
|-----------|-------|----------|
| `-burn 1.0` | Binary encoding | Walkable areas = 1.0 |
| `-tr 1.0 1.0` | 1m pixel resolution | Analysis-appropriate scale |
| `-a_nodata 0.0` | Background value | Non-walkable areas = 0.0 |
| `-te [bbox]` | Spatial extent | Study area boundaries |
| `-ot Float32` | Data precision | Statistical compatibility |

### Output Applications
- **Binary mask generation**: Walkable vs. non-walkable areas
- **Accessibility modeling**: Distance-based calculations
- **Statistical analysis**: Area calculations and spatial metrics
- **Visualization**: Map production and presentation

---

## Step 06: Comprehensive Raster Layer Integration and Export

### Objective
Consolidate all processed raster layers into standardized TIFF format with high compression for efficient storage and cloud backup. This step ensures all walkability analysis components are harmonized with consistent spatial parameters and optimized for Google Drive storage.

### 6.1 Raster Layer Merging

Merge all walkability-related raster layers into a single comprehensive dataset:

```python
processing.run("gdal:merge", {
    'INPUT': [
        '/srv/extrassd/2025_walkability/segmentation_raster_0p3m.tif',
        '/srv/extrassd/2025_walkability/building_footprints_raster.tif',
        '/srv/extrassd/2025_walkability/walkability_surface_nobuilding.tif',
        '/srv/extrassd/2025_walkability/nocreek_out_zero_merge_raster_stu_sate_v4.tif',
        '/srv/extrassd/2025_walkability/buffer_zones_50m.tif',
        '/srv/extrassd/2025_walkability/alleys_raster.tif'
    ],
    'PCT': False,
    'SEPARATE': True,  # Maintain separate bands for each layer
    'NODATA_INPUT': 0,
    'NODATA_OUTPUT': 0,
    'OPTIONS': 'COMPRESS=DEFLATE|PREDICTOR=2|ZLEVEL=9|TILED=YES|BIGTIFF=YES',
    'EXTRA': '',
    'DATA_TYPE': 5,  # Float32 for statistical analysis
    'OUTPUT': '/srv/extrassd/2025_walkability/merged/walkability_comprehensive_dataset.tif'
})
```

### 6.2 Vector to Raster Standardization

Convert all vector layers to raster format with consistent spatial parameters:

#### 6.2.1 Building Outlines Conversion

```python
processing.run("gdal:rasterize", {
    'INPUT': '/srv/extrassd/2025_walkability/kelowna_building_outline.gpkg|layername=building_outlines',
    'FIELD': '',
    'BURN': 1,
    'USE_Z': False,
    'UNITS': 0,
    'WIDTH': 19672,
    'HEIGHT': 27641,
    'EXTENT': '313648.347000000,333320.347000000,5516570.373100000,5544211.373100000 [EPSG:26911]',
    'NODATA': 0,
    'OPTIONS': 'COMPRESS=DEFLATE|PREDICTOR=2|ZLEVEL=9|TILED=YES',
    'DATA_TYPE': 0,  # Byte for binary data
    'INIT': None,
    'INVERT': False,
    'EXTRA': '',
    'OUTPUT': '/srv/extrassd/2025_walkability/export_ready/buildings_raster_compressed.tif'
})
```

#### 6.2.2 Segmentation Polygons Conversion

```python
processing.run("gdal:rasterize", {
    'INPUT': '/srv/extrassd/2025_walkability/walkability_segment_zonal_stats.gpkg|layername=full_seg',
    'FIELD': 'mean_0',  # Use mean spectral value as raster values
    'BURN': None,
    'USE_Z': False,
    'UNITS': 0,
    'WIDTH': 19672,
    'HEIGHT': 27641,
    'EXTENT': '313648.347000000,333320.347000000,5516570.373100000,5544211.373100000 [EPSG:26911]',
    'NODATA': -9999,
    'OPTIONS': 'COMPRESS=DEFLATE|PREDICTOR=2|ZLEVEL=9|TILED=YES',
    'DATA_TYPE': 5,  # Float32 for spectral values
    'INIT': None,
    'INVERT': False,
    'EXTRA': '',
    'OUTPUT': '/srv/extrassd/2025_walkability/export_ready/segments_spectral_raster.tif'
})
```

#### 6.2.3 Walkable Areas (Non-Building) Conversion

```python
processing.run("gdal:rasterize", {
    'INPUT': '/srv/extrassd/2025_walkability/walkability_450_650_nobuilding.gpkg|layername=parking',
    'FIELD': '',
    'BURN': 1,
    'USE_Z': False,
    'UNITS': 0,
    'WIDTH': 19672,
    'HEIGHT': 27641,
    'EXTENT': '313648.347000000,333320.347000000,5516570.373100000,5544211.373100000 [EPSG:26911]',
    'NODATA': 0,
    'OPTIONS': 'COMPRESS=DEFLATE|PREDICTOR=2|ZLEVEL=9|TILED=YES',
    'DATA_TYPE': 0,  # Byte for binary walkability
    'INIT': None,
    'INVERT': False,
    'EXTRA': '',
    'OUTPUT': '/srv/extrassd/2025_walkability/export_ready/walkable_areas_raster.tif'
})
```

### 6.3 Compression and Optimization Standards

#### Compression Parameters

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `COMPRESS=DEFLATE` | Lossless compression | Reduces file size significantly |
| `PREDICTOR=2` | Horizontal differencing | Enhances compression for spatial data |
| `ZLEVEL=9` | Maximum compression | Optimal for cloud storage |
| `TILED=YES` | Tiled structure | Improves access performance |
| `BIGTIFF=YES` | Large file support | Handles datasets > 4GB |

### 6.4 Individual Layer Export for Google Drive

Create optimized versions of each layer for cloud storage:

```bash
# Building footprints
gdal_translate \
    -co COMPRESS=DEFLATE \
    -co PREDICTOR=2 \
    -co ZLEVEL=9 \
    -co TILED=YES \
    /srv/extrassd/2025_walkability/export_ready/buildings_raster_compressed.tif \
    /srv/extrassd/2025_walkability/google_drive_export/kelowna_buildings_walkability.tif

# Walkable surface areas
gdal_translate \
    -co COMPRESS=DEFLATE \
    -co PREDICTOR=2 \
    -co ZLEVEL=9 \
    -co TILED=YES \
    /srv/extrassd/2025_walkability/export_ready/walkable_areas_raster.tif \
    /srv/extrassd/2025_walkability/google_drive_export/kelowna_walkable_surface.tif

# Spectral segmentation
gdal_translate \
    -co COMPRESS=DEFLATE \
    -co PREDICTOR=3 \
    -co ZLEVEL=9 \
    -co TILED=YES \
    /srv/extrassd/2025_walkability/export_ready/segments_spectral_raster.tif \
    /srv/extrassd/2025_walkability/google_drive_export/kelowna_spectral_segments.tif
```

### 6.5 Batch Processing Script

Automate the conversion and export process:

```python
import processing
import os

# Define standard parameters
STANDARD_PARAMS = {
    'WIDTH': 19672,
    'HEIGHT': 27641,
    'EXTENT': '313648.347000000,333320.347000000,5516570.373100000,5544211.373100000 [EPSG:26911]',
    'NODATA': 0,
    'OPTIONS': 'COMPRESS=DEFLATE|PREDICTOR=2|ZLEVEL=9|TILED=YES'
}

# Vector layers to convert
vector_layers = [
    {
        'input': '/srv/extrassd/2025_walkability/kelowna_building_outline.gpkg|layername=building_outlines',
        'output': '/srv/extrassd/2025_walkability/google_drive_export/buildings.tif',
        'burn_value': 1,
        'data_type': 0
    },
    {
        'input': '/srv/extrassd/2025_walkability/walkability_segment_zonal_stats.gpkg|layername=full_seg',
        'output': '/srv/extrassd/2025_walkability/google_drive_export/segments.tif',
        'field': 'mean_0',
        'data_type': 5
    },
    {
        'input': '/srv/extrassd/2025_walkability/walkability_450_650_nobuilding.gpkg|layername=parking',
        'output': '/srv/extrassd/2025_walkability/google_drive_export/walkable_surfaces.tif',
        'burn_value': 1,
        'data_type': 0
    }
]

# Process each layer
for layer in vector_layers:
    params = STANDARD_PARAMS.copy()
    params['INPUT'] = layer['input']
    params['OUTPUT'] = layer['output']
    params['DATA_TYPE'] = layer['data_type']
    
    if 'field' in layer:
        params['FIELD'] = layer['field']
    else:
        params['BURN'] = layer['burn_value']
    
    processing.run("gdal:rasterize", params)
    print(f"Processed: {layer['output']}")
```

### 6.6 File Size Optimization Results

Expected compression ratios for Google Drive storage:

| Layer Type | Uncompressed | Compressed | Reduction |
|------------|-------------|------------|-----------|
| Binary (Buildings) | ~500MB | ~50MB | 90% |
| Spectral Values | ~2GB | ~400MB | 80% |
| Multi-band Composite | ~5GB | ~800MB | 84% |

### 6.7 Cloud Storage Organization

Recommended Google Drive folder structure:
```
Kelowna_Walkability_Analysis/
├── Raw_Data/
│   ├── kelowna_buildings_walkability.tif
│   ├── kelowna_walkable_surface.tif
│   └── kelowna_spectral_segments.tif
├── Processed/
│   └── walkability_comprehensive_dataset.tif
└── Documentation/
    ├── processing_log.md
    └── metadata.xml
```

### 6.8 Quality Control and Validation

Verify exported datasets before upload:

```bash
# Check spatial properties
gdalinfo /srv/extrassd/2025_walkability/google_drive_export/kelowna_buildings_walkability.tif

# Validate compression
gdalinfo -stats -hist /srv/extrassd/2025_walkability/google_drive_export/kelowna_walkable_surface.tif

# Verify coordinate system consistency
gdalsrsinfo -V /srv/extrassd/2025_walkability/google_drive_export/kelowna_spectral_segments.tif
```


---

## Quality Assurance - Recommended

### Validation Checkpoints
1. **Coordinate system consistency** across all processing steps
2. **Geometric validity** before spatial operations
3. **Attribute preservation** through processing chain
4. **Spatial accuracy** of segmentation boundaries
5. **Statistical integrity** of zonal calculations

### Expected Outputs
- Segmented vector polygons with spectral statistics
- Non-building area polygons for walkability analysis
- Binary raster masks for spatial modeling
- Documented processing parameters for reproducibility

---

## Technical Requirements

### Software Dependencies
- QGIS 3.x with Processing framework
- Orfeo Toolbox (OTB) ≥ 7.0
- GDAL/OGR ≥ 3.0
- Python processing environment

### Hardware Recommendations
- **RAM**: Minimum 16GB for 30cm resolution imagery
- **Storage**: SSD recommended for intermediate files
- **Processing**: Multi-core CPU for tiled operations



# Walkability Buffer Analysis and Creek processing

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


## Overview

This document outlines the complete data processing pipeline for walkability analysis in urban environments. The workflow transforms high-resolution orthophotos into segmented vector datasets suitable for walkability assessment and spatial analysis.

## Prerequisites

- QGIS 3.x with Processing Toolbox
- Orfeo Toolbox (OTB) plugin
- GDAL/OGR tools
- Input data: High-resolution orthophotos (10cm GSD)
- Building footprint vector data

---


## Next Steps

1. Further analysis of walkability metrics using the processed data
2. Integration with demographic data for population-weighted walkability assessment
3. Visualization of results for urban planning applications

