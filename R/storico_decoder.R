# =============================================================================
# Decodifica semantica di gol_storico_regionale via storico_decoder
# =============================================================================

#' Applica il decoder semantico a gol_storico_regionale
#'
#' Aggiunge le colonne `variabile`, `caratteristica`, `modalita`, `percorso`,
#' `unita`, `confidenza` derivate dal lookup `storico_decoder` su
#' `(tema, caption_num, col_index, era)`. La colonna `era` viene calcolata
#' al volo da `data_riferimento` (cut a 2025-01-01).
#'
#' @param data Un `data.table` con la stessa struttura di
#'   `gol_storico_regionale`. Se `NULL` (default), usa il dataset esposto.
#' @param min_confidenza Tiene solo le righe con `confidenza >=` il livello
#'   indicato. Default `"low"` (tutte). Per analisi rigorose usare `"high"`.
#'
#' @return Un `data.table` con le colonne originali piu' quelle semantiche.
#'
#' @examples
#' d <- gol_decode_storico()
#' d[tema == "A1" & confidenza == "high",
#'   .(data_riferimento, anchor, variabile, percorso, valore_num)]
#'
#' @importFrom data.table copy as.IDate setkey :=
#' @export
gol_decode_storico <- function(data = NULL, min_confidenza = "low") {
  if (is.null(data)) {
    data <- get("gol_storico_regionale", envir = asNamespace("golDatasets"))
  }
  decoder <- get("storico_decoder", envir = asNamespace("golDatasets"))

  d <- data.table::copy(data)
  d[,
    era := ifelse(
      data_riferimento < data.table::as.IDate("2025-01-01"),
      "pre_2025",
      "post_2025"
    )
  ]

  out <- merge(
    d,
    decoder[, .(
      tema,
      caption_num,
      col_index,
      era,
      variabile,
      caratteristica,
      modalita,
      percorso,
      unita,
      confidenza
    )],
    by = c("tema", "caption_num", "col_index", "era"),
    all.x = TRUE,
    sort = FALSE
  )

  # Filtro confidenza
  livelli <- c("high" = 3L, "medium" = 2L, "low" = 1L)
  soglia <- livelli[[min_confidenza]]
  out <- out[
    is.na(confidenza) |
      livelli[confidenza] >= soglia
  ]
  out[]
}
