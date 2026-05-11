# =============================================================================
# Utility per i mapper INAPP focus_gol_all -> long format
# =============================================================================

# 1. Mapping report_id -> data_riferimento -----------------------------------
# Derivato dall'analisi delle date INAPP gia' presenti in
# INAPP GOL/csv_long/tab_long_completo.csv.

.inapp_report_dates <- c(
  "INAPP_Focus-GOL_1-2025" = "2024-06-30",
  "INAPP_Focus-GOL_3-2025" = "2025-01-31",
  "INAPP_Focus-GOL_4-2025" = "2025-02-28",
  "INAPP_Focus-GOL_5-2025" = "2025-03-31",
  "INAPP_Focus-GOL_6-2025" = "2025-04-30",
  "INAPP_Focus-GOL_7-2025" = "2025-05-31",
  "INAPP_Focus-GOL_8-2025" = "2025-06-30",
  "INAPP_Focus-GOL_9-2025" = "2025-08-31",
  "INAPP_Focus-GOL_12-2025" = "2025-09-30",
  "INAPP_Focus-GOL_13-2025" = "2025-10-31",
  "INAPP_Focus-GOL_16-2025" = "2025-11-30",
  "INAPP_Focus-GOL_17-2025" = "2025-12-31"
)

# 2. Parser numerico italiano ------------------------------------------------

#' Converte stringhe numeriche in formato italiano (1.234,5) in numeric
#' @noRd
.parse_number_it <- function(x) {
  if (is.null(x) || length(x) == 0L) {
    return(numeric(0))
  }
  s <- as.character(x)
  s <- gsub("[\\s\u00a0]", "", s, perl = TRUE)
  # rimuovi punti delle migliaia, sostituisci virgola con punto
  s <- gsub("\\.", "", s, perl = TRUE)
  s <- gsub(",", ".", s, fixed = TRUE)
  s[s %in% c("", "-", "n.d.", "n.d", "..", "NA")] <- NA_character_
  suppressWarnings(as.numeric(s))
}

# 3. Splittatore di celle multi-valore --------------------------------------

#' Divide una cella con piu' valori separati da spazi/non-numeric in un
#' vettore di numerici. Utile quando tabula fonde colonne adiacenti.
#' @noRd
.split_multi_values <- function(cell) {
  if (is.na(cell) || cell == "") {
    return(numeric(0))
  }
  toks <- strsplit(cell, "\\s+")[[1]]
  .parse_number_it(toks)
}

# 4. Normalizzazione anchor regionale ---------------------------------------
# Riusa le 22 etichette canoniche definite in R/utils-regioni.R.

#' Mappa varianti di nomi regionali alle 22 etichette canoniche.
#' @noRd
.normalize_anchor_inapp <- function(x) {
  raw <- gsub("\\s+", " ", trimws(x))
  fix <- c(
    "Italia" = "Totale",
    "P.A. Bolzano-Bolzen" = "P.A. Bolzano",
    "Bolzano" = "P.A. Bolzano",
    "Trento" = "P.A. Trento",
    "Emilia Romagna" = "Emilia-Romagna",
    "Friuli Venezia Giulia" = "Friuli-Venezia Giulia",
    "Valle d'Aosta/Vallee d'Aoste" = "Valle d'Aosta"
  )
  out <- ifelse(raw %in% names(fix), unname(fix[raw]), raw)
  out
}

# 5. Lettura sicura di un CSV grezzo di focus_gol_all -----------------------

#' Legge un CSV grezzo, mantenendo tutte le righe e colonne come character.
#' Restituisce NULL se il file e' troppo piccolo per contenere dati utili.
#' @noRd
.read_focus_csv <- function(csv_path, min_rows = 5L) {
  if (!file.exists(csv_path)) {
    return(NULL)
  }
  raw <- tryCatch(
    data.table::fread(
      csv_path,
      sep = ",",
      header = FALSE,
      fill = TRUE,
      colClasses = "character",
      quote = "\""
    ),
    error = function(e) NULL
  )
  if (is.null(raw) || nrow(raw) < min_rows) {
    return(NULL)
  }
  raw
}
