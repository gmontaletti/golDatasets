# =============================================================================
# Test gol_extract_series()
# =============================================================================

test_that("Singola regione: ritorna data + valore, niente regione/percorso", {
  s <- gol_extract_series(
    variabile = "occupati_totale",
    etichetta = "Emilia-Romagna"
  )
  expect_s3_class(s, "data.table")
  expect_setequal(names(s), c("data", "valore"))
  expect_gte(nrow(s), 12L)
  expect_true(all(!is.na(s$valore)))
})

test_that("Multi-regione: aggiunge la colonna regione", {
  s <- gol_extract_series(
    variabile = "raggiunti",
    etichetta = c("Emilia-Romagna", "Lombardia", "Campania", "Sicilia")
  )
  expect_true("regione" %in% names(s))
  expect_equal(data.table::uniqueN(s$regione), 4L)
})

test_that("Inferenza tavola dalla variabile", {
  s_raggiunti <- gol_extract_series(
    variabile = "raggiunti",
    etichetta = "Totale"
  )
  expect_gt(nrow(s_raggiunti), 0L)

  s_occupati <- gol_extract_series(
    variabile = "occupati_totale",
    etichetta = "Totale"
  )
  expect_gt(nrow(s_occupati), 0L)

  s_individui <- gol_extract_series(
    variabile = "individui",
    etichetta = "Totale"
  )
  expect_gt(nrow(s_individui), 0L)
})

test_that("Variabile sconosciuta -> errore esplicito", {
  expect_error(
    gol_extract_series(variabile = "foobar_inesistente"),
    "Impossibile inferire la tavola"
  )
})

test_that("Filtri che non matchano -> errore esplicito", {
  expect_error(
    gol_extract_series(variabile = "occupati_totale", etichetta = "Marte"),
    "Nessuna riga corrisponde ai filtri"
  )
})

test_that("Tavola passata esplicitamente sovrascrive l'inferenza", {
  s <- gol_extract_series(
    variabile = "1_reinserimento_lavorativo_ass",
    etichetta = "Lombardia",
    tavola = 1.2
  )
  expect_s3_class(s, "data.table")
  expect_gt(nrow(s), 0L)
})
