# Note need to turn off calvolt(v) before running this code 
#calibrateVoltage(v) = getVdac(calvolt(v), :+, true)
calibrateVoltage_p(v) = getVdac(v, :+, true)
calibrateVoltage_n(v) = getVdac(v, :-, true)

using Plots
using DataFrames
using Interpolations
using CSV

function get_points(V)
    println(V)
    push!(classifierV, V)

    sleep(10)
    x = map(1:10) do i
        sleep(1)
        labjack_signals.value[1][3] |> (x -> x * 1000)
    end

    return DataFrame(setV=V, readV=x)
end

df = mapfoldl(get_points, vcat, [10:5:145; 150:50:1000; 2000:1000:10000])
df1 = filter(:readV => x -> x > 10, df)
df2 = transform(df, :readV => x -> abs.(x))
df2 = sort(df2, [:readV_function])

itp = interpolate((df2[!, :readV_function],), df2[!, :setV], Gridded(Linear()))
xdata = 10:10.0:10000.0
extp = extrapolate(itp, Flat())
p = scatter(df2[!, :readV_function],
    df2[!, :setV], 
    xscale=:log10, 
    yscale=:log10,
    xlim=(10, 10000), 
    ylim=(10, 10000),
    xlabel = "Read Voltage (V)",
    ylabel = "Set Voltage (V)",
    legend = :bottomright,
    color = :darkred,
    label = "Data"
)

p = plot!(xdata, extp.(xdata), color = :black, label = "Fit")

df2 |>  CSV.write("voltage_calibration_n.csv")
savefig(p, "voltage_calibration_n.pdf")
display(p)