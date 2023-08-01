const black = RGBA(0, 0, 0, 1)
const red = RGBA(0.8, 0.2, 0, 1)
const mblue = RGBA(0, 0, 0.8, 1)
const mgrey = RGBA(0.4, 0.4, 0.4, 1)
const _Gtk = Gtk.ShortNames

function initializeSMPSPlot()
    plot5 = InspectDR.Plot2D(:log, :lin, title = "")
    InspectDR.overwritefont!(plot5.layout, fontname = "Helvetica", fontscale = 1.2)
    plot5.layout[:enable_legend] = true
    plot5.layout[:halloc_legend] = 170
    plot5.layout[:halloc_left] = 50 ### change the horizontal margin
    plot5.layout[:enable_timestamp] = false
    plot5.layout[:length_tickmajor] = 10
    plot5.layout[:length_tickminor] = 6
    plot5.layout[:format_xtick] = InspectDR.TickLabelStyle(UEXPONENT)
    plot5.layout[:frame_data] = InspectDR.AreaAttributes(
        line = InspectDR.line(style = :solid, color = black, width = 0.5),
    )
    plot5.layout[:line_gridmajor] = InspectDR.LineStyle(:solid, Float64(0.75), RGBA(0, 0, 0, 1))

    plot5.xext = InspectDR.PExtents1D()
    plot5.xext_full = InspectDR.PExtents1D(6.0, 130.0) # X-Lims

    a = plot5.annotation
    a.xlabel = "Diameter (nm)"
    a.ylabels = ["Inverted dN/dlnD (cm-3)"]
    mp5, gplot5 = push_plot_to_gui!(plot5, gui["SMPSBox1"], wnd)

    wfrm = add(plot5, [0.0], [0.0], id = "UPSCAN")
    wfrm.line = line(color = black, width = 2, style = :solid)
    wfrm = add(plot5, [0.0], [0.0], id = "DOWNSCAN")
    wfrm.line = line(color = red, width = 2, style = :solid)

    graph = plot5.strips[1]
    graph.grid = InspectDR.GridRect(vmajor = true, vminor = true, hmajor = true, hminor = true)


    Gtk.showall(wnd)  
end


plot5 = InspectDR.Plot2D(:log, :lin, title = "")
InspectDR.overwritefont!(plot5.layout, fontname = "Helvetica", fontscale = 1.2)
plot5.layout[:enable_legend] = true
plot5.layout[:halloc_legend] = 170
plot5.layout[:halloc_left] = 50 ### change the horizontal margin
plot5.layout[:enable_timestamp] = false
plot5.layout[:length_tickmajor] = 10
plot5.layout[:length_tickminor] = 6
plot5.layout[:format_xtick] = InspectDR.TickLabelStyle(UEXPONENT)
plot5.layout[:frame_data] = InspectDR.AreaAttributes(
    line = InspectDR.line(style = :solid, color = black, width = 0.5),
)
plot5.layout[:line_gridmajor] = InspectDR.LineStyle(:solid, Float64(0.75), RGBA(0, 0, 0, 1))

plot5.xext = InspectDR.PExtents1D()
plot5.xext_full = InspectDR.PExtents1D(6.0, 130.0) # X-Lims

a = plot5.annotation
a.xlabel = "Diameter (nm)"
a.ylabels = ["Inverted dN/dlnD (cm-3)"]
mp5, gplot5 = push_plot_to_gui!(plot5, gui["SMPSBox1"], wnd)

wfrm = add(plot5, [0.0], [0.0], id = "UPSCAN")
wfrm.line = line(color = black, width = 2, style = :solid)
wfrm = add(plot5, [0.0], [0.0], id = "DOWNSCAN")
wfrm.line = line(color = red, width = 2, style = :solid)

graph = plot5.strips[1]
graph.grid = InspectDR.GridRect(vmajor = true, vminor = true, hmajor = true, hminor = true)


Gtk.showall(wnd)

cvs = gui["MappingIMG"]

