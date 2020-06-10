"""
Dieser Type beinhaltet die Angabe für den Referenztag und -monat für die Zerfallskorrektur
zu einem bestimmten Jahr
"""
struct RefDate
  date::String
  format::String
end


"""
In diesem Type sind grundlegenden Einstellungen gespeichert. Dazu gehören
der Name des Nuklidvektors, der Berechnungszeitraum, das Optimierungsziel,
die zu berücksichtigen Messgeräte, ein möglicher Schwellenwert, das
Referenzdatum [`RefDate`](@ref) (Tag und Monat) für die Zerfallskorrektur und die
zu berücksichtigenden Freigabepfade für die jeweilligen Messverfahren.
"""
struct Settings
  nv::Symbol
  year::Array{Int64}
  gauge::Array{Symbol}
  target::Symbol
  treshold::Real
  refDate::RefDate
  paths::Dict
  tenuSv::Bool
end

"""
Dieser Type beinhaltet die zusätzlichen Bedingungen zur Berechnung des
Nuklidvektors. Dazu gehören das einzuschränkende Nuklid, das Relationszeichen,
die Grenze und eine Wichtung.
"""
struct Constraint
  nuclide::Symbol
  relation::Symbol
  limit::Float64
  weight::Float64
end
