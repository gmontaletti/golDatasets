# =============================================================================
# Mapper per i CSV in INAPP GOL/focus_gol_all/
# -----------------------------------------------------------------------------
# Trasformano i CSV grezzi di tabula in long format compatibile con i
# dataset storia (volumi, caratteristiche, esiti).
# =============================================================================

# 1. Tab 1.5: Patto di servizio per target × regione -------------------------
# Schema CSV: c1=regione, c2=Totale, c3="SFL ADI NASpI" fusi, c4=Altri.
# 22 regioni + Totale Italia, 12 report. ~276 righe per (regione × target).

#' Mapper Tab 1.5 INAPP focus_gol_all
#' @noRd
.map_tab_1_5 <- function(csv_path, report_id, data_riferimento) {
  raw <- .read_focus_csv(csv_path, min_rows = 10L)
  if (is.null(raw) || ncol(raw) < 4L) {
    return(NULL)
  }

  data_rows <- raw[V1 %in% c(.canonical_regioni, "Totale", "Italia")]
  if (nrow(data_rows) == 0L) {
    return(NULL)
  }

  out_list <- vector("list", nrow(data_rows))
  for (i in seq_len(nrow(data_rows))) {
    r <- data_rows[i]
    reg <- .normalize_anchor_inapp(r$V1)
    tot <- .parse_number_it(r$V2)
    three <- .split_multi_values(r$V3)
    altri <- .parse_number_it(r$V4)

    if (length(three) != 3L) {
      next
    }

    out_list[[i]] <- data.table::data.table(
      data_riferimento = data_riferimento,
      fonte = paste0("inapp_focus_", report_id, "_t15"),
      regione = reg,
      percorso = NA_character_,
      caratteristica = "target_patto_servizio",
      modalita = c(
        "Totale",
        "SFL_domanda_accolta",
        "ADI_attivabili",
        "NASpI_domanda_presentata",
        "Altri_disoccupati"
      ),
      variabile = "patto_servizio_attivo",
      unita = "count",
      valore = c(tot, three, altri),
      confidenza = "high"
    )
  }
  out_list <- Filter(Negate(is.null), out_list)
  if (length(out_list) == 0L) {
    return(NULL)
  }
  res <- data.table::rbindlist(out_list)
  res[!is.na(valore) & valore > 0]
}

# 1bis. Tab 1.3: caratteristiche socio-anagrafiche per regione, % riga ------
# Schema osservato in 17/2025 (10 col) e 3/2025 (10 col) e 12/2025 (12 col):
# col1=Regione, col2=Maschi, col3=Femmine, col4=Tot, col5=15-29,
# col6 puo' essere "30-54 55+" fuso (10 col) o "30-54" separato (12 col).
# Sotto, comune: cittadinanza Italiana/Straniera/Tot e anzianita'.
# Strategia: riconoscere le regioni in V1 ed estrarre le colonne in base
# al numero di colonne effettivo.

.MAP_1_3_GENERE <- c(
  carat = "genere",
  mods = "Maschi,Femmine",
  unit = "percentage"
)
.MAP_1_3_ETA <- c(
  carat = "classe_eta",
  mods = "15-29,30-54,55+",
  unit = "percentage"
)
.MAP_1_3_CITT <- c(
  carat = "cittadinanza",
  mods = "Italiana,Straniera",
  unit = "percentage"
)
.MAP_1_3_DUR <- c(
  carat = "durata_disoccupazione",
  mods = "ge_6mesi,ge_12mesi",
  unit = "percentage"
)

#' Mapper Tab 1.3 INAPP focus_gol_all
#' @noRd
.map_tab_1_3 <- function(csv_path, report_id, data_riferimento) {
  raw <- .read_focus_csv(csv_path, min_rows = 6L)
  if (is.null(raw) || ncol(raw) < 9L) {
    return(NULL)
  }

  rows <- raw[V1 %in% c(.canonical_regioni, "Totale", "Italia")]
  if (nrow(rows) == 0L) {
    return(NULL)
  }

  out_list <- vector("list", nrow(rows))
  for (i in seq_len(nrow(rows))) {
    r <- as.character(unlist(rows[i, ]))
    reg <- .normalize_anchor_inapp(r[1])
    n <- length(r)
    # Estrai modalita' a seconda della struttura. La regola:
    # genere: V2, V3 (Maschi, Femmine)
    # eta: V5, V6 (split se necessario), V7? (puo' essere fuso in V6)
    # cittadinanza: V8, V9 (split se necessario)
    # durata: ultima cella (V10/V12) split in 2 valori
    maschi <- .parse_number_it(r[2])
    femmine <- .parse_number_it(r[3])
    # Eta: V5 = 15-29, V6 = "30-54 55+" o solo "30-54"
    eta_giovani <- .parse_number_it(r[5])
    v6_split <- .split_multi_values(r[6])
    if (length(v6_split) == 2L) {
      eta_medi <- v6_split[1]
      eta_anziani <- v6_split[2]
    } else if (n >= 7L) {
      eta_medi <- .parse_number_it(r[6])
      eta_anziani <- .parse_number_it(r[7])
    } else {
      eta_medi <- NA_real_
      eta_anziani <- NA_real_
    }
    # Cittadinanza: V8 (potrebbe essere "Ita Stra" fuso) o V9/V10
    citt_idx <- if (length(v6_split) == 2L) 8L else 9L
    v_citt <- r[citt_idx]
    v_citt_split <- .split_multi_values(v_citt)
    if (length(v_citt_split) == 2L) {
      citt_ita <- v_citt_split[1]
      citt_str <- v_citt_split[2]
    } else if (n >= citt_idx + 1L) {
      citt_ita <- .parse_number_it(r[citt_idx])
      citt_str <- .parse_number_it(r[citt_idx + 1L])
    } else {
      citt_ita <- NA_real_
      citt_str <- NA_real_
    }
    # Durata: ultima cella della riga, "ge6 ge12" fuso
    # Durata: ultima cella della riga puo' contenere 2 valori
    # ("ge6 ge12") oppure 3 ("totale_cittadinanza ge6 ge12") nei report
    # con struttura ibrida. In ogni caso ge_6mesi e ge_12mesi sono gli
    # ULTIMI due valori.
    dur_split <- .split_multi_values(r[n])
    n_dur <- length(dur_split)
    dur_6 <- if (n_dur >= 2L) dur_split[n_dur - 1L] else NA_real_
    dur_12 <- if (n_dur >= 1L) dur_split[n_dur] else NA_real_

    out_list[[i]] <- data.table::data.table(
      data_riferimento = data_riferimento,
      fonte = paste0("inapp_focus_", report_id, "_t13"),
      regione = reg,
      percorso = NA_character_,
      caratteristica = c(
        "genere",
        "genere",
        "classe_eta",
        "classe_eta",
        "classe_eta",
        "cittadinanza",
        "cittadinanza",
        "durata_disoccupazione",
        "durata_disoccupazione"
      ),
      modalita = c(
        "Maschi",
        "Femmine",
        "15-29",
        "30-54",
        "55+",
        "Italiana",
        "Straniera",
        "ge_6mesi",
        "ge_12mesi"
      ),
      variabile = "presi_in_carico_pc",
      unita = "percentage",
      valore = c(
        maschi,
        femmine,
        eta_giovani,
        eta_medi,
        eta_anziani,
        citt_ita,
        citt_str,
        dur_6,
        dur_12
      ),
      confidenza = "high"
    )
  }
  out_list <- Filter(Negate(is.null), out_list)
  if (length(out_list) == 0L) {
    return(NULL)
  }
  res <- data.table::rbindlist(out_list, fill = TRUE)
  res[!is.na(valore)]
}

# 1ter. Tab 1.5 "per percorso": vulnerabilita' x percorso GOL ----------------
# Schema osservato in 12/2025 e simili: col1 = "Percorso N. nome",
# col2 = raggiunti (A), col3 = con caratt. vulnerabilita' (B),
# col4 = B/A %, col5..n = donne, dis_6m, under30, over55, disabilita'
# Le righe sono 5 percorsi GOL + Totale.

.PERCORSO_1_5_PATTERN <- list(
  "1_reinserimento_lavorativo" = "^1\\.?\\s*Reinserimento",
  "2_aggiornamento_upskilling" = "^2\\.?\\s*Aggiornamento",
  "3_riqualificazione_reskilling" = "^3\\.?\\s*Riqualificazione",
  "4_lavoro_inclusione" = "^4\\.?\\s*Lavoro",
  "5_ricollocazione_collettiva" = "^5\\.?\\s*Ricollocazione",
  "totale_percorsi" = "^Totale\\s*$|^Totale\\s+percors"
)

#' Mapper Tab 1.5 "per percorso" INAPP focus_gol_all
#'
#' Schema alternativo della tabella 1.5 presente nei report mensili
#' (3-16/2025). Vulnerabilita' per percorso GOL invece che per regione.
#' @noRd
.map_tab_1_5_per_percorso <- function(csv_path, report_id, data_riferimento) {
  raw <- .read_focus_csv(csv_path, min_rows = 6L)
  if (is.null(raw) || ncol(raw) < 5L) {
    return(NULL)
  }

  # Identifica righe percorso
  match_percorso <- function(s) {
    for (k in names(.PERCORSO_1_5_PATTERN)) {
      if (grepl(.PERCORSO_1_5_PATTERN[[k]], s, perl = TRUE)) return(k)
    }
    NA_character_
  }
  raw[, percorso_id := vapply(V1, match_percorso, character(1))]
  rows <- raw[!is.na(percorso_id)]
  if (nrow(rows) == 0L) {
    return(NULL)
  }

  out_list <- vector("list", nrow(rows))
  for (i in seq_len(nrow(rows))) {
    r <- as.character(unlist(rows[i, ]))
    perc <- rows[i]$percorso_id
    n <- length(r)
    # I numeri possono essere singoli o fusi - cerco i primi 8 numerici
    # nelle celle dopo V1
    all_nums <- unlist(lapply(r[-1L], .split_multi_values))
    all_nums <- all_nums[!is.na(all_nums)]
    if (length(all_nums) < 5L) {
      next
    }

    # Ordine atteso: raggiunti(A), vulnerab(B), B/A%,
    # donne, dis6m+, under30, over55, disabili
    labels <- c(
      "raggiunti",
      "vulnerabili",
      "vulnerabili_pc",
      "donne",
      "disocc_ge6mesi",
      "under_30",
      "over_55",
      "disabili"
    )
    n_use <- min(length(all_nums), length(labels))
    out_list[[i]] <- data.table::data.table(
      data_riferimento = data_riferimento,
      fonte = paste0("inapp_focus_", report_id, "_t15p"),
      regione = NA_character_,
      percorso = perc,
      caratteristica = "vulnerabilita",
      modalita = labels[seq_len(n_use)],
      variabile = "vulnerabilita_per_percorso",
      unita = ifelse(
        grepl("_pc$", labels[seq_len(n_use)]),
        "percentage",
        "count"
      ),
      valore = all_nums[seq_len(n_use)],
      confidenza = "medium"
    )
  }
  out_list <- Filter(Negate(is.null), out_list)
  if (length(out_list) == 0L) {
    return(NULL)
  }
  res <- data.table::rbindlist(out_list, fill = TRUE)
  res[!is.na(valore) & valore > 0]
}

# 2. Tab 2.3: Corsi di formazione in competenze digitali ---------------------
# Schema a sezioni: ogni sezione e' header + righe.
# Sezioni: Totale (1 riga aggregata), Area geografica, Percorso GOL,
# Classe di eta', Genere, Titolo di studio, Cittadinanza.
# Output: long con (dimensione, modalita) + 4 variabili
# (corsi_totali, corsi_totali_pc, corsi_completati, corsi_completati_pc).

.SEZIONI_2_3 <- c(
  "Area geografica" = "area_geografica",
  "Percorso GOL" = "percorso_gol",
  "Classe di et\u00e0" = "classe_eta",
  "Genere" = "genere",
  "Titolo di studio" = "titolo_studio",
  "Cittadinanza" = "cittadinanza"
)

#' Mapper Tab 2.3 INAPP focus_gol_all
#' @noRd
.map_tab_2_3 <- function(csv_path, report_id, data_riferimento) {
  raw <- .read_focus_csv(csv_path, min_rows = 6L)
  if (is.null(raw) || ncol(raw) < 3L) {
    return(NULL)
  }

  out_list <- list()
  current_dim <- "totale"
  for (i in seq_len(nrow(raw))) {
    r <- raw[i]
    label <- trimws(r$V1)
    val2 <- r$V2
    val3 <- r$V3

    if (label == "" || label == "A" || label == "E") {
      next
    }
    if (label %in% names(.SEZIONI_2_3)) {
      current_dim <- .SEZIONI_2_3[[label]]
      next
    }
    if (label == "Totale" && current_dim != "totale") {
      # ignore "Totale" rows within sub-sections
      next
    }

    n_tot <- .parse_number_it(val2)
    triple <- .split_multi_values(val3)
    # atteso: % sul totale, n. completati, % su completati
    if (length(triple) < 3L) {
      next
    }

    mod <- if (label == "Totale") "Totale" else label

    out_list[[length(out_list) + 1L]] <- data.table::data.table(
      data_riferimento = data_riferimento,
      fonte = paste0("inapp_focus_", report_id, "_t23"),
      dimensione = current_dim,
      modalita = mod,
      variabile = c(
        "corsi_totali",
        "corsi_totali_pc",
        "corsi_completati",
        "corsi_completati_pc"
      ),
      unita = c("count", "percentage", "count", "percentage"),
      valore = c(n_tot, triple[1], triple[2], triple[3]),
      confidenza = "high"
    )
  }
  if (length(out_list) == 0L) {
    return(NULL)
  }
  res <- data.table::rbindlist(out_list, fill = TRUE)
  res[!is.na(valore)]
}

# 3. Orchestratore -----------------------------------------------------------

#' Costruisce il long format delle tabelle INAPP focus_gol_all
#'
#' Cicla sui CSV in `INAPP GOL/focus_gol_all/<report_id>/` invocando i
#' mapper specifici per ciascuna tabella supportata. Le tabelle non
#' coperte da un mapper sono ignorate silenziosamente.
#'
#' Coperte: 1.5 (patto servizio per target), 2.3 (formazione competenze
#' digitali per dimensione).
#'
#' Non coperte (future work): 1.3, 1.4, 1.6, 1.7.
#'
#' @param root Cartella radice `INAPP GOL/focus_gol_all/`. Se `NULL`,
#'   usa il default rispetto alla cwd.
#' @return Una lista con due `data.table`: `caratteristiche` (da 1.5)
#'   e `esiti` (da 2.3). Se nessun mapper produce output, lista con
#'   data.table vuoti.
#'
#' @importFrom data.table rbindlist
#' @export
build_inapp_focus_long <- function(root = "INAPP GOL/focus_gol_all") {
  if (!dir.exists(root)) {
    warning("Cartella ", root, " non trovata", call. = FALSE)
    return(list(
      caratteristiche = data.table::data.table(),
      esiti = data.table::data.table()
    ))
  }

  caratt_list <- list()
  esiti_list <- list()

  report_dirs <- list.dirs(root, recursive = FALSE)
  for (rdir in report_dirs) {
    report_id <- basename(rdir)
    if (!report_id %in% names(.inapp_report_dates)) {
      next
    }
    data_rif <- data.table::as.IDate(.inapp_report_dates[[report_id]])

    # Tab 1.3 (caratteristiche per regione, % riga)
    csv_13 <- list.files(
      rdir,
      pattern = "^tab_1_3_.*\\.csv$",
      full.names = TRUE
    )
    if (length(csv_13) > 0L) {
      r13 <- .map_tab_1_3(csv_13[1], report_id, data_rif)
      if (!is.null(r13) && nrow(r13) > 0L) {
        caratt_list[[length(caratt_list) + 1L]] <- r13
      }
    }

    # Tab 1.5: prova prima il mapper "per regione", poi il "per percorso"
    csv_15 <- list.files(
      rdir,
      pattern = "^tab_1_5_.*\\.csv$",
      full.names = TRUE
    )
    if (length(csv_15) > 0L) {
      r15 <- .map_tab_1_5(csv_15[1], report_id, data_rif)
      if (!is.null(r15) && nrow(r15) > 0L) {
        caratt_list[[length(caratt_list) + 1L]] <- r15
      } else {
        # Schema alternativo: vulnerabilita' per percorso
        r15p <- .map_tab_1_5_per_percorso(csv_15[1], report_id, data_rif)
        if (!is.null(r15p) && nrow(r15p) > 0L) {
          caratt_list[[length(caratt_list) + 1L]] <- r15p
        }
      }
    }

    csv_23 <- list.files(
      rdir,
      pattern = "^tab_2_3_.*\\.csv$",
      full.names = TRUE
    )
    if (length(csv_23) > 0L) {
      r23 <- .map_tab_2_3(csv_23[1], report_id, data_rif)
      if (!is.null(r23) && nrow(r23) > 0L) {
        esiti_list[[length(esiti_list) + 1L]] <- r23
      }
    }
  }

  list(
    caratteristiche = if (length(caratt_list) > 0L) {
      data.table::rbindlist(caratt_list, fill = TRUE)
    } else {
      data.table::data.table()
    },
    esiti = if (length(esiti_list) > 0L) {
      data.table::rbindlist(esiti_list, fill = TRUE)
    } else {
      data.table::data.table()
    }
  )
}
