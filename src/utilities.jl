function array2string(x::Array{String, 1})
    prod(x .* ", ")[1:end-2]
end

function array2string(x::Array{<:Number, 1})
	x = map(y -> string(y), x)
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

Transponiert einen Vektor (`n × 1`) zu (`1 × n`)
"""
function travec(x::Array)
	reshape(x, 1, length(x))
end
