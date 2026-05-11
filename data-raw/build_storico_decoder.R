# =============================================================================
# Scaffold del decoder semantico per gol_storico_regionale
# -----------------------------------------------------------------------------
# Per ogni (tema, caption_num, col_index, era) calcola:
#   - header_modal: stringa header_above piu' frequente
#   - caption_title_modal: titolo della tabella piu' frequente
#   - variabile: etichetta semantica auto-derivata via regex
#   - caratteristica, modalita, percorso, unita: campi normalizzati
#   - confidenza: high | medium | low
#
# Output:
#   - inst/extdata/storico_decoder.csv (editabile a mano per refinement)
#   - data/storico_decoder.rda
# =============================================================================

suppressPackageStartupMessages(library(data.table))

load("data/gol_storico_regionale.rda")
dt <- copy(gol_storico_regionale)
dt[,
  era := ifelse(
    data_riferimento < as.IDate("2025-01-01"),
    "pre_2025",
    "post_2025"
  )
]

# 1. Aggregazione per modal header --------------------------------------------

modal <- function(x) {
  if (length(x) == 0L) {
    return(NA_character_)
  }
  t <- table(x[!is.na(x) & x != ""])
  if (length(t) == 0L) {
    return(NA_character_)
  }
  names(t)[which.max(t)]
}

scaffold <- dt[,
  .(
    n_rows = .N,
    header_modal = modal(header_above),
    caption_title_modal = modal(caption_title),
    n_header_variants = uniqueN(header_above)
  ),
  by = .(tema, caption_num, col_index, era)
]

# 2. Regex per riconoscimento ------------------------------------------------

# Percorsi GOL
RX_PERCORSI <- list(
  "1_reinserimento_lavorativo" = "Reinserimento",
  "2_aggiornamento_upskilling" = "Aggiornamento|[Uu]pskilling",
  "3_riqualificazione_reskilling" = "Riqualificazione|[Rr]eskilling",
  "4_lavoro_inclusione" = "Lavoro\\s*e\\s*inclusione|inclusione",
  "5_ricollocazione_collettiva" = "Ricollocazione"
)

# Caratteristiche anagrafiche (tema B)
RX_ANAGRAFICA <- list(
  list(carat = "genere", mod = "Maschi", rx = "Maschi"),
  list(carat = "genere", mod = "Femmine", rx = "Femmine"),
  list(carat = "classe_eta", mod = "15-29", rx = "15[–—\\-]29|15-29|Giovani"),
  list(carat = "classe_eta", mod = "30-54", rx = "30[–—\\-]54|30-54"),
  list(carat = "classe_eta", mod = "55+", rx = "55\\+|55 e oltre|Anziani"),
  list(carat = "cittadinanza", mod = "Italiana", rx = "Italian[ai]"),
  list(carat = "cittadinanza", mod = "Straniera", rx = "Stranier[ai]"),
  list(
    carat = "durata_disoccupazione",
    mod = "ge_6mesi",
    rx = ">=\\s*6\\s*mesi|6 mesi"
  ),
  list(
    carat = "durata_disoccupazione",
    mod = "ge_12mesi",
    rx = ">=\\s*12\\s*mesi|12 mesi"
  )
)

classify_unita <- function(header, caption) {
  txt <- paste(header, caption, sep = " | ")
  out <- rep("count", length(txt))
  out[grepl(
    "tasso|%\\)|[Vv]alori\\s*%|incidenza|percentuale",
    txt
  )] <- "percentage"
  out
}

# 2bis. Mapping posizionale per tema B (caption 3 e 1.3/1.4) -----------------
# Lo schema di B (anagrafiche × regione) ha 12 colonne canoniche:
#   0=Maschi 1=Femmine 2=Totale_g 3=15-29 4=30-54 5=55+ 6=Totale_e
#   7=Italiana 8=Straniera 9=Totale_c 10=>=6mesi 11=>=12mesi
# Per caption_num == "3" e "1.3"/"1.4" il col_index e' stabile.
.B_POSITIONAL <- list(
  list(carat = "genere", mod = "Maschi", col = 0L),
  list(carat = "genere", mod = "Femmine", col = 1L),
  list(carat = "genere", mod = "Totale", col = 2L),
  list(carat = "classe_eta", mod = "15-29", col = 3L),
  list(carat = "classe_eta", mod = "30-54", col = 4L),
  list(carat = "classe_eta", mod = "55+", col = 5L),
  list(carat = "classe_eta", mod = "Totale", col = 6L),
  list(carat = "cittadinanza", mod = "Italiana", col = 7L),
  list(carat = "cittadinanza", mod = "Straniera", col = 8L),
  list(carat = "cittadinanza", mod = "Totale", col = 9L),
  list(carat = "durata_disoccupazione", mod = "ge_6mesi", col = 10L),
  list(carat = "durata_disoccupazione", mod = "ge_12mesi", col = 11L)
)

# Mapping posizionale per tema H caption 2.2 ---------------------------------
# Header tipico: "Occupati alla data di riferimento | Individui raggiunti | ..."
# col 0=presi/raggiunti, 1=occupati_totale, 2=di_cui_nuovi, 3=quota_nuovi_pc, ...
.H_22_POSITIONAL <- list(
  list(var = "raggiunti", unit = "count", col = 0L),
  list(var = "occupati_totale", unit = "count", col = 1L),
  list(var = "nuovi_occupati", unit = "count", col = 2L),
  list(var = "occupati_pc", unit = "rate", col = 3L),
  list(var = "quota_nuovi_su_occ", unit = "rate", col = 4L),
  list(var = "gia_occupati", unit = "count", col = 5L)
)

# Mapping posizionale per tema H caption "8" ANPAL pre-2025 -----------------
# Header: "Presi in carico (A) | Nuovi occupati 60gg (B) | %(B/A) |
#          Nuovi occupati 90gg (C) | %(C/A) | Variazioni"
# Variante alternativa: 90gg/180gg invece di 60gg/90gg (riconosciuta dal
# pattern globale del header_modal). Qui codifichiamo solo la PRIMA
# variante (la piu' frequente). La seconda viene catturata dal match
# col_token-based applicato prima.
.H_C8_POSITIONAL <- list(
  list(var = "presi_in_carico_totale", unit = "count", col = 0L),
  list(var = "occupati_60gg", unit = "count", col = 1L),
  list(var = "tasso_occupati_60gg", unit = "rate", col = 2L),
  list(var = "occupati_90gg", unit = "count", col = 3L),
  list(var = "tasso_occupati_90gg", unit = "rate", col = 4L)
)

# Mapping posizionale per tema H caption "6" ANPAL pre-2025 -----------------
# Header: "Presi in carico | Occupati a 60 giorni di cui con lo stesso datore"
.H_C6_POSITIONAL <- list(
  list(var = "presi_in_carico_totale", unit = "count", col = 0L),
  list(var = "occupati_60gg", unit = "count", col = 1L),
  list(var = "tasso_occupati_60gg", unit = "rate", col = 2L)
)

# Mapping posizionale per tema F caption 2.1 ---------------------------------
.F_21_POSITIONAL <- list(
  list(var = "presi_in_carico_totale", unit = "count", col = 0L),
  list(var = "con_politica_avviata", unit = "count", col = 1L),
  list(var = "con_politica_avviata_pc", unit = "rate", col = 2L)
)

# Mapping posizionale per tema A1 caption "1.2" post-2025 -------------------
# Quando l'INAPP rimpiazzo (v0.4.0) genera col_index 0..9, ordine fisso:
# 5 percorsi GOL × {valore_assoluto, percentuale_riga}.
.A1_C12_POSITIONAL <- list(
  list(
    var = "presi_in_carico_ass",
    percorso = "1_reinserimento_lavorativo",
    unit = "count",
    col = 0L
  ),
  list(
    var = "presi_in_carico_pc",
    percorso = "1_reinserimento_lavorativo",
    unit = "percentage_row",
    col = 1L
  ),
  list(
    var = "presi_in_carico_ass",
    percorso = "2_aggiornamento_upskilling",
    unit = "count",
    col = 2L
  ),
  list(
    var = "presi_in_carico_pc",
    percorso = "2_aggiornamento_upskilling",
    unit = "percentage_row",
    col = 3L
  ),
  list(
    var = "presi_in_carico_ass",
    percorso = "3_riqualificazione_reskilling",
    unit = "count",
    col = 4L
  ),
  list(
    var = "presi_in_carico_pc",
    percorso = "3_riqualificazione_reskilling",
    unit = "percentage_row",
    col = 5L
  ),
  list(
    var = "presi_in_carico_ass",
    percorso = "4_lavoro_inclusione",
    unit = "count",
    col = 6L
  ),
  list(
    var = "presi_in_carico_pc",
    percorso = "4_lavoro_inclusione",
    unit = "percentage_row",
    col = 7L
  ),
  list(
    var = "presi_in_carico_ass",
    percorso = "5_ricollocazione_collettiva",
    unit = "count",
    col = 8L
  ),
  list(
    var = "presi_in_carico_pc",
    percorso = "5_ricollocazione_collettiva",
    unit = "percentage_row",
    col = 9L
  )
)

# Mapping posizionale per tema A1 caption "2" pre-2025 (ANPAL) ---------------
# Header tipico: "1 2 3 4 | Reinserimento Aggiornamento Riqualificazione
# Lavoro e | Valori % | Valori assoluti"
# Struttura osservata: 4 percorsi × valore_assoluto + 4 percorsi × percentuale
# col 0-3 = valore_assoluto, col 4-7 = percentuale_riga.
.A1_C2_POSITIONAL <- list(
  list(
    var = "presi_in_carico_ass",
    percorso = "1_reinserimento_lavorativo",
    unit = "count",
    col = 0L
  ),
  list(
    var = "presi_in_carico_ass",
    percorso = "2_aggiornamento_upskilling",
    unit = "count",
    col = 1L
  ),
  list(
    var = "presi_in_carico_ass",
    percorso = "3_riqualificazione_reskilling",
    unit = "count",
    col = 2L
  ),
  list(
    var = "presi_in_carico_ass",
    percorso = "4_lavoro_inclusione",
    unit = "count",
    col = 3L
  ),
  list(
    var = "presi_in_carico_pc",
    percorso = "1_reinserimento_lavorativo",
    unit = "percentage_row",
    col = 4L
  ),
  list(
    var = "presi_in_carico_pc",
    percorso = "2_aggiornamento_upskilling",
    unit = "percentage_row",
    col = 5L
  ),
  list(
    var = "presi_in_carico_pc",
    percorso = "3_riqualificazione_reskilling",
    unit = "percentage_row",
    col = 6L
  ),
  list(
    var = "presi_in_carico_pc",
    percorso = "4_lavoro_inclusione",
    unit = "percentage_row",
    col = 7L
  )
)

# 3. Auto-derivazione semantica ----------------------------------------------

scaffold[,
  c(
    "variabile",
    "caratteristica",
    "modalita",
    "percorso",
    "unita",
    "confidenza"
  ) := list(
    NA_character_,
    NA_character_,
    NA_character_,
    NA_character_,
    NA_character_,
    NA_character_
  )
]

# Estrai il "token" della colonna corrente dal header_modal usando col_index
# come posizione dopo lo split su spazi multipli
extract_col_token <- function(header, idx) {
  if (is.na(header)) {
    return(NA_character_)
  }
  # Prende l'ultima "riga" del header (dopo l'ultimo |)
  parts <- strsplit(header, "\\s*\\|\\s*")[[1]]
  ultima <- parts[length(parts)]
  toks <- strsplit(ultima, "\\s{2,}|\\s")[[1]]
  toks <- toks[nchar(toks) > 0]
  if (idx + 1L <= length(toks)) toks[idx + 1L] else NA_character_
}

scaffold[, col_token := mapply(extract_col_token, header_modal, col_index)]

# Tema A1: percorsi
for (i in seq_len(nrow(scaffold))) {
  s <- scaffold[i]
  if (s$tema == "A1") {
    # col 0 = totale; col_index dispari nelle vecchie versioni potrebbe essere %
    if (s$col_index == 0L) {
      scaffold[
        i,
        `:=`(
          variabile = "presi_in_carico_totale",
          unita = classify_unita(s$header_modal, s$caption_title_modal),
          confidenza = "high"
        )
      ]
      next
    }
    # Riconosci percorso dal col_token (singola colonna), non da
    # header_modal globale. Il vecchio loop con break causava overmatch:
    # tutti i col_index venivano mappati al primo percorso trovato
    # nell'header (sempre "Reinserimento"). Le righe non catturate qui
    # vengono recuperate dal mapping posizionale .A1_C2_POSITIONAL piu'
    # in basso.
    tk <- s$col_token
    if (!is.na(tk)) {
      for (perc_id in names(RX_PERCORSI)) {
        if (
          grepl(RX_PERCORSI[[perc_id]], tk, perl = TRUE, ignore.case = TRUE)
        ) {
          # Determina assoluto vs % dal token stesso (es. *_ass, *_pc)
          is_pc <- grepl("_pc$|%|percent|riga", tk, ignore.case = TRUE) ||
            (grepl("%|riga", s$header_modal) &&
              s$col_index >= 5L)
          scaffold[
            i,
            `:=`(
              variabile = if (is_pc) {
                "presi_in_carico_pc"
              } else {
                "presi_in_carico_ass"
              },
              percorso = perc_id,
              unita = if (is_pc) "percentage_row" else "count",
              confidenza = "medium"
            )
          ]
          break
        }
      }
    }
  }

  # Tema B: anagrafica
  if (s$tema == "B") {
    for (an in RX_ANAGRAFICA) {
      tk <- s$col_token
      if (!is.na(tk) && grepl(an$rx, tk, perl = TRUE)) {
        scaffold[
          i,
          `:=`(
            variabile = "presi_in_carico",
            caratteristica = an$carat,
            modalita = an$mod,
            unita = classify_unita(s$header_modal, s$caption_title_modal),
            confidenza = "high"
          )
        ]
        break
      }
    }
  }

  # Tema F: politiche.
  # Limita l'attribuzione delle variabili "in_formazione", "con_politica_avviata",
  # "in_tirocinio" alle prime 3 col_index (1, 2, 3) per evitare l'over-matching
  # quando il caption_title contiene queste keyword.
  if (s$tema == "F") {
    h <- s$header_modal
    if (s$col_index == 0L) {
      scaffold[
        i,
        `:=`(
          variabile = "presi_in_carico_totale",
          unita = "count",
          confidenza = "high"
        )
      ]
    } else if (
      s$col_index <= 3L &&
        grepl("politica\\s*avviata|con\\s*politica", h)
    ) {
      scaffold[
        i,
        `:=`(
          variabile = "con_politica_avviata",
          unita = classify_unita(h, s$caption_title_modal),
          confidenza = "medium"
        )
      ]
    } else if (
      s$col_index <= 3L &&
        grepl("formazione", h, ignore.case = TRUE)
    ) {
      scaffold[
        i,
        `:=`(
          variabile = "in_formazione",
          unita = classify_unita(h, s$caption_title_modal),
          confidenza = "medium"
        )
      ]
    } else if (
      s$col_index <= 3L &&
        grepl("tirocinio|tirocini", h, ignore.case = TRUE)
    ) {
      scaffold[
        i,
        `:=`(
          variabile = "in_tirocinio",
          unita = classify_unita(h, s$caption_title_modal),
          confidenza = "medium"
        )
      ]
    }
  }

  # Tema H: esiti occupazionali.
  # I pattern "60 giorni / 90 giorni / 180 giorni" sono valutati solo sulla
  # PROPRIA colonna (col_token) per evitare overmatch: l'header_modal
  # globale contiene piu' periodi insieme (es. "Nuovi occupati 60 90") e
  # il vecchio loop mappava tutte le colonne al primo periodo trovato.
  if (s$tema == "H") {
    if (s$col_index == 0L) {
      scaffold[
        i,
        `:=`(
          variabile = "presi_in_carico_totale",
          unita = "count",
          confidenza = "high"
        )
      ]
    } else {
      tk <- s$col_token
      if (!is.na(tk)) {
        is_pc <- grepl("%|tasso|incidenza|riga", tk, ignore.case = TRUE)
        if (grepl("60", tk)) {
          scaffold[
            i,
            `:=`(
              variabile = if (is_pc) {
                "tasso_occupati_60gg"
              } else {
                "occupati_60gg"
              },
              unita = if (is_pc) "rate" else "count",
              confidenza = "medium"
            )
          ]
        } else if (grepl("90", tk)) {
          scaffold[
            i,
            `:=`(
              variabile = if (is_pc) {
                "tasso_occupati_90gg"
              } else {
                "occupati_90gg"
              },
              unita = if (is_pc) "rate" else "count",
              confidenza = "medium"
            )
          ]
        } else if (grepl("180", tk)) {
          scaffold[
            i,
            `:=`(
              variabile = if (is_pc) {
                "tasso_occupati_180gg"
              } else {
                "occupati_180gg"
              },
              unita = if (is_pc) "rate" else "count",
              confidenza = "medium"
            )
          ]
        }
      }
    }
  }
}

# 3bis. Fallback posizionale per le righe ancora NA --------------------------
# Per i temi con schema stabile, applica i mapping posizionali dichiarati
# in cima al file. La condizione `is.na(variabile)` evita di sovrascrivere
# le righe gia' classificate dai pattern regex.

# Tema B: caption_num "3" e "1.3"/"1.4" hanno la stessa griglia anagrafica
for (m in .B_POSITIONAL) {
  scaffold[
    tema == "B" &
      caption_num %in% c("3", "1.3", "1.4") &
      col_index == m$col &
      is.na(variabile),
    `:=`(
      variabile = "presi_in_carico",
      caratteristica = m$carat,
      modalita = m$mod,
      unita = classify_unita(header_modal, caption_title_modal),
      confidenza = "high"
    )
  ]
}

# Tema H caption 2.2 (formato INAPP / MLPS post-2024)
for (m in .H_22_POSITIONAL) {
  scaffold[
    tema == "H" & caption_num == "2.2" & col_index == m$col & is.na(variabile),
    `:=`(
      variabile = m$var,
      unita = m$unit,
      confidenza = "medium"
    )
  ]
}

# Tema H caption 8 ANPAL (60/90 giorni) - solo varianti con 60gg
for (m in .H_C8_POSITIONAL) {
  scaffold[
    tema == "H" & caption_num == "8" & col_index == m$col & is.na(variabile),
    `:=`(
      variabile = m$var,
      unita = m$unit,
      confidenza = "medium"
    )
  ]
}

# Tema H caption 6 ANPAL (60 giorni)
for (m in .H_C6_POSITIONAL) {
  scaffold[
    tema == "H" & caption_num == "6" & col_index == m$col & is.na(variabile),
    `:=`(
      variabile = m$var,
      unita = m$unit,
      confidenza = "medium"
    )
  ]
}

# Tema F caption 2.1 col 0-2 (formato ANPAL standard)
for (m in .F_21_POSITIONAL) {
  scaffold[
    tema == "F" & caption_num == "2.1" & col_index == m$col & is.na(variabile),
    `:=`(
      variabile = m$var,
      unita = m$unit,
      confidenza = "medium"
    )
  ]
}

# Tema A1 col 0 = totale gia' presa in carico per qualsiasi caption
scaffold[
  tema == "A1" & col_index == 0L & is.na(variabile),
  `:=`(
    variabile = "presi_in_carico_totale",
    unita = "count",
    confidenza = "high"
  )
]

# Tema A1 caption 2 ANPAL pre-2025 (8 colonne posizionali per 4 percorsi)
for (m in .A1_C2_POSITIONAL) {
  scaffold[
    tema == "A1" & caption_num == "2" & col_index == m$col & is.na(percorso),
    `:=`(
      variabile = m$var,
      percorso = m$percorso,
      unita = m$unit,
      confidenza = "high"
    )
  ]
}

# Tema A1 caption 1.2 post-2025 (rimpiazzo INAPP, 10 colonne x 5 percorsi)
for (m in .A1_C12_POSITIONAL) {
  scaffold[
    tema == "A1" &
      caption_num == "1.2" &
      era == "post_2025" &
      col_index == m$col &
      is.na(percorso),
    `:=`(
      variabile = m$var,
      percorso = m$percorso,
      unita = m$unit,
      confidenza = "high"
    )
  ]
}

# 4. Safety net per le righe ancora NA ---------------------------------------

scaffold[
  is.na(variabile),
  `:=`(
    variabile = paste0("raw_col_", col_index),
    unita = "unknown",
    confidenza = "low"
  )
]

# Riordino colonne
setcolorder(
  scaffold,
  c(
    "tema",
    "caption_num",
    "col_index",
    "era",
    "variabile",
    "caratteristica",
    "modalita",
    "percorso",
    "unita",
    "confidenza",
    "header_modal",
    "caption_title_modal",
    "n_rows",
    "n_header_variants",
    "col_token"
  )
)

# 5. Salva CSV editabile + .rda ----------------------------------------------

dir.create("inst/extdata", recursive = TRUE, showWarnings = FALSE)
fwrite(scaffold, "inst/extdata/storico_decoder.csv")

storico_decoder <- copy(scaffold)
setkey(storico_decoder, tema, caption_num, col_index, era)
save(storico_decoder, file = "data/storico_decoder.rda", compress = "xz")

# 6. Riepilogo ---------------------------------------------------------------

message("\n--- Scaffold decoder generato ---")
message("  Righe totali: ", nrow(scaffold))
print(scaffold[, .N, by = .(tema, confidenza)][order(tema, confidenza)])

message("\n--- Distribuzione per tema ---")
print(scaffold[, .N, by = tema])

message("\nSalvato: inst/extdata/storico_decoder.csv (editabile)")
message("Salvato: data/storico_decoder.rda")
