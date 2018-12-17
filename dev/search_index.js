var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "NuVe.jl Dokumentation",
    "title": "NuVe.jl Dokumentation",
    "category": "page",
    "text": ""
},

{
    "location": "#NuVe.jl-Dokumentation-1",
    "page": "NuVe.jl Dokumentation",
    "title": "NuVe.jl Dokumentation",
    "category": "section",
    "text": ""
},

{
    "location": "#Benutzung-1",
    "page": "NuVe.jl Dokumentation",
    "title": "Benutzung",
    "category": "section",
    "text": "Todo"
},

{
    "location": "#NuVe.CalcFactors-Tuple{NamedArrays.NamedArray}",
    "page": "NuVe.jl Dokumentation",
    "title": "NuVe.CalcFactors",
    "category": "method",
    "text": "CalcFactors(x::NamedArrays.NamedArray)\n\nBerechnet die noch fehlenden Faktoren für die zu lösende Ungleichung.\n\n\n\n\n\n"
},

{
    "location": "#NuVe.addUserConstraints-Tuple{JuMP.Model,Array{JuMP.VariableRef,1},Array{Constraint,1}}",
    "page": "NuVe.jl Dokumentation",
    "title": "NuVe.addUserConstraints",
    "category": "method",
    "text": "addUserConstraints(x::Array{VariableRef,1}, c::Array{Constraint,1})\n\nFügt die vom Nutzer festgelegten Randbedingungen dem Modell hinzu.\n\n\n\n\n\n"
},

{
    "location": "#NuVe.decayCorrection-Tuple{Settings,DataFrames.DataFrame,Array{Int64,1}}",
    "page": "NuVe.jl Dokumentation",
    "title": "NuVe.decayCorrection",
    "category": "method",
    "text": "decayCorrection()\n\nDiese Funktion gibt die zerfallskorrigierte Eingangsgröße der Proben eines gewählten Nuklidvektors im bei Settings angegeben Zeitraum zurück.\n\n\n\n\n\n"
},

{
    "location": "#NuVe.df2namedarray-Tuple{DataFrames.DataFrame,String,String}",
    "page": "NuVe.jl Dokumentation",
    "title": "NuVe.df2namedarray",
    "category": "method",
    "text": "df2namedarray(x::DataFrame, rowname::String, columnname::String)\n\nDiese Funktion wandelt einen DataFrame in ein Array{Float64, 2} um. Potentiell fehlende Werte werden durch 0 ersetzt.\n\n\n\n\n\n"
},

{
    "location": "#NuVe.getInterval-Tuple{Settings}",
    "page": "NuVe.jl Dokumentation",
    "title": "NuVe.getInterval",
    "category": "method",
    "text": "getInterval()\n\nMacht aus den Einstellungen (Settings) für Anfangs- und Endjahr ein Array, welches zusätzlich jedes Jahr dazwischen enthält.\n\n\n\n\n\n"
},

{
    "location": "#NuVe.getSampleFromSource-Tuple{Symbol}",
    "page": "NuVe.jl Dokumentation",
    "title": "NuVe.getSampleFromSource",
    "category": "method",
    "text": "getSampleFromSource(x::Symbol)\n\nRuft alle vorhanden Proben zu einem Nuklidvektor ab.\n\n\n\n\n\n"
},

{
    "location": "#NuVe.nuclideParts-Tuple{NamedArrays.NamedArray}",
    "page": "NuVe.jl Dokumentation",
    "title": "NuVe.nuclideParts",
    "category": "method",
    "text": "nuclideParts(x::NamedArrays.NamedArray)\n\nGibt ein NamedArray mit den Nuklidanteilen wieder. Die Summe aller Nuklide über jeder Probe ergibt 1.\n\n\n\n\n\n"
},

{
    "location": "#NuVe.setObjectives-Tuple{Settings,JuMP.Model,Array{JuMP.VariableRef,1},NamedArrays.NamedArray,Array{Constraint,1}}",
    "page": "NuVe.jl Dokumentation",
    "title": "NuVe.setObjectives",
    "category": "method",
    "text": "setObjectives(x::Array{VariableRef,1}, parts::NamedArrays.NamedArray, c::Array{Constraint,1})\n\nLegt das Optimierungsziel des Modells aufgrund der Einstellungen (Settings) fest.\n\n\n\n\n\n"
},

{
    "location": "#NuVe.df2array-Tuple{DataFrames.DataFrame}",
    "page": "NuVe.jl Dokumentation",
    "title": "NuVe.df2array",
    "category": "method",
    "text": "df2array(x::DataFrame)\n\nWandelt ein DataFrame in ein Array{Any,2} um.\n\n\n\n\n\n"
},

{
    "location": "#NuVe.diffDays-Tuple{Settings,Array{Dates.Date,1}}",
    "page": "NuVe.jl Dokumentation",
    "title": "NuVe.diffDays",
    "category": "method",
    "text": "diffDays(sample_date::Array{Date,1})\ndiffDays(sample_date::Array{Date,1}, year::Int64)\ndiffDays(sample_date::Array, year::Array{Int64, 1})\ndiffDays(sample_date::Date)\n\nGibt die Anzahl an Tagen von der Probenahme von allen Proben eines Nuklidvektors und einem Referenzdatum an. Das Jahr und der Referenzmonat bzw. -tag werden aus den Einstellungen bezogen (Settings) oder das Jahr wird separat angegeben.\n\n\n\n\n\n"
},

{
    "location": "#NuVe.getNuclideTypes-Tuple{String}",
    "page": "NuVe.jl Dokumentation",
    "title": "NuVe.getNuclideTypes",
    "category": "method",
    "text": "getNuclideTypes(s::String)\n\nGibt alle Nuklide eines bestimmten Strahlungstypes (α, β oder γ) zurück.\n\n\n\n\n\n"
},

{
    "location": "#NuVe.getNuclidesFromConstraint-Tuple{Array{Constraint,1}}",
    "page": "NuVe.jl Dokumentation",
    "title": "NuVe.getNuclidesFromConstraint",
    "category": "method",
    "text": "getNuclidesFromConstraint(x::Array{Constraint,1})\n\nGibt alle Nuklide zurück, welche in sich in einem Array von Constraints befinden.\n\n\n\n\n\n"
},

{
    "location": "#NuVe.getSampleDate-Tuple{Symbol}",
    "page": "NuVe.jl Dokumentation",
    "title": "NuVe.getSampleDate",
    "category": "method",
    "text": "getSampleDate(x::Symbol)\n\nRuft das Probenahmedatum bzw. Referenzdatum zu allen Proben eines Nuklidvektors ab.\n\n\n\n\n\n"
},

{
    "location": "#NuVe.getSampleInfo-Tuple{String,Symbol}",
    "page": "NuVe.jl Dokumentation",
    "title": "NuVe.getSampleInfo",
    "category": "method",
    "text": "getSampleInfo(x::String, nv::Symbol)\n\nFragt zu einem gegebenen Nuklidvektor weitere Informationen ab (z. B. \"date\" oder \"source\" (Herkunftsort))\n\n\n\n\n\n"
},

{
    "location": "#NuVe.getWeightsFromConstraint-Tuple{Array{Constraint,1}}",
    "page": "NuVe.jl Dokumentation",
    "title": "NuVe.getWeightsFromConstraint",
    "category": "method",
    "text": "getWeightsFromConstraint(x::Array{Constraint,1})\n\nGibt alle Wichtungen der Nuklide zurück, welche in sich in einem Array von Constraints befinden. Diese Funktion wird beispielsweise benötigt, wenn auf die Repräsentativität der Proben optimiert werden soll. Hierbei wird die Abweichung der Nuklide des Nuklidvektors gegenüber dem Mittelwert der Nuklide der Proben minimiert.\n\n\n\n\n\n"
},

{
    "location": "#NuVe.nvdb-Tuple{}",
    "page": "NuVe.jl Dokumentation",
    "title": "NuVe.nvdb",
    "category": "method",
    "text": "Datenbank mit allen Nuklidvektoren, Proben, Halbwertszeiten und Freigabewerten\n\n\n\n\n\n"
},

{
    "location": "#NuVe.readDb-Tuple{String,Array{String,1}}",
    "page": "NuVe.jl Dokumentation",
    "title": "NuVe.readDb",
    "category": "method",
    "text": "readDb(s::String, arg::Array{String,1})\n\nGibt die angegebene Tabelle mit den angegebenen Spalten als DataFrame zurück.\n\n\n\n\n\n"
},

{
    "location": "#NuVe.readDb-Tuple{String}",
    "page": "NuVe.jl Dokumentation",
    "title": "NuVe.readDb",
    "category": "method",
    "text": "readDb(s::String)\n\nGibt die angegebene Tabelle vollständig als DataFrame zurück.\n\n\n\n\n\n"
},

{
    "location": "#NuVe.removeMissing-Tuple{DataFrames.DataFrame}",
    "page": "NuVe.jl Dokumentation",
    "title": "NuVe.removeMissing",
    "category": "method",
    "text": " removeMissing(x::DataFrame)\n\nErsetzt in einem DataFrame alle missing durch 0.\n\n\n\n\n\n"
},

{
    "location": "#NuVe.travec-Tuple{Array}",
    "page": "NuVe.jl Dokumentation",
    "title": "NuVe.travec",
    "category": "method",
    "text": "travec(x::Array)\n\nTransponiert einen Vektor (n × 1) zu (1 × n).\n\n\n\n\n\n"
},

{
    "location": "#Funktionen-1",
    "page": "NuVe.jl Dokumentation",
    "title": "Funktionen",
    "category": "section",
    "text": "Modules = [NuVe]\nOrder   = [:function]"
},

{
    "location": "#NuVe.Constraint",
    "page": "NuVe.jl Dokumentation",
    "title": "NuVe.Constraint",
    "category": "type",
    "text": "Dieser Type beinhaltet die zusätzlichen Bedingungen zur Berechnung des Nuklidvektors. Dazu gehören das einzuschränkende Nuklid, das Relationszeichen, die Grenze und eine Wichtung.\n\n\n\n\n\n"
},

{
    "location": "#NuVe.RefDate",
    "page": "NuVe.jl Dokumentation",
    "title": "NuVe.RefDate",
    "category": "type",
    "text": "Dieser Type beinhaltet die Angabe für den Referenztag und -monat für die Zerfallskorrektur zu einem bestimmten Jahr\n\n\n\n\n\n"
},

{
    "location": "#NuVe.Settings",
    "page": "NuVe.jl Dokumentation",
    "title": "NuVe.Settings",
    "category": "type",
    "text": "In diesem Type sind grundlegenden Einstellungen gespeichert. Dazu gehören der Name des Nuklidvektors, der Berechnungszeitraum, das Optimierungsziel, die zu berücksichtigen Messgeräte, ein möglicher Schwellenwert, das Referenzdatum RefDate (Tag und Monat) für die Zerfallskorrektur und die zu berücksichtigenden Freigabepfade für die jeweilligen Messverfahren.\n\n\n\n\n\n"
},

{
    "location": "#Typen-1",
    "page": "NuVe.jl Dokumentation",
    "title": "Typen",
    "category": "section",
    "text": "Modules = [NuVe]\nOrder   = [:type]"
},

{
    "location": "#Index-1",
    "page": "NuVe.jl Dokumentation",
    "title": "Index",
    "category": "section",
    "text": ""
},

]}
