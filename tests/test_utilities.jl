include("../src/utilities.jl")

@test string.([1, 2, 3, 4]) |> array2string == "1, 2, 3, 4"
