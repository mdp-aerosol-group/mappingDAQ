

termination = map(_ -> smps_scan_termination(), filter(s -> s == "DONE", smps_scan_state))

#:AS


#mmm = filter(_ -> smap .== :SMPS, oneHz)




# plotHz = every(1)
# plotLoop = map(plotHz) do _
#     if length(ts) > 3
#         tm = ts[1]:Minute(10):ts[end]
#         ticks = Dates.format.(tm, "HH:MM")
#         n = length(ts)
#         p1 = plot(ts[1:n-2], N_TSI3776[1:n-2]; color = :black, label = "> 2.5 nm")
#         p1 = plot!(ts[1:n-2], N_TSI3025[1:n-2]; label = "> 5 nm", color = :darkred)
#         p1 = plot!(
#             ts[1:n-2],
#             N_TSI3771[1:n-2];
#             color = :steelblue3,
#             label = "> 10 nm",
#             yscale = :log10,
#             ylim = (100, 1000000),
#             xticks = (tm, ticks),
#         )

#         push!(p, p1)
#     end
# end

# dispLoop = map(display, p)



using Gtk
using Reactive

(@isdefined wnd) && destroy(wnd)
gui = GtkBuilder(filename=pwd()*"/example1.glade")  
wnd = gui["mainWindow"]
Gtk.showall(wnd)    

oneHz = every(1.0)
global_state = map(_ -> Gtk.get_gtk_property(gui["ModeSelect"], "active-id", String), oneHz)
instrumentStateChanged = Reactive.Signal(0)
TEMcounts = Signal(0)
SMPScounts = Signal(0)
CONCcounts = Signal(0)

select_box = gui["ModeSelect"]
instrumentChanged = signal_connect(select_box, "changed") do widget, others...
    push!(global_state, Gtk.get_gtk_property(gui["ModeSelect"], "active-id", String))
    push!(instrumentStateChanged,instrumentStateChanged.value+1)
end

stateReset = map(instrumentStateChanged) do _
    if global_state.value == "TEM"
        println("Changed to TEM Mode, set TEMcounts = 0 ")
        push!(TEMcounts, 0)
    elseif global_state.value == "CONC"
        println("Changed to Concentration Mode, singing a song ")
        push!(CONCcounts, 0)
    elseif global_state.value == "SMPS"
        println("Changed to SMPS mode, don't touch the cable ")
        push!(SMPScounts, 0)
    end 
end

oneHzFilteredSignal1 = map(filter(s -> s == "TEM", global_state)) do _
    push!(TEMcounts, TEMcounts.value + 1)
    println("TEMcounts  ", TEMcounts.value)
end

oneHzFilteredSignal2 = map(filter(s -> s == "SMPS", global_state)) do _
    push!(SMPScounts, SMPScounts.value + 1)
    println("SMPScounts  ", SMPScounts.value)
end

oneHzFilteredSignal3 = map(filter(s -> s == "CONC", global_state)) do _
    push!(CONCcounts, CONCcounts.value + 1)
    println("CONCcounts  ", CONCcounts.value)
end




# if StartDiameter changes then Recompute Voltage
function startDiameterChanged(widget::GtkEntryLeaf, EventAny::Gtk.GdkEventAny)
    set_voltage_SMPS("StartDiameter", "StartV")
end

# if endDiameter changes then Recompute Voltage
function endDiameterChanged(widget::GtkEntryLeaf, EventAny::Gtk.GdkEventAny)
    set_voltage_SMPS("EndDiameter", "EndV")
end

function set_voltage_SPINBox(source::GtkSpinButtonLeaf, destination::String)
    D = get_gtk_property(gui["Diameter"], "value", Float64)
    Λˢᵐᵖˢ, δˢᵐᵖˢ = set_SMPS_config()
    V = ztov(Λˢᵐᵖˢ, dtoz(Λˢᵐᵖˢ, D * 1e-9))
    if V > 10000.0
        V = 10000.0
        D = ztod(Λˢᵐᵖˢ, 1, vtoz(Λˢᵐᵖˢ, 10000.0))
        set_gtk_property!(gui["Diameter"], "value", round(D, digits = 0))
    elseif V < 10.0
        V = 10.0
        D = ztod(Λˢᵐᵖˢ, 1, vtoz(Λˢᵐᵖˢ, 10.0))
        set_gtk_property!(gui["Diameter"], "value", round(D, digits = 0))
    end
    set_gtk_property!(gui["VSet"], :text, @sprintf("%0.0f", V))
end

function set_voltage_SMPS(source::String, destination::String)
    D = parse_box(source, 100.0)
    (D == 100.0) && set_gtk_property!(gui["SMPSDp"], :text, "100")
    Λˢᵐᵖˢ, δˢᵐᵖˢ = set_SMPS_config()
    V = ztov(Λˢᵐᵖˢ, dtoz(Λˢᵐᵖˢ, D * 1e-9))
    if V > 10000.0
        V = 10000.0
        D = ztod(Λˢᵐᵖˢ, 1, vtoz(Λˢᵐᵖˢ, 10000.0))
        set_gtk_property!(gui["SMPSDp"], :text, @sprintf("%0.0f", D))
    elseif V < 10.0
        V = 10.0
        D = ztod(Λˢᵐᵖˢ, 1, vtoz(Λˢᵐᵖˢ, 10.0))
        set_gtk_property!(gui["SMPSDp"], :text, @sprintf("%0.0f", D))
    end
    set_gtk_property!(gui["SMPSV"], :text, @sprintf("%0.0f", V))
end

function set_SMPS_config()
    (column == :TSI) && ((r₁, r₂, l) = (9.37e-3, 1.961e-2, 0.44369))
    (column == :HFDMA) && ((r₁, r₂, l) = (0.05, 0.058, 0.6))
    (column == :RDMA) && ((r₁, r₂, l) = (2.4e-3, 50.4e-3, 10e-3))
    form = (column == :RDMA) ? :radial : :cylindrical
    Λˢᵐᵖˢ = DMAconfig(t, p, qsa, qsh, r₁, r₂, l, leff, polarity, 6, form)
    z1, z2 = vtoz(Λˢᵐᵖˢ, 10000.0), vtoz(Λˢᵐᵖˢ, 10.0)
    δˢᵐᵖˢ = setupDMA(Λˢᵐᵖˢ, z1, z2, bins)
    return Λˢᵐᵖˢ, δˢᵐᵖˢ
end