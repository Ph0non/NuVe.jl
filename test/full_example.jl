# Settings
p = Dict(:fma => convert(Array{String, 1}, NuVe.readDb("clearance_val").:path)[[collect(1:3); collect(5:11)]], :is => convert(Array{String, 1}, NuVe.readDb("clearance_val").:path)[[collect(1:3); 10]])
setting = Settings(:A10, [2019, 2026], [:fma, :is], :mean, 1, RefDate("1 Jan", "d u"), p)

# Decay Correction
q0 = decayCorrection(setting, getSampleFromSource(setting.nv), getInterval(setting))

@test q0["2019"][5,3] |> ismissing == true
@test isapprox(q0["2021"][1,4], 3.868912616974668)
@test isapprox(q0["2024"][13,12], 3.8851361070608976)

# Transform DataFrame to NamedArray
q1 = Dict()
for (key, value) in q0
    push!(q1, key => df2namedarray(value, "samples", "nuclides"))
end

@test isapprox(q1["2021"][1,"Nb94"], 0.09798535533562212)
@test isapprox(q1["2024"][13,"Am241"], 0.21735287601251008)

# determine percents
q2 = Dict()
for (key, value) in q0
    push!(q2, key => df2namedarray(value, "samples", "nuclides") |> nuclideParts)
end

@test isapprox(q2["2020"][5,"Cs137"], 0.15620117797991342)
@test isapprox(q2["2020"][10,"Pu241"], 0.008343576209308942)

# calc some factors
q3_a = Dict()
q3_∑ = Dict()
for (key, value) in q2
    (q3a, q3∑) = value |> CalcFactors
    push!(q3_a, key => q3a)
    push!(q3_∑, key => q3∑)
end

@test isapprox(q3_a["2024"][1,"1b"], 0.020052127083862895)
@test isapprox(q3_a["2025"][1,"1a*"], 0.6383234421244084)
@test isapprox(q3_∑["2022"][3,"fma"], 0.13542013493837893)
@test isapprox(q3_∑["2022"][5,"is"], 0.22208799526459147)

# define some constraints
con1 = [Constraint(:Co60, :>, 5, 1)
    Constraint(:Cs137, :>, 5, 1)
    Constraint(:Ni63, :<, 70, 1)
    Constraint(:Am241, :<, 10, 1)]

# TODO: implement constraints for decay types
# con2 = [Constraint(:∑γ, :<, 20, 1)]

q4 = Dict()
for i in getInterval(setting) .|> string
    m = NuVe.JuMP.Model(NuVe.JuMP.with_optimizer(NuVe.Cbc.Optimizer))
    NuVe.JuMP.@variable(m, 0 ≤ x[1:length(con1)] ≤ 10_000, Int)
    NuVe.JuMP.@constraint(m, sum(x) == 10_000);
    addUserConstraints(m, x, con1)
    NuVe.setObjectives(setting, m, x, q2[i], con1)
    setBound(setting, m, x, con1, q3_a[i], q3_∑[i])

    NuVe.JuMP.optimize!(m)

    if NuVe.JuMP.termination_status(m) == NuVe.MOI.Success && NuVe.JuMP.primal_status(m) == NuVe.MOI.FeasiblePoint
        push!(q4, i => [round.(Int, NuVe.JuMP.value(x[j]))./100 for j=1:length(con1)])
    else
        push!(q4, i => NuVe.JuMP.termination_status(m))
    end
end

@test q4["2019"] == [5.56, 15.64, 70.0, 8.8]
@test q4["2026"] == [5.0, 16.33, 70.0, 8.67]
