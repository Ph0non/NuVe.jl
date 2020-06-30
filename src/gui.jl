using Gtk

import Base.popfirst!
popfirst!(x::GtkListStoreLeaf) = deleteat!(x, 1)
qs = nothing
old_qs = nothing
sDict = Dict[]
rTxt_nuc = GtkCellRendererText()
rTxt_val = GtkCellRendererText()
rTxt_val.:xalign[Float64] = 1.0

c1 = GtkTreeViewColumn("Nuklid", rTxt_nuc, Dict([("text", 0)]) )
c2 = GtkTreeViewColumn(" ", rTxt_nuc, Dict([("text", 112)]) )
c1.:fixed_width[Float64] = 85
TVCDict = Dict(string(value) =>  GtkTreeViewColumn(string(value), rTxt_val, Dict([("text", index)]) ) for (index, value) in enumerate([1990:2100;]) )
for i in keys(TVCDict)
    TVCDict[i].:fixed_width[Float64] = 65
    TVCDict[i].:max_width[Float64] = 65
    TVCDict[i].:alignment[Float64] = 0.5
end

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
    b["sp_year_decay"].:text[String] = year(now()) |> string
    nothing
end

function init_opt()
    b["cobo_opt"].:active[Int] = 5
    nothing
end

function init_Dicts()
    decayDict = Dict{String,NamedArray{Float64,2}}()
    partDict = Dict{String,NamedArray{Float64,2}}()
    q3_aDict = Dict{String,NamedArray{Float64,2}}()
    q3_∑Dict = Dict{String,NamedArray{Float64,2}}()
    nvDict = init_nvDict()
    DlDict = init_DlDict()
    return decayDict, partDict, q3_aDict, q3_∑Dict, nvDict, DlDict
end

function init_nvDict()
    nvDict = SortedDict{String,Union{Array{Float64,1}, MOI.TerminationStatusCode}}()
end

function init_DlDict()
    DlDict = Dict{String,Union{Float64, MOI.TerminationStatusCode}}()
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

"Lösche alle bis auf einen (sonst CRASH)"
function popRows(x::GtkListStoreLeaf)
    for i = 1:length(x) - 1
        pop!(x)
    end
end

"Zeilen hinzufügen"
function addRows(x::GtkListStoreLeaf, nvDict::SortedDict{String,Union{MOI.TerminationStatusCode, Array{Float64,1}}})
    for j = 1:length(first(nvDict)[2])
        push!(x, tuple( getNuclidesFromConstraint(c)[j], (0 for i in 1990:qs.year[1]-1)..., (format_numbers(nvDict[i][j]) for i in keys(nvDict))..., (0 for i in qs.year[2]+1:2100)..., "" ) ) # Zeilen
    end
end

function addDLRow(x::GtkListStoreLeaf, dlDict::Dict{String,Union{Float64, MOI.TerminationStatusCode}} )
    push!(x, tuple("Dosis\n[µSv/a]", (0 for i in 1990:qs.year[1]-1)..., (format_numbers(dlDict[i]) for i in keys(dlDict))..., (0 for i in qs.year[2]+1:2100)..., "" ) ) # Zeilen
end

function addRows(x::GtkListStoreLeaf, d::Dict)
    for j = 1:size(first(sDict[2])[2], 2)
        push!(b["ls_decay"], tuple( getNuclidesFromConstraint(c)[j], (0 for i in 1990:qs.year[1]-1)..., (format_numbers(nvDict[i][j]) for i in keys(nvDict))..., (0 for i in qs.year[2]+1:2100)..., "" ) ) # Zeilen
    end
end


# c1_decay_stat = [GtkTreeViewColumn(val, rTxt_nuc, Dict([("text", index)]) ) for (index, val) in enumerate(["Min" "Max" "Mittel"])]
# c2_decay = GtkTreeViewColumn(" ", rTxt_nuc, Dict([("text", 112+3)]) )
# TVCDict_decay = Dict(string(value) =>  GtkTreeViewColumn(string(value), rTxt_val, Dict([("text", index+3)]) ) for (index, value) in enumerate([1990:2100;]) )
# for i in keys(TVCDict_decay)
#     TVCDict_decay[i].:fixed_width[Float64] = 65
#     TVCDict_decay[i].:max_width[Float64] = 65
#     TVCDict_decay[i].:alignment[Float64] = 0.5
# end
# # Spalten (Nuklide) alphabetisch sortiert
# sDict[2]["2022"][:, nu_names |> sort]



function format_numbers(x::Float64)
    q = replace( string(x), "." => ",")
    if length( q[ findfirst(",", q)[1] : end] ) < 3
        q *= "0"
    end
    return q
end

"Werte in Tabelle ändern"
function change_tv(nvDict::SortedDict{String,Union{MOI.TerminationStatusCode, Array{Float64,1}}}, dlDict::Dict{String,Union{Float64, MOI.TerminationStatusCode}} )
    if length(b["ls_result"]) == 0 # Es wurden noch keine Werte in ls_result geschrieben
        addRows(b["ls_result"], nvDict)
        if b["cbtn_10us_show"].active[Bool]
            addDLRow(b["ls_result"], dlDict)
        end
        push!(b["tv_result"], c1)
        for i in string.([qs.year[1]:qs.year[2];])
            push!(b["tv_result"], TVCDict[i])
        end
        push!(b["tv_result"], c2)
    else
        popRows(b["ls_result"])
        addRows(b["ls_result"], nvDict)
        if b["cbtn_10us_show"].active[Bool]
            addDLRow(b["ls_result"], dlDict)
        end
        popfirst!(b["ls_result"])

        for i in string.([old_qs.year[1]:old_qs.year[2];])
            deleteat!(b["tv_result"], TVCDict[i])
        end
        deleteat!(b["tv_result"], c2)
        for i in string.([qs.year[1]:qs.year[2];])
            push!(b["tv_result"], TVCDict[i])
        end
        push!(b["tv_result"], c2)
    end
end

function run_app()
    global b = GtkBuilder(filename = joinpath(pwd(), prefix, "nuve.glade"))
    global c = Constraint[]
    include(joinpath(prefix, "signals.jl"))
    include(joinpath(prefix, "callbacks.jl"))
    populate_ls_nv()
    populate_ls_opt()
    init_desense_con()
    global win = b["main"]
    Gtk.showall(win)
    init_sp_year()
    init_opt()
    init_clearpath()
end

function init_settings()
    if qs != nothing
        global old_qs = qs
    end
    b["pbar"].:fraction[Float64] = 0
    createSettings()
    
    if isempty(sDict)
        (decayDict, partDict, q3_aDict, q3_∑Dict, nvDict, DlDict) = init_Dicts()
    else
        decayDict = sDict[1]
        partDict = sDict[2]
        q3_aDict = sDict[3]
        q3_∑Dict = sDict[4]
        nvDict = init_nvDict()
        DlDict = init_DlDict()
    end
    decayDict = calcDecayCorrection(decayDict)
    partDict = calcParts(partDict, decayDict)
    (q3_aDict, q3_∑Dict) = calcFactors(q3_aDict, q3_∑Dict, partDict, decayDict)
    
    if isempty(sDict)
        push!(sDict, decayDict, partDict, q3_aDict, q3_∑Dict)
    else
        sDict[1] = decayDict
        sDict[2] = partDict
        sDict[3] = q3_aDict
        sDict[4] = q3_∑Dict
    end

    return (decayDict, partDict, q3_aDict, q3_∑Dict, nvDict, DlDict)
end
