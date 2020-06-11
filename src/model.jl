"""
	addUserConstraints(x::Array{VariableRef,1}, c::Array{Constraint,1})

Fügt die vom Nutzer festgelegten Randbedingungen dem Modell hinzu.
"""
# https://discourse.julialang.org/t/error-in-jump-with-nonlinear-objective/35261/6
# lower und upper bound statt constraint
function addUserConstraints(m::Model, x::Array{VariableRef,1}, c::Array{Constraint,1})
	for i = 1:length(c)
		if c[i].relation == :<
			@constraint(m, x[i] <= 100c[i].limit)
		elseif c[i].relation == :>
			@constraint(m, x[i] >= 100c[i].limit)
		elseif c[i].relation == :(=)
			@constraint(m, x[i] == 100c[i].limit)
		end
	end
end

"""
	setObjectives(x::Array{VariableRef,1}, parts::NamedArrays.NamedArray, c::Array{Constraint,1})

Legt das Optimierungsziel des Modells aufgrund der Einstellungen ([`Settings`](@ref)) fest.
"""
function setObjectives(s::Settings, m::Model, x::Array{VariableRef,1}, parts::NamedArrays.NamedArray, c::Array{Constraint,1})
	if s.target == :fma
		@objective(m, Max, sum( ε["fma", getNuclidesFromConstraint(c)] .* x))
	elseif s.target == :mc
		@objective(m, Max, sum( ε["mc", getNuclidesFromConstraint(c)] .* x ))
	elseif s.target == :como
		@objective(m, Max, sum( ε["como", getNuclidesFromConstraint(c)] .* x ))
	elseif s.target == :lb124
		@objective(m, Max, sum( ε["lb124", getNuclidesFromConstraint(c)] .* x ))
	elseif s.target == :is
		@objective(m, Max, sum( ε["is", getNuclidesFromConstraint(c)] .* x ))
	# elseif setting.target in keys(readDb("clearance_val").path)
		# @objective(m, :Max, sum(x .* f_red[setting.target, :]) );
	elseif s.target == :mean
		# if isZ01
			# np_red = mean(np, 1)[:, rel_nuclides]
		# else
			meanOverSamples = mean(parts, dims=1)[:, getNuclidesFromConstraint(c)]
		# end
		tempObjective = x .- 10_000 * meanOverSamples'

		@variable(m, z[1:length(c)] )
		@constraint(m, z .>=  tempObjective.array )
		@constraint(m, z .>= -tempObjective.array )
		@objective(m, Min, sum(z .* getWeightsFromConstraint(c)) )
	end
end

function setBound(s::Settings, m::Model, x::Array{VariableRef,1}, c::Array{Constraint,1}, ∑xᵢdivfᵢ::NamedArrays.NamedArray, ∑εᵢxᵢ::NamedArrays.NamedArray)
	∑εᵢyᵢ = ε[s.gauge .|> String, getNuclidesFromConstraint(c)] * x

	@constraint(m, [j in names(∑xᵢdivfᵢ, 1), l in keys(s.paths), k in s.paths[l]], ∑εᵢyᵢ[String(l)] * ∑xᵢdivfᵢ[j, k] ≤ s.treshold * ∑εᵢxᵢ[j, String(l)] * [f[s.paths[l], getNuclidesFromConstraint(c)] * x][1][k])
end


function test_nv(s::Settings, nv::Array{Float64,1})
	t0 = decayCorrection(s, getSampleFromSource(s.nv), getInterval(s))

	t1 = Dict()
	for (key, value) in t0
	    push!(t1, key => df2namedarray(value, "samples", "nuclides"))
	end

	"Anteile"
	t2 = Dict()
	for (key, value) in t0
	    push!(t2, key => df2namedarray(value, "samples", "nuclides") |> nuclideParts)
	end

	"Faktoren"
	t3_a = Dict()
	t3_∑ = Dict()
	for (key, value) in t2
	    (t3a, t3∑) = value |> CalcFactors
	    push!(t3_a, key => t3a)
	    push!(t3_∑, key => t3∑)
	end

	
end

"""
	defineModel()(x::Array{VariableRef,1}, parts::NamedArrays.NamedArray, c::Array{Constraint,1})

Erstellt abhängig vom Flag `tenuSv` das passende Modell. Wenn `tenuSv == true` wird versucht das 10-µSv-Konzept für Metalle zur Rezyklierung ohne Berücksichtigung der Oberfläche  einzuhalten. 
"""
function defineModel(s::Settings, con:: Array{Constraint,1}, q2::T, q3a::T, q3∑::T, q3a_end::T, q3∑_end::T) where {T<:NamedArray{Float64,2}}
	m = JuMP.Model(Cbc.Optimizer)
	JuMP.set_silent(m)

    JuMP.@variable(m, 0 ≤ x[1:length(con)] ≤ 10_000, Int)
    JuMP.@constraint(m, sum(x) == 10_000);
    addUserConstraints(m, x, con)
    setObjectives(s, m, x, q2, con)
	setBound(s, m, x, con, q3a, q3∑)
	setBound(s, m, x, con, q3a_end, q3∑_end)

	"Reducer"
	global r = [con[i].nuclide for i=1:length(con)] |> unique .|> string
	return (m, x)
end

function nuclideToConstrain()
    q = [fit(LogNormal, Dos_Produkt_gewerblich)
        fit(LogNormal, Dos_Produkt_Haushalt)
        fit(LogNormal, Dos_Sportplatz)
        fit(LogNormal, Dos_Kleinkind)
        fit(LogNormal, Dos_Transport)
        fit(LogNormal, Dos_Herstellung_Metall)]

	szenario = funs[findmax(quantile.(q, 0.95))[2]]
	id_red = findmax( quantile.( [fit(LogNormal, szenario()[:, i]) for i=1:length(r[nv_x .> 0])], 0.95 ) )[2]
	
    return (string(szenario)[10:end], findfirst(r .==  r[nv_x .> 0][id_red]))
end

const funs = [func_Dos_Produkt_gewerblich
        func_Dos_Produkt_Haushalt
        func_Dos_Sportplatz
        func_Dos_Kleinkind
        func_Dos_Transport
        func_Dos_Gamma_Metall]


function solveStd()
    JuMP.optimize!(m)

    if JuMP.termination_status(m) != JuMP.MOI.OPTIMAL 
        println("Problem unlösbar")
        return JuMP.termination_status(m)
    end
    global nv_x = round.(JuMP.value.(x)./100, digits=2)
    return nothing
end

function solve10()
    heu_vec = [1/(2^n) for n=1:14]
    koef_vec = zeros(length(heu_vec), length(r))
    iter_ind = zeros(Int64, length(r))
    iter_max = 30

    for i = 1:iter_max
        JuMP.optimize!(m)
        if JuMP.termination_status(m) != JuMP.MOI.OPTIMAL 
            println("Problem unlösbar")
            return JuMP.termination_status(m)
        end
        global nv_x = round.(JuMP.value.(x)./100, digits=2)

        Max_Dosis = checkDose()
        dos = quantile( fit(LogNormal, Max_Dosis.array), 0.95)
        (szenario, id_nuc) = nuclideToConstrain()
        print("JuMP Status: "* string(JuMP.termination_status(m)) * "\nDosis: " * string(round(dos, digits=2)) * " µSv/a\nSzenario: " * szenario * ", Nuklid: " * r[id_nuc] * "\n")
        global iter_ind[id_nuc] += 1
        koef_vec[iter_ind[id_nuc], id_nuc] = 1
        if dos < 9.9
            iter_ind[id_nuc] == 1 ? break : nothing
            koef_vec[iter_ind[id_nuc]-1, id_nuc] = 0
        end
        set_upper_bound( x[id_nuc], 10_000 * (1 - sum(heu_vec .* koef_vec[:,id_nuc]))  )
        print("Iteration: " * string(i) * "/" * string(iter_max) * ", new upper bound: " * string( round(100 * (1 - sum(heu_vec .* koef_vec[:,id_nuc]) ), digits=2)) * "%\n\n")
        maximum(iter_ind) == length(heu_vec) ? break : nothing
    end
    return nothing
end