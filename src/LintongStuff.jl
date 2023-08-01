
function update_mapdata(lon1, lat1, lon2, lat2; osm_addr=osm_addr)
        
    prune_map(lon1, lat1, lon2, lat2)
    md = get_map_data(osm_addr;#"/home/lcai8/Downloads/code notebook/osm_maps/NCSUcentennial.osm"; 
        trim_to_connected_graph = true, use_cache = false)
    return md
end

function relative_loc(lat,lon, mapdata)
    lat_diff,lon_diff,lat_ref,lon_ref,lat_cent,lon_cent = latlon_paras(mapdata)
    lat_enu = (lat - lat_cent)/lat_diff * lat_ref
    lon_enu = (lon - lon_cent)/lon_diff * lon_ref
    return lat_enu, lon_enu
end

function latlon_paras(md)
    lat_diff = md.bounds.max_y - md.bounds.min_y
    lon_diff = md.bounds.max_x - md.bounds.min_x
    lat_bounds = OpenStreetMapX.ENU(md.bounds).max_y
    lon_bounds = OpenStreetMapX.ENU(md.bounds).max_x
    lat_cent = OpenStreetMapX.center(md.bounds).lat
    lon_cent = OpenStreetMapX.center(md.bounds).lon
    return lat_diff,lon_diff, lat_bounds,lon_bounds, lat_cent,lon_cent
end

function smooth_locations(lats,lons,cons; npts = 15, smpts = 0)
    ### smpts refer to rolling mean, npts indicates the number of points to be averaged
    if smpts > 0
        cons = rollmean(cons, smpts)
        stps = floor(Int,smpts/2)
        lats = lats[stps:end-stps]
        lons = lons[stps:end-stps]
    else
        cons = map(i->mean(cons[i:i+npts]),1:npts:(size(cons)[1]-npts))
        stps = floor(Int,npts/2)
        lats = lats[stps+1:npts:end-stps-1]
        lons = lons[stps+1:npts:end-stps-1]
    end
    return DataFrame(lat=lats,lon=lons,con=cons)
end

function map_loc_correction(lat_series,lon_series,con_series,respts,mapdata)
    enu_loc = DataFrame(lat=[],lon=[])
    for i in 1:size(df)[1]
        push!(enu_loc,relative_loc(lat_series[i],lon_series[i], mapdata))
    end

    sm_loc = smooth_locations(enu_loc[!,:lat],enu_loc[!,:lon],con_series,npts=respts)

    return sm_loc
end

function maps_basic(lon1 = datapacket.value[:lon]-0.02,
    lat1= datapacket.value[:lat]-0.02, 
    lon2 = datapacket.value[:lon]+0.02, 
    lat2 = datapacket.value[:lat]+0.02,
    date = "20230131",
    respts = 10, osm_addr="/data/minimap.osm";
    lat_series,lon_series,con_series)

    #masterdf = dataframe[(starttime .<= dataframe.t .<= stoptime), :]
    mapdata = update_mapdata(lon1, lat1, lon2, lat2, osm_addr=osm_addr)

    sm_loc = map_loc_correction(lat_series,lon_series,con_series,respts,mapdata)

    ############## map background settings #############
    pf = OpenStreetMapXPlot.plotmap(
        mapdata.nodes,
        OpenStreetMapX.ENU(mapdata.bounds);
        roadways = mapdata.roadways,
        roadwayStyle = OpenStreetMapXPlot.LAYER_STANDARD,
        width = 600,
        height = 600,
        )
    pf = scatter!(sm_loc.lon,sm_loc.lat,zcolor=sm_loc.con,
        markertrokewidth = 0, label = nothing,
        c = cgrad(:jet,scale=log), ### log scale concentration, only for colorbar
        colorbar = :true, colorbar_title = L"Concentration (#/cm^{-3})",
        xlabel = "Lat (m)", ylabel = "Lon (m)",
        bottom_margin = 15px, right_margin = 20px)
    savefig(pf,"track_"*date*".png")

    return mapdata, pf
end

function fast_update(pp, x, y, c)
    series = pp.series_list[end]
    series.plotattributes[:x] = x
    series.plotattributes[:y] = y
    series.plotattributes[:marker_z] = c
    
    savefig(pp,"track_"*date*".png") #### can create a new address to save the image and push to GUI
    return display(pp)
end


function plotmytrack(map,mapdata,lat_series,lon_series,con_series,respts)
    n = length(lat_series)
    m = length(con_series)
    i = n>m ? i=m : i=n
    sm_loc = map_loc_correction(lat_series[1:i],lon_series[1:i],con_series[1:i],respts,mapdata)
    fast_update(map, sm_loc.lon,sm_loc.lat,sm_loc.con)
end

##################################### test codes #####################################

date = "20230501"
path = "/home/daq.local/Data/EPA/"
searchdir(path,key) = filter(x->occursin(key,x), readdir(path))
files = searchdir(path,date)
filter!(x -> occursin("all", x), files)

masterdf = CSV.read(path * files[5], DataFrame)
md,maptest=maps_basic(-78.70,35.75,-78.66,35.80, date,respts, osm_addr,lat_series=masterdf[!,:lat],lon_series=masterdf[!,:lon],con_series=masterdf[!,:N_TSI3025]) 
maps_update(-78.70,35.75,-78.66,35.80,
    "20230501",10,"/home/daq.local/opt/mappingDAQ/src/minimap.osm",
    masterdf = masterdf)


    md = get_map_data(osm_addr;#"/home/lcai8/Downloads/code notebook/osm_maps/NCSUcentennial.osm"; 
        trim_to_connected_graph = true, use_cache = false)
    latlon_paras(md)
    isa(md.nodes, Dict{Int,OpenStreetMapX.LLA})
    (mapdata.bounds)
    md.nodes
    OpenStreetMapX.latlon.(md.nodes)
    keywords = collect(keys(md.nodes))
    
    OpenStreetMapX.ECEF.(md.nodes[keywords[1]])