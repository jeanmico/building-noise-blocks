# identifies objects in between a point and a road.
# User-supplied data (must be compatible with read_sf)
#  - points
#  - roads
# buildings are sourced from: https://github.com/microsoft/GlobalMLBuildingFootprints

#================#
# USER INPUTS ####
#================#

buffer_radius = 750  # provide radius in meters
path_to_roads = "C:/Users/jeanmico/projects/footprints_shade/VMT_2023.geojson"
#path_to_points = ""

#===========#
# SET UP ####
#===========#
# LIBRARIES ####
library(sf)
library(ggplot2)

#=============#
# GET DATA ####
#=============#

# TODO: read in points
#my_points = sf_read(path_to_points)
my_points = data.frame(id = c(143, 455),
                      lon = c(-71.778246, -71.776622),
                      lat = c(42.254431, 42.251837))
my_points = st_as_sf(my_points, coords = c("lat", "lon"), crs=4326)

# TODO: construct bounding box based on points of interest and buffer
  # this is a placeholder 

# TODO: execute call to download building footprints
path_to_buildings = "C:/Users/jeanmico/projects/building_noise_blocks/building-noise-blocks/example_massach.geojson"
building_prints = read_sf(path_to_buildings)

my_bounds = st_as_sfc(st_bbox(building_prints))
st_crs(my_bounds) = 4326

roads = read_sf(path_to_roads)
st_crs(roads) = 4326
st_crs(building_prints) = 4326
st_crs(building_prints) == st_crs(roads)


# clip if needed to reduce file sizes
roads_clip = roads[my_bounds,]
buildings_clip = building_prints[my_bounds,]
my_centers = st_centroid(buildings_clip)

# garbage cleanup
#roads = NULL 
#building_prints = NULL
#gc()

# sync up the columns yay
cols_add_builds = setdiff(colnames(roads_clip), colnames(buildings_clip))
cols_add_roads = setdiff(colnames(buildings_clip), colnames(roads_clip))

roads_clip[cols_add_roads] <- NA
buildings_clip[cols_add_builds] <- NA
buildings_clip = buildings_clip[, colnames(roads_clip)]

fulldf = rbind(buildings_clip, roads_clip)

colnames(buildings_clip) == colnames(roads_clip)

# into a units-based coorinate system
flatdf = st_transform(fulldf, crs = 102039)
my_points = st_transform(my_points, crs = 102039)

mybuffers = st_buffer(my_points, buffer_radius)
mybuffers = st_join(mybuffers, flatdf)

#mygeo = st_join(my_points, fulldf)

myplt = ggplot() + 
  geom_sf(data = mybuffers) + 
  geom_sf(data = my_points) + 
  geom_sf(data = flatdf) + 
  theme_bw()
myplt
