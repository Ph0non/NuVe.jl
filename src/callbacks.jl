function cb_nv_changed(widget)
    println(widget.:active_id[String])
end

function cb_cbtn_con_toggled(widget)
    for j in ["cobo", "lmt", "w"]
        b[j * "_" * widget.:name[String][6:end] ].sensitive[Bool] = !b[j * "_" * widget.:name[String][6:end] ].sensitive[Bool]
    end

    if widget.:active[Bool] == false
        nu_sym = nu_names[ lowercase.(nu_names) .== widget.:name[String][6:end] ][1] |> Symbol
        delete_con(nu_sym)
    else
        create_con(widget.:name[String][6:end])
    end
end

function cb_con_changed(widget)
    create_con(widget.:name[String][6:end])
end

function cb_tb_calc(widget)
    q_nv = b["cobo_nv"].:active_id[String] |> Symbol
    q_year = tryparse.(Int, [b["sp_year_min"].:text[String], b["sp_year_max"].:text[String] ])
    q_gauge = Symbol[]
    for i in ["fma", "como", "lb124", "mc", "is"]
        b["cbtn_" * i].:active[Bool] ? push!(q_gauge, Symbol(i)) : nothing
    end
    q_target = Symbol(collect(keys(id_proc))[b["cobo_opt"].:active[Int]+1])
    q_treshold = parse_num_con(b["ent_th"].:text[String]) == nothing ? 1.0 : parse_num_con(b["ent_th"].:text[String])
    q_refdate = RefDate("1 Jan", "d u")
    q_paths = Dict{Symbol,Array{String,1}}()
    for i in q_gauge
        push!(q_paths, i => [j for j in collect(keys(f.dicts[1]))[1:end-1] if b["cbtn_" * String(i) * "_" * j].:active[Bool] ] )
    end
    q_10us = b["swt_10us_calc"].:active[Bool]
    global qs = Settings(q_nv, q_year, q_gauge, q_target, q_treshold, q_refdate, q_paths, q_10us)
end

function cb_sp_year_min_changed(widget)
    if tryparse(Int64, widget.:text[String]) > tryparse(Int64, b["sp_year_max"].:text[String])
        b["sp_year_max"].:text[String] = widget.:text[String]
    end
end

function cb_sp_year_max_changed(widget)
    if tryparse(Int64, widget.:text[String]) < tryparse(Int64, b["sp_year_min"].:text[String])
        b["sp_year_min"].:text[String] = widget.:text[String]
    end
end