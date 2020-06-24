using Gtk
# global b = GtkBuilder(filename = joinpath(pwd(), prefix, "nuve.glade"))

import Base.popfirst!
popfirst!(x::GtkListStoreLeaf) = deleteat!(x, 1)
qs = nothing
old_qs = nothing
sDict = Dict[]
rTxt = GtkCellRendererText()

xf_ana = XLSX.readxlsx(joinpath("src", "Vollanalysen.xlsx"))

function populate_ls_nv()
    empty!(b["ls_nv"])
    for i=1:length(XLSX.gettable(xf_ana["Übersicht NV"])[1][1])
        push!(b["ls_nv"], tuple(sort!(XLSX.gettable(xf_ana["Übersicht NV"])[1][1])[i]))
    end
end

id_proc = SortedDict("mean" => "Mittelwert", "fma" => "FMA", "is" => "in-situ", "mc" => "MicroCont II", "lb124" => "Lb 124", "como" => "CoMo 170")
function populate_ls_opt()
    empty!(b["ls_opt"])
    for i in keys(id_proc)
        push!(b["ls_opt"], tuple(id_proc[i]))
    end
end

function desense_con_widget(wid::String, nu::String)
    b[wid * "_" * nu].:sensitive[Bool] = false
    nothing
end

function init_desense_con()
    for j in ["cobo", "lmt", "w"]
        for i in lowercase.(nu_names)
            desense_con_widget(j, i)
        end
    end
end

function init_sp_year()
    b["sp_year_min"].:text[String] = year(now()) |> string
    b["sp_year_max"].:text[String] = year(now())+5 |> string
    nothing
end

function init_opt()
    b["cobo_opt"].:active[Int] = 5
    nothing
end

function init_clearpath()
    q = Dict("fma"  => ["OF", "1a", "2a", "4a", "1b", "2b", "3b", "4b", "5b", "6b", "1a*"],
             "como" => ["OF", "1a",       "4a",                   "4b", "5b", "6b"       ],
             "mc"   => ["OF", "1a",       "4a",                   "4b", "5b", "6b"       ],
             "lb124"=> ["OF", "1a",       "4a",                   "4b", "5b", "6b"       ],
             "is"   => ["OF",             "4a",                   "4b", "5b", "6b"       ])

    for i in keys(q)
        for j in q[i]
            b["cbtn_" * i * "_" * j].:active[Bool] = true
        end
    end
    b["cbtn_fma"].:active[Bool] = true
    nothing
end

c = Constraint[]
function create_con(nu_str::String)
    nu_sym = nu_names[ lowercase.(nu_names) .== nu_str ][1] |> Symbol
    # Constraint schon vorhanden? Falls ja, dann löschen und neu erstellen
    delete_con(nu_sym)
    
    con_sym = [:(=), :<, :>][b["cobo_" * nu_str].:active[Int] + 1]
    lmt = parse_num_con( b["lmt_" * nu_str].:text[String]) == nothing ? 100.0 : parse_num_con( b["lmt_" * nu_str].:text[String])
    w = parse_num_con( b["w_" * nu_str].:text[String]) == nothing ? 1.0 : parse_num_con( b["w_" * nu_str].:text[String])

    push!(c, Constraint(nu_sym, con_sym, lmt, w))
end

function parse_num_con(s::String)
    s = replace(s, "," => ".")
    s = replace(s, "%" => "")
    s = replace(s, " " => "")
    tryparse(Float64, s)
end

function delete_con(nu_sym::Symbol)
    nu_ind = findfirst(nu_sym .== [c[i].nuclide for i=1:length(c)])
    if nu_ind != nothing
        deleteat!(c, nu_ind)
    end
end

function run_app()
    global b = GtkBuilder(filename = joinpath(pwd(), prefix, "nuve.glade"))
    include(joinpath(prefix, "signals.jl"))
    include(joinpath(prefix, "callbacks.jl"))
    populate_ls_nv()
    populate_ls_opt()
    init_desense_con()
    win = b["main"]
    Gtk.showall(win)
    init_sp_year()
    init_opt()
    init_clearpath()
end
