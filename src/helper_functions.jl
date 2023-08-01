# +
# helper_functions.jl
#
# collection of functions
#
# function push_plot_to_gui!(plot, box, wnd)
# -- adds the plot to a Gtk box located in a window
#
# function refreshplot(gplot::InspectDR.GtkPlot)
# -- refreshes the Gtk plot on screen
#
# function addpoint!(x::Float64,y::Float64,plot::InspectDR.Plot2D,
#  				     gplot::InspectDR.GtkPlot)
# -- adds an x/y point to the plot
#

# UPDATE COORDS LINE 369

function parse_missing(N)
    return str = try
        @sprintf("%.1f", N)
    catch
        "missing"
    end
end

function parse_missing1(N)
    return str = try
        @sprintf("%.2f", N)
    catch
        "missing"
    end
end

# parse_box functions read a text box and returns the formatted result
function parse_box(s::String, default::Float64)
    x = get_gtk_property(gui[s], :text, String)
    y = try
        parse(Float64, x)
    catch
        y = default
    end
end

function parse_box(s::String, default::Int)
    x = get_gtk_property(gui[s], :text, String)
    y = try
        parse(Int, x)
    catch
        y = default
    end
end

function parse_box(s::String, default::Missing)
    x = get_gtk_property(gui[s], :text, String)
    y = try
        parse(Float64, x)
    catch
        y = missing
    end
end

function parse_box(s::String)
    x = get_gtk_property(gui[s], :active_id, String)
    y = Symbol(x)
end

function set_SMPS_config()
    (#column == :TSI) && ((r₁, r₂, l) = (9.37e-3, 1.961e-2, 0.44369))
    #(column == :HFDMA) && ((r₁, r₂, l) = (0.05, 0.058, 0.6))
    (r₁, r₂, l) = (2.4e-3, 50.4e-3, 10e-3))
    form = :radial
    Λˢᵐᵖˢ = get_DMA_config(
        conf["DMA"]["Qsh"],
        conf["DMA"]["Qsa"],
        conf["DMA"]["T"],
        conf["DMA"]["p"],
        conf["DMA"]["polarity"] |> Symbol,
        Symbol(conf["DMA"]["model"]),
    )
    #DMAconfig(t, p, qsa, qsh, r₁, r₂, l, leff, polarity, 6, form)
    # z1, z2 = vtoz(Λˢᵐᵖˢ, 10000.0), vtoz(Λˢᵐᵖˢ, 10.0)
    # bins = 30
    # δˢᵐᵖˢ = setupDMA(Λˢᵐᵖˢ, z1, z2, bins)
end


function powerSMPSswitch(widget::Gtk.GtkSwitchLeaf, state::Bool)
    push!(powerSMPS, state)
end

function reset_scan()
    set_voltage_SMPS("StartDiameter", "StartV")
    set_voltage_SMPS("EndDiameter", "EndV")
    set_voltage_SMPS("ClassifierDiameterSMPS", "ClassifierV")

    a = pwd() |> x -> split(x, "/")
    path = mapreduce(a -> "/" * a, *, a[2:3]) * "/Data/"
    outfile = path * "yyyymmdd_hhmm.csv"
    Gtk.set_gtk_property!(gui["DataFile"], :text, outfile)
    Gtk.set_gtk_property!(gui["ScanNumber"], :text, "0")
    Gtk.set_gtk_property!(gui["ScanCounter"], :text, "1000")
    Gtk.set_gtk_property!(gui["ScanState"], :text, "HOLD")
    Gtk.set_gtk_property!(gui["setV"], :text, "0")
end


# if StartDiameter changes then Recompute Voltage
function startDiameterChanged(widget::GtkEntryLeaf, EventAny::Gtk.GdkEventAny)
    set_voltage_SMPS("StartDiameter", "StartV")
end

# if endDiameter changes then Recompute Voltage
function endDiameterChanged(widget::GtkEntryLeaf, EventAny::Gtk.GdkEventAny)
    set_voltage_SMPS("EndDiameter", "EndV")
end

function set_voltage_SPINBox(sbox::GtkSpinButtonLeaf, destination::String)
    D = get_gtk_property(sbox, "value", Float64)
    setV = ztov(Λ, dtoz(Λ, D * 1e-9))
    if setV > 10000.0
        setV = 10000.0
        D = ztod(Λ, 1, vtoz(Λ, 10000.0))
        set_gtk_property!(sbox, "value", round(D, digits = 0))
    elseif setV < 10.0
        setV = 10.0
        D = ztod(Λ, 1, vtoz(Λ, 10.0))
        set_gtk_property!(sbox, "value", round(D, digits = 0))
    end
    set_gtk_property!(gui[destination], :text, @sprintf("%d", setV))
    return setV
end

function set_voltage_SMPS(source::String, destination::String)
    D = parse_box(source, 100.0)
    (D == 100.0) && set_gtk_property!(gui[source], :text, "100")
    V = ztov(Λ, dtoz(Λ, D * 1e-9))
    if V > 10000.0
        V = 10000.0
        D = ztod(Λ, 1, vtoz(Λ, 10000.0))
        set_gtk_property!(gui[source], :text, @sprintf("%0.0f", D))
    elseif V < 10.0
        V = 10.0
        D = ztod(Λ, 1, vtoz(Λ, 10.0))
        set_gtk_property!(gui[source], :text, @sprintf("%0.0f", D))
    end
    set_gtk_property!(gui[destination], :text, @sprintf("%d", V))
end

function graph1(yaxis)
    plot = InspectDR.transientplot(yaxis, title = "")
    InspectDR.overwritefont!(plot.layout, fontname = "Helvetica", fontscale = 1.2)
    plot.layout[:enable_legend] = true
    plot.layout[:halloc_legend] = 170
    plot.layout[:halloc_left] = 50
    plot.layout[:enable_timestamp] = false
    plot.layout[:length_tickmajor] = 10
    plot.layout[:length_tickminor] = 6
    plot.layout[:format_xtick] = InspectDR.TickLabelStyle(UEXPONENT)
    plot.layout[:frame_data] = InspectDR.AreaAttributes(
        line = InspectDR.line(style = :solid, color = black, width = 0.5),
    )
    plot.layout[:line_gridmajor] =
        InspectDR.LineStyle(:solid, Float64(0.75), RGBA(0, 0, 0, 1))

    plot.xext = InspectDR.PExtents1D()
    plot.xext_full = InspectDR.PExtents1D(0, 205)

    a = plot.annotation
    a.xlabel = ""
    a.ylabels = ["Counts(#)"]

    return plot
end


# -- adds an x/y point to the plot
function addpoint!(
    x::Float64,
    y::Float64,
    plot::InspectDR.Plot2D,
    gplot::InspectDR.GtkPlot,
    strip::Int,
    autoscale::Bool,
)

    push!(plot.data[strip].ds.x, x)
    push!(plot.data[strip].ds.y, y)
    cut = plot.data[strip].ds.x[end] - bufferlength
    ii = plot.data[strip].ds.x .<= cut
    deleteat!(plot.data[strip].ds.x, ii)
    deleteat!(plot.data[strip].ds.y, ii)
    plot.xext = InspectDR.PExtents1D()
    plot.xext_full =
        InspectDR.PExtents1D(plot.data[strip].ds.x[1], plot.data[strip].ds.x[end])

    if autoscale == true
        miny, maxy = Float64[], Float64[]
        for x in plot.data
            push!(miny, minimum(x.ds.y))
            push!(maxy, maximum(x.ds.y))
        end
        miny = minimum(miny)
        maxy = maximum(maxy)
        graph = plot.strips[1]
        graph.yext = InspectDR.PExtents1D()
        graph.yext_full = InspectDR.PExtents1D(miny, maxy)
    end

    refreshplot(gplot)
end

function addseries!(
    x::Array{Float64},
    y::Array{Float64},
    plot::InspectDR.Plot2D,
    gplot::InspectDR.GtkPlot,
    strip::Int,
    autoscalex::Bool,
    autoscaley::Bool,
)

    plot.data[strip].ds.x = x
    plot.data[strip].ds.y = y
    if autoscaley == true
        miny, maxy = Float64[], Float64[]
        for x in plot.data
            push!(miny, minimum(x.ds.y))
            push!(maxy, maximum(x.ds.y))
        end
        miny = minimum(miny)
        maxy = maximum(maxy)
        graph = plot.strips[1]
        graph.yext = InspectDR.PExtents1D()
        graph.yext_full = InspectDR.PExtents1D(miny, maxy)
    end

    if autoscalex == true
        minx, maxx = Float64[], Float64[]
        for x in plot.data
            push!(minx, minimum(x.ds.x))
            push!(maxx, maximum(x.ds.x))
        end
        minx = minimum(minx)
        maxx = maximum(maxx)
        plot.xext = InspectDR.PExtents1D()
        plot.xext_full = InspectDR.PExtents1D(minx, maxx)
    end

    refreshplot(gplot)
end
# -- adds the plot to a Gtk box located in a window
function push_plot_to_gui!(plot::InspectDR.Plot2D, box::GtkBoxLeaf, wnd::GtkWindowLeaf)

    mp = InspectDR.Multiplot()
    InspectDR._add(mp, plot)
    grd = Gtk.Grid()
    Gtk.set_gtk_property!(grd, :column_homogeneous, true)
    status = _Gtk.Label("")
    push!(box, grd)
    gplot = InspectDR.GtkPlot(false, wnd, grd, [], mp, status)
    InspectDR.sync_subplots(gplot)
    return mp, gplot
end

# -- setup of the frame for a particular GUI plot
# Traced from InspectDR source code without title refresh
function refreshplot(gplot::InspectDR.GtkPlot)
    if !gplot.destroyed
        set_gtk_property!(gplot.grd, :visible, false)
        InspectDR.sync_subplots(gplot)
        for sub in gplot.subplots
            InspectDR.render(sub, refreshdata = true)
            Gtk.draw(sub.canvas)
        end
        set_gtk_property!(gplot.grd, :visible, true)
        Gtk.showall(gplot.grd)
        sleep(eps(0.0))
    end
end

function smps_scan_termination(smsp_state)
    if "DONE" .== filter(s -> s == "DONE", smsp_state)
        push!(dmaState, :CLASSIFIER)
    end
end

function smps_plotting()
    #try
    i = smps_elapsed_time.value
    DpBuffer[i] = Dp.value
    concSBuffer[i] = datapacket.value[:count]
    stateBuffer[i] = datapacket.value[:smpsState]
    TemTotal += datapacket.value[:count]
    #catch
        #println("I fail")
#   end
end

function produceplot()
    ii = .~isnan.(DpBuffer) .& .~isnan.(concSBuffer) .& .~isnothing(stateBuffer)
    
    jj = stateBuffer[ii] .== "UPSCAN"
    kk = stateBuffer[ii] .== "DOWNSCAN"

    # CHECK THAT JJ IS NOT EMPTY
    if datapacket.value[:smpsState] == "UPSCAN"
        addseries!(DpBuffer[ii][jj], concSBuffer[ii][jj], plot5, gplot5, 1, false, true)
    end
    if datapacket.value[:smpsState] == "DOWNSCAN"
        addseries!(reverse(DpBuffer[ii][kk].+ 5), reverse(concSBuffer[ii][kk]), plot5, gplot5, 2, false, true)
    end
end

function update_mapdata(lon1, lat1, lon2, lat2; osm_addr=osm_addr)
        
    prune_map(lon1, lat1, lon2, lat2)
    md = OpenStreetMapX.get_map_data(osm_addr;#"/home/lcai8/Downloads/code notebook/osm_maps/NCSUcentennial.osm"; 
        trim_to_connected_graph = true, use_cache = false)
    return md
end

function relative_loc(lat,lon, mapdata)
    lat_diff,lon_diff,lat_ref,lon_ref,lat_cent,lon_cent = latlon_paras(mapdata)
    lat_enu = 2*(lat - lat_cent)/lat_diff * lat_ref
    lon_enu = 2*(lon - lon_cent)/lon_diff * lon_ref
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

function smooth_locations(lats,lons,cons; npts = 10, smpts = 0)
    ### smpts refer to rolling mean, npts indicates the number of points to be averaged
    if smpts > 0
        cons = rollmean(cons, smpts)
        stps = floor(Int,smpts/2)
        lats = lats[stps:end-stps]
        lons = lons[stps:end-stps]
    else
        cons = map(i->mean(cons[i:i+npts]),1:npts:(length(cons)-npts))
        stps = floor(Int,npts/2)
        lats = lats[stps+1:npts:end-stps-1]
        lons = lons[stps+1:npts:end-stps-1]
    end
    lenscheck = minimum(length, [lats, lons, cons])
    return DataFrame(lat=lats[1:lenscheck],lon=lons[1:lenscheck],con=cons[1:lenscheck])
end

function map_loc_correction(lat_series,lon_series,con_series,respts,mapdata)
    enu_loc = DataFrame(lat=[],lon=[])
    for i in 1:size(lat_series)[1]
        push!(enu_loc,relative_loc(lat_series[i],lon_series[i], mapdata))
    end
    if respts > 0
        sm_loc = smooth_locations(enu_loc[!,:lat],enu_loc[!,:lon],con_series,npts=respts)
        return sm_loc
    else 
        return DataFrame(lat=enu_loc.lat,lon=enu_loc.lon,con=con_series)
    end
end

### UPDATE MAP COORDS
function maps_basic(lon1 = datapacket.value[:lon]-0.02,
    lat1= datapacket.value[:lat]-0.02, 
    lon2 = datapacket.value[:lon]+0.02, 
    lat2 = datapacket.value[:lat]+0.02,
    date = "20230131",
    respts = 10, osm_addr="/data/minimap.osm";
    lat_series,lon_series,con_series)

    mapdata = update_mapdata(lon1, lat1, lon2, lat2, osm_addr=osm_addr)
    ############## map background settings #############
    pf = OpenStreetMapXPlot.plotmap(
        mapdata.nodes,
        OpenStreetMapX.ENU(mapdata.bounds);
        roadways = mapdata.roadways,
        roadwayStyle = OpenStreetMapXPlot.LAYER_STANDARD,
        width = 650,
        height = 550,
        km=false,
        )
    println("Map initialization compelete!")
    minilen = minimum(length, [lat_series, lon_series, con_series])
    if  minilen >= respts
        sm_loc = map_loc_correction(lat_series[1:minilen],lon_series[1:minilen],con_series[1:minilen],respts,mapdata)
        pf = scatter!(sm_loc.lon,sm_loc.lat,zcolor=sm_loc.con,
            markertrokewidth = 0, label = nothing,
            c = cgrad(:jet,scale=log), ### log scale concentration, only for colorbar
            colorbar = :true, #Plots.gr_colorbar_title(pf, titile=L"Concentration (#/cm^3)"),
            colorbar_ticks  = [0, 10, 100, 1000, 10000],
            xlabel = "Lat (m)", ylabel = "Lon (m)",
            bottom_margin = 15px, right_margin = 40px)
    else
        sm_loc = map_loc_correction(lat_series[1:minilen],lon_series[1:minilen],con_series[1:minilen],0,mapdata)
        pf = scatter!(sm_loc.lon,sm_loc.lat,zcolor=sm_loc.con,
            markertrokewidth = 0, label = nothing,
            c = cgrad(:jet,scale=log), ### log scale concentration, only for colorbar
            colorbar = :true,#Plots.gr_colorbar_title(L"Concentration (#/cm^3)"),
            colorbar_ticks  = [0, 10, 100, 1000, 10000],
            xlabel = "Lat (m)", ylabel = "Lon (m)",
            bottom_margin = 15px, right_margin = 40px)
    end
    savefig(pf,"/home/daq.local/Data/EPA/tracks/track_"*date*".png")
    #set_gtk_property!(gui["DriveStartt"], :text, string(Dates.format(now(),"HH:MM:SS")))
    return mapdata, pf
end

function plotincanvas(imgbox = imgbox, can = can, addr = "/home/daq.local/Data/EPA/tracks/track_"*datenow*".png")
    @guarded draw(can) do _
        ctx = getgc(can)
        img = read_from_png(addr)
        set_source_surface(ctx, img, 0, 0)
        paint(ctx)
    end
    draw(can)
    #id = signal_connect((w) -> draw(can), "value-changed")
    Gtk.showall(imgbox)
    show(can)
end

function fast_update(pp, x, y, c, date)
    series = pp.series_list[end]
    series.plotattributes[:x] = x
    series.plotattributes[:y] = y
    series.plotattributes[:marker_z] = c

    minc = minimum(c)
    maxc = maximum(c)
    plot!(pp; clim = (minc, maxc))

    savefig(pp,"/home/daq.local/Data/EPA/tracks/track_"*date*".png") #### can create a new address to save the image and push to GUI
    #return display(pp)
end


function plotmytrack(map,mapdata,lat_series,lon_series,con_series,respts,date)
    minilen = minimum(length, [lat_series, lon_series, con_series])
    if minilen >= respts
        sm_loc = map_loc_correction(lat_series[1:minilen],lon_series[1:minilen],con_series[1:minilen],respts,mapdata)
        fast_update(map, sm_loc.lon,sm_loc.lat,sm_loc.con,date)
    elseif minilen >= 1
        sm_loc = map_loc_correction(lat_series[1:minilen],lon_series[1:minilen],con_series[1:minilen],0,mapdata)
        fast_update(map, sm_loc.lon,sm_loc.lat,sm_loc.con,date)
        println("I don't have enough data for smoothing")
    else
        println(minilen, "I don't have any data to plot!")
    end
end







