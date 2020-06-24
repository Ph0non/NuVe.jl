function array2string(x::Array{String, 1})
    prod(x .* ", ")[1:end-2]
end

# function array2string(x::Array{<:Number, 1})
# 	x = string.(x)
# 	array2string(x)
# end

"""
	getSampleInfo(x::String, nv::Symbol)

Fragt zu einem gegebenen Nuklidvektor weitere Informationen ab (z. B. "date" oder "source" (Herkunftsort))
"""
function getSampleInfo(x::String, nv::Symbol)
	DBInterface.execute(nvdb(), "select " * x * " from nv_source join nv_summary on nv_source.nv_id = nv_summary.nv_id where NV = '" * (nv |> String) *"'")
end

"""
	df2array(x::DataFrame)

Wandelt ein `DataFrame` in ein `Array{Any,2}` um.
"""
function df2array(x::DataFrame)
	convert(Array, x)
end

"""
	travec(x::Array)

Transponiert einen Vektor (`n × 1`) zu (`1 × n`).
"""
function travec(x::Array)
	Base.reshape(x, 1, length(x))
end

"""
	 removeMissing(x::DataFrame)

Ersetzt in einem DataFrame alle `missing` durch 0.
"""
function removeMissing(x::DataFrame)
	for i in names(x)
		x[!, i] = coalesce.(x[!, i], 0)
	end
	return x
end

"""
	df2namedarray(x::DataFrame, rowname::String, columnname::String)

Diese Funktion wandelt einen `DataFrame` in ein `Array{Float64, 2}` um.
Potentiell fehlende Werte werden durch 0 ersetzt.
"""
function df2namedarray(x::DataFrame, rowname::String, columnname::String)
	NamedArray(convert(Array{Float64, 2}, removeMissing(x)[names(x)[2:end]]),
		( string.(x[:, 1]), string.(names(x))[2:end] ),
		(rowname, columnname) )
end

"""
	nuclideParts(x::NamedArrays.NamedArray)

Gibt ein NamedArray mit den Nuklidanteilen wieder. Die Summe aller Nuklide über
jeder Probe ergibt 1.
"""
function nuclideParts(x::NamedArrays.NamedArray)
	x./sum(x, dims=2)
end

"""
	CalcFactors(x::NamedArrays.NamedArray)

Berechnet die noch fehlenden Faktoren für die zu lösende Ungleichung.
"""
function CalcFactors(x::NamedArrays.NamedArray)
	∑xᵢdivfᵢ = x * fᵀ
	∑εᵢxᵢ = x * ɛᵀ

	return ∑xᵢdivfᵢ, ∑εᵢxᵢ
end

"""
	getNuclidesFromConstraint(x::Array{Constraint,1})

Gibt alle Nuklide zurück, welche in sich in einem Array von Constraints befinden.
"""
function getNuclidesFromConstraint(x::Array{Constraint,1})
	[x[i].nuclide |> String for i=1:length(x) ]
end

"""
	getWeightsFromConstraint(x::Array{Constraint,1})

Gibt alle Wichtungen der Nuklide zurück, welche in sich in einem Array von Constraints befinden.
Diese Funktion wird beispielsweise benötigt, wenn auf die Repräsentativität der Proben optimiert werden soll. Hierbei wird die Abweichung der Nuklide des Nuklidvektors gegenüber dem Mittelwert der Nuklide der Proben minimiert.
"""
function getWeightsFromConstraint(x::Array{Constraint,1})
	[x[i].weight for i=1:length(x) ]
end

function calcDecayCorrection(decayDict::Dict{String,NamedArray{Float64,2}})
	if (old_qs != nothing) && (old_qs.nv == qs.nv)
		missed_years = setdiff(getInterval(qs), tryparse.(Int64, collect(keys(decayDict))))
	else
		decayDict = Dict{String,NamedArray{Float64,2}}()
		missed_years = getInterval(qs)
	end
	
	if !isempty(missed_years)
		q0 = decayCorrection(qs, getSampleFromSource(qs.nv), missed_years)
		for (key, value) in q0
			push!(decayDict, key => df2namedarray(value, "samples", "nuclides"))
		end
	end
	return decayDict
end

function calcParts(partDict::T, decayDict::T) where {T<:Dict{String,NamedArray{Float64,2}}}
	if (old_qs != nothing) && (old_qs.nv == qs.nv)
		missed_years = setdiff(tryparse.(Int64, collect(keys(decayDict))), tryparse.(Int64, collect(keys(partDict))))
	else
		partDict = Dict{String,NamedArray{Float64,2}}()
		missed_years = getInterval(qs)
	end

	if !isempty(missed_years)
		for (key, value) in decayDict
			push!(partDict, key => value |> nuclideParts)
		end
	end
	return partDict
end

function calcFactors(q3_aDict::T, q3_∑Dict::T, partDict::T, decayDict::T) where{T<:Dict{String,NamedArray{Float64,2}}}
	if (old_qs != nothing) && (old_qs.nv == qs.nv)
		missed_years = setdiff(tryparse.(Int64, collect(keys(decayDict))), tryparse.(Int64, collect(keys(q3_aDict))))
	else
		q3_aDict = Dict{String,NamedArray{Float64,2}}()
		q3_∑Dict = Dict{String,NamedArray{Float64,2}}()
		missed_years = getInterval(qs)
	end

	if !isempty(missed_years)
		for (key, value) in partDict
			(q3a, q3∑) = value |> CalcFactors
			push!(q3_aDict, key => q3a)
			push!(q3_∑Dict, key => q3∑)
		end
	end
	return q3_aDict, q3_∑Dict
end

function createSettings()
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
    q_10us = b["cbtn_10us_calc"].:active[Bool]
    global qs = Settings(q_nv, q_year, q_gauge, q_target, q_treshold, q_refdate, q_paths, q_10us)
end

function solveAll(i::Int64, part::T, q3_a1::T, q3_∑1::T,  q3_a2::T, q3_∑2::T) where {T<:NamedArray{Float64,2}}
	global (m, x) = defineModel(qs, c, part, q3_a1, q3_∑1, q3_a2, q3_∑2)
    if qs.tenuSv == false
        e = solveStd()
    else
        e = solve10()
    end

	return e, nv_x
end

# export SQLite to XLSX
# for i in eachrow(DBInterface.execute(nvdb(), "select NV from nv_summary") |> DataFrame |> sort)
#     XLSX.openxlsx(joinpath("src", "Vollanalysen.xlsx"), mode="rw") do xf
#         XLSX.addsheet!(xf, i[1])
#         XLSX.writetable!(xf[i[1]],  collect(DataFrames.eachcol(getSampleFromSource(Symbol(i[1])))), DataFrames.names(getSampleFromSource(Symbol(i[1]))))
#     end
# end