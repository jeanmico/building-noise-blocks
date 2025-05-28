library(sf)
library(ggplot2)

buffer_radius = 750

#library(osmextract)
#osm_lines = oe_get("us/washington",
#                    layer = "lines", 
#                    stringsAsFactors = FALSE, 
#                    #extra_tags = c('addr:city', 'addr:postcode', 'addr:state', 'addr:street', 'addr:housenumber'),
#                    query = "SELECT * FROM 'lines' WHERE highway IS NOT NULL",
#                    quiet = FALSE)

building_prints = read_sf("C:/Users/jeanmico/projects/footprints_shade/example_massach.geojson")
my_bounds = st_as_sfc(st_bbox(building_prints))
st_crs(my_bounds) = 4326

roads = read_sf("C:/Users/jeanmico/projects/footprints_shade/VMT_2023.geojson")
tmp = roads
st_crs(building_prints) == st_crs(roads)
roads_clip = roads[my_bounds,]
buildings_clip = building_prints[my_bounds,]
my_centers = st_centroid(buildings_clip)

fulldf = st_join(roads_clip, buildings_clip, left = TRUE)
full_clip = fulldf[my_bounds,]

flatdf = st_transform(full_clip, crs = 102039)


# sync up the columns yay
cols_add_builds = setdiff(colnames(roads), colnames(building_prints))
cols_add_roads = setdiff(colnames(building_prints), colnames(roads))

roads[cols_add_roads] <- NA
building_prints[cols_add_builds] <- NA
building_prints = building_prints[, colnames(roads)]

fulldf = rbind(building_prints, roads)

colnames(building_prints) == colnames(roads)


mycoords = data.frame(id = c(143, 455),
                      lon = c(-71.778246, -71.776622),
                      lat = c(42.254431, 42.251837))
mycoords = st_as_sf(mycoords, coords = c("lat", "lon"), crs=4326)

mycoords = st_transform(mycoords, crs = 102039)

mybuffers = st_buffer(mycoords, buffer_radius)

mygeo = st_join(mybuffers, flatsf)

myplt = ggplot() + 
  geom_sf(data = full_clip)
myplt
