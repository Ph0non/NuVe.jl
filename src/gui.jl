using NuVe
using Interact
using Blink
using WebIO
using Dates

# ui = button()
# display(ui)
#
# w = Window()
# body!(w, q2)

"Dropdown-Widget für die Auswahl des NV"
function gui_get_nv_picker()
    gui_nv_picker_ = Dict()
    # for i in NuVe.readDb("nv_summary", ["NV"])[:,1]
    for i in readDb("nv_summary", ["NV"])[:,1]
        push!(gui_nv_picker_, i => i)
    end
    dropdown(gui_nv_picker_ |> sort, label="Nuklidvektor")
end
gui_nv_picker = gui_get_nv_picker()

"Dropdown-Widget für die Auswahl des Optimierungsziels"
dict_optim = OrderedDict("Probenmittelwert" => :mean, "FMA" => :fma, "CoMo" => :como, "MC" => :mc, "Lb124" => :lb124, "In-situ" => :is)
gui_optim_picker = dropdown(dict_optim, label="Optimierungsziel")

"Widget für das Jahresintervall"
gui_date = rangeslider([2010:2030;], value=[2015,2025])

"Widget für den Referenztag"
gui_ref_day = dropdown([1:Dates.daysinmonth(Date(2018,12,1));], label="Tag")
"Widget für den Referenzmonat"
gui_ref_month = dropdown([1:12;], label="Monat")

# gui_device_list = dropdown(OrderedDict("FMA" => :fma, "CoMo" => :como, "MC" => :mc, "Lb124" => :lb124, "In-situ" => :is), multiple=false, label="Berücksichtigte Messgeräte")
gui_cb_fma = checkbox(label="FMA", value=true)
gui_cb_como = checkbox(label="CoMo")
gui_cb_mc = checkbox(label="MC")
gui_cb_lb124 = checkbox(label="Lb124")
gui_cb_is = checkbox(label="In-situ")

w = Blink.Window()
# body!(w, dom"div"(gui_nv_picker, dom"div"("Hello World")))

q = node(:div, className="tile is-ancestor box",
        node(:div, className="tile is-parent is-3",
            node(:div, className="tile is-vertical",
                node(:div, className="tile is-parent",
                    node(:div, className="tile is-child box",
                        node(:div, className="columns is-centered", gui_nv_picker)
                        ),
                    node(:div, className="tile is-parent box",
                        node(:div, className="tile is-child",
                            node(:div, className="columns is-centered", gui_ref_day, gui_ref_month),
                            )
                        ),
                    node(:div, className="tile is-child box", gui_date)
                    ),
                    node(:div, className="tile is-parent",
                        # node(:div, className="tile box", gui_device_list),
                        node(:div, className="tile is-vertical box", "Berücksichtigte Messgeräte",
                            node(:div, className="tile", gui_cb_fma, gui_cb_como, gui_cb_lb124, gui_cb_mc, gui_cb_is)
                        ),
                        node(:div, className="tile box", gui_optim_picker)
                    )
                )
            )
        )

# q |> display
body!(w, q)
