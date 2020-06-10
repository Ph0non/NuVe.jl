# statistic parameter
perz = 0.95;
sample_size = 150_000;

# Distributions
# Einflussgröße = Abgeschnitten( Verteilung( µ. σ ), min, max)
sample_Einzelmasse = rand(Einzelmasse, sample_size);
sample_Ausschöpfung = rand(Ausschöpfung, sample_size);
sample_FGW_nach_FMA = sample_Ausschöpfung ./ max(sample_Einzelmasse ./ Mittelungsmasse, ones(sample_size))
sample_Vermischung = rand(Vermischung, sample_size);
sample_FGW_bei_Transport = sample_FGW_nach_FMA ./ sample_Vermischung
sample_Masse_Transport = rand(Masse_Transport, sample_size);
sample_Masse_Ofen = rand(Masse_Ofen, sample_size);
sample_Anteil_Schrott = rand(Anteil_Schrott, sample_size);

sample_Masse_Schrott_ges = sample_Masse_Ofen .* sample_Anteil_Schrott
sample_Masse_Schrott_KGR = min(sample_Masse_Transport, sample_Masse_Schrott_ges)
sample_Anzahl_Öfen = ceil.(sample_Masse_Transport ./ sample_Masse_Schrott_ges)
sample_Vermischung_Ofen = min.( sample_Masse_Schrott_KGR ./ sample_Masse_Ofen, 1 )
sample_Vermischung_Ofen_Sportplatz = min.(sample_Vermischung_Ofen, 0.1)

sample_Anteil_Schlacke = rand(Anteil_Schlacke, sample_size);
sample_Anteil_Staub = rand(Anteil_Staub, sample_size);

# Szenarien
# Produktnutzung gewerblich
sample_Produktmasse_gewerblich = rand(Produktmasse_gewerblich, sample_size);
sample_Abstand_gewerblich = rand(Abstand_gewerblich, sample_size);
sample_Expositionszeit_gewerblich = rand(Expositionszeit_gewerblich, sample_size);

# Produktnutzung Haushalt
sample_Produktmasse_Haushalt = rand(Produktmasse_Haushalt, sample_size);
sample_Abstand_Haushalt = rand(Abstand_Haushalt, sample_size);
sample_Expositionszeit_Haushalt = rand(Expositionszeit_Haushalt, sample_size);

# Sportplatz
sample_Staubkonzentration_Sportplatz = rand(Staubkonzentration_Sportplatz, sample_size);
sample_Expositionszeit_Sportplatz = rand(Expositionszeit_Sportplatz, sample_size);

# Kleinkind
sample_Ingestion_Kleinkind = rand(Ingestion_Kleinkind, sample_size);
sample_Schlacke_Kleinkind = rand(Schlacke_Kleinkind, sample_size);

# Transport
sample_Transportzeit = rand(Transportzeit, sample_size);

# Herstellung Metall
sample_Anteil_KGR_Chargen = rand(Anteil_KGR_Chargen, sample_size);
sample_Ingestion_Staub_Metall = rand(Ingestion_Staub_Metall, sample_size);
sample_Staubkonzentration_Metall = rand(Staubkonzentration_Metall, sample_size);
