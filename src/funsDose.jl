function doseNucSum(dos::Array{Float64,2})
    NamedArray( sum(dos, dims=2), ([1:sample_size;], ["Dosis µSv/a"]))
end

function func_Konz_Schlacke()
    q = @. akt_bei_transport * fraktionierung["Fraktionierung Schlacke", r[nv_x .> 0]]' * sample_Vermischung_Ofen
    NamedArray( q ./ sample_Anteil_Schlacke,  ([1:sample_size;], r[nv_x .> 0]))
end

function func_Konz_Staub()
    q = @. akt_bei_transport * fraktionierung["Fraktionierung Staub", r[nv_x .> 0]]' * sample_Vermischung_Ofen
    NamedArray( q ./ sample_Anteil_Staub,  ([1:sample_size;], r[nv_x .> 0]))
end

function func_Konz_Sportplatz()
    q = @. akt_bei_transport * fraktionierung["Fraktionierung Schlacke", r[nv_x .> 0]]' * sample_Vermischung_Ofen_Sportplatz
    NamedArray( q ./ sample_Anteil_Schlacke,  ([1:sample_size;], r[nv_x .> 0]))
end

function func_Dos_Produkt_gewerblich()
    @. dosfac_geo["Produkt", r[nv_x .> 0]].array' * Konz_Produkt *  sample_Produktmasse_gewerblich * 1E3 * sample_Expositionszeit_gewerblich / (sample_Abstand_gewerblich ^ 2) * 1E6
end

function func_Dos_Produkt_Haushalt()
    @. dosfac_geo["Produkt", r[nv_x .> 0]].array' * Konz_Produkt * sample_Produktmasse_Haushalt * 1E3 * sample_Expositionszeit_Haushalt / (sample_Abstand_Haushalt ^ 2) * 1E6
end

function func_Dos_Sportplatz()
    @. dosfac_ink["Inh. Erw.", r[nv_x .> 0]]' * Konz_Schlacke_Sport * sample_Staubkonzentration_Sportplatz * Atemrate_Sportplatz * sample_Expositionszeit_Sportplatz * 1E6
end

function func_Dos_Kleinkind()
    @. dosfac_ink["Ing. 1-2a", r[nv_x .> 0]]' * Konz_Schlacke * 1E6 * sample_Ingestion_Kleinkind * sample_Schlacke_Kleinkind
end

function func_Dos_Transport()
    @. dosfac_geo["Transport", r[nv_x .> 0]]' * akt_bei_transport * sample_Transportzeit * 1E6
end

function func_Dos_Ingestion()
    @. dosfac_ink["Ing. Arb.", r[nv_x .> 0]]' * Konz_Staub * 1E6 * sample_Anteil_KGR_Chargen * sample_Ingestion_Staub_Metall
end

function func_Dos_Inhalation()
    @. dosfac_ink["Inh. Arb.", r[nv_x .> 0]]' * Konz_Staub * 1E6 * sample_Anteil_KGR_Chargen * Arbeitszeit * sample_Staubkonzentration_Metall * Atemrate_Metall
end

function func_Dos_Gamma_Metall()
    @. dosfac_geo["Ofen", r[nv_x .> 0]]' * akt_bei_transport * sample_Vermischung_Ofen * 1E6 * sample_Anteil_KGR_Chargen * Arbeitszeit * Dichte_Eisen
end

function checkDose()
    global anteil_fgw = 1/sum(nv_x[nv_x .> 0] ./ fgw_[1,r[nv_x .> 0]].array) * nv_x[nv_x .> 0]
    global akt_bei_transport = NamedArray( kron(anteil_fgw', sample_FGW_bei_Transport), ([1:sample_size;], r[nv_x .> 0] ))
    global Konz_Produkt = @. akt_bei_transport * fraktionierung["Fraktionierung Produkt",r[nv_x .> 0]]' * sample_Vermischung_Ofen

    global Konz_Schlacke = func_Konz_Schlacke()

    global Konz_Staub = func_Konz_Staub()

    global Konz_Schlacke_Sport = func_Konz_Sportplatz()

    # Szenario Produktnutzung gewerblich
    global Dos_Produkt_gewerblich = func_Dos_Produkt_gewerblich() |> doseNucSum

    # Szenario Produktnutzung Haushalt
    global Dos_Produkt_Haushalt = func_Dos_Produkt_Haushalt() |> doseNucSum

    # Szenario Nebenproduktnutzung Sportplatz
    global Dos_Sportplatz = func_Dos_Sportplatz() |> doseNucSum

    # Szenario Nebenproduktnutzung spielendes Kleinkind
    global Dos_Kleinkind = func_Dos_Kleinkind() |> doseNucSum

    # Szenario Transport
    global Dos_Transport = func_Dos_Transport() |> doseNucSum

    # Szenario Herstellung Metall
    # Dosis Ingestion
    global Dos_Ingestion = func_Dos_Ingestion() |> doseNucSum

    # Dosis Inhalation
    global Dos_Inhalation = func_Dos_Inhalation() |> doseNucSum

    # Dosis Gamma Metall
    global Dos_Gamma_Metall = func_Dos_Gamma_Metall() |> doseNucSum
    global Dos_Herstellung_Metall = @. Dos_Ingestion + Dos_Inhalation + Dos_Gamma_Metall

    return max.(Dos_Produkt_gewerblich, Dos_Produkt_Haushalt, Dos_Sportplatz, Dos_Kleinkind, Dos_Transport, Dos_Herstellung_Metall)
end
