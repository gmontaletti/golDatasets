# =============================================================================
# Smoke test sui tre dataset esposti dal package
# =============================================================================

test_that("gol_inapp_mensile carica con la struttura attesa", {
  data("gol_inapp_mensile", package = "golDatasets")
  expect_s3_class(gol_inapp_mensile, "data.table")
  expect_true(all(
    c(
      "report_id",
      "data_riferimento",
      "tavola",
      "etichetta",
      "variabile",
      "percorso",
      "unita_misura",
      "valore"
    ) %in%
      names(gol_inapp_mensile)
  ))
  expect_gte(nrow(gol_inapp_mensile), 10000L)
  expect_gte(data.table::uniqueN(gol_inapp_mensile$data_riferimento), 12L)
  expect_true(all(
    sort(unique(gol_inapp_mensile$tavola)) %in%
      c(1.1, 1.2, 2.1, 2.2)
  ))
})

test_that("gol_storico_regionale e' filtrato a temi e quality_flag attesi", {
  data("gol_storico_regionale", package = "golDatasets")
  expect_s3_class(gol_storico_regionale, "data.table")
  expect_true(all(gol_storico_regionale$tema %in% c("A1", "B", "F", "H")))
  expect_true(all(gol_storico_regionale$quality_flag == "ok"))
  expect_gte(data.table::uniqueN(gol_storico_regionale$data_riferimento), 25L)
})

test_that("cob_regionale_trimestrale ha le 21 regioni canoniche", {
  data("cob_regionale_trimestrale", package = "golDatasets")
  expect_s3_class(cob_regionale_trimestrale, "data.table")
  expect_equal(data.table::uniqueN(cob_regionale_trimestrale$regione), 21L)
  expect_setequal(
    unique(cob_regionale_trimestrale$flusso),
    c("avviamenti", "cessazioni")
  )
  expect_gte(
    data.table::uniqueN(paste(
      cob_regionale_trimestrale$anno,
      cob_regionale_trimestrale$trimestre
    )),
    35L
  )
  expect_true(inherits(
    cob_regionale_trimestrale$data_inizio_trimestre,
    "IDate"
  ))
})

test_that("build_gol_datasets e' esportato e ha la firma attesa", {
  expect_true(exists(
    "build_gol_datasets",
    envir = asNamespace("golDatasets"),
    inherits = FALSE
  ))
  args <- names(formals(build_gol_datasets))
  expect_setequal(args, c("input_root", "output_dir", "overwrite", "verbose"))
})
