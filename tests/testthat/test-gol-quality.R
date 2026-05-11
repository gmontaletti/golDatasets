# =============================================================================
# Test gol_quality_classify(), gol_storico_quality(), gol_rescan_recommendations
# =============================================================================

test_that("gol_quality_classify riconosce le 5 categorie", {
  out <- gol_quality_classify(
    n_anchor = c(1, 10, 20, 22, 22),
    pct_na_valore = c(0.9, 0, 0, 0.02, 0),
    n_header_variants = c(5, 3, 3, 2, 8),
    n_col_index = c(10, 10, 10, 10, 4)
  )
  expect_equal(
    out,
    c("rescan_critical", "rescan_high", "rescan_low", "ok", "review")
  )
})

test_that("gol_storico_quality ritorna data.table con severity valide", {
  q <- gol_storico_quality()
  expect_s3_class(q, "data.table")
  expect_true(all(
    q$severity %in%
      c("ok", "review", "rescan_low", "rescan_high", "rescan_critical")
  ))
  expect_true(all(
    c(
      "file",
      "ente",
      "tema",
      "caption_num",
      "n_anchor",
      "severity",
      "header_per_col"
    ) %in%
      names(q)
  ))
})

test_that("Post-rebuild: INAPP A1/1.2 ha 22 anchor per ogni file", {
  q <- gol_storico_quality()
  inapp_a1_12 <- q[ente == "INAPP" & tema == "A1" & caption_num == "1.2"]
  expect_true(all(inapp_a1_12$n_anchor >= 22))
})

test_that("rescan_severity coerente con la fonte", {
  data("gol_storico_regionale", package = "golDatasets")
  expect_true("rescan_severity" %in% names(gol_storico_regionale))
  expect_true(all(
    gol_storico_regionale$rescan_severity %in%
      c("ok", "rescan_low", "replaced_from_inapp_csv_long")
  ))
  # Le righe rimpiazzate riguardano solo INAPP A1/1.2
  repl <- gol_storico_regionale[
    rescan_severity == "replaced_from_inapp_csv_long"
  ]
  expect_true(all(repl$tema == "A1"))
  expect_true(all(repl$caption_num == "1.2"))
  expect_true(all(repl$ente == "INAPP"))
})

test_that("gol_rescan_recommendations non e' vuoto", {
  data("gol_rescan_recommendations", package = "golDatasets")
  expect_s3_class(gol_rescan_recommendations, "data.table")
  expect_gt(nrow(gol_rescan_recommendations), 0L)
  expect_true(all(gol_rescan_recommendations$severity != "ok"))
})

test_that("Nessuna duplicazione (file, anchor, tema, caption_num, col_index)", {
  data("gol_storico_regionale", package = "golDatasets")
  k <- gol_storico_regionale[,
    .N,
    by = .(file, anchor, tema, caption_num, col_index)
  ]
  expect_true(all(k$N == 1L))
})
