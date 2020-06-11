#module NuVe
using JuMP, Cbc
using SQLite, NamedArrays, Dates
import Statistics.mean, DataFrames.describe
using DataFrames, Distributions, XLSX

prefix = ""
if splitpath(pwd())[end] != "src"
    # global prefix = "src"
end

include(joinpath(prefix, "types.jl"))
include(joinpath(prefix, "utilities.jl"))
include(joinpath(prefix, "database.jl"))
include(joinpath(prefix, "decay.jl"))
include(joinpath(prefix, "dists.jl"))
include(joinpath(prefix, "samples.jl"))
include(joinpath(prefix, "funsDose.jl"))
include(joinpath(prefix, "model.jl"))

# export Types
export Settings, Constraint, RefDate

# export functions
export decayCorrection, df2namedarray, nuclideParts, CalcFactors, addUserConstraints, setBound, getSampleFromSource, getInterval, setObjectives

#end
