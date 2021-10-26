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

function getIdxFromNuc(used_nuc::Array{String,1}, i::Int64, cg::Array{Constraint,1})
	group_alpha = [:U233, :U234, :U235, :U238, :Pu238, :Pu239Pu240, :Am241, :Cm242, :Cm244]
	group_beta = [:H3, :C14, :Fe55, :Ni59, :Ni63, :Sr90, :Pu241]
	group_gamma = [:Mn54, :Co57, :Co60, :Zn65, :Nb94, :Ru106, :Ag108m, :Ag110m, :Sb125, :Ba133, :Cs134, :Cs137, :Ce144, :Eu152, :Eu154, :Eu155]

	dict_group_nuc = Dict(:sa => group_alpha, :sb => group_beta, :sg => group_gamma)

	idx_nuc = indexin( dict_group_nuc[cg[i].nuclide] , used_nuc .|> Symbol)
	return idx_nuc[idx_nuc .!= nothing]
end

function addUserConstraintsNuclideGroups(m::Model, x::Array{VariableRef,1}, used_nuc::Array{String,1}, cg::Array{Constraint,1})
	for i = 1:length(cg)
		if cg[i].relation == :<
			@constraint(m, sum(x[j] for j in getIdxFromNuc(used_nuc, i, cg)) <= 100cg[i].limit)
		elseif cg[i].relation == :>
			@constraint(m, sum(x[j] for j in getIdxFromNuc(used_nuc, i, cg)) >= 100cg[i].limit)
		elseif cg[i].relation == :(=)
			@constraint(m, sum(x[j] for j in getIdxFromNuc(used_nuc, i, cg)) == 100cg[i].limit)
		end
	end
end

"""
	setObjectives(x::Array{VariableRef,1}, parts::NamedArrays.NamedArray, c::Array{Constraint,1})

Legt das Optimierungsziel des Modells aufgrund der Einstellungen ([`Settings`](@ref)) fest.
"""
function setObjectives(s::Settings, m::Model, x::Array{VariableRef,1}, parts::NamedArrays.NamedArray, c::Array{Constraint,1})
	if s.target == :fma
		@objective(m, Max, sum( ε["fma", getNuclidesFromConstraint(c)] .* getWeightsFromConstraint(c) .* x))
	elseif s.target == :mc
		@objective(m, Max, sum( ε["mc", getNuclidesFromConstraint(c)] .* getWeightsFromConstraint(c) .* x ))
	elseif s.target == :como
		@objective(m, Max, sum( ε["como", getNuclidesFromConstraint(c)] .* getWeightsFromConstraint(c) .* x ))
	elseif s.target == :lb124
		@objective(m, Max, sum( ε["lb124", getNuclidesFromConstraint(c)] .* getWeightsFromConstraint(c) .* x ))
	elseif s.target == :is
		@objective(m, Max, sum( ε["is", getNuclidesFromConstraint(c)] .* getWeightsFromConstraint(c) .* x ))
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
	elseif s.target == :fgw3a
		@objective(m, Min, sum( f["3a", getNuclidesFromConstraint(c)] .* getWeightsFromConstraint(c) .* x ))
	end
end

function setBound(s::Settings, m::Model, x::Array{VariableRef,1}, c::Array{Constraint,1}, ∑xᵢdivfᵢ::NamedArrays.NamedArray, ∑εᵢxᵢ::NamedArrays.NamedArray)
	∑εᵢyᵢ = ε[s.gauge .|> String, getNuclidesFromConstraint(c)] * x

	@constraint(m, [j in names(∑xᵢdivfᵢ, 1), l in keys(s.paths), k in s.paths[l]], s.treshold * ∑εᵢyᵢ[String(l)] * ∑xᵢdivfᵢ[j, k] ≤ ∑εᵢxᵢ[j, String(l)] * [f[s.paths[l], getNuclidesFromConstraint(c)] * x][1][k])
end

# ∑εᵢyᵢ[1,1] *  ∑xᵢdivfᵢ[1, "1a"] <= ∑εᵢxᵢ[1, "fma"] *  [f[s.paths[:fma], getNuclidesFromConstraint(con1)] * x][1][1]

function test_nv()
	createSettings() # erstellt aktuell ausgewählte Optionen
	# denk daran, dass die Neuauswahl eines NVs die Dicts zurücksetzt (auch nvDict)
	s = qs
	t0 = decayCorrection(s, getSampleFromSource(s.nv), getInterval(s))

	t1 = Dict{String,NamedArray{Float64,2}}()
	for (key, value) in t0
	    push!(t1, key => df2namedarray(value, "samples", "nuclides"))
	end

	"Anteile"
	t2 = Dict{String,NamedArray{Float64,2}}()
	for (key, value) in t0
	    push!(t2, key => df2namedarray(value, "samples", "nuclides") |> nuclideParts)
	end

	"Faktoren"
	∑xᵢdivfᵢ = Dict{String,NamedArray{Float64,2}}()
	∑εᵢxᵢ = Dict{String,NamedArray{Float64,2}}()
	for (key, value) in t2
	    (t3a, t3∑) = value |> CalcFactors
	    push!(∑xᵢdivfᵢ, key => t3a)
	    push!(∑εᵢxᵢ, key => t3∑)
	end

	# packe den NV in ein NamedArray und Dict (für die jeweiligen Jahre)
	y = Dict(i => NamedArray(nvDict[i]', (["1"], getNuclidesFromConstraint(con)) ) for i in keys(nvDict))
	# und berechne dann die Faktoren analog wie die Faktoren für die Proben
	∑yᵢdivfᵢ = Dict{String,NamedArray{Float64,2}}()
	∑εᵢyᵢ = Dict{String,NamedArray{Float64,2}}()
	for (key, value) in y
	    (t4a, t4∑) = CalcFactors(value, getNuclidesFromConstraint(con))
	    push!(∑yᵢdivfᵢ, key => t4a)
	    push!(∑εᵢyᵢ, key => t4∑)
	end

	# ∑xᵢdivfᵢ["2021"]
	# ∑εᵢxᵢ["2021"]
	# ∑yᵢdivfᵢ["2021"]
	# ∑εᵢyᵢ["2021"]

	# Anfang des Jahres
	α1 = Dict(i => NamedArray( ∑xᵢdivfᵢ[i] ./ ∑yᵢdivfᵢ[i], keys.(∑xᵢdivfᵢ[i].dicts) .|> collect) for i in keys(nvDict))
	β1 = Dict(i => NamedArray( ∑εᵢyᵢ[i] ./ ∑εᵢxᵢ[i], keys.(∑εᵢxᵢ[i].dicts) .|> collect) for i in keys(nvDict))
	
	# Ende des Jahres
	α2 = Dict(i => NamedArray( ∑xᵢdivfᵢ[incStrYear(i)] ./ ∑yᵢdivfᵢ[i], keys.(∑xᵢdivfᵢ[i].dicts) .|> collect) for i in keys(nvDict))
	β2 = Dict(i => NamedArray( ∑εᵢyᵢ[i] ./ ∑εᵢxᵢ[incStrYear(i)], keys.(∑εᵢxᵢ[i].dicts) .|> collect) for i in keys(nvDict))
	

	SW = Dict{String,NamedArray{Float64,3}}()
	for i in keys(nvDict)
		γ = Array{Float64}(undef, length(getSampleFromSource(s.nv).s_id), length(keys(fᵀ.dicts[2])), length(keys(ɛᵀ.dicts[2])))
		for (key, value) in enumerate(keys(ɛᵀ.dicts[2]))
			# speichere jeweils den kleineren Wert zwischen Jahresanfang und Jahresende
			γ[:,:,key] = min.( 1 ./ (α1[i] .*  β1[i][:, value]), 1 ./ (α2[i] .*  β2[i][:, value]) )
		end
		push!(SW, i => NamedArray( γ, (getSampleFromSource(s.nv).s_id, keys(fᵀ.dicts[2]) |> collect, keys(ɛᵀ.dicts[2]) |> collect) ) )
	end
	
	return SW
end

"""
	defineModel()(x::Array{VariableRef,1}, parts::NamedArrays.NamedArray, c::Array{Constraint,1})

Erstellt abhängig vom Flag `tenuSv` das passende Modell. Wenn `tenuSv == true` wird versucht das 10-µSv-Konzept für Metalle zur Rezyklierung ohne Berücksichtigung der Oberfläche  einzuhalten. 
"""
function defineModel(s::Settings, ccon::Array{Constraint,1}, q2::T, q3a::T, q3∑::T, q3a_end::T, q3∑_end::T) where {T<:NamedArray{Float64,2}}
	global con = deepcopy(ccon)
	m = JuMP.Model(Cbc.Optimizer)
	JuMP.set_silent(m)

	# seperate nuclide-specific constraint from nuclide-group constraint
	
	# delete nuclide-group constraint from var 'con' and add it to extra constraint array for nuclide groups
	global conGroup = Constraint[]
	for i in [:sa, :sb, :sg]
		nu_ind = findfirst(i .== [c[i].nuclide for i=1:length(c)])
		if nu_ind != nothing
			push!(conGroup, con[nu_ind])
			deleteat!(con, nu_ind)
		end
	end

    JuMP.@variable(m, 0 ≤ x[1:length(con)] ≤ 10_000, Int)
    JuMP.@constraint(m, sum(x) == 10_000);
    addUserConstraints(m, x, con)
	addUserConstraintsNuclideGroups(m, x, getNuclidesFromConstraint(con), conGroup)
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
    global koef_vec = zeros(length(heu_vec), length(r))
    iter_ind = zeros(Int64, length(r))
	iter_max = 50
	id_nuc_last_idx = Int64[]

    for i = 1:iter_max
		JuMP.optimize!(m)
        if JuMP.termination_status(m) == JuMP.MOI.OPTIMAL 
            # return JuMP.termination_status(m)
			global nv_x = round.(JuMP.value.(x)./100, digits=2)

			Max_Dosis = checkDose()
			dos = quantile( fit(LogNormal, Max_Dosis.array), 0.95)	
			global (szenario, id_nuc) = nuclideToConstrain()
			print("JuMP Status: "* string(JuMP.termination_status(m)) * "\nDosis: " * string(round(dos, digits=2)) * " µSv/a\nSzenario: " * szenario * ", Nuklid: " * r[id_nuc] * "\n")
			append!(id_nuc_last_idx, id_nuc)
			# if length(id_nuc_last_idx) > 1
			# 	if id_nuc_last_idx[end] != id_nuc_last_idx[end-1]
			# 		koef_vec[iter_ind[id_nuc_last_idx[end-1]], id_nuc_last_idx[end-1]] = 0
			# 		koef_vec[iter_ind[id_nuc_last_idx[end-1]]+ 1, id_nuc_last_idx[end-1]] = 1
			# 		set_upper_bound( x[id_nuc_last_idx[end-1]], 10_000 * (1 - sum(heu_vec .* koef_vec[:,id_nuc_last_idx[end-1]]))  )
			# 	end
			# end
			
			global iter_ind[id_nuc] += 1
			koef_vec[iter_ind[id_nuc], id_nuc] = 1
			if dos < 9.6
				if iter_ind[id_nuc] == 1 # warum ausgerechnet diese Bedingung?
					println("Lösung gefunden!")
					break
				else
					nothing
				end
				koef_vec[iter_ind[id_nuc]-1, id_nuc] = 0
			end
			set_upper_bound( x[id_nuc], 10_000 * (1 - sum(heu_vec .* koef_vec[:,id_nuc]))  )
			print("Iteration: " * string(i) * "/" * string(iter_max) * ", new upper bound: " * string( round(100 * (1 - sum(heu_vec .* koef_vec[:,id_nuc]) ), digits=2)) * "%\n\n")
			# for j in 1:length(r)
			# 	println("Upper Bound " * string(r[iter_ind[j]]) * ": " * string( round(100 * (1 - sum(heu_vec .* koef_vec[:,j]) ), digits=2)) * "%")
			# end
		else
			println("Problem unlösbar")
			global iter_ind[id_nuc] += 1
			koef_vec[iter_ind[id_nuc], id_nuc] = 1		
			koef_vec[iter_ind[id_nuc]-1, id_nuc] = 0
			set_upper_bound( x[id_nuc], 10_000 * (1 - sum(heu_vec .* koef_vec[:,id_nuc]))  )
			print("Iteration: " * string(i) * "/" * string(iter_max) * ", new upper bound: " * string( round(100 * (1 - sum(heu_vec .* koef_vec[:,id_nuc]) ), digits=2)) * "%\n\n")
		end
		if maximum(iter_ind) == length(heu_vec) 
			println("Keine bessere Lösung möglich!")
			break
		else
			nothing
		end
    end
    return nothing
end