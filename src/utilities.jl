function array2string(x::Array{String, 1})
    prod(x .* ", ")[1:end-2]
end

function array2string(x::Array{<:Number, 1})
	x = map(y -> string(y), x)
	array2string(x)
end
