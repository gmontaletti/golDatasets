# =============================================================================
# Costruzione del dataset gol_method_ruptures
# -----------------------------------------------------------------------------
# Riferimento: dataset_long/README.md, sezione "Cambiamenti di definizione
# lungo la serie". Tre rotture, tutte collocate al passaggio dal formato
# pre-2025 (ANPAL/MLPS) al formato INAPP Focus GOL del 2025.
# =============================================================================

suppressPackageStartupMessages(library(data.table))

gol_method_ruptures <- data.table(
  data = as.IDate(rep("2025-01-01", 3)),
  evento = c(
    "Cambio unita': presi in carico -> individui",
    "Regione di ultima presa in carico",
    "Da 4 a 5 percorsi (Ricollocazione collettiva)"
  ),
  scope = c(
    "conteggi (A1, A2, B, E, F)",
    "assegnazione regionale (tutti i temi)",
    "colonne percorso (A1, F, H, I)"
  ),
  riferimento = "INAPP Focus GOL, formato 2025"
)

save(
  gol_method_ruptures,
  file = "data/gol_method_ruptures.rda",
  compress = "xz"
)

message("Salvato: data/gol_method_ruptures.rda")
