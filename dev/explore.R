# =============================================================================
# Script di esplorazione interattiva del package golDatasets
# -----------------------------------------------------------------------------
# NON e' un test automatizzato. Va eseguito riga per riga o sezione per
# sezione in una sessione R / RStudio, per ispezionare i tre dataset, le
# funzioni di estrazione, gli indicatori COB e la visualizzazione con
# rotture metodologiche.
#
# Prerequisiti:
#   - Stare nella radice del repository (`gol_datasets/`)
#   - Avere data.table, ggplot2 installati (renv: installati nel project)
#   - Per il caricamento da sorgente: devtools (opzionale)
# =============================================================================

# 1. Setup -------------------------------------------------------------------

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})

# Caricamento del package. Scegli UNA delle due modalita':
# (a) dal sorgente nel repo (sviluppo)
devtools::load_all(".")
# (b) installato (utente finale)
# library(golDatasets)

# 2. Panoramica dei tre dataset esposti --------------------------------------

# Informazioni di alto livello su ciascun .rda
data(package = "golDatasets")$results[, c("Item", "Title")]

# Dimensioni e tipo
sapply(
  list(
    gol_inapp_mensile = gol_inapp_mensile,
    gol_storico_regionale = gol_storico_regionale,
    cob_regionale_trimestrale = cob_regionale_trimestrale,
    gol_method_ruptures = gol_method_ruptures,
    gol_rescan_recommendations = gol_rescan_recommendations
  ),
  function(x) c(nrow = nrow(x), ncol = ncol(x))
)

# Schema rapido
str(gol_inapp_mensile, max.level = 1)
str(gol_storico_regionale, max.level = 1)
str(cob_regionale_trimestrale, max.level = 1)


# 3. INAPP Focus GOL: copertura e contenuto ----------------------------------

# Date disponibili
sort(unique(gol_inapp_mensile$data_riferimento))

# Tavole e variabili
gol_inapp_mensile[, .N, by = .(tavola, variabile)][order(tavola, variabile)]

# Etichette regionali (canoniche)
sort(unique(gol_inapp_mensile$etichetta))

# Esempio: presi in carico totali (tav 2.2) per regione, ultima data
ultima <- max(gol_inapp_mensile$data_riferimento)
gol_inapp_mensile[
  tavola == 2.2 &
    data_riferimento == ultima &
    dimensione == "regione" &
    variabile == "presi_in_carico" &
    percorso == "",
  .(regione = etichetta, presi_in_carico = valore)
][order(-presi_in_carico)]


# 4. gol_extract_series(): estrazione strutturata ----------------------------

# 4.1 Serie singola - inferenza automatica della tavola
s_er <- gol_extract_series(
  variabile = "occupati_totale",
  etichetta = "Emilia-Romagna"
)
s_er # 12 punti (Jun 2024 + 11 mesi 2025)

# 4.2 Multi-regione
s_multi <- gol_extract_series(
  variabile = "raggiunti",
  etichetta = c("Lombardia", "Lazio", "Campania", "Sicilia")
)
s_multi[, .N, by = regione]

# 4.3 Override esplicito della tavola (per variabili meno comuni)
s_perc <- gol_extract_series(
  variabile = "1_reinserimento_lavorativo_ass",
  etichetta = c("Emilia-Romagna", "Lombardia"),
  tavola = 1.2
)
head(s_perc)


# 5. plot_timeline() con rotture annotate ------------------------------------

# 5.1 Singola regione + rotture 2025
plot_timeline(
  s_er,
  ruptures = gol_method_ruptures,
  title = "Occupati GOL - Emilia-Romagna",
  y_label = "N. occupati"
)

# 5.2 Multi-regione, palette CVD-safe Okabe-Ito
plot_timeline(
  s_multi,
  group = "regione",
  ruptures = gol_method_ruptures,
  title = "Raggiunti GOL per regione"
)

# 5.3 Multi-percorso (loop di gol_extract_series + rbindlist)
percorsi <- c(
  "1_reinserimento_lavorativo_ass",
  "2_aggiornamento_upskilling_ass",
  "3_riqualificazione_reskilling_ass",
  "4_lavoro_inclusione_ass",
  "5_ricollocazione_collettiva_ass"
)
serie_percorsi <- rbindlist(lapply(percorsi, function(v) {
  s <- gol_extract_series(variabile = v, etichetta = "Lombardia", tavola = 1.2)
  s[, percorso := sub("_ass$", "", v)]
  s[]
}))
plot_timeline(
  serie_percorsi,
  group = "percorso",
  ruptures = gol_method_ruptures,
  title = "Presi in carico per percorso - Lombardia"
)


# 6. Storico GOL 2022-2025: qualita' e provenienza ---------------------------

# 6.1 Distribuzione di severita' delle estrazioni
q <- gol_storico_quality()
q[, .N, by = severity][order(severity)]

# 6.2 File problematici (rescan recommendations)
gol_rescan_recommendations

# 6.3 Tracciatura della fonte (originale vs rimpiazzata vs parziale)
gol_storico_regionale[, .N, by = rescan_severity]

# 6.4 Verifica del rimpiazzo INAPP A1/1.2: 22 anchor per file (era 1-3)
gol_storico_regionale[
  ente == "INAPP" & tema == "A1" & caption_num == "1.2",
  .(n_anchor = uniqueN(anchor), n_col = uniqueN(col_index)),
  by = file
][order(file)]


# 7. COB INPS: indicatori derivati -------------------------------------------

ind <- cob_compute_indicators()
str(ind, max.level = 1)

# 7.1 Saldo netto trimestrale top 5 regioni 2025
ind[anno == 2025 & trimestre == 3, .(regione, saldo_rapporti)][order(
  -saldo_rapporti
)][1:5]

# 7.2 Indice di rotazione contrattuale (rapporti / lavoratori distinti)
ind[
  regione == "Emilia-Romagna" & anno >= 2023,
  .(anno, trimestre, rotation_avviamenti, rotation_cessazioni)
]

# 7.3 Variazione YoY degli avviamenti
ind[
  regione == "Lombardia" & anno >= 2018,
  .(anno, trimestre, yoy_avviamenti = round(yoy_avviamenti, 3))
]


# 8. Plot COB ----------------------------------------------------------------

# 8.1 Saldo netto multi-regione 2017-2025
plot_timeline(
  ind[
    regione %in% c("Emilia-Romagna", "Lombardia", "Veneto"),
    .(data = data_inizio_trimestre, valore = saldo_rapporti, regione)
  ],
  group = "regione",
  date_breaks = "1 year",
  title = "Saldo netto avviamenti - cessazioni",
  y_label = "Saldo trimestrale (rapporti)"
)

# 8.2 Confronto rotazione Nord vs Sud
plot_timeline(
  ind[
    regione %in% c("Lombardia", "Calabria"),
    .(data = data_inizio_trimestre, valore = rotation_avviamenti, regione)
  ],
  group = "regione",
  date_breaks = "1 year",
  title = "Indice di rotazione (rapporti / lavoratori)",
  y_label = "Rapporti per lavoratore"
)


# 9. Merge GOL + COB sulla chiave regionale ----------------------------------

# Stesse 21 etichette canoniche: il join e' diretto.
occupati_gol <- gol_extract_series(variabile = "occupati_totale")[
  data == max(data),
  .(regione, occupati_gol = valore)
]
cob_2025 <- ind[
  anno == 2025,
  .(avviamenti_2025 = sum(avviamenti_rapporti, na.rm = TRUE)),
  by = regione
]
panel <- merge(occupati_gol, cob_2025, by = "regione")
panel[, quota := occupati_gol / avviamenti_2025]
panel[order(-quota)]

# 10. Help e documentazione --------------------------------------------------

# Riferimenti rapidi
# ?gol_inapp_mensile
# ?gol_storico_regionale
# ?cob_regionale_trimestrale
# ?gol_method_ruptures
# ?gol_rescan_recommendations
# ?gol_extract_series
# ?cob_compute_indicators
# ?gol_storico_quality
# ?plot_timeline
# ?build_gol_datasets

# Vignette
vignette("merge-gol-cob", package = "golDatasets")
