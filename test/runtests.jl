using Test

using JuMP, Cbc
using SQLite, NamedArrays
import Statistics.mean, DataFrames.describe
const MOI = JuMP.MathOptInterface

include("./test_utilities.jl")
