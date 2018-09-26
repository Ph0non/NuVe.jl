function array2string(arg::Array{String,1})
    prod(arg .* ", ")[1:end-2]
end
