using AdafruitUltimateGPS
using CondensationParticleCounters

using LibSerialPort
using Reactive
using Dates
using CSV
using Plots
using Chain
using DataStructures
using Plots

list_ports()

const portCPC1 = CondensationParticleCounters.config(:TSI3776C, "/dev/ttyUSB0")
const portCPC2 = CondensationParticleCounters.config(:TSI3022, "/dev/ttyUSB1")
const portCPC3 = CondensationParticleCounters.config(:TSI3771, "/dev/ttyUSB2")
const portGPS = AdafruitUltimateGPS.config("/dev/ttyUSB5")

const dataBufferCPC1 = CircularBuffer{String}(10)
const dataBufferCPC2 = CircularBuffer{String}(10)
const dataBufferCPC3 = CircularBuffer{String}(10)

@async CondensationParticleCounters.stream(portCPC1, :TSI3776C, "/home/daq.local/Data/EPA/" * Dates.format(now(), dateformat"yyyymmdd") * "_TSI3776C.csv", dataBufferCPC1)
@async CondensationParticleCounters.stream(portCPC2, :TSI3022, "/home/daq.local/Data/EPA/" * Dates.format(now(), dateformat"yyyymmdd") * "_TSI3022.csv", dataBufferCPC2)
@async CondensationParticleCounters.stream(portCPC3, :TSI3771, "/home/daq.local/Data/EPA/" * Dates.format(now(), dateformat"yyyymmdd") * "_TSI3771.csv", dataBufferCPC3)
@async AdafruitUltimateGPS.stream(portGPS, "/home/daq.local/Data/EPA/" * Dates.format(now(), dateformat"yyyymmdd") * ".csv")


const N_TSI3776 = CircularBuffer{Float64}(3600)
const N_TSI3025 = CircularBuffer{Float64}(3600)
const N_TSI3771 = CircularBuffer{Float64}(3600)
const ts = CircularBuffer{DateTime}(3600)
const startt = now(UTC) |> datetime2unix
const datapacket = Signal((t=startt, N_TSI3776=0.0, N_TSI3025=0.0, N_TSI3771=0.0, tgps=startt, lat=0.0, lon=0.0))

parseN(x) = @chain split(x, ",") getindex(_, 3) parse(Float64, _)
parseN(x::Missing) = 0.0

function acquire(t)
    N1 = CondensationParticleCounters.get_current_record(dataBufferCPC1) |> parseN
    N2 = CondensationParticleCounters.get_current_record(dataBufferCPC2) |> parseN
    N3 = CondensationParticleCounters.get_current_record(dataBufferCPC3) |> parseN
    gps = AdafruitUltimateGPS.get_current_RMC()

    push!(ts, unix2datetime(t))
    if ismissing(gps)
        tgps, lat, lon = t, 0.0, 0.0
    else
        tgps, lat, lon = datetime2unix(gps.t), gps.lat, gps.lon
    end
    (N1 > 0) && push!(N_TSI3776, N1)
    (N2 > 0) && push!(N_TSI3025, N2)
    (N3 > 0) && push!(N_TSI3771, N3)

    push!(datapacket, (t=t, N_TSI3776=N1, N_TSI3025=N2, N_TSI3771=N3, tgps=tgps, lat=lat, lon=lon))
    [datapacket.value] |> CSV.write(fileAll; append=true)
end

p = Signal(plot([now()], [1.0]))
fileAll = "/home/daq.local/Data/EPA/" * Dates.format(now(), dateformat"yyyymmdd_HHMMSS") * "_all.csv"
[datapacket.value] |> CSV.write(fileAll)

oneHz = every(1.0)
asd = map(acquire, oneHz)

plotHz = every(30)
plotLoop = map(plotHz) do _
    if length(ts) > 3
        tm = ts[1]:Minute(10):ts[end]
        ticks = Dates.format.(tm, "HH:MM")
        n = length(ts)
        p1 = plot(ts[1:n-2], N_TSI3776[1:n-2], color = :black, label = "> 2.5 nm")
        p1 = plot!(ts[1:n-2], N_TSI3025[1:n-2], label = "> 5 nm", color = :darkred)
        p1 = plot!(ts[1:n-2], N_TSI3771[1:n-2], color = :steelblue3, label = "> 10 nm", yscale = :log10, ylim = (100,1000000), xticks=(tm, ticks))

        push!(p, p1)
    end
end

dispLoop = map(display, p)
