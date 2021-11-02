# Distributions
# Einflussgröße = Abgeschnitten( Verteilung( µ, σ ), min, max)
const Einzelmasse = truncated(Normal(200, 300), 5, 300)
const Ausschöpfung = truncated(Normal(0.3, 0.1), 0.05, 1)
const Vermischung = truncated(Normal(1.001, 0.001), 1.0, 1.002)
const Masse_Transport = truncated(Normal(20, 20), 5, 40)
const Masse_Ofen = truncated(Normal(50, 100), 1, 500)
const Anteil_Schrott = truncated(Normal(0.6, 0.6), 0.2, 1)
const Anteil_Schlacke = truncated(Normal(0.05, 0.05), 0.01, 0.1)
const Anteil_Staub = truncated(Normal(0.005, 0.005), 0.001, 0.01)
const Mittelungsmasse = 300

# Szenarien
# Produktnutzung gewerblich
const Abstand_gewerblich = truncated(Normal(1, 1), 1, 2)
const Produktmasse_gewerblich = truncated(Normal(200, 200), 1, 500)
const Expositionszeit_gewerblich = truncated(Normal(1500, 500), 100, 2000)

# Produktnutzung Haushalt
const Produktmasse_Haushalt = truncated(Normal(30, 30), 1, 50)
const Abstand_Haushalt = truncated(Normal(1, 1), 1, 2)
const Expositionszeit_Haushalt = truncated(Normal(3000, 3000), 100, 8760)

# Sportplatz
const Staubkonzentration_Sportplatz = truncated(Normal(0.002, 0.001), 0.001, 0.004)
const Expositionszeit_Sportplatz = truncated(Normal(400, 400), 50, 1000)
const Atemrate_Sportplatz = 1.7;

# Kleinkind
const Ingestion_Kleinkind = truncated(Normal(50, 50), 10, 100)
const Schlacke_Kleinkind = truncated(Normal(0.2, 0.1), 0.1, 0.3)

# Transport
const Transportzeit = truncated(Normal(120, 100), 50, 500)

# Herstellung Metall
const Anteil_KGR_Chargen = truncated(Normal(0.1, 0.1), 0.05, 0.25)
const Ingestion_Staub_Metall = truncated(Normal(20, 10), 10, 30)
const Staubkonzentration_Metall = truncated(Normal(0.0005, 0.001), 0.0001, 0.002)
const Atemrate_Metall = 1.2
const Dichte_Eisen = 7.8
const Arbeitszeit = 1800
