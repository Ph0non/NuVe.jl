function array2string(x::Array{String, 1})
    prod(x .* ", ")[1:end-2]
end

function array2string(x::Array{<:Number, 1})
	x = String.(x)
	array2string(x)
end

"""
	getSampleInfo(x::String, nv::Symbol)

Fragt zu einem gegebenen Nuklidvektor weitere Informationen ab (z. B. "date" oder "source" (Herkunftsort))
"""
function getSampleInfo(x::String, nv::Symbol)
	SQLite.query(nvdb, "select " * x * " from nv_source join nv_summary on nv_source.nv_id = nv_summary.nv_id where NV = '" * (nv |> String) *"'")
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
	reshape(x, 1, length(x))
end

"""
	 removeMissing(x::DataFrame)

Ersetzt in einem DataFrame alle `missing` durch 0.
"""
function removeMissing(x::DataFrame)
	for i in Symbol.(nu_names)
		x[i] = coalesce.(x[i], 0)
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
		( String.(x[1]), String.(names(x))[2:end] ),
		(rowname, columnname) )
end

"""
	nuclide_parts(x::NamedArrays.NamedArray)

Gibt ein NamedArray mit den Nuklidanteilen wieder. Die Summe aller Nuklide über
jeder Probe ergibt 1.
"""
function nuclide_parts(x::NamedArrays.NamedArray)
	x./sum(x, dims=2)
end

function calc_factors(x::NamedArrays.NamedArray)
	a = 1 ./ (x * fᵀ)
	∑Co60Eq = x * ɛᵀ

	return a, ∑Co60Eq
end
