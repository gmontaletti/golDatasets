# =============================================================================
# Valutazione di qualita' delle estrazioni in gol_storico_regionale
# -----------------------------------------------------------------------------
# Identifica i (file, tema, caption_num) le cui estrazioni dai PDF di
# origine sono incomplete o rumorose, e propone una severita' per il
# rescanning. Pensata per essere chiamata sul dataset esposto dopo la build
# (o su una sua copia user-supplied).
# =============================================================================

# 1. Classificatore -----------------------------------------------------------

#' Classifica la qualita' di un'estrazione GOL storica
#'
#' Applica una scala discreta di severita' a un insieme di metriche
#' aggregate per `(file, tema, caption_num)`. La scala e' calibrata sui
#' valori osservati nei 27 PDF di monitoraggio GOL 2022-2025.
#'
#' @param n_anchor Numero di anchor regionali distinti riconosciuti
#'   (atteso: 21-22).
#' @param pct_na_valore Percentuale di righe con `valore_num` non parsabile
#'   (0-1).
#' @param n_header_variants Numero di stringhe `header_above` distinte.
#' @param n_col_index Numero di `col_index` distinti.
#'
#' @return Un character vector della stessa lunghezza degli input con
#'   valori in `c("ok", "review", "rescan_low", "rescan_high", "rescan_critical")`.
#'
#' @importFrom data.table fcase
#' @export
gol_quality_classify <- function(
  n_anchor,
  pct_na_valore,
  n_header_variants,
  n_col_index
) {
  header_per_col <- n_header_variants / pmax(n_col_index, 1L)
  data.table::fcase(
    # TIER 1: dati inutilizzabili (rimpiazzo/re-estrazione obbligatori)
    n_anchor < 5 | pct_na_valore > 0.5                             ,
    "rescan_critical"                                              ,
    # TIER 2: forte degrado (re-estrazione altamente raccomandata)
    n_anchor < 19                                                  ,
    "rescan_high"                                                  ,
    # TIER 3: una o due regioni mancanti
    n_anchor < 21                                                  ,
    "rescan_low"                                                   ,
    # TIER 4: ok
    n_anchor >= 21 & pct_na_valore <= 0.05 & header_per_col <= 1.5 ,
    "ok"                                                           ,
    # Default: rumore header alto ma dato completo
    default = "review"
  )
}

# 2. Calcolo delle metriche ---------------------------------------------------

#' Calcola le metriche di qualita' per `gol_storico_regionale`
#'
#' Per ogni `(file, tema, caption_num)` produce 4 metriche aggregate e
#' assegna una severita' usando [gol_quality_classify()].
#'
#' @param data Un `data.table` con la stessa struttura di
#'   `gol_storico_regionale`. Se `NULL` (default), usa il dataset esposto.
#'
#' @return Un `data.table` con le colonne `file, ente, data_riferimento,
#'   tema, caption_num, n_rows, n_anchor, n_col_index, n_header_variants,
#'   pct_na_valore, header_per_col, severity`. Ordinato per severita'
#'   decrescente.
#'
#' @examples
#' q <- gol_storico_quality()
#' q[severity != "ok", .N, by = .(ente, severity)]
#'
#' @importFrom data.table :=
#' @export
gol_storico_quality <- function(data = NULL) {
  if (is.null(data)) {
    data <- get("gol_storico_regionale", envir = asNamespace("golDatasets"))
  }
  q <- data[,
    .(
      ente = ente[1],
      data_riferimento = data_riferimento[1],
      n_rows = .N,
      n_anchor = data.table::uniqueN(anchor),
      n_col_index = data.table::uniqueN(col_index),
      n_header_variants = data.table::uniqueN(header_above),
      pct_na_valore = mean(is.na(valore_num))
    ),
    by = .(file, tema, caption_num)
  ]

  q[, header_per_col := n_header_variants / pmax(n_col_index, 1L)]
  q[,
    severity := gol_quality_classify(
      n_anchor,
      pct_na_valore,
      n_header_variants,
      n_col_index
    )
  ]

  severity_order <- c(
    "rescan_critical",
    "rescan_high",
    "rescan_low",
    "review",
    "ok"
  )
  q[, severity := factor(severity, levels = severity_order)]
  data.table::setorder(q, severity, -n_rows)
  q[, severity := as.character(severity)]
  q[]
}
