function cb_nv_changed(widget)
    init_Dicts()
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
    if qs != nothing
        global old_qs = qs
    end
    b["pbar"].:fraction[Float64] = 0
    createSettings()
    (decayDict, partDict, q3_aDict, q3_∑Dict, nvDict) = init_Dicts()
    
    decayDict = calcDecayCorrection(decayDict)
    partDict = calcParts(partDict, decayDict)
    (q3_aDict, q3_∑Dict) = calcFactors(q3_aDict, q3_∑Dict, partDict, decayDict)
    # println(decayDict["2022"])
    y = collect(qs.year[1]:qs.year[2])

    # l = Threads.SpinLock()
    # Threads.@threads 
    for i in y  
        (e, nv_x) = solveAll(i, partDict[string(i)], q3_aDict[string(i)], q3_∑Dict[string(i)], q3_aDict[string(i+1)], q3_∑Dict[string(i+1)])

        if e === nothing
            push!(nvDict, string(i) => nv_x)
        else
            push!(nvDict, string(i) => e)
        end
        # Threads.lock(l)
            b["pbar"].:fraction[Float64] = length(nvDict)/length(y)
            # jj[]
        # Threads.unlock(l)
    end

    change_tv(nvDict)
end

function cb_sp_year_min_changed(widget)
    if tryparse(Int64, widget.:text[String]) > tryparse(Int64, b["sp_year_max"].:text[String])
        b["sp_year_max"].:text[String] = widget.:text[String]
    end
end

# jj = Threads.Atomic{Int}(0)

function cb_sp_year_max_changed(widget)
    if tryparse(Int64, widget.:text[String]) < tryparse(Int64, b["sp_year_min"].:text[String])
        b["sp_year_min"].:text[String] = widget.:text[String]
    end
end

function cb_cbtn_10us_calc(widget)
    if widget.:active[Bool] == true
        b["cbtn_10us_show"].:active[Bool] = true
    end
end