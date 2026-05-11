# =============================================================================
# Test storico_decoder, gol_decode_storico, gol_storia_*
# =============================================================================

test_that("storico_decoder ha la struttura attesa", {
  data("storico_decoder", package = "golDatasets")
  expect_s3_class(storico_decoder, "data.table")
  expect_gte(nrow(storico_decoder), 200L)
  expect_true(all(
    c("tema", "caption_num", "col_index", "era", "variabile", "confidenza") %in%
      names(storico_decoder)
  ))
  expect_true(all(storico_decoder$tema %in% c("A1", "B", "F", "H")))
  expect_true(all(
    storico_decoder$confidenza %in%
      c("high", "medium", "low")
  ))
})

test_that("gol_decode_storico arricchisce con colonne semantiche", {
  d <- gol_decode_storico()
  expect_true(all(c("variabile", "confidenza", "era") %in% names(d)))
  expect_true(any(d$confidenza == "high"))
  expect_gte(nrow(d), 20000L)
})

test_that("gol_storia_volumi e' lungo e ha le colonne attese", {
  data("gol_storia_volumi", package = "golDatasets")
  expect_s3_class(gol_storia_volumi, "data.table")
  expect_gte(nrow(gol_storia_volumi), 5000L)
  expect_true(all(
    c("data_riferimento", "fonte", "regione", "variabile", "valore", "era") %in%
      names(gol_storia_volumi)
  ))
  # Copre piu' di 20 date distinte
  expect_gte(data.table::uniqueN(gol_storia_volumi$data_riferimento), 20L)
})

test_that("gol_storia_volumi_series filtra per variabile", {
  s <- gol_storia_volumi_series(
    variabile = "presi_in_carico_totale",
    regione = "Totale"
  )
  expect_s3_class(s, "data.table")
  expect_true("data" %in% names(s))
  expect_true("valore" %in% names(s))
  expect_gte(nrow(s), 1L)
})

test_that("gol_storia_caratteristiche_series filtra per genere", {
  s <- gol_storia_caratteristiche_series(
    caratteristica = "genere",
    regione = "Totale"
  )
  expect_s3_class(s, "data.table")
  expect_true("modalita" %in% names(s))
  expect_true(all(s$modalita %in% c("Maschi", "Femmine", "Totale")))
})

test_that("gol_storia_esiti_series funziona per lep_e", {
  s <- gol_storia_esiti_series(variabile = "lep_e", regione = "Totale")
  expect_s3_class(s, "data.table")
  expect_gte(nrow(s), 1L)
  expect_true(all(s$valore > 0))
})

test_that("Errore esplicito per variabile inesistente", {
  expect_error(
    gol_storia_volumi_series(variabile = "non_esiste_proprio"),
    "Nessuna riga"
  )
})
