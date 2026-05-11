# =============================================================================
# Script di esplorazione interattiva del package golDatasets (v0.8.0)
# -----------------------------------------------------------------------------
# NON e' un test automatizzato. Va eseguito riga per riga in RStudio:
# Ctrl/Cmd+Enter su ogni riga, oppure selezione e Ctrl/Cmd+Enter.
#
# Sezioni:
#   1. Setup e caricamento package
#   2. Panoramica dei 6 dataset esposti + 3 metadati
#   3. Tre dataset di storia lunga 2022-2025
#   4. Grafici: presi in carico 2022-2025
#   5. Grafici: caratteristiche dei beneficiari
#   6. Grafici: esiti del programma (occupazione, LEP, politiche)
#   7. Vulnerabilita' e target PNRR (v0.7/0.8)
#   8. COB INPS: serie del mercato del lavoro
#   9. Merge cross-dataset GOL + COB
#  10. Diagnostica qualita' e rescanning
# =============================================================================

# 1. Setup -------------------------------------------------------------------

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})

# Caricamento package dal sorgente (sviluppo). Per utente finale:
# library(golDatasets)
devtools::load_all(".")


# 2. Panoramica dei dataset --------------------------------------------------

data(package = "golDatasets")$results[, c("Item", "Title")]

# Dimensioni dei dataset esposti
sapply(
  list(
    gol_inapp_mensile = gol_inapp_mensile,
    gol_storico_regionale = gol_storico_regionale,
    gol_storia_volumi = gol_storia_volumi,
    gol_storia_caratteristiche = gol_storia_caratteristiche,
    gol_storia_esiti = gol_storia_esiti,
    cob_regionale_trimestrale = cob_regionale_trimestrale,
    gol_method_ruptures = gol_method_ruptures,
    gol_rescan_recommendations = gol_rescan_recommendations,
    storico_decoder = storico_decoder
  ),
  function(x) c(nrow = nrow(x), ncol = ncol(x))
)


# 3. Storia lunga 2022-2025: copertura ---------------------------------------

# Date distinte coperte
gol_storia_volumi[, uniqueN(data_riferimento)]
range(gol_storia_volumi$data_riferimento)

# Variabili presenti per ciascun dataset di storia
gol_storia_volumi[, .N, by = variabile][order(-N)]
gol_storia_caratteristiche[, .N, by = .(caratteristica, modalita)][
  order(caratteristica, -N)
]
gol_storia_esiti[, .N, by = variabile][order(-N)]

# Verifica delle 3 rotture metodologiche
gol_method_ruptures


# 4. Grafici - Presi in carico ------------------------------------------------

# 4.1 Italia, serie completa 2022-2025
serie_pic_italia <- gol_storia_volumi_series(
  variabile = "presi_in_carico_totale",
  regione = "Totale"
)
plot_timeline(
  serie_pic_italia,
  ruptures = gol_method_ruptures,
  title = "Presi in carico GOL - Italia, 2022-2025",
  subtitle = "Integrazione storico ANPAL/MLPS + INAPP mensile",
  y_label = "N. presi in carico"
)

# 4.2 Confronto multi-regione (4 grandi regioni)
serie_pic_multi <- gol_storia_volumi_series(
  variabile = "presi_in_carico_totale",
  regione = c("Lombardia", "Lazio", "Campania", "Sicilia")
)
plot_timeline(
  serie_pic_multi,
  group = "regione",
  ruptures = gol_method_ruptures,
  title = "Presi in carico GOL - 4 regioni a confronto",
  y_label = "N. presi in carico"
)

# 4.3 Per percorso GOL (5 percorsi, decomposizione)
percorsi <- c(
  "1_reinserimento_lavorativo",
  "2_aggiornamento_upskilling",
  "3_riqualificazione_reskilling",
  "4_lavoro_inclusione",
  "5_ricollocazione_collettiva"
)
serie_percorsi <- gol_storia_volumi_series(
  variabile = "presi_in_carico_ass",
  regione = "Totale",
  percorso = percorsi
)
plot_timeline(
  serie_percorsi,
  group = "percorso",
  ruptures = gol_method_ruptures,
  title = "Presi in carico per percorso GOL - Italia",
  y_label = "N. presi in carico"
)


# 5. Grafici - Caratteristiche dei beneficiari -------------------------------

# 5.1 Composizione di genere (% riga)
serie_genere <- gol_storia_caratteristiche_series(
  caratteristica = "genere",
  modalita = c("Maschi", "Femmine"),
  regione = "Totale"
)
plot_timeline(
  serie_genere,
  group = "modalita",
  ruptures = gol_method_ruptures,
  title = "Composizione di genere dei beneficiari GOL",
  subtitle = "Italia, % presi in carico"
)

# 5.2 Classi di eta'
serie_eta <- gol_storia_caratteristiche_series(
  caratteristica = "classe_eta",
  modalita = c("15-29", "30-54", "55+"),
  regione = "Totale"
)
plot_timeline(
  serie_eta,
  group = "modalita",
  ruptures = gol_method_ruptures,
  title = "Composizione per classe di eta'",
  subtitle = "Italia, % presi in carico"
)

# 5.3 Cittadinanza
serie_citt <- gol_storia_caratteristiche_series(
  caratteristica = "cittadinanza",
  modalita = c("Italiana", "Straniera"),
  regione = "Totale"
)
plot_timeline(
  serie_citt,
  group = "modalita",
  ruptures = gol_method_ruptures,
  title = "Composizione per cittadinanza"
)

# 5.4 Durata della disoccupazione precedente
serie_dur <- gol_storia_caratteristiche_series(
  caratteristica = "durata_disoccupazione",
  regione = "Totale"
)
plot_timeline(
  serie_dur,
  group = "modalita",
  ruptures = gol_method_ruptures,
  title = "Durata disoccupazione - quote di lungo periodo",
  y_label = "% presi in carico"
)


# 6. Grafici - Esiti del programma -------------------------------------------

# 6.1 LEP - 6 prestazioni essenziali, trend mensile 2024-2025
leps <- c("lep_e", "lep_f1", "lep_f2", "lep_h", "lep_j", "lep_o")
serie_lep <- rbindlist(lapply(leps, function(v) {
  gol_storia_esiti_series(variabile = v, regione = "Totale")[, lep := v]
}))
plot_timeline(
  serie_lep,
  group = "lep",
  ruptures = gol_method_ruptures,
  title = "Prestazioni LEP - Italia",
  y_label = "N. beneficiari LEP",
  date_breaks = "3 months"
)

# 6.2 Politiche attivate vs raggiunti (volumi vs platea)
serie_politiche <- rbindlist(list(
  gol_storia_esiti_series(variabile = "raggiunti", regione = "Totale")[,
    serie := "Raggiunti"
  ],
  gol_storia_esiti_series(variabile = "con_politica", regione = "Totale")[,
    serie := "Con politica attivata"
  ],
  gol_storia_esiti_series(variabile = "tirocinio_co", regione = "Totale")[,
    serie := "In tirocinio"
  ]
))
plot_timeline(
  serie_politiche,
  group = "serie",
  ruptures = gol_method_ruptures,
  title = "Raggiunti, con politica, tirocini - Italia"
)

# 6.3 Esiti occupazionali storici (tasso a 60gg, era ANPAL)
serie_t60 <- gol_storia_esiti_series(
  variabile = "tasso_occupati_60gg",
  regione = "Totale"
)
plot_timeline(
  serie_t60,
  title = "Tasso di occupazione a 60 giorni - Italia",
  subtitle = "Serie storica ANPAL gennaio-aprile 2023",
  y_label = "% occupati / presi in carico"
)

# 6.4 Occupazione totale 2024-2025 multi-regione
serie_occ <- gol_storia_esiti_series(
  variabile = "occupati_totale",
  regione = c("Emilia-Romagna", "Lombardia", "Campania", "Sicilia")
)
plot_timeline(
  serie_occ,
  group = "regione",
  ruptures = gol_method_ruptures,
  title = "Occupati alla data di riferimento",
  y_label = "N. occupati"
)

# 6.5 Serie mensile 2024-06 -> 2025-12 (13 punti) - metriche occupazionali
# Note: queste metriche partono dal nuovo formato MLPS/INAPP (tav 2.2) e
# non sono confrontabili con `tasso_occupati_60gg` ANPAL 2022-2023.
metriche_occ <- c(
  "occupati_pc",
  "gia_occupati_pc",
  "nuovi_occupati_pc",
  "quota_nuovi_su_occ"
)
serie_metriche <- rbindlist(lapply(metriche_occ, function(v) {
  gol_storia_esiti_series(variabile = v, regione = "Totale")[, metrica := v]
}))
plot_timeline(
  serie_metriche,
  group = "metrica",
  ruptures = gol_method_ruptures,
  title = "Esiti occupazionali GOL - Italia",
  subtitle = "Tassi % e quote, formato MLPS/INAPP 2024-06 -> 2025-12",
  y_label = "%",
  date_breaks = "2 months"
)

# 6.6 Volumi occupazionali (count) - 4 metriche complementari
volumi_occ <- c(
  "raggiunti",
  "occupati_totale",
  "gia_occupati",
  "nuovi_occupati"
)
serie_volumi_occ <- rbindlist(lapply(volumi_occ, function(v) {
  gol_storia_esiti_series(variabile = v, regione = "Totale")[, metrica := v]
}))
plot_timeline(
  serie_volumi_occ,
  group = "metrica",
  ruptures = gol_method_ruptures,
  title = "Volumi occupazionali GOL - Italia",
  subtitle = "Conteggi assoluti, 13 punti mensili",
  y_label = "N. individui",
  date_breaks = "2 months"
)

# 6.7 Formazione - 4 categorie LEP
form_vars <- c(
  "c07_form_incl_dig",
  "c11_form_no_dig",
  "c12_form_spec_dig",
  "tirocinio_co"
)
serie_form <- rbindlist(lapply(form_vars, function(v) {
  gol_storia_esiti_series(variabile = v, regione = "Totale")[, metrica := v]
}))
plot_timeline(
  serie_form,
  group = "metrica",
  ruptures = gol_method_ruptures,
  title = "Formazione e tirocini GOL - Italia",
  subtitle = "13 punti mensili 2024-06 -> 2025-12",
  y_label = "N. beneficiari",
  date_breaks = "2 months"
)


# 7. Vulnerabilita' e target PNRR (v0.7-0.8) --------------------------------

# 7.1 Target patto di servizio per Italia (numerosita' per target)
serie_target <- gol_storia_caratteristiche_series(
  caratteristica = "target_patto_servizio",
  regione = "Totale"
)
plot_timeline(
  serie_target,
  group = "modalita",
  ruptures = gol_method_ruptures,
  title = "Beneficiari con patto di servizio per target PNRR",
  subtitle = "Italia, valori assoluti",
  date_breaks = "3 months"
)

# 7.2 Vulnerabilita' - aggregato Italia (filtro percorso = totale_percorsi)
# La caratteristica "vulnerabilita" ha la dimensione `percorso` valorizzata:
# senza filtro si sovrappongono 4 percorsi per ogni modalita'.
serie_vuln_italia <- gol_storia_caratteristiche_series(
  caratteristica = "vulnerabilita",
  modalita = c("donne", "disocc_ge6mesi", "under_30", "over_55", "disabili"),
  percorso = "totale_percorsi"
)
plot_timeline(
  serie_vuln_italia,
  group = "modalita",
  ruptures = gol_method_ruptures,
  title = "Vulnerabilita' aggregata - Italia",
  subtitle = "totale percorsi GOL, sub-categorie",
  date_breaks = "2 months"
)

# 7.3 Vulnerabilita' - confronto per percorso GOL (fissata una modalita')
serie_vuln_perc <- gol_storia_caratteristiche_series(
  caratteristica = "vulnerabilita",
  modalita = "donne",
  percorso = c(
    "1_reinserimento_lavorativo",
    "4_lavoro_inclusione",
    "5_ricollocazione_collettiva"
  )
)
plot_timeline(
  serie_vuln_perc,
  group = "percorso",
  ruptures = gol_method_ruptures,
  title = "Donne in vulnerabilita' per percorso GOL",
  date_breaks = "2 months"
)


# 8. COB INPS - mercato del lavoro -------------------------------------------

ind_cob <- cob_compute_indicators()

# 8.1 Saldo netto multi-regione 2017-2025
plot_timeline(
  ind_cob[
    regione %in% c("Lombardia", "Emilia-Romagna", "Lazio", "Sicilia"),
    .(data = data_inizio_trimestre, valore = saldo_rapporti, regione)
  ],
  group = "regione",
  date_breaks = "1 year",
  title = "Saldo netto avviamenti - cessazioni (rapporti)",
  subtitle = "COB INPS, 2017-Q1 -> 2025-Q3",
  y_label = "Saldo trimestrale (rapporti)"
)

# 8.2 Indice di rotazione (rapporti / lavoratori) - Nord vs Sud
plot_timeline(
  ind_cob[
    regione %in% c("Lombardia", "Calabria"),
    .(data = data_inizio_trimestre, valore = rotation_avviamenti, regione)
  ],
  group = "regione",
  date_breaks = "1 year",
  title = "Rotazione contrattuale - rapporti per lavoratore",
  y_label = "Rapporti / lavoratore"
)

# 8.3 Variazione YoY degli avviamenti - Italia (Totale)
# Ricostruisce un aggregato sommando tutte le regioni
italia_cob <- ind_cob[,
  .(
    avviamenti = sum(avviamenti_rapporti, na.rm = TRUE)
  ),
  by = .(anno, trimestre, data = data_inizio_trimestre)
]
italia_cob[, yoy := avviamenti / shift(avviamenti, 4) - 1]
plot_timeline(
  italia_cob[!is.na(yoy), .(data, valore = yoy * 100)],
  date_breaks = "1 year",
  title = "Variazione YoY avviamenti - Italia",
  y_label = "Variazione % sullo stesso trimestre anno prec."
)


# 9. Merge GOL + COB sulla chiave regionale ----------------------------------

# Occupati GOL ultima data
occ_gol <- gol_storia_esiti_series(variabile = "occupati_totale")[
  data == max(data),
  .(regione, occupati_gol = valore)
]

# Avviamenti COB 2025
cob_2025 <- ind_cob[
  anno == 2025,
  .(avviamenti_2025 = sum(avviamenti_rapporti, na.rm = TRUE)),
  by = regione
]

panel <- merge(occ_gol, cob_2025, by = "regione")
panel[, quota := occupati_gol / avviamenti_2025]
panel[order(-quota)]


# 10. Diagnostica qualita' ---------------------------------------------------

# Severita' per (file, tema, caption_num)
q <- gol_storico_quality()
q[, .N, by = severity][order(severity)]

# Raccomandazioni di re-estrazione
gol_rescan_recommendations

# Provenienza delle righe in gol_storico_regionale
gol_storico_regionale[, .N, by = rescan_severity]

# Distribuzione di confidenza nel decoder semantico
storico_decoder[, .N, by = .(tema, confidenza)][order(tema, confidenza)]

# 11. Riferimenti rapidi (help) ----------------------------------------------

# Dataset
# ?gol_inapp_mensile
# ?gol_storia_volumi
# ?gol_storia_caratteristiche
# ?gol_storia_esiti
# ?gol_storico_regionale
# ?cob_regionale_trimestrale
# ?gol_method_ruptures
# ?gol_rescan_recommendations
# ?storico_decoder

# Funzioni
# ?gol_extract_series
# ?gol_storia_volumi_series
# ?gol_storia_caratteristiche_series
# ?gol_storia_esiti_series
# ?gol_decode_storico
# ?cob_compute_indicators
# ?gol_storico_quality
# ?plot_timeline
# ?build_gol_datasets
# ?build_inapp_focus_long

# Vignette: esempi narrativi con plot annotati
# vignette("merge-gol-cob", package = "golDatasets")
