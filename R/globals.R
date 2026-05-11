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
  "dimensione",
  "unita_misura",
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
  "flusso",
  # cob_compute_indicators
  "avviamenti_rapporti",
  "cessazioni_rapporti",
  "avviamenti_lavoratori",
  "cessazioni_lavoratori",
  "saldo_rapporti",
  "saldo_lavoratori",
  "rotation_avviamenti",
  "rotation_cessazioni",
  "yoy_avviamenti",
  "yoy_cessazioni",
  "yoy_saldo",
  # plot_timeline
  "evento",
  "label",
  ".",
  # gol_quality
  "n_anchor",
  "pct_na_valore",
  "n_header_variants",
  "n_col_index",
  "header_per_col",
  "n_rows",
  "severity",
  "rescan_severity",
  "header_above",
  "caption_num",
  "caption_title",
  "ente",
  "file",
  "titolo_tabella",
  # storico_decoder + storia lunga
  "era",
  "variabile",
  "caratteristica",
  "modalita",
  "unita",
  "confidenza",
  "fonte",
  "storico_decoder",
  "gol_storico_regionale",
  "gol_inapp_mensile",
  "gol_storia_volumi",
  "gol_storia_caratteristiche",
  "gol_storia_esiti",
  # inapp_focus_mappers
  "V1",
  "percorso_id",
  # dedup_storia
  ".__has_value",
  ".__prio",
  # .warn_if_overplot
  "N"
))
