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

    csv_15 <- list.files(
      rdir,
      pattern = "^tab_1_5_.*\\.csv$",
      full.names = TRUE
    )
    if (length(csv_15) > 0L) {
      r15 <- .map_tab_1_5(csv_15[1], report_id, data_rif)
      if (!is.null(r15) && nrow(r15) > 0L) {
        caratt_list[[length(caratt_list) + 1L]] <- r15
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
