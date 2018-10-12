if isfile("nvdb-v3.sqlite")
    "Datenbank mit allen Nuklidvektoren, Proben, Halbwertszeiten und Freigabewerten"
    global nvdb = SQLite.DB("nvdb-v3.sqlite")

    "Die Namen aller verwendeten Nuklide"
    global nu_names = map(x -> String(x),
						SQLite.query(nvdb, "select nuclide from nuclide_decayType")[:,1])

	"Die Halbwertszeiten aller Nuklide"
	const hl = SQLite.query(nvdb, "select " * array2string(nu_names) * " from halflife");
end


"""
    read_db(s::String)

Gibt die angegebene Tabelle vollständig als DataFrame zurück.
"""
function read_db(tab)::String
	df = SQLite.query(nvdb, "select * from " * tab) |> DataFrame
end

"""
    read_db(s::String, arg::Array{String,1})

Gibt die angegebene Tabelle mit den angegebenen Spalten als DataFrame zurück.
"""
function read_db(tab::String, arg::Array{String,1})
	df = SQLite.query(nvdb, "select " * array2string(arg) * " from " * tab) |> DataFrame
end

"""
    get_nuclide_types(s::String)

Gibt alle Nuklide eines bestimmten Strahlungstypes (α, β oder γ) zurück.
"""
function get_nuclide_types(t::String)
	 map(x -> String(x),
        SQLite.query(nvdb,  "select nuclide from nuclide_decayType where decayType = '" * t * "'" )
        |> DataFrame )
end

"""
	getSampleFromSource(x::Symbol)

Ruft alle vorhanden Proben zu einem Nuklidvektor ab.
"""
function getSampleFromSource(nv::Symbol)
	q = SQLite.query(nvdb, "select s_id, date, " * array2string(nu_names) *
	" from nv_source join nv_summary on nv_source.nv_id = nv_summary.nv_id where NV = '" *
	(nv |> string) * "'")
	q.date = map(x->Date(x, "dd.mm.yyyy"), q.date)
	return q
end
