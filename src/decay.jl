using Dates

"""
	getSampleDate(x::Symbol)

Ruft das Probenahmedatum bzw. Referenzdatum zu allen Proben eines Nuklidvektors ab.
"""
function getSampleDate(nv::Symbol)
	Date.(getSampleInfo("date", nv)[1], "dd.mm.yyyy")
end

function getRefDate(x::RefDate)
	Dates.monthday(Dates.DateTime(x.date, Dates.DateFormat(x.format)))
end

"""
	diffDays(sample_date::Array{Date,1})
	diffDays(sample_date::Array{Date,1}, year::Int64)
	diffDays(sample_date::Array, year::Array{Int64, 1})
	diffDays(sample_date::Date)

Gibt die Anzahl an Tagen von der Probenahme von allen Proben eines Nuklidvektors
und einem Referenzdatum an. Das Jahr und der Referenzmonat bzw. -tag werden
aus den Einstellungen bezogen ([`Settings`](@ref)) oder das Jahr wird separat
angegeben.
"""
function diffDays(s::Settings, sample_date::Array{Date,1})
	(ref_month, ref_day) = Dates.monthday(Dates.DateTime(s.refDate.date, Dates.DateFormat(s.refDate.format)))
	([Date(s.year[1], ref_month, ref_day) : Dates.Year(1) : Date(s.year[end], ref_month, ref_day);] |> travec) .- sample_date
end

function diffDays(s::Settings, sample_date::Array{Date,1}, year::Int64)
	(ref_month, ref_day) = Dates.monthday(Dates.DateTime(s.refDate.date, Dates.DateFormat(s.refDate.format)))
	Date(year, ref_month, ref_day) .- sample_date
end

function diffDays(sample_date::Date)
	diffDays([sample_date])
end

function diffDays(s::Settings, sample_date::Array{Date,1}, year::Array{Int64, 1})
	(ref_month, ref_day) = Dates.monthday(Dates.DateTime(s.refDate.date, Dates.DateFormat(s.refDate.format)))
	([Date(year[1], ref_month, ref_day) : Dates.Year(1) : Date(year[end], ref_month, ref_day);] |> travec) .- sample_date
end


"""
	getInterval()

Macht aus den Einstellungen ([`Settings`](@ref)) für Anfangs- und Endjahr ein Array, welches
zusätzlich jedes Jahr dazwischen enthält.
"""
function getInterval(s::Settings)
	[s.year[1]:s.year[2];]
end

"""
	decayCorrection()

Diese Funktion gibt die zerfallskorrigierte Eingangsgröße der Proben eines
gewählten Nuklidvektors im bei [`Settings`](@ref) angegeben Zeitraum zurück.
"""
function decayCorrection(s::Settings, sample::DataFrame, year::Array{Int64, 1})
	sample_array = df2array(sample[Symbol.(nu_names)])
	diff_days = map(x -> x.value, diffDays(s, sample.date, year))
	hl_array = convert(Array{Float64}, hl)

	sample_decay = Dict()
	for (index, i) in enumerate(year)
		push!(sample_decay, string(i) => DataFrame([sample.s_id sample_array .* 2 .^ (-diff_days[:,index] ./ hl_array)], deleteat!(names(sample), 2) ))

		"Zerfallskorrektur für Am-241 aus Nachbildung durch Pu-241"
		sample_decay[string(i)].Am241 = coalesce.(sample_decay[string(i)].Am241, 0)
		sample_decay[string(i)].Am241 .+= coalesce.(sample.Pu241, 0) .* hl.Pu241[1] / (hl.Pu241[1] - hl.Am241[1]) .* (2 .^ (-diff_days[:,index] / hl.Pu241[1]) - 2 .^ (-diff_days[:,index] / hl.Am241[1]) )
	end

	return sample_decay
end
