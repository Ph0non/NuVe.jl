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
function setObjectives(m::Model, x::Array{VariableRef,1}, parts::NamedArrays.NamedArray, c::Array{Constraint,1})
	if setting.target == :fma
		@objective(m, Max, sum( ε["fma", getNuclidesFromConstraint(c)] .* x))
	elseif setting.target == :mc
		@objective(m, Max, sum( ε["mc", getNuclidesFromConstraint(c)] .* x ))
	elseif setting.target == :como
		@objective(m, Max, sum( ε["como", getNuclidesFromConstraint(c)] .* x ))
	elseif setting.target == :lb124
		@objective(m, Max, sum( ε["lb124", getNuclidesFromConstraint(c)] .* x ))
	elseif setting.target == :is
		@objective(m, Max, sum( ε["is", getNuclidesFromConstraint(c)] .* x ))
	# elseif setting.target in keys(readDb("clearance_val").path)
		# @objective(m, :Max, sum(x .* f_red[setting.target, :]) );
	elseif setting.target == :mean
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

function setBound(m::Model, x::Array{VariableRef,1}, c::Array{Constraint,1}, ∑xᵢdivfᵢ::NamedArrays.NamedArray, ∑εᵢxᵢ::NamedArrays.NamedArray)
	∑εᵢyᵢ = ε[setting.gauge .|> String, getNuclidesFromConstraint(c)] * x

	@constraint(m, [j in names(∑xᵢdivfᵢ, 1), l in keys(setting.paths), k in setting.paths[l]], ∑εᵢyᵢ[String(l)] * ∑xᵢdivfᵢ[j, k] ≤ setting.treshold * ∑εᵢxᵢ[j, String(l)] * [f[setting.paths[l], getNuclidesFromConstraint(c)] * x][1][k])
end
