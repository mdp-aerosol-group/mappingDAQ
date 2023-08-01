
const Vsbox = gui["VSet"]
const id2 = signal_connect(Vsbox, "value-changed") do widget, others...
    setV = get_gtk_property(Vsbox, :value, Float64)

    println(a)
end

const dsbox = gui["Diameter"]
const id3 = signal_connect(dsbox, "value-changed") do widget, others...
    a = get_gtk_property(dsbox, :value, Float64)
    println(a)
end


function DispGUIOutput()
    set_gtk_property!(gui["readVP"], :text, string(round(datapacket.value[:readVp], digits = 3)))
    set_gtk_property!(gui["readVN"], :text, string(round(datapacket.value[:readVn], digits = 3)))
    set_gtk_property!(gui["readIP"], :text, string(round(datapacket.value[:readIp], digits = 3)))
    set_gtk_property!(gui["readIN"], :text, string(round(datapacket.value[:readIn], digits = 3)))
    set_gtk_property!(gui["readTemp"], :text, string(round(datapacket.value[:T], digits = 3)))
    set_gtk_property!(gui["CPC1Serial"], :text, string(datapacket.value[:N_TSI3776]))
    set_gtk_property!(gui["CPC1Count"], :text, string(datapacket.value[:count]))
    set_gtk_property!(gui["CPC2Serial"], :text, string(datapacket.value[:N_TSI3025]))
    set_gtk_property!(gui["CPC3Serial"], :text, string(datapacket.value[:N_TSI3771]))
    set_gtk_property!(gui["GPSLat"], :text, string(datapacket.value[:lat]))
    set_gtk_property!(gui["GPSLong"], :text, string(datapacket.value[:lon]))
    set_gtk_property!(gui["GPSTime"], :text, string(Dates.format(unix2datetime(datapacket.value[:tgps]),"HH:MM:SS")))
    set_gtk_property!(gui["CompTime"], :text, string(Dates.format(now(),"HH:MM:SS")))
    set_gtk_property!(gui["sonictemp"], :text, string(datapacket.value[:SonicT]))
    set_gtk_property!(gui["uwind"], :text, string(datapacket.value[:uwind]))
    set_gtk_property!(gui["vwind"], :text, string(datapacket.value[:vwind]))
    set_gtk_property!(gui["wwind"], :text, string(datapacket.value[:wwind]))
end

function SMPSOutput()
    set_gtk_property!(gui["ScanState"], :text, string(smps_scan_state.value))
    set_gtk_property!(gui["SMPSt"], :text, string(smps_elapsed_time.value))
    set_gtk_property!(gui["SMPSV"], :text, string(round(datapacket.value[:readVn], digits = 2)))
    set_gtk_property!(gui["SMPSDp"], :text, string(round(Dp.value, digits = 1)))
    set_gtk_property!(gui["smpsCount"], :text, string(datapacket.value[:count]))
    set_gtk_property!(gui["TotalConc"], :text, string(datapacket.value[:N_TSI3025]))
    set_gtk_property!(gui["CountSerial"], :text, string(portCPC1))
    set_gtk_property!(gui["readRH"], :text, string(round(datapacket.value[:RH], digits = 4)))
    #SMPSPlot1(Dp.value,datapacket.value[:count],plot5)
end

function startSMPS()
    push!(dmaState, :SMPS)
    push!(smps_start_time, datetime2unix(now(UTC)))
end

############################################################

global_state = map(_ -> Gtk.get_gtk_property(gui["ModeSelect"], "active-id", String), oneHz)
instrumentStateChanged = Reactive.Signal(0)
TEMcounts = Signal(0)
TEMctimer = Signal(0)

select_box = gui["ModeSelect"]
instrumentChanged = signal_connect(select_box, "changed") do widget, others...
    push!(global_state, Gtk.get_gtk_property(gui["ModeSelect"], "active-id", String))
    push!(instrumentStateChanged,instrumentStateChanged.value+1)
end

spin_voltage_signal = signal_connect(gui["Diameter"],"value-changed") do _
    setV = set_voltage_SPINBox(gui["Diameter"], "VSet")
    set_voltage_SMPS("Diameter", "SMPSDp")
    classifierV.value = setV
end


starttime = Gtk.get_gtk_property(gui["DriveStartt"], :text, String)
starttime = length(starttime) > 0 ? Dates.Time(starttime, "HH:MM:SS") : println("Need to put driving start time!")


stoptime = Gtk.get_gtk_property(gui["DropStopt"], :text, String)
stoptime = length(stoptime) > 0 ? Dates.Time(stoptime, "HH:MM:SS") : println("Need to put driving end time!")

recentermapbutton = signal_connect(gui["Recenter"],"pressed") do _
    global map1, mapdata
    loncen = Gtk.get_gtk_property(gui["XCen"], "value", Float64)
    latcen = Gtk.get_gtk_property(gui["YCen"], "value", Float64)
    scale = Gtk.get_gtk_property(gui["MapScalar"], "value", Float64)
    lonscale = scale * 0.025
    latscale = scale * 0.02
    mapdata, map1 = maps_basic(loncen-lonscale,latcen-latscale,loncen+lonscale,latcen+latscale, datenow,respts, osm_addr,lat_series=Lat_buffer[:],lon_series=Lon_buffer[:],con_series=Con_buffer[:]) 
    plotincanvas()
end


