# =============================================================================
# Script di costruzione dei tre dataset canonici GOL
# -----------------------------------------------------------------------------
# Esecuzione (dalla radice del repo):
#
#   Rscript data-raw/build_all.R
#
# Carica gli helper in `R/`, invoca `build_gol_datasets()` e scrive i tre
# file `.rda` in `data/`. Eseguito controllo di coerenza minimo sui valori
# di ritorno.
# =============================================================================

# 1. Setup -------------------------------------------------------------------
suppressPackageStartupMessages(library(data.table))

# Sorgenti R: load_all manuale (non c'e' ancora DESCRIPTION / NAMESPACE).
source("R/utils-regioni.R")
source("R/build_datasets.R")
source("R/gol_quality.R")
source("R/storico_decoder.R")
source("R/build_storia_lunga.R")
source("R/inapp_focus_helpers.R")
source("R/inapp_focus_mappers.R")

# 2. Build -------------------------------------------------------------------
out <- build_gol_datasets(
  input_root = ".",
  output_dir = "data",
  overwrite = TRUE,
  verbose = TRUE
)

# 3. Verifiche di coerenza ---------------------------------------------------
message("\n--- Verifiche ---")
stopifnot(
  "gol_inapp_mensile: nessun report" = nrow(out$gol_inapp_mensile) > 0L,
  "gol_inapp_mensile: meno di 12 date" = data.table::uniqueN(
    out$gol_inapp_mensile$data_riferimento
  ) >=
    12L,
  "gol_inapp_mensile: tavole inattese" = all(
    sort(unique(out$gol_inapp_mensile$tavola)) %in% c(1.1, 1.2, 2.1, 2.2)
  ),

  "gol_storico_regionale: temi inattesi" = all(
    out$gol_storico_regionale$tema %in% c("A1", "B", "F", "H")
  ),
  "gol_storico_regionale: anchor non canonici" = all(
    out$gol_storico_regionale$anchor %in% .canonical_regioni
  ),
  "gol_storico_regionale: quality_flag != ok" = all(
    out$gol_storico_regionale$quality_flag == "ok"
  ),
  "gol_storico_regionale: meno di 25 date" = data.table::uniqueN(
    out$gol_storico_regionale$data_riferimento
  ) >=
    25L,

  "cob: regioni != 21" = data.table::uniqueN(
    out$cob_regionale_trimestrale$regione
  ) ==
    21L,
  "cob: trimestri attesi >= 35" = data.table::uniqueN(paste(
    out$cob_regionale_trimestrale$anno,
    out$cob_regionale_trimestrale$trimestre
  )) >=
    35L,
  "cob: flussi inattesi" = setequal(
    unique(out$cob_regionale_trimestrale$flusso),
    c("avviamenti", "cessazioni")
  )
)
message("Tutte le verifiche superate.")

# 3.5 Snapshot raccomandazioni di rescanning ---------------------------------
gol_rescan_recommendations <- gol_storico_quality(out$gol_storico_regionale)
gol_rescan_recommendations <- gol_rescan_recommendations[severity != "ok"]
save(
  gol_rescan_recommendations,
  file = "data/gol_rescan_recommendations.rda",
  compress = "xz"
)
message(
  "Salvato: data/gol_rescan_recommendations.rda (",
  nrow(gol_rescan_recommendations),
  " righe non-ok)"
)

# 3.6 Decoder semantico + 3 dataset di storia lunga -------------------------
message("\n--- Build decoder + storia lunga ---")
# Lo scaffold del decoder e' generato da data-raw/build_storico_decoder.R
# che va eseguito separatamente. Carica il .rda gia' costruito.
if (file.exists("data/storico_decoder.rda")) {
  load("data/storico_decoder.rda")
  message("Decoder caricato: ", nrow(storico_decoder), " righe")

  # Decodifica inline (non chiamiamo gol_decode_storico perche' cerca il
  # namespace del package non ancora installato)
  d <- data.table::copy(out$gol_storico_regionale)
  d[,
    era := ifelse(
      data_riferimento < data.table::as.IDate("2025-01-01"),
      "pre_2025",
      "post_2025"
    )
  ]
  storico_decoded <- merge(
    d,
    storico_decoder[, .(
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

  # Mapper INAPP focus_gol_all
  focus_long <- build_inapp_focus_long()
  message(
    "INAPP focus mappers: ",
    nrow(focus_long$caratteristiche),
    " righe caratteristiche, ",
    nrow(focus_long$esiti),
    " righe esiti"
  )

  gol_storia_volumi <- .build_gol_storia_volumi(
    storico_decoded = storico_decoded,
    inapp = out$gol_inapp_mensile
  )
  gol_storia_caratteristiche <- .build_gol_storia_caratteristiche(
    storico_decoded = storico_decoded,
    focus_long = focus_long
  )
  gol_storia_esiti <- .build_gol_storia_esiti(
    storico_decoded = storico_decoded,
    inapp = out$gol_inapp_mensile,
    focus_long = focus_long
  )

  save(gol_storia_volumi, file = "data/gol_storia_volumi.rda", compress = "xz")
  save(
    gol_storia_caratteristiche,
    file = "data/gol_storia_caratteristiche.rda",
    compress = "xz"
  )
  save(gol_storia_esiti, file = "data/gol_storia_esiti.rda", compress = "xz")

  message("Salvato: gol_storia_volumi (", nrow(gol_storia_volumi), " righe)")
  message(
    "Salvato: gol_storia_caratteristiche (",
    nrow(gol_storia_caratteristiche),
    " righe)"
  )
  message("Salvato: gol_storia_esiti (", nrow(gol_storia_esiti), " righe)")
} else {
  message(
    "Decoder non presente: eseguire Rscript data-raw/build_storico_decoder.R"
  )
}

# 4. File generati -----------------------------------------------------------
message("\nFile in data/:")
print(file.info(list.files("data", full.names = TRUE))[, "size", drop = FALSE])
