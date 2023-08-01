using AdafruitUltimateGPS
using CondensationParticleCounters
using YoungModel81000
using DifferentialMobilityAnalyzers
using LabjackU6Library

using Cairo
using LibSerialPort
using Reactive
using Dates
using CSV
using Chain
using DataStructures
using YAML
using DataFrames
using Interpolations
using Printf
using InspectDR
using NumericIO
using Colors
using Underscores

using Gtk
using Lazy
using Statistics
using OrderedCollections
using GeoStats
using RollingFunctions
using LaTeXStrings
using Plots
using Plots.PlotMeasures
using Colors
using Images
import OpenStreetMapX
import OpenStreetMapXPlot

import NumericIO: UEXPONENT
const conf = YAML.load_file("config.yaml")
const oneHz = every(1.0)

(@isdefined wnd) && destroy(wnd)
gui = GtkBuilder(filename = pwd() * "/" * conf["GUI"]["config"]) # Load GUI
wnd = gui["mainWindow"]

imgbox = gui["MappingIMG"]
can = GtkCanvas()
push!(imgbox, can)

include("helper_functions.jl")
include("smps_signals.jl")
include("daq_loops.jl")
include("dma_logic.jl")
include("set_gui_initial_state.jl")
include("prune.jl")
Gtk.showall(wnd)   
##### double check the ports
list_ports()


const portCPC1 = CondensationParticleCounters.config(:TSI3776C, "/dev/ttyUSB0")
const portCPC2 = CondensationParticleCounters.config(:TSI3022, "/dev/ttyUSB1")
const portCPC3 = CondensationParticleCounters.config(:TSI3771, "/dev/ttyUSB2")
const portSONIC = YoungModel81000.config("/dev/ttyUSB3") 
const portGPS = AdafruitUltimateGPS.config("/dev/ttyUSB4")

const dataBufferCPC1 = CircularBuffer{String}(10)
const dataBufferCPC2 = CircularBuffer{String}(10)
const dataBufferCPC3 = CircularBuffer{String}(10)
const dataBufferGPS = CircularBuffer{String}(20)

datenow = Dates.format(now(), dateformat"yyyymmdd")

@async CondensationParticleCounters.stream(
    portCPC1,
    :TSI3776C,
    "/home/daq.local/Data/EPA/" *
    datenow *
    "_TSI3776C.csv",
    dataBufferCPC1,
)
@async CondensationParticleCounters.stream(
    portCPC2,
    :TSI3022,
    "/home/daq.local/Data/EPA/" *
    datenow *
    "_TSI3022.csv",
    dataBufferCPC2,
)
@async CondensationParticleCounters.stream(
    portCPC3,
    :TSI3771,
    "/home/daq.local/Data/EPA/" *
    datenow *
    "_TSI3771.csv",
    dataBufferCPC3,
)
@async YoungModel81000.stream(
    portSONIC,
    "/home/daq.local/Data/EPA/" * datenow * "_sonic.csv",
)
@async AdafruitUltimateGPS.stream(
    portGPS,
    "/home/daq.local/Data/EPA/" * datenow * ".csv",
)

const N_TSI3776 = CircularBuffer{Float64}(3600)
const N_TSI3025 = CircularBuffer{Float64}(3600)
const N_TSI3771 = CircularBuffer{Float64}(3600)
const Lat_buffer = CircularBuffer{Float64}(3600)
const Lon_buffer  = CircularBuffer{Float64}(3600)
const Con_buffer = CircularBuffer{Float64}(3600)
const ts = CircularBuffer{DateTime}(3600)
const startt = now(UTC) |> datetime2unix
const datapacket = Signal((
    t = startt,
    N_TSI3776 = 0.0,
    N_TSI3025 = 0.0,
    N_TSI3771 = 0.0,
    tgps = startt,
    lat = 0.0,
    lon = 0.0,
    T = 0.0,
    RH = 0.0,
    telapse = 0,
    smpsState = "DRIVING",
    setV = 0.0,
    readVp = 0.0,
    readVn = 0.0,
    readIp = 0.0,
    readIn = 0.0,
    count = 0.0,
    uwind = 0.0,
    vwind = 0.0,
    wwind = 0.0,
    SonicT = 0.0,
    globalState = "Concentration"
))


parseN(x) = @chain split(x, ",") getindex(_, 3) parse(Float64, _)
parseN(x::Missing) = 0.0

sleep(1)

function acquire(t)
    AIN, Tk, rawcount, count = labjack_signals.value
    RH = AIN[conf["LJ"]["AIN"]["RH"]+1] * 100.0
    T = AIN[conf["LJ"]["AIN"]["T"]+1] * 100.0 - 40.0
    readVp = AIN[conf["LJ"]["AIN"]["Vp"]+1] |> (x -> (x * 1000.0))
    readIp = AIN[conf["LJ"]["AIN"]["Ip"]+1] |> (x -> -x * 0.167 * 1000.0)
    readVn = AIN[conf["LJ"]["AIN"]["Vn"]+1] |> (x -> (x * 1000.0))
    readIn = AIN[conf["LJ"]["AIN"]["In"]+1] |> (x -> -x * 0.167 * 1000.0)

    telapse = smps_elapsed_time.value
    setV = V.value
    smpsState = smps_scan_state.value
    
    N1 = CondensationParticleCounters.get_current_record(dataBufferCPC1) |> parseN
    N2 = CondensationParticleCounters.get_current_record(dataBufferCPC2) |> parseN
    N3 = CondensationParticleCounters.get_current_record(dataBufferCPC3) |> parseN
    gps = AdafruitUltimateGPS.get_current_RMC()
    Sonic = YoungModel81000.get_current_winds()
    
    push!(ts, unix2datetime(t))
    if ismissing(gps)
        tgps, lat, lon = t, 0.0, 0.0
    else
        tgps, lat, lon = datetime2unix(gps.t), gps.lat, gps.lon
    end

    if ismissing(Sonic)
        uwind, vwind, wwind, SonicT = 0.0, 0.0, 0.0, 0.0
    else
        uwind, vwind, wwind, SonicT = Sonic.u, Sonic.v, Sonic.w, Sonic.temp
    end

    (N1 > 0) && push!(N_TSI3776, N1)
    (N2 > 0) && push!(N_TSI3025, N2)
    (N3 > 0) && push!(N_TSI3771, N3)

    push!(Lat_buffer, lat)
    push!(Lon_buffer, lon)
    push!(Con_buffer, N2)

    push!(
        datapacket,
        (
            t = t,
            N_TSI3776 = N1,
            N_TSI3025 = N2,
            N_TSI3771 = N3,
            tgps = tgps,
            lat = lat,
            lon = lon,
            T = T,
            RH = RH,
            telapse = telapse,
            smpsState = smpsState,
            setV = setV,
            readVp = readVp,
            readVn = readVn,
            readIp = readIp,
            readIn = readIn,
            count = count[1],
            uwind = uwind,
            vwind = vwind,
            wwind = wwind,
            SonicT = SonicT,
            globalState = global_state.value
        ),
    )
    [datapacket.value] |> CSV.write(fileAll; append = true)
    return nothing
end


#p = Signal(plot([now()], [1.0]))
fileAll =
    "/home/daq.local/Data/EPA/" *
    Dates.format(now(), dateformat"yyyymmdd_HHMMSS") *
    "_all.csv"
[datapacket.value] |> CSV.write(fileAll)

Gtk.showall(wnd)   

asd = map(acquire, oneHz)
sleep(1)

output1 = map(_ -> DispGUIOutput(), oneHz)
output2 = map(_ -> SMPSOutput(),oneHz)
sleep(1)

respts = 10
osm_addr = "/home/daq.local/opt/mappingDAQ/src/minimap.osm"
(lon1,lat1,lon2,lat2) = (-78.701170,35.751723,-78.661197,35.782050) 
mapdata, map1 = maps_basic(lon1,lat1,lon2,lat2, datenow,respts, osm_addr,lat_series=Lat_buffer[:],lon_series=Lon_buffer[:],con_series=Con_buffer[:]) 

oneHzFilteredSignal1 = map(filter(s -> s == "ClassifierTEM", global_state)) do _
    push!(TEMcounts, TEMcounts.value + datapacket.value[:count])
    push!(TEMctimer, TEMctimer.value + 1)
    NASFlow = Gtk.get_gtk_property(gui["NASFlow"], "value", Float64)
    CumTEM = TEMcounts.value * NASFlow * 16.667
    Gtk.set_gtk_property!(gui["TEMTime"], :text, string(TEMctimer.value))
    Gtk.set_gtk_property!(gui["TEMacc"], :text, string(CumTEM))

end

DpBuffer = zeros(1000) .* NaN
concSBuffer = zeros(1000) .* NaN
stateBuffer = Array{Union{Nothing, String}}(nothing, 1000)

oneHzFilteredSignal2 = map(filter(s -> s == "SMPS", global_state)) do _
    @async smps_plotting()
    @async produceplot()
end

myTimer = every(10)
slow_state = map(_ -> global_state.value, myTimer)
Gtk.showall(wnd)
sleep(3)


imgsig = map(filter(s -> s == "Concentration", slow_state)) do _
    @async plotmytrack(map1, mapdata,Lat_buffer,Lon_buffer,Con_buffer,respts,datenow) 
    @async plotincanvas()
end


SMPSButton = gui["ResetSMPS"]
signal_connect(SMPSButton,"clicked") do widget, others...
    DpBuffer = zeros(1000) .* NaN
    concSBuffer = zeros(1000) .* NaN
    stateBuffer = Array{Union{Nothing, String}}(nothing, 1000)
end

##############
#InspectDR.clearsubplots(gplot5)
#mp5, gplot5 = initializeSMPSPlot()
# clear_data(gplot5,refresh_gui=true)

