using Cairo
using Gtk
using Plots

const io = PipeBuffer()

histio() = show(io, MIME("track_20230501.png"))

function plotincanvas(h=500, w=600)
    #win = gui["MappingIMG"]

    win = GtkWindow("Normal Histogram Widget", h, w) |> (vbox = GtkBox(:v))
    can = GtkCanvas()
    push!(vbox, can)
    set_gtk_property!(vbox, :expand, can, true)
    @guarded draw(can) do _
        ctx = getgc(can)
        #histio()
        img = read_from_png("track_20230501.png")
        set_source_surface(ctx, img, 0, 0)
        paint(ctx)
    end
    draw(can)
    #id = signal_connect((w) -> draw(can), "value-changed")
    showall(win)
    show(can)
end

plotincanvas()