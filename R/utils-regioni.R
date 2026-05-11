# =============================================================================
# Utility per la normalizzazione delle etichette regionali GOL
# =============================================================================

# 1. Etichette canoniche -----------------------------------------------------
# Riferimento: dataset_long/README.md riga 44. Lista delle 22 etichette
# regionali standard usate nei file `gol_*_long.csv` e in
# `INAPP GOL/csv_long/tab_long_completo.csv`. Comprende le due PPAA
# (Bolzano, Trento) e l'aggregato nazionale (`Totale` o `Italia`).

.canonical_regioni <- c(
  "Abruzzo",
  "Basilicata",
  "P.A. Bolzano",
  "Calabria",
  "Campania",
  "Emilia-Romagna",
  "Friuli-Venezia Giulia",
  "Lazio",
  "Liguria",
  "Lombardia",
  "Marche",
  "Molise",
  "Piemonte",
  "Puglia",
  "Sardegna",
  "Sicilia",
  "Toscana",
  "P.A. Trento",
  "Umbria",
  "Valle d'Aosta",
  "Veneto",
  "Totale"
)

# Le 21 regioni/PPAA escluso l'aggregato nazionale.
.regioni_21 <- setdiff(.canonical_regioni, "Totale")

# 2. Mappatura nomi COB -> forma canonica ------------------------------------
# Le Comunicazioni Obbligatorie (file `cob/`) usano forme non standard:
# - PPAA senza prefisso `P.A.`
# - alcuni nomi senza trattino (`Emilia Romagna`, `Friuli Venezia Giulia`)
# - bilinguismo (`Bolzano/Bolzen`, bilingue per Valle d'Aosta)
# - marker `N.D. (c )` (dato non disponibile) e `Totale (d)` (aggregato),
#   mappati a NA per essere filtrati a valle.
#
# Caratteri non-ASCII espressi con escape Unicode per portabilita' CRAN:
#   \u2019 = apostrofo tipografico, \u00e9 = e con accento acuto.

.cob_region_map <- c(
  "Bolzano/Bolzen"                                  = "P.A. Bolzano",
  "Trento"                                          = "P.A. Trento",
  "Emilia Romagna"                                  = "Emilia-Romagna",
  "Friuli Venezia Giulia"                           = "Friuli-Venezia Giulia",
  "Valle d\u2019Aosta/Vall\u00e9e d\u2019Aoste"     = "Valle d'Aosta",
  "Valle d'Aosta/Vall\u00e9e d'Aoste"               = "Valle d'Aosta",
  "N.D. (c )"                                       = NA_character_,
  "Totale (d)"                                      = NA_character_
)

#' Normalizza nomi regionali COB alle 22 etichette canoniche GOL
#'
#' Mappa le forme non canoniche presenti nel file COB INPS
#' (`co_regionale_avviamenti_cessazioni_long.csv`) alle etichette canoniche
#' usate nei dataset GOL. Le righe `N.D.` e `Totale` ritornano `NA`,
#' permettendo al chiamante di filtrarle.
#'
#' @param x Vettore character con le etichette regionali COB originali.
#' @return Vettore character della stessa lunghezza con i nomi canonici;
#'   `NA_character_` per i marker non regionali.
#' @noRd
.normalize_regioni_cob <- function(x) {
  mapped <- unname(.cob_region_map[x])
  # Per le etichette gia' canoniche (Abruzzo, Lazio, ...) la lookup ritorna
  # NA; ripristiniamo il valore originale. Solo le chiavi della mappa
  # producono NA "vero" (N.D. e Totale).
  keys <- names(.cob_region_map)
  out <- ifelse(x %in% keys, mapped, x)
  out
}
