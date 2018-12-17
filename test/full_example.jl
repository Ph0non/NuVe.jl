p = Dict(:fma => convert(Array{String, 1}, NuVe.readDb("clearance_val").:path)[[collect(1:3); collect(5:11)]], :is => convert(Array{String, 1}, NuVe.readDb("clearance_val").:path)[[collect(1:3); 10]])
setting = Settings(:A10, [2019, 2026], [:fma, :is], :mean, 1, RefDate("1 Jan", "d u"), p)

q0 = decayCorrection(setting, getSampleFromSource(setting.nv), getInterval(setting))

@test q0["2019"][5,3] |> ismissing == true
@test q0["2021"][1,4] == 3.868912616974668
@test q0["2024"][13,12] == 3.8851361070608976

q1 = Dict()
for (key, value) in q0
    push!(q1, key => df2namedarray(value, "samples", "nuclides"))
end
q1

@test q1["2021"][1,"Nb94"] == 0.09798535533562212
@test q1["2024"][13,"Am241"] == 0.21735287601251008
