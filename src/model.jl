"""
	addUserConstraints(x::Array{VariableRef,1}, c::Array{Constraint,1})

Fügt die vom Nutzer festgelegten Randbedingungen dem Modell hinzu.
"""
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
