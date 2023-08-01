using Gtkusing 
using GtkReactive
using Reactive
using Images

(@isdefined wnd) && destroy(wnd)
gui = GtkBuilder(filename=pwd()*"/example.glade")  

cvs = gui["Image"]
wnd = gui["mainWindow"]
c = canvas(UserUnit)
push!(cvs, c)


myTimer = every(10.0)
plotmeSignal = map(_ -> plotmytrack, myTimer)

Gtk.showall(wnd)    

imgsig = map(myTimer) do r
    p = plot(rand(10), size = (400,400))
    savefig(p, "tmp.png")
    img = load("tmp.png")
    GtkReactive.copy!(c, img)
    img
end

redraw = draw(c, imgsig) do cnvs, image
end
