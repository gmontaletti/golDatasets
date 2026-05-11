# =============================================================================
# Indicatori derivati dai flussi COB INPS
# -----------------------------------------------------------------------------
# Trasforma `cob_regionale_trimestrale` (formato long: una riga per flusso)
# in un wide-table con indicatori derivati:
#   - saldo_netto = avviamenti - cessazioni (a livello di rapporti e di
#     lavoratori distinti)
#   - rotation_*  = rapporti / lavoratori (intensita' di rotazione)
#   - yoy_*       = variazione % rispetto allo stesso trimestre dell'anno
#     precedente
# =============================================================================

#' Calcola indicatori derivati dai flussi COB
#'
#' A partire dal dataset long `cob_regionale_trimestrale`, ricompone i flussi
#' di avviamenti e cessazioni in un'unica riga per `(regione, anno, trimestre)`
#' e calcola gli indicatori derivati piu' usati per analisi di mercato del
#' lavoro regionale.
#'
#' @param data Un `data.table` con la stessa struttura di
#'   `cob_regionale_trimestrale`. Se `NULL` (default), usa il dataset esposto
#'   dal package.
#'
#' @return Un `data.table` in formato wide con una riga per
#'   `(regione, anno, trimestre)` e le seguenti colonne aggiuntive rispetto
#'   alle chiavi:
#'   \describe{
#'     \item{avviamenti_rapporti, cessazioni_rapporti}{numero di rapporti
#'       avviati / cessati nel trimestre.}
#'     \item{avviamenti_lavoratori, cessazioni_lavoratori}{numero di
#'       lavoratori distinti coinvolti.}
#'     \item{saldo_rapporti}{avviamenti_rapporti - cessazioni_rapporti.}
#'     \item{saldo_lavoratori}{avviamenti_lavoratori - cessazioni_lavoratori.}
#'     \item{rotation_avviamenti, rotation_cessazioni}{rapporti per lavoratore,
#'       indicatore di rotazione.}
#'     \item{yoy_avviamenti, yoy_cessazioni, yoy_saldo}{variazione percentuale
#'       sul corrispondente trimestre dell'anno precedente (lag 4).}
#'     \item{data_inizio_trimestre}{`IDate`, primo giorno del trimestre.}
#'   }
#'
#' @examples
#' ind <- cob_compute_indicators()
#' # Saldo netto trimestrale Emilia-Romagna
#' ind[regione == "Emilia-Romagna",
#'     .(anno, trimestre, saldo_rapporti)]
#'
#' @importFrom data.table dcast setkey shift :=
#' @export
cob_compute_indicators <- function(data = NULL) {
  if (is.null(data)) {
    data <- get("cob_regionale_trimestrale", envir = asNamespace("golDatasets"))
  }
  dt <- data.table::dcast(
    data,
    regione + anno + trimestre + data_inizio_trimestre ~ flusso,
    value.var = c("rapporti", "lavoratori", "media")
  )
  # Rinomina per leggibilita' (avviamenti/cessazioni come prefisso)
  data.table::setnames(
    dt,
    old = c(
      "rapporti_avviamenti",
      "rapporti_cessazioni",
      "lavoratori_avviamenti",
      "lavoratori_cessazioni",
      "media_avviamenti",
      "media_cessazioni"
    ),
    new = c(
      "avviamenti_rapporti",
      "cessazioni_rapporti",
      "avviamenti_lavoratori",
      "cessazioni_lavoratori",
      "rotation_avviamenti",
      "rotation_cessazioni"
    ),
    skip_absent = TRUE
  )
  dt[, saldo_rapporti := avviamenti_rapporti - cessazioni_rapporti]
  dt[, saldo_lavoratori := avviamenti_lavoratori - cessazioni_lavoratori]

  data.table::setkey(dt, regione, anno, trimestre)
  dt[,
    yoy_avviamenti := avviamenti_rapporti /
      data.table::shift(avviamenti_rapporti, 4) -
      1,
    by = regione
  ]
  dt[,
    yoy_cessazioni := cessazioni_rapporti /
      data.table::shift(cessazioni_rapporti, 4) -
      1,
    by = regione
  ]
  dt[,
    yoy_saldo := saldo_rapporti / data.table::shift(saldo_rapporti, 4) - 1,
    by = regione
  ]

  dt[]
}
