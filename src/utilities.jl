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
	for i in names(x)
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
