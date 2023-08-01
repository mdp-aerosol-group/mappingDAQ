const Vhi = Signal(20.0)
const Vlow = Signal(6000.0)
const tscan = Signal(240)
const thold = Signal(20)
const tflush = Signal(10)

include("dma_control.jl")               # High voltage power supply
include("labjack_io.jl")                # Labjack channels I/O
include("smps_signals.jl")              # Labjack channels I/O

const HANDLE = openUSBConnection(conf["LJ"]["ID"])
const caliInfo = getCalibrationInformation(HANDLE)
const Λ = get_DMA_config(
    conf["DMA"]["Qsh"],
    conf["DMA"]["Qsa"],
    conf["DMA"]["T"],
    conf["DMA"]["p"],
    conf["DMA"]["polarity"] |> Symbol,
    Symbol(conf["DMA"]["model"]),
)

const classifierV = Signal(200.0)
const dmaState = Signal(:CLASSIFIER)
const smps_start_time = Signal(datetime2unix(now(UTC)))
const smps_elapsed_time = map(t -> Int(round(t - smps_start_time.value; digits = 0)), oneHz)
const smps_scan_state, V, Dp, terminationSignal = smps_signals()
const calvolt_p = get_cal("voltage_calibration_p.csv")
const calvolt_n = get_cal("voltage_calibration_n.csv")

calibrateVoltage_p(v) = getVdac(calvolt_p(v), :+, true)
calibrateVoltage_n(v) = getVdac(calvolt_n(v), :-, true)

const signalV_p = map(calibrateVoltage_p, V)
const signalV_n = map(calibrateVoltage_n, V)
const labjack_signals = map(labjackReadWrite, signalV_n, signalV_p)

function get_current_record()
    AIN, Tk, rawcount, count = labjack_signals.value
    RH = AIN[conf["LJ"]["AIN"]["RH"]+1] * 100.0
    T = AIN[conf["LJ"]["AIN"]["T"]+1] * 100.0 - 40.0
    readVp = AIN[conf["LJ"]["AIN"]["Vp"]+1] |> (x -> (x * 1000.0))
    readIp = AIN[conf["LJ"]["AIN"]["Ip"]+1] |> (x -> -x * 0.167 * 1000.0)
    readVn = AIN[conf["LJ"]["AIN"]["Vn"]+1] |> (x -> (x * 1000.0))
    readIn = AIN[conf["LJ"]["AIN"]["In"]+1] |> (x -> -x * 0.167 * 1000.0)
 
    @sprintf(
        "LABJCACK,%i,%.3f,%s,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f",
        smps_elapsed_time.value,
        V.value,
        smps_scan_state.value,
        readVp,
        readIp,
        readVn,
        readIn,
        RH,
        T,
        count[1] ./ 16.666666
    )
end

stateReset = map(instrumentStateChanged) do _
    if global_state.value == "ClassifierTEM"
        push!(dmaState, :CLASSIFIER)
        println("Changed to TEM Mode, click 'reset' button if want recounting")
    elseif global_state.value == "Concentration"
        println("Changed to Concentration Mode, singing a song ")
        push!(dmaState, :CLASSIFIER)
    elseif global_state.value == "SMPS"
        showall(wnd)
        startSMPS()
        println("Changed to SMPS mode, don't touch the cable ")
    end 
end


TEM_button = gui["TEMReset"]
signal_connect(TEM_button,"clicked") do widget, others...
    println("Reset TEM counting and timer!")
    push!(TEMcounts, 0)
    push!(TEMctimer, 0)
end


