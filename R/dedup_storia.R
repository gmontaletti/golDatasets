# =============================================================================
# Utility di deduplicazione per i dataset di storia lunga
# =============================================================================

# Priorita' delle fonti: piu' basso = piu' prioritario.
# Ordine: mapper INAPP focus > storico INAPP > MLPS > ANPAL > ALTRO.
.fonte_priorita <- function(fonte) {
  out <- rep(99L, length(fonte))
  out[grepl("^inapp_focus_", fonte)] <- 1L
  out[fonte == "inapp_mensile"] <- 1L
  out[fonte == "storico_INAPP"] <- 2L
  out[fonte == "storico_MLPS"] <- 3L
  out[fonte == "storico_ANPAL"] <- 4L
  out[fonte == "storico_ALTRO"] <- 5L
  out
}

#' Deduplica un dataset di storia lunga GOL
#'
#' Applica regole di deduplicazione in ordine sulla chiave logica indicata:
#' \enumerate{
#'   \item se piu' righe hanno `valore == 0` o `NA`, mantiene la prima riga
#'     con valore non-zero/non-NA.
#'   \item se i valori sono identici tra fonti diverse, mantiene una sola
#'     riga (la fonte di priorita' piu' alta).
#'   \item se i valori differiscono, mantiene la riga della fonte di
#'     priorita' piu' alta (inapp_focus > storico_INAPP > MLPS > ANPAL > ALTRO).
#' }
#'
#' @param data Un `data.table` long con almeno le colonne `valore` e `fonte`.
#' @param keys Vettore character delle colonne che identificano la chiave
#'   logica di un osservazione (es. `c("data_riferimento", "regione",
#'   "variabile", "percorso")`).
#'
#' @return Un `data.table` deduplicato con le stesse colonne, una riga per
#'   chiave logica.
#'
#' @examples
#' dt <- data.table::data.table(
#'   data_riferimento = as.Date("2025-01-31"),
#'   regione = "Lombardia", variabile = "x", percorso = NA,
#'   valore = c(0, 100, 100),
#'   fonte  = c("storico_ANPAL", "storico_MLPS", "storico_INAPP")
#' )
#' dedup_storia(dt, keys = c("data_riferimento", "regione",
#'                             "variabile", "percorso"))
#' # Tiene la riga storico_INAPP (priorita' piu' alta tra le non-zero)
#'
#' @importFrom data.table copy setorder := .I .SD setkeyv
#' @export
dedup_storia <- function(data, keys) {
  if (nrow(data) == 0L) {
    return(data)
  }
  stopifnot("valore" %in% names(data), "fonte" %in% names(data))
  stopifnot(all(keys %in% names(data)))

  dt <- data.table::copy(data)
  dt[, .__has_value := !is.na(valore) & valore != 0]
  dt[, .__prio := .fonte_priorita(fonte)]
  # Ordina: prima le righe con valore presente (TRUE > FALSE quando
  # ordini per -has_value), poi per priorita' di fonte crescente
  data.table::setorderv(
    dt,
    c(keys, ".__has_value", ".__prio"),
    order = c(rep(1L, length(keys)), -1L, 1L)
  )
  out <- dt[, .SD[1L], by = keys]
  out[, c(".__has_value", ".__prio") := NULL]
  out[]
}
