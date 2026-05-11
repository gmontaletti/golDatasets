# =============================================================================
# Test plot_timeline() e gol_method_ruptures
# =============================================================================

test_that("gol_method_ruptures ha la struttura attesa", {
  expect_s3_class(gol_method_ruptures, "data.table")
  expect_equal(nrow(gol_method_ruptures), 3L)
  expect_true(all(
    c("data", "evento", "scope", "riferimento") %in%
      names(gol_method_ruptures)
  ))
  expect_true(inherits(gol_method_ruptures$data, "IDate"))
})

test_that("plot_timeline restituisce un oggetto ggplot", {
  serie <- data.frame(
    data = as.Date(c("2024-06-30", "2024-12-31", "2025-01-31", "2025-06-30")),
    valore = c(100, 110, 120, 130)
  )
  p <- plot_timeline(serie, title = "Test")
  expect_s3_class(p, "ggplot")
})

test_that("plot_timeline accetta gol_method_ruptures e li aggrega per data", {
  serie <- data.frame(
    data = as.Date(c("2024-06-30", "2025-06-30")),
    valore = c(100, 150)
  )
  p <- plot_timeline(serie, ruptures = gol_method_ruptures)
  expect_s3_class(p, "ggplot")
  # Il plot ha almeno 4 layer: line, point, vline, label
  expect_gte(length(p$layers), 4L)
})

test_that("plot_timeline accetta una variabile di raggruppamento", {
  serie <- data.frame(
    data = rep(as.Date(c("2024-06-30", "2025-06-30")), 2),
    valore = c(100, 150, 80, 120),
    regione = rep(c("A", "B"), each = 2)
  )
  p <- plot_timeline(serie, group = "regione")
  expect_s3_class(p, "ggplot")
})
