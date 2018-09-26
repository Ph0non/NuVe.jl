"""
In diesem Type sind grundlegenden Einstellungen gespeichert. Dazu gehören
der Name des Nuklidvektors, der Berechnungszeitraum, das Optimierungsziel
und die zu berücksichtigen Messgeräte.
"""
struct Settings
  nv::String
  year::Array{Int64}
  gauge::Array{String}
  target::String
end

"""
Dieser Type beinhaltet die zusätzlichen Bedingungen zur Berechnung des
Nuklidvektors. Dazu gehören das einzuschränkende Nuklid, das Relationszeichen,
die Grenze und eine Wichtung.
"""
struct Constraint
  name::String
  relation::String
  limit::Float64
  weight::Float64
end
