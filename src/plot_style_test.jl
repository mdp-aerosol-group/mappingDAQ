using OpenStreetMapXPlot
pyplot()
using OpenStreetMapX

osm_addr = "/home/daq.local/opt/mappingDAQ/src/minimap.osm"

mapdata = OpenStreetMapX.get_map_data(osm_addr;#"/home/lcai8/Downloads/code notebook/osm_maps/NCSUcentennial.osm"; 
        trim_to_connected_graph = true, use_cache = false)

pf = OpenStreetMapXPlot.plotmap(
    mapdata.nodes,
    OpenStreetMapX.ENU(mapdata.bounds);
    roadways = mapdata.roadways,
    roadwayStyle = OpenStreetMapXPlot.LAYER_STANDARD,
    width = 600,
    height = 500,
    use_plain_pyplot = true,
    km=false,
    )
sm_loc = map_loc_correction(Lat_buffer[:],Lon_buffer[:],Con_buffer[:],0,mapdata)
scatter!(sm_loc.lon,sm_loc.lat,zcolor=sm_loc.con,
    label = "",
    cmap = cgrad(:jet,scale=log), edgecolors = nothing,### log scale concentration, only for colorbar
    colorbar = :true, colorbar_title = L"Concentration (#/cm^{-3})",
    colorbar_ticks  = [0, 10, 100, 1000, 10000],
    xlabel = "Lat (m)", ylabel = "Lon (m)",
    bottom_margin = 15px, right_margin = 20px)


PyPlot.display_figs()