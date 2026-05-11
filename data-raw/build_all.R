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

# 4. File generati -----------------------------------------------------------
message("\nFile in data/:")
print(file.info(list.files("data", full.names = TRUE))[, "size", drop = FALSE])
