import pandas as pd
import geopandas as gpd
from shapely import geometry
import mercantile
from tqdm import tqdm
import os
import tempfile

# Geometry copied from https://geojson.io
aoi_geom = {
    "coordinates": [
        [
            [-71.779491, 42.246624], 
            [-71.779491, 42.260474], 
            [-71.775800, 42.246624],
            [-71.775800, 42.260474]
            #[-122.16484503187519, 47.69090474454916],
           # [-122.16484503187519, 47.6217555345674],
            #[-122.06529607517405, 47.6217555345674],
            #[-122.06529607517405, 47.69090474454916],
            #[-122.16484503187519, 47.69090474454916],
        ]
    ],
    "type": "Polygon",
}
aoi_shape = geometry.shape(aoi_geom)
minx, miny, maxx, maxy = aoi_shape.bounds

output_fn = "example_massach.geojson"

quad_keys = set()
for tile in list(mercantile.tiles(minx, miny, maxx, maxy, zooms=9)):
    quad_keys.add(mercantile.quadkey(tile))
quad_keys = list(quad_keys)
print(f"The input area spans {len(quad_keys)} tiles: {quad_keys}")



df = pd.read_csv(
    "https://minedbuildings.z5.web.core.windows.net/global-buildings/dataset-links.csv", dtype=str
)
df.head()

idx = 0
combined_gdf = gpd.GeoDataFrame()
with tempfile.TemporaryDirectory() as tmpdir:
    # Download the GeoJSON files for each tile that intersects the input geometry
    tmp_fns = []
    for quad_key in tqdm(quad_keys):
        rows = df[df["QuadKey"] == quad_key]
        if rows.shape[0] == 1:
            url = rows.iloc[0]["Url"]

            df2 = pd.read_json(url, lines=True)
            df2["geometry"] = df2["geometry"].apply(geometry.shape)

            gdf = gpd.GeoDataFrame(df2, crs=4326)
            fn = os.path.join(tmpdir, f"{quad_key}.geojson")
            tmp_fns.append(fn)
            if not os.path.exists(fn):
                gdf.to_file(fn, driver="GeoJSON")
        elif rows.shape[0] > 1:
            raise ValueError(f"Multiple rows found for QuadKey: {quad_key}")
        else:
            raise ValueError(f"QuadKey not found in dataset: {quad_key}")

    # Merge the GeoJSON files into a single file
    for fn in tmp_fns:
        gdf = gpd.read_file(fn)  # Read each file into a GeoDataFrame
        gdf = gdf[gdf.geometry.within(aoi_shape)]  # Filter geometries within the AOI
        gdf['id'] = range(idx, idx + len(gdf))  # Update 'id' based on idx
        idx += len(gdf)
        combined_gdf = pd.concat([combined_gdf,gdf],ignore_index=True)




combined_gdf = combined_gdf.to_crs('EPSG:4326')
combined_gdf.to_file(output_fn, driver='GeoJSON')

