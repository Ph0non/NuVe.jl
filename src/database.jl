"Pfad zur Datenbank"
const db = joinpath(dirname(dirname(Base.functionloc(NuVe.eval, Tuple{Nothing})[1])), "src", "nvdb-v3.sqlite")

"""
    readDb(s::String)
Gibt die angegebene Tabelle vollständig als DataFrame zurück.
"""
function readDb(s::String)
	SQLite.Query(nvdb(), "select * from " * s) |> DataFrame
end

"""
    readDb(s::String, arg::Array{String,1})

Gibt die angegebene Tabelle mit den angegebenen Spalten als DataFrame zurück.
"""
function readDb(tab::String, arg::Array{String,1})
	SQLite.Query(nvdb(), "select " * array2string(arg) * " from " * tab) |> DataFrame
end

# if isfile(db)
"Datenbank mit allen Nuklidvektoren, Proben, Halbwertszeiten und Freigabewerten"
function nvdb()
	@warn(db)
	SQLite.DB(db)
end

"Die Namen aller verwendeten Nuklide"
const nu_names = SQLite.columns(nvdb(), "clearance_val").name[2:end] .|> String

"Die Halbwertszeiten aller Nuklide"
const hl = SQLite.Query(nvdb(), "select " * array2string(nu_names) * " from halflife") |> DataFrame

"Die Freigabewerte aller Nuklide"
const clearance_val = df2namedarray(readDb("clearance_val"), "path", "nuclide")

"Die Messeffizienzen für die verschiedenen Messverfahren und Nuklide"
const ɛ = df2namedarray(readDb("efficiency"), "method", "nuclide")

"Das Inverse der Freigabewerte"
const f = NamedArray( 1 ./ clearance_val, clearance_val.dicts, clearance_val.dimnames)
const fᵀ = f'
const ɛᵀ = ɛ'
# end


"""
    getNuclideTypes(s::String)

Gibt alle Nuklide eines bestimmten Strahlungstypes (α, β oder γ) zurück.
"""
function getNuclideTypes(t::String)
	 SQLite.Query(nvdb(),  "select nuclide from nuclide_decayType where decayType = '" * t * "'" ) |> DataFrame
end

"""
	getSampleFromSource(x::Symbol)

Ruft alle vorhanden Proben zu einem Nuklidvektor ab.
"""
function getSampleFromSource(nv::Symbol)
	q = SQLite.Query(nvdb(), "select s_id, date, " * array2string(nu_names) *
	" from nv_source join nv_summary on nv_source.nv_id = nv_summary.nv_id where NV = '" *
	(nv |> string) * "'") |> DataFrame
	q.date = map(x->Date(x, "dd.mm.yyyy"), q.date)
	return q
end
