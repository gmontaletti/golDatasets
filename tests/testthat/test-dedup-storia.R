# =============================================================================
# Test dedup_storia() e unicita' delle chiavi nei 3 dataset storia
# =============================================================================

test_that("dedup_storia mantiene una sola riga per chiave", {
  dt <- data.table::data.table(
    data_riferimento = as.Date("2025-01-31"),
    regione = "Lombardia",
    variabile = "x",
    percorso = NA_character_,
    valore = c(0, 100, 100),
    fonte = c("storico_ANPAL", "storico_MLPS", "storico_INAPP")
  )
  out <- dedup_storia(
    dt,
    keys = c("data_riferimento", "regione", "variabile", "percorso")
  )
  expect_equal(nrow(out), 1L)
})

test_that("dedup_storia preferisce valore non-zero", {
  dt <- data.table::data.table(
    data_riferimento = as.Date("2025-01-31"),
    regione = "Lazio",
    variabile = "x",
    percorso = NA_character_,
    valore = c(0, 50),
    fonte = c("storico_INAPP", "storico_MLPS")
  )
  out <- dedup_storia(
    dt,
    keys = c("data_riferimento", "regione", "variabile", "percorso")
  )
  expect_equal(out$valore, 50)
})

test_that("dedup_storia preferisce fonte di priorita' piu' alta", {
  dt <- data.table::data.table(
    data_riferimento = as.Date("2025-01-31"),
    regione = "Sicilia",
    variabile = "x",
    percorso = NA_character_,
    valore = c(100, 100, 100),
    fonte = c("storico_ANPAL", "storico_MLPS", "inapp_focus_X_t13")
  )
  out <- dedup_storia(
    dt,
    keys = c("data_riferimento", "regione", "variabile", "percorso")
  )
  expect_equal(nrow(out), 1L)
  expect_equal(out$fonte, "inapp_focus_X_t13")
})

test_that("dedup_storia preferisce valore valorizzato a NA", {
  dt <- data.table::data.table(
    data_riferimento = as.Date("2025-01-31"),
    regione = "Veneto",
    variabile = "x",
    percorso = NA_character_,
    valore = c(NA_real_, 200),
    fonte = c("storico_INAPP", "storico_MLPS")
  )
  out <- dedup_storia(
    dt,
    keys = c("data_riferimento", "regione", "variabile", "percorso")
  )
  expect_equal(out$valore, 200)
})

test_that("Nessun duplicato residuo nei 3 dataset storia", {
  data("gol_storia_volumi", package = "golDatasets")
  data("gol_storia_caratteristiche", package = "golDatasets")
  data("gol_storia_esiti", package = "golDatasets")
  expect_equal(
    gol_storia_volumi[,
      .N,
      by = c("data_riferimento", "regione", "variabile", "percorso")
    ][N > 1, .N],
    0L
  )
  expect_equal(
    gol_storia_caratteristiche[,
      .N,
      by = c(
        "data_riferimento",
        "regione",
        "caratteristica",
        "modalita",
        "percorso"
      )
    ][N > 1, .N],
    0L
  )
  expect_equal(
    gol_storia_esiti[,
      .N,
      by = c("data_riferimento", "regione", "variabile", "percorso")
    ][N > 1, .N],
    0L
  )
})

test_that("in_formazione ha ora una sola riga per (data, regione)", {
  data("gol_storia_esiti", package = "golDatasets")
  k <- gol_storia_esiti[
    variabile == "in_formazione",
    .N,
    by = .(data_riferimento, regione)
  ][N > 1]
  expect_equal(nrow(k), 0L)
})
