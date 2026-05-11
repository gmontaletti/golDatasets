# =============================================================================
# Estrazione di serie pronte per plot a partire dai dataset GOL
# =============================================================================

#' Estrai una serie temporale pronta per plot da `gol_inapp_mensile`
#'
#' Filtra `gol_inapp_mensile` lungo tavola, variabile, percorso, etichetta
#' regionale e unita' di misura, restituendo un `data.table` con le colonne
#' `data`, `valore` (ed eventualmente `regione`, `percorso`) pronto per
#' essere passato a [plot_timeline()].
#'
#' La tavola viene dedotta automaticamente dalla `variabile` quando
#' `tavola = NULL`. Ad esempio `variabile = "occupati_totale"` implica
#' `tavola == 2.2`, `variabile = "raggiunti"` implica `tavola == 2.1`,
#' `variabile = "individui"` o `"totale"` implicano `tavola == 1.1`.
#'
#' @param data Un `data.table` con la stessa struttura di
#'   `gol_inapp_mensile`. Se `NULL` (default), usa il dataset esposto.
#' @param variabile Nome della variabile (es. `"occupati_totale"`,
#'   `"raggiunti"`, `"individui"`, `"con_politica"`).
#' @param etichetta Vettore di etichette regionali. `NULL` (default) per
#'   tutte; passare ad esempio `"Italia"` o `"Totale"` per l'aggregato
#'   nazionale, o un vettore di regioni per il confronto.
#' @param tavola Numero di tavola (1.1, 1.2, 2.1, 2.2). `NULL` per
#'   inferenza automatica dalla `variabile`.
#' @param percorso Filtro sulla colonna `percorso`. Default `NULL`
#'   (nessun filtro: le variabili che esistono per un solo percorso
#'   restituiscono una serie unica, quelle che si decompongono mantengono
#'   la colonna `percorso`). Passare `""` per restringere all'aggregato
#'   senza disaggregazione, o un singolo percorso
#'   (`"1_reinserimento_lavorativo"`, ...) per filtrare.
#' @param unita_misura Default `"valore_assoluto"`. Altri valori possibili:
#'   `"percentuale"`, `"percentuale_riga"`.
#'
#' @return Un `data.table` con almeno le colonne `data` (IDate) e `valore`
#'   (numeric). Se `etichetta` ha piu' valori, e' presente anche `regione`.
#'   Se `percorso = NULL`, e' presente anche `percorso`.
#'
#' @examples
#' # Occupati totale, Emilia-Romagna
#' s1 <- gol_extract_series(variabile = "occupati_totale",
#'                          etichetta = "Emilia-Romagna")
#'
#' # Confronto multi-regione
#' s2 <- gol_extract_series(variabile = "raggiunti",
#'                          etichetta = c("Emilia-Romagna", "Lombardia",
#'                                        "Campania", "Sicilia"))
#'
#' # Decomposizione per percorso (Emilia-Romagna)
#' s3 <- gol_extract_series(variabile = "presi_in_carico",
#'                          etichetta = "Emilia-Romagna",
#'                          percorso = NULL)
#'
#' @importFrom data.table copy setnames
#' @export
gol_extract_series <- function(
  data = NULL,
  variabile,
  etichetta = NULL,
  tavola = NULL,
  percorso = NULL,
  unita_misura = "valore_assoluto"
) {
  if (is.null(data)) {
    data <- get("gol_inapp_mensile", envir = asNamespace("golDatasets"))
  }

  # 1. Inferenza tavola dalla variabile -------------------------------------
  if (is.null(tavola)) {
    tavola <- .infer_tavola(variabile)
  }

  # 2. Filtri base -----------------------------------------------------------
  # Maschera booleana costruita fuori dal `[]`: nessuna NSE, R CMD check
  # pulito, comportamento identico a un classico subset.
  mask <- data$tavola == tavola &
    data$variabile == variabile &
    data$dimensione == "regione" &
    data$unita_misura == unita_misura
  if (!is.null(percorso)) {
    mask <- mask & data$percorso == percorso
  }
  if (!is.null(etichetta)) {
    mask <- mask & data$etichetta %in% etichetta
  }
  dt <- data[mask]

  if (nrow(dt) == 0L) {
    stop(
      "Nessuna riga corrisponde ai filtri: variabile='",
      variabile,
      "', tavola=",
      tavola,
      ", percorso='",
      if (is.null(percorso)) "<any>" else percorso,
      "'",
      call. = FALSE
    )
  }

  # 3. Selezione colonne pronte per plot -----------------------------------
  out <- data.table::copy(dt[, .(
    data = data_riferimento,
    valore,
    regione = etichetta,
    percorso
  )])

  # Se una sola regione, rimuovi la colonna `regione`
  if (data.table::uniqueN(out$regione) == 1L) {
    out[, regione := NULL]
  }
  # Se percorso e' fissato a un singolo valore, rimuovilo
  if (data.table::uniqueN(out$percorso) == 1L) {
    out[, percorso := NULL]
  }

  data.table::setkey(out, NULL)
  out[order(data)]
}

# Helper interno: associa variabile -> tavola di default
#' @noRd
.infer_tavola <- function(variabile) {
  tav <- switch(
    variabile,
    "2022" = 1.1,
    "2023" = 1.1,
    "2024" = 1.1,
    "2025" = 1.1,
    "incidenza_pc" = 1.1,
    "individui" = 1.1,
    "totale" = 1.1,
    "raggiunti" = 2.1,
    "con_politica" = 2.1,
    "con_politica_pc" = 2.1,
    "con_pol_o_tiroc" = 2.1,
    "con_pol_o_tiroc_pc" = 2.1,
    "c07_form_incl_dig" = 2.1,
    "c11_form_no_dig" = 2.1,
    "c12_form_spec_dig" = 2.1,
    "tirocinio_co" = 2.1,
    "lep_e" = 2.1,
    "lep_f1" = 2.1,
    "lep_f2" = 2.1,
    "lep_h" = 2.1,
    "lep_j" = 2.1,
    "lep_o" = 2.1,
    "presi_in_carico" = 2.2,
    "gia_occupati" = 2.2,
    "gia_occupati_pc" = 2.2,
    "nuovi_occupati" = 2.2,
    "nuovi_occupati_pc" = 2.2,
    "occupati_totale" = 2.2,
    "occupati_pc" = 2.2,
    "quota_nuovi_su_occ" = 2.2,
    NULL
  )
  if (is.null(tav)) {
    stop(
      "Impossibile inferire la tavola per variabile = '",
      variabile,
      "'. Specifica esplicitamente il parametro `tavola`.",
      call. = FALSE
    )
  }
  tav
}
