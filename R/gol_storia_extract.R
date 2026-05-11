# =============================================================================
# Funzioni di estrazione tematica per la storia lunga GOL 2022-2025
# =============================================================================

#' Estrae una serie di volumi (presi in carico) per plot_timeline
#'
#' @param variabile Nome della variabile (es. `"presi_in_carico_totale"`,
#'   `"presi_in_carico_ass"`, `"presi_in_carico_pc"`, `"individui_raggiunti"`).
#' @param regione Vettore di etichette regionali. `NULL` = tutte.
#' @param percorso Filtro sul percorso GOL. `NULL` = tutti.
#' @param min_confidenza Default `"medium"`.
#'
#' @return Un `data.table` con colonne `data, valore, fonte` e (se
#'   multivalore) `regione`, `percorso`.
#'
#' @importFrom data.table copy uniqueN setkey
#' @export
gol_storia_volumi_series <- function(
  variabile,
  regione = NULL,
  percorso = NULL,
  min_confidenza = "medium"
) {
  data <- get("gol_storia_volumi", envir = asNamespace("golDatasets"))
  mask <- data$variabile == variabile
  if (!is.null(regione)) {
    mask <- mask & data$regione %in% regione
  }
  if (!is.null(percorso)) {
    mask <- mask & data$percorso %in% percorso
  }

  livelli <- c("high" = 3L, "medium" = 2L, "low" = 1L)
  soglia <- livelli[[min_confidenza]]
  mask <- mask & livelli[data$confidenza] >= soglia

  out <- data[
    mask,
    .(data = data_riferimento, valore, regione, percorso, fonte)
  ]
  if (nrow(out) == 0L) {
    stop("Nessuna riga corrisponde ai filtri", call. = FALSE)
  }
  if (data.table::uniqueN(out$regione) == 1L) {
    out[, regione := NULL]
  }
  if (data.table::uniqueN(out$percorso) == 1L) {
    out[, percorso := NULL]
  }
  data.table::setkey(out, NULL)
  out[order(data)]
}

#' Estrae una serie di caratteristiche dei beneficiari
#'
#' @param caratteristica Nome della caratteristica (`"genere"`, `"classe_eta"`,
#'   `"cittadinanza"`, `"durata_disoccupazione"`).
#' @param modalita Vettore di modalita' (`"Maschi"`, `"Femmine"`, `"15-29"` ...).
#'   `NULL` = tutte.
#' @param regione Filtro regionale. `NULL` = tutte.
#' @param min_confidenza Default `"medium"`.
#'
#' @return Un `data.table` pronto per `plot_timeline(group = "modalita")`.
#' @export
gol_storia_caratteristiche_series <- function(
  caratteristica,
  modalita = NULL,
  regione = NULL,
  min_confidenza = "medium"
) {
  data <- get("gol_storia_caratteristiche", envir = asNamespace("golDatasets"))
  mask <- data$caratteristica == caratteristica
  if (!is.null(modalita)) {
    mask <- mask & data$modalita %in% modalita
  }
  if (!is.null(regione)) {
    mask <- mask & data$regione %in% regione
  }

  livelli <- c("high" = 3L, "medium" = 2L, "low" = 1L)
  soglia <- livelli[[min_confidenza]]
  mask <- mask & livelli[data$confidenza] >= soglia

  out <- data[
    mask,
    .(data = data_riferimento, valore, regione, modalita, fonte)
  ]
  if (nrow(out) == 0L) {
    stop("Nessuna riga corrisponde ai filtri", call. = FALSE)
  }
  if (data.table::uniqueN(out$regione) == 1L) {
    out[, regione := NULL]
  }
  data.table::setkey(out, NULL)
  out[order(data)]
}

#' Estrae una serie di esiti (occupazionali, LEP, politiche)
#'
#' @param variabile Nome della variabile (es. `"occupati_totale"`,
#'   `"raggiunti"`, `"con_politica"`, `"lep_e"`, `"tasso_occupati_60gg"`).
#' @param regione,percorso,min_confidenza Come negli altri estrattori.
#'
#' @return Un `data.table` pronto per `plot_timeline()`.
#' @export
gol_storia_esiti_series <- function(
  variabile,
  regione = NULL,
  percorso = NULL,
  min_confidenza = "medium"
) {
  data <- get("gol_storia_esiti", envir = asNamespace("golDatasets"))
  mask <- data$variabile == variabile
  if (!is.null(regione)) {
    mask <- mask & data$regione %in% regione
  }
  if (!is.null(percorso)) {
    mask <- mask & data$percorso %in% percorso
  }

  livelli <- c("high" = 3L, "medium" = 2L, "low" = 1L)
  soglia <- livelli[[min_confidenza]]
  mask <- mask & livelli[data$confidenza] >= soglia

  out <- data[
    mask,
    .(data = data_riferimento, valore, regione, percorso, fonte)
  ]
  if (nrow(out) == 0L) {
    stop("Nessuna riga corrisponde ai filtri", call. = FALSE)
  }
  if (data.table::uniqueN(out$regione) == 1L) {
    out[, regione := NULL]
  }
  if (data.table::uniqueN(out$percorso) == 1L) {
    out[, percorso := NULL]
  }
  data.table::setkey(out, NULL)
  out[order(data)]
}
