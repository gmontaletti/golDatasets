# =============================================================================
# Dichiarazione di variabili globali per R CMD check
# -----------------------------------------------------------------------------
# Le colonne di un data.table appaiono come simboli non legati al global env
# nel parser di R CMD check. La dichiarazione qui sotto le marca come legittime
# per silenziare il NOTE "no visible binding for global variable".
# =============================================================================

utils::globalVariables(c(
  # gol_inapp_mensile
  "data_riferimento",
  "tavola",
  "valore",
  "report_id",
  "etichetta",
  "variabile",
  "percorso",
  # gol_storico_regionale
  "quality_flag",
  "anchor",
  "valore_num",
  "col_index",
  "page",
  "tema",
  # cob_regionale_trimestrale
  "regione",
  "anno",
  "trimestre",
  "rapporti",
  "lavoratori",
  "media",
  "data_inizio_trimestre",
  "flusso"
))
