"""
In diesem Type sind grundlegenden Einstellungen gespeichert. Dazu gehören
der Name des Nuklidvektors, der Berechnungszeitraum, das Optimierungsziel,
die zu berücksichtigen Messgeräte und ein möglicher Schwellenwert.
"""
struct Settings
  nv::Symbol
  year::Array{Int64}
  gauge::Array{Symbol}
  target::Symbol
  treshold::Real
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
