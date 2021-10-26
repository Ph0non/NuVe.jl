"Pfad zur Datenbank"
#const db = joinpath(dirname(dirname(Base.functionloc(NuVe.eval, Tuple{Nothing})[1])), "src", "nvdb-v3.sqlite")
# const db = joinpath("src", "nvdb-v3.sqlite")
xf_param = XLSX.readxlsx(joinpath("src", "Parameter.xlsx"))
xf_ana = XLSX.readxlsx(joinpath("src", "Vollanalysen.xlsx"))
# """
#     readDb(s::String)
# Gibt die angegebene Tabelle vollständig als DataFrame zurück.
# """
# function readDb(s::String)
# 	DBInterface.execute(nvdb(), "select * from " * s) |> DataFrame
# end

# """
#     readDb(s::String, arg::Array{String,1})

# Gibt die angegebene Tabelle mit den angegebenen Spalten als DataFrame zurück.
# """
# function readDb(tab::String, arg::Array{String,1})
# 	DBInterface.execute(nvdb(), "select " * array2string(arg) * " from " * tab) |> DataFrame
# end

# "Datenbank mit allen Nuklidvektoren, Proben, Halbwertszeiten und Freigabewerten"
# function nvdb()
# 	SQLite.DB(db)
# end

"Die Freigabewerte aller Nuklide"
# const clearance_val = df2namedarray(readDb("clearance_val"), "path", "nuclide")
function fun_clearance_val()
	sheet_fgw = xf_param["Freigabewerte"]
	NamedArray(convert(Matrix{Float64}, sheet_fgw["B2:N33"]'), convert(Tuple{Vector{String}, Vector{String}}, (sheet_fgw["B1:N1"] |>vec , sheet_fgw["A2:A33"] |> vec)))
end
const clearance_val = fun_clearance_val()

"Die Namen aller verwendeten Nuklide"
const nu_names = clearance_val.dicts[2] |> keys .|> String

"Die Halbwertszeiten aller Nuklide"
function fun_hl()
	sheet_hl = xf_param["Halbwertszeiten"]
	hltmp = convert(Matrix{Float64}, [sheet_hl["B2:B33"][i] .* (sheet_hl["C2:C33"][i] == "a" ? 365.25 : 1) for i=1:length(nu_names)]')
	DataFrame(hltmp, Symbol.(sheet_hl["A2:A33"] |> vec))
end
# const hl = DBInterface.execute(nvdb(), "select " * array2string(nu_names) * " from halflife") |> DataFrame
const hl = fun_hl()

"Die Messeffizienzen für die verschiedenen Messverfahren und Nuklide"
function fun_ɛ()
	sheet_ɛ = xf_param["Messeffizienzen"]
	q = NamedArray(convert(Matrix{Float64}, coalesce.(sheet_ɛ["B2:F33"], 0)'), convert(Tuple{Vector{String}, Vector{String}}, (sheet_ɛ["B1:F1"] |>vec , sheet_ɛ["A2:A33"] |> vec)))
	NamedArray(q ./ q[:, "Co60"], convert(Tuple{Vector{String}, Vector{String}}, (sheet_ɛ["B1:F1"] |>vec , sheet_ɛ["A2:A33"] |> vec)))
end 
# const ɛ = df2namedarray(readDb("efficiency"), "method", "nuclide")
const ɛ = fun_ɛ()
const ɛᵀ = ɛ'

"Das Inverse der Freigabewerte"
const f = NamedArray( 1 ./ clearance_val.array, clearance_val.dicts, clearance_val.dimnames)
const fᵀ = f'

"""
#     getNuclideTypes(s::String)

# Gibt alle Nuklide eines bestimmten Strahlungstypes (α, β oder γ) zurück.
# """
# function getNuclideTypes(t::String)
# 	 DBInterface.execute(nvdb(),  "select nuclide from nuclide_decayType where decayType = '" * t * "'" ) |> DataFrame
# end

"""
	getSampleFromSource(x::Symbol)

Ruft alle vorhanden Proben zu einem Nuklidvektor ab.
"""
function getSampleFromSource(nv::Symbol)
	q = XLSX.getdata(xf_ana[string(nv)]) |> permutedims
	q2 = q[.!ismissing.(q[:,1]), :]
	dt = [Int; Date; repeat([float], 32)]
	q3 = DataFrame(q2[2:end, :], Symbol.(q2[1,:]))
	for i=1:length(dt)
		q3[!,i] = dt[i].(q3[!,i])
	end
	return q3
end

"Parameter von Excel-Blatt einlesen für 10µSv-Berechnung"
const int_sheet = xf_param["Dosiskoeffizienten"]
const fgw_ = NamedArray(int_sheet["B2:U3"], (int_sheet["A2:A3"] |> vec, int_sheet["B1:U1"] |> vec))
const fraktionierung = NamedArray(int_sheet["B6:U8"], (int_sheet["A6:A8"] |> vec, int_sheet["B1:U1"] |> vec))
const dosfac_geo =  NamedArray(int_sheet["B11:U14"], (int_sheet["A11:A14"] |> vec, int_sheet["B1:U1"] |> vec))
const dosfac_ink =  NamedArray(int_sheet["B17:U21"], (int_sheet["A17:A21"] |> vec, int_sheet["B1:U1"] |> vec))