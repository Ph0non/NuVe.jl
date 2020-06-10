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
function defineModel(s::Settings, con:: Array{Constraint,1}, q2::T, q3a::T, q3∑::T) where {T<:NamedArray{Float64,2}}
	# if s.tenuSv == false
		m = JuMP.Model(Cbc.Optimizer)
	# else
	# 	m = Model(
    #     		optimizer_with_attributes(Juniper.Optimizer, 
    #         		"registered_functions" => [Juniper.register(:g_max, 3, g_max, autodiff=true)],
    #         		"nl_solver" => optimizer_with_attributes(Ipopt.Optimizer),
    #         		"mip_solver" => optimizer_with_attributes(Cbc.Optimizer),
    #         		"feasibility_pump" => true,
    #         		"processors" => 4
    #         	)
	# 		)
	# 	JuMP.register(m, :g_max, 3, g_max, autodiff=true)
	# end

    JuMP.@variable(m, 0 ≤ x[1:length(con)] ≤ 10_000, Int)
    JuMP.@constraint(m, sum(x) == 10_000);
    addUserConstraints(m, x, con)
    setObjectives(s, m, x, q2, con)
	setBound(s, m, x, con, q3a, q3∑)
	setBound(s, m, x, con, q3_a["2022"], q3_∑["2022"]) # TODO: nur temporär. Muss Jahresende berücksichtigen

	"Reducer"
	global r = [con[i].nuclide for i=1:length(con)] |> unique .|> string
	"Summenformel"
	global e1 = @expression(m, sum(x[index] / fgw_[1, value] for (index, value) in enumerate(r) ))
	return (m, x)
end


@everywhere g_max(x,y,z) = max(x,y,z)

"Produktnutzung gewerblich"
function modelPg(m::Model)
	eh_Pg_1 = 1E9 .* dosfac_geo["Produkt",r].array .* fraktionierung["Fraktionierung Produkt",r].array
	eh_Pg_2 = sample_Produktmasse_gewerblich .* sample_Expositionszeit_gewerblich .* sample_Vermischung_Ofen ./ sample_Abstand_gewerblich ./ sample_Abstand_gewerblich .* sample_FGW_bei_Transport
	eh_Pg_3 = @expression(m, [sum(x[i] * eh_Pg_1[i] * eh_Pg_2[j] for i=1:length(eh_Pg_1)) for j=1:length(eh_Pg_2)])
	z_Pg = JuMP.@variable(m, 0 ≤ z_Pg[1:sample_size]) # Hilfsvariable Dosis
	JuMP.@constraint(m, e1 * z_Pg .== eh_Pg_3)
	return z_Pg
end


"Produktnutzung Haushalt"
function modelPh(m::Model)
	eh_Ph_1 = 1E9 .* dosfac_geo["Produkt",r].array .* fraktionierung["Fraktionierung Produkt",r].array
	eh_Ph_2 = sample_Produktmasse_Haushalt .* sample_Expositionszeit_Haushalt .* sample_Vermischung_Ofen ./ sample_Abstand_Haushalt ./ sample_Abstand_Haushalt .* sample_FGW_bei_Transport
	eh_Ph_3 = @expression(m, [sum(x[i] * eh_Ph_1[i] * eh_Ph_2[j] for i=1:length(eh_Ph_1)) for j=1:length(eh_Ph_2)])
	z_Ph = JuMP.@variable(m, 0 ≤ z_Ph[1:sample_size]) # Hilfsvariable Dosis
	JuMP.@constraint(m, e1 * z_Ph .== eh_Ph_3)
	return z_Ph
end


"Sportplatz"
function modelSp(m::Model)
	eh_Sp_1 = 1E6 .* Atemrate_Sportplatz .* dosfac_ink["Inh. Erw.", r].array .* fraktionierung["Fraktionierung Schlacke",r].array
	eh_Sp_2 = sample_Staubkonzentration_Sportplatz .* sample_Expositionszeit_Sportplatz .* sample_Vermischung_Ofen_Sportplatz ./ sample_Anteil_Schlacke .* sample_FGW_bei_Transport
	eh_Sp_3 = @expression(m, [sum(x[i] * eh_Sp_1[i] * eh_Sp_2[j] for i=1:length(eh_Sp_1)) for j=1:length(eh_Sp_2)])
	z_Sp = JuMP.@variable(m, 0 ≤ z_Sp[1:sample_size]) # Hilfsvariable Dosis
	JuMP.@constraint(m, e1 * z_Sp .== eh_Sp_3)
	return z_Sp
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

 funs = [func_Dos_Produkt_gewerblich
        func_Dos_Produkt_Haushalt
        func_Dos_Sportplatz
        func_Dos_Kleinkind
        func_Dos_Transport
        func_Dos_Gamma_Metall]

# function modellMaxDos(m::Model, z_Pg::T, z_Ph::T, z_Sp::T) where {T<:Array{VariableRef,1}}
# 	gm = []
# 	for i=1:sample_size
# 		push!(gm, JuMP.@variable(m, g_max(z_Pg[i], z_Ph[i], z_Sp[i])) )
# 	end
# 	return gm
# end

# [z_Pg z_Ph z_Sp]
# gm = JuMP.@variable(m, gm[1:sample_size])
# for i=1:sample_size
# 	gm[i] = g_max(z_Pg[i], z_Ph[i], z_Sp[i])
# end

# function modellMaxDos(m::Model, z_Pg::T, z_Ph::T, z_Sp::T) where {T<:Array{VariableRef,1}}
# 	for i=1:sample_size
# 		@NLconstraint(m, g_max(z_Pg[i], z_Ph[i], z_Sp[i]) ≤ 60)
# 	end
# 	return m
# end
