module NuVe

using JuMP, Cbc
using SQLite, NamedArrays
import Statistics.mean, DataFrames.describe
const MOI = JuMP.MathOptInterface

include("types.jl")
include("utilities.jl")
include("database.jl")
include("decay.jl")
include("model.jl")

# export Types
export Settings, Constraint, RefDate

# export functions
export decayCorrection, df2namedarray, nuclideParts, CalcFactors, addUserConstraints, setBound, getSampleFromSource, getInterval

end
