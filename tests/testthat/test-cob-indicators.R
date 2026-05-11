# =============================================================================
# Test cob_compute_indicators()
# =============================================================================

test_that("cob_compute_indicators produce 21 regioni x 35 trimestri", {
  ind <- cob_compute_indicators()
  expect_s3_class(ind, "data.table")
  expect_equal(nrow(ind), 21L * 35L)
  expect_equal(data.table::uniqueN(ind$regione), 21L)
})

test_that("Tutti gli indicatori derivati sono presenti", {
  ind <- cob_compute_indicators()
  expected <- c(
    "avviamenti_rapporti",
    "cessazioni_rapporti",
    "avviamenti_lavoratori",
    "cessazioni_lavoratori",
    "rotation_avviamenti",
    "rotation_cessazioni",
    "saldo_rapporti",
    "saldo_lavoratori",
    "yoy_avviamenti",
    "yoy_cessazioni",
    "yoy_saldo"
  )
  expect_true(all(expected %in% names(ind)))
})

test_that("saldo_rapporti coincide con avviamenti - cessazioni", {
  ind <- cob_compute_indicators()
  expect_equal(
    ind$saldo_rapporti,
    ind$avviamenti_rapporti - ind$cessazioni_rapporti
  )
})

test_that("yoy e' NA nei primi 4 trimestri di ogni regione", {
  ind <- cob_compute_indicators()
  primi4 <- ind[anno == 2017 & trimestre <= 4]
  expect_true(all(is.na(primi4$yoy_avviamenti)))
})

test_that("rotation_avviamenti = rapporti / lavoratori", {
  ind <- cob_compute_indicators()
  expect_equal(
    ind$rotation_avviamenti,
    ind$avviamenti_rapporti / ind$avviamenti_lavoratori,
    tolerance = 1e-6
  )
})
