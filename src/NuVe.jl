#module NuVe
using JuMP, Cbc
using SQLite, NamedArrays, Dates, DataStructures
import Statistics.mean, DataFrames.describe
using DataFrames, Distributions, XLSX

prefix = ""
if splitpath(pwd())[end] != "src"
    global prefix = "src"
end

include(joinpath("types.jl"))
include(joinpath("utilities.jl"))
include(joinpath("database.jl"))
include(joinpath("decay.jl"))
include(joinpath("dists.jl"))
include(joinpath("samples.jl"))
include(joinpath("funsDose.jl"))
include(joinpath("model.jl"))

# export Types
export Settings, Constraint, RefDate

# export functions
export decayCorrection, df2namedarray, nuclideParts, CalcFactors, addUserConstraints, setBound, getSampleFromSource, getInterval, setObjectives

#end
