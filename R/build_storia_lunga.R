# =============================================================================
# Builder dei 3 dataset tematici per la storia lunga GOL 2022-2025
# -----------------------------------------------------------------------------
# Integra:
#   - gol_storico_regionale decodificato (storico_decoder) per pre-2025
#   - gol_inapp_mensile per la cadenza mensile 2025
#
# Schema comune long: data_riferimento, fonte, regione, percorso, valore,
# unita, confidenza (e variabili specifiche del tema).
# =============================================================================

#' @noRd
.build_gol_storia_volumi <- function(storico_decoded = NULL, inapp = NULL) {
  if (is.null(storico_decoded)) {
    storico_decoded <- gol_decode_storico()
  }
  if (is.null(inapp)) {
    inapp <- get("gol_inapp_mensile", envir = asNamespace("golDatasets"))
  }
  storico <- storico_decoded

  # Parte storica: tema A1
  parte_storico <- storico[
    tema == "A1" &
      !is.na(variabile) &
      variabile %in%
        c(
          "presi_in_carico_totale",
          "presi_in_carico_ass",
          "presi_in_carico_pc"
        ),
    .(
      data_riferimento,
      fonte = paste0("storico_", ente),
      regione = anchor,
      percorso = percorso,
      variabile = variabile,
      unita = unita,
      valore = valore_num,
      confidenza = confidenza,
      rescan_severity = rescan_severity
    )
  ]

  # Parte INAPP mensile: tav 1.1 (volumi anno x regione) + tav 1.2 (percorso)
  parte_inapp_11 <- inapp[
    tavola == 1.1 & dimensione == "regione",
    .(
      data_riferimento,
      fonte = "inapp_mensile",
      regione = etichetta,
      percorso = NA_character_,
      variabile = ifelse(
        variabile == "individui",
        "individui_raggiunti",
        paste0("presi_in_carico_anno_", variabile)
      ),
      unita = unita_misura,
      valore = valore,
      confidenza = "high",
      rescan_severity = "ok"
    )
  ]

  parte_inapp_12 <- inapp[
    tavola == 1.2 & dimensione == "regione",
    .(
      data_riferimento,
      fonte = "inapp_mensile",
      regione = etichetta,
      percorso = sub("_(ass|pc)$", "", variabile),
      variabile = ifelse(
        grepl("_pc$", variabile),
        "presi_in_carico_pc",
        "presi_in_carico_ass"
      ),
      unita = unita_misura,
      valore = valore,
      confidenza = "high",
      rescan_severity = "ok"
    )
  ]

  out <- data.table::rbindlist(
    list(parte_storico, parte_inapp_11, parte_inapp_12),
    use.names = TRUE
  )
  out[,
    era := ifelse(
      data_riferimento < data.table::as.IDate("2025-01-01"),
      "pre_2025",
      "post_2025"
    )
  ]
  out <- dedup_storia(
    out,
    keys = c("data_riferimento", "regione", "variabile", "percorso")
  )
  data.table::setkey(out, data_riferimento, regione, percorso, variabile)
  out[]
}

#' @noRd
.build_gol_storia_caratteristiche <- function(
  storico_decoded = NULL,
  focus_long = NULL
) {
  if (is.null(storico_decoded)) {
    storico_decoded <- gol_decode_storico()
  }
  storico <- storico_decoded

  parte_storico <- storico[
    tema == "B" & !is.na(caratteristica),
    .(
      data_riferimento,
      fonte = paste0("storico_", ente),
      regione = anchor,
      percorso = NA_character_,
      caratteristica,
      modalita,
      variabile = variabile,
      unita = unita,
      valore = valore_num,
      confidenza
    )
  ]

  if (!is.null(focus_long) && nrow(focus_long$caratteristiche) > 0L) {
    parte_storico <- data.table::rbindlist(
      list(parte_storico, focus_long$caratteristiche),
      use.names = TRUE,
      fill = TRUE
    )
  }

  parte_storico[,
    era := ifelse(
      data_riferimento < data.table::as.IDate("2025-01-01"),
      "pre_2025",
      "post_2025"
    )
  ]
  parte_storico[, rescan_severity := "ok"]
  parte_storico <- dedup_storia(
    parte_storico,
    keys = c(
      "data_riferimento",
      "regione",
      "caratteristica",
      "modalita",
      "percorso"
    )
  )
  data.table::setkey(
    parte_storico,
    data_riferimento,
    regione,
    caratteristica,
    modalita
  )
  parte_storico[]
}

#' @noRd
.build_gol_storia_esiti <- function(
  storico_decoded = NULL,
  inapp = NULL,
  focus_long = NULL
) {
  if (is.null(storico_decoded)) {
    storico_decoded <- gol_decode_storico()
  }
  if (is.null(inapp)) {
    inapp <- get("gol_inapp_mensile", envir = asNamespace("golDatasets"))
  }
  storico <- storico_decoded

  # Parte storica: tema H (occupazione) + tema F (politiche)
  parte_storico <- storico[
    tema %in% c("F", "H") & !is.na(variabile) & !grepl("^raw_col_", variabile),
    .(
      data_riferimento,
      fonte = paste0("storico_", ente),
      regione = anchor,
      percorso = NA_character_,
      variabile,
      unita,
      valore = valore_num,
      confidenza,
      tema_storico = tema
    )
  ]

  # Parte INAPP tav 2.1 (LEP, politiche, formazione)
  inapp_21 <- inapp[
    tavola == 2.1 & dimensione == "regione",
    .(
      data_riferimento,
      fonte = "inapp_mensile",
      regione = etichetta,
      percorso = NA_character_,
      variabile,
      unita = unita_misura,
      valore,
      confidenza = "high",
      tema_storico = NA_character_
    )
  ]

  # Parte INAPP tav 2.2 (occupati)
  inapp_22_reg <- inapp[
    tavola == 2.2 & dimensione == "regione" & percorso == "",
    .(
      data_riferimento,
      fonte = "inapp_mensile",
      regione = etichetta,
      percorso = NA_character_,
      variabile,
      unita = unita_misura,
      valore,
      confidenza = "high",
      tema_storico = NA_character_
    )
  ]

  inapp_22_perc <- inapp[
    tavola == 2.2 & dimensione == "regione" & percorso != "",
    .(
      data_riferimento,
      fonte = "inapp_mensile",
      regione = etichetta,
      percorso,
      variabile,
      unita = unita_misura,
      valore,
      confidenza = "high",
      tema_storico = NA_character_
    )
  ]

  parts <- list(parte_storico, inapp_21, inapp_22_reg, inapp_22_perc)
  if (!is.null(focus_long) && nrow(focus_long$esiti) > 0L) {
    parts[[length(parts) + 1L]] <- focus_long$esiti
  }
  out <- data.table::rbindlist(parts, use.names = TRUE, fill = TRUE)
  out[,
    era := ifelse(
      data_riferimento < data.table::as.IDate("2025-01-01"),
      "pre_2025",
      "post_2025"
    )
  ]
  out[, rescan_severity := "ok"]
  out <- dedup_storia(
    out,
    keys = c("data_riferimento", "regione", "variabile", "percorso")
  )
  data.table::setkey(out, data_riferimento, regione, variabile)
  out[]
}
