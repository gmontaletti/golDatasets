# =============================================================================
# Costruzione dei tre dataset canonici GOL a partire dai CSV grezzi del repo
# -----------------------------------------------------------------------------
# Implementa la raccomandazione pratica derivata dall'analisi di copertura
# dei dati: produce tre data.table normalizzati e li salva come .rda nella
# directory `data/`, anticipando la convenzione di un futuro package R.
# =============================================================================

# 1. Funzione orchestratrice -------------------------------------------------

#' Costruisce i tre dataset canonici GOL e li scrive in `data/`
#'
#' Legge i CSV grezzi presenti nel repository e produce tre `data.table`
#' normalizzati:
#'
#' - `gol_inapp_mensile`: serie mensile INAPP Focus GOL 2024-06 -> 2025-12
#'   (long format gia' normalizzato).
#' - `gol_storico_regionale`: storico GOL 2022-2025 ristretto ai temi con
#'   schema stabile (A1, B, F, H), `quality_flag == "ok"`, anchor regionale
#'   canonico.
#' - `cob_regionale_trimestrale`: flussi COB INPS 2017-Q1 -> 2025-Q3, con
#'   nomi regionali armonizzati alle 21 etichette canoniche.
#'
#' Ogni dataset viene salvato come file `.rda` compresso (`xz`) in
#' `output_dir`.
#'
#' @param input_root Radice del repository (contiene `dataset_long/`,
#'   `INAPP GOL/`, `cob/`). Default: directory corrente.
#' @param output_dir Cartella di destinazione dei file `.rda`. Creata se
#'   mancante. Default: `"data"`.
#' @param overwrite Se `FALSE`, salta i file gia' presenti in `output_dir`.
#' @param verbose Se `TRUE` stampa un riepilogo per dataset.
#'
#' @return Invisibilmente, una lista con i tre `data.table`:
#'   `gol_inapp_mensile`, `gol_storico_regionale`, `cob_regionale_trimestrale`.
#'
#' @importFrom data.table fread rbindlist setkey setnames setDT
#'   uniqueN := .N as.IDate
#' @export
build_gol_datasets <- function(
  input_root = ".",
  output_dir = "data",
  overwrite = TRUE,
  verbose = TRUE
) {
  # 1.1 Validazione input ----------------------------------------------------
  paths <- list(
    inapp = file.path(
      input_root,
      "INAPP GOL",
      "csv_long",
      "tab_long_completo.csv"
    ),
    long = file.path(input_root, "dataset_long"),
    cob = file.path(
      input_root,
      "cob",
      "co_regionale_avviamenti_cessazioni_long.csv"
    )
  )
  long_files <- file.path(
    paths$long,
    paste0("gol_", c("A1", "B", "F", "H"), "_long.csv")
  )
  missing <- c(
    if (!file.exists(paths$inapp)) paths$inapp,
    long_files[!file.exists(long_files)],
    if (!file.exists(paths$cob)) paths$cob
  )
  if (length(missing)) {
    stop(
      "File sorgente mancanti:\n  - ",
      paste(missing, collapse = "\n  - "),
      call. = FALSE
    )
  }
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  # 1.2 Costruzione dataset --------------------------------------------------
  gol_inapp_mensile <- .build_gol_inapp_mensile(paths$inapp)
  gol_storico_regionale <- .build_gol_storico_regionale(long_files)
  cob_regionale_trimestrale <- .build_cob_regionale_trimestrale(paths$cob)

  # 1.3 Salvataggio .rda -----------------------------------------------------
  to_save <- list(
    gol_inapp_mensile = gol_inapp_mensile,
    gol_storico_regionale = gol_storico_regionale,
    cob_regionale_trimestrale = cob_regionale_trimestrale
  )
  for (nm in names(to_save)) {
    out_path <- file.path(output_dir, paste0(nm, ".rda"))
    if (!overwrite && file.exists(out_path)) {
      if (verbose) {
        message("Skip (esiste): ", out_path)
      }
      next
    }
    assign(nm, to_save[[nm]])
    save(list = nm, file = out_path, compress = "xz")
    if (verbose) {
      message(
        "Salvato: ",
        out_path,
        " (",
        formatC(file.info(out_path)$size, big.mark = "'", format = "d"),
        " byte)"
      )
    }
  }

  # 1.4 Riepilogo ------------------------------------------------------------
  if (verbose) {
    .print_summary(to_save)
  }

  invisible(to_save)
}

# 2. Helper: INAPP Focus GOL mensile -----------------------------------------

#' Costruisce `gol_inapp_mensile` da `tab_long_completo.csv`
#' @noRd
.build_gol_inapp_mensile <- function(path) {
  dt <- data.table::fread(
    path,
    colClasses = c(
      report_id = "character",
      tavola = "character",
      titolo_tabella = "character",
      dimensione = "character",
      etichetta = "character",
      variabile = "character",
      percorso = "character",
      unita_misura = "character"
    )
  )
  dt[, data_riferimento := data.table::as.IDate(data_riferimento)]
  dt[, tavola := as.numeric(tavola)]
  dt[, valore := as.numeric(valore)]
  data.table::setkey(
    dt,
    report_id,
    tavola,
    data_riferimento,
    etichetta,
    variabile,
    percorso
  )
  dt[]
}

# 3. Helper: storico GOL temi stabili ----------------------------------------

#' Costruisce `gol_storico_regionale` da `dataset_long/gol_{A1,B,F,H}_long.csv`
#' @noRd
.build_gol_storico_regionale <- function(files) {
  dt <- data.table::rbindlist(
    lapply(files, function(f) {
      data.table::fread(
        f,
        colClasses = c(
          file = "character",
          ente = "character",
          tema = "character",
          caption_num = "character",
          caption_title = "character",
          anchor = "character",
          header_above = "character",
          valore_raw = "character",
          unit_guess = "character",
          quality_flag = "character"
        )
      )
    }),
    use.names = TRUE,
    fill = TRUE
  )
  dt <- dt[quality_flag == "ok"]
  dt <- dt[anchor %in% .canonical_regioni]
  dt[, data_riferimento := data.table::as.IDate(data_riferimento)]
  dt[, valore_num := as.numeric(valore_num)]
  dt[, col_index := as.integer(col_index)]
  dt[, page := as.integer(page)]
  data.table::setkey(dt, tema, file, anchor, col_index)
  dt[]
}

# 4. Helper: COB INPS trimestrale --------------------------------------------

#' Costruisce `cob_regionale_trimestrale` da `co_regionale_*_long.csv`
#' @noRd
.build_cob_regionale_trimestrale <- function(path) {
  dt <- data.table::fread(
    path,
    sep = ";",
    colClasses = c(
      regione = "character",
      trimestre_roman = "character",
      flusso = "character",
      file_origine = "character"
    )
  )
  dt[, regione := .normalize_regioni_cob(regione)]
  dt <- dt[!is.na(regione)]
  dt[, anno := as.integer(anno)]
  dt[, trimestre := as.integer(trimestre)]
  dt[, rapporti := as.numeric(rapporti)]
  dt[, lavoratori := as.numeric(lavoratori)]
  dt[, media := as.numeric(media)]
  # Data inizio trimestre: utile per merge con serie mensili.
  dt[,
    data_inizio_trimestre := data.table::as.IDate(
      sprintf("%d-%02d-01", anno, (trimestre - 1L) * 3L + 1L)
    )
  ]
  data.table::setkey(dt, regione, anno, trimestre, flusso)
  dt[]
}

# 5. Riepilogo a video -------------------------------------------------------

#' Stampa un riepilogo compatto dei tre dataset
#' @noRd
.print_summary <- function(lst) {
  message("\n--- gol_inapp_mensile ---")
  x <- lst$gol_inapp_mensile
  message("  righe          : ", nrow(x))
  message(
    "  date           : ",
    data.table::uniqueN(x$data_riferimento),
    " (",
    min(x$data_riferimento),
    " -> ",
    max(x$data_riferimento),
    ")"
  )
  message("  tavole         : ", paste(sort(unique(x$tavola)), collapse = ", "))
  message("  etichette      : ", data.table::uniqueN(x$etichetta))

  message("\n--- gol_storico_regionale ---")
  x <- lst$gol_storico_regionale
  message("  righe          : ", nrow(x))
  message("  temi           : ", paste(sort(unique(x$tema)), collapse = ", "))
  message(
    "  date           : ",
    data.table::uniqueN(x$data_riferimento),
    " (",
    min(x$data_riferimento),
    " -> ",
    max(x$data_riferimento),
    ")"
  )
  message("  regioni        : ", data.table::uniqueN(x$anchor))
  message("  enti           : ", paste(sort(unique(x$ente)), collapse = ", "))

  message("\n--- cob_regionale_trimestrale ---")
  x <- lst$cob_regionale_trimestrale
  message("  righe          : ", nrow(x))
  message("  regioni        : ", data.table::uniqueN(x$regione))
  message(
    "  trimestri      : ",
    data.table::uniqueN(paste(x$anno, x$trimestre)),
    " (",
    min(x$anno),
    "-Q",
    min(x[anno == min(anno), trimestre]),
    " -> ",
    max(x$anno),
    "-Q",
    max(x[anno == max(anno), trimestre]),
    ")"
  )
  message("  flussi         : ", paste(sort(unique(x$flusso)), collapse = ", "))
}
