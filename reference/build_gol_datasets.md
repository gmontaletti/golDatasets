# Costruisce i tre dataset canonici GOL e li scrive in `data/`

Legge i CSV grezzi presenti nel repository e produce tre `data.table`
normalizzati:

## Usage

``` r
build_gol_datasets(
  input_root = ".",
  output_dir = "data",
  overwrite = TRUE,
  verbose = TRUE
)
```

## Arguments

- input_root:

  Radice del repository (contiene `dataset_long/`, `INAPP GOL/`,
  `cob/`). Default: directory corrente.

- output_dir:

  Cartella di destinazione dei file `.rda`. Creata se mancante. Default:
  `"data"`.

- overwrite:

  Se `FALSE`, salta i file gia' presenti in `output_dir`.

- verbose:

  Se `TRUE` stampa un riepilogo per dataset.

## Value

Invisibilmente, una lista con i tre `data.table`: `gol_inapp_mensile`,
`gol_storico_regionale`, `cob_regionale_trimestrale`.

## Details

- `gol_inapp_mensile`: serie mensile INAPP Focus GOL 2024-06 -\> 2025-12
  (long format gia' normalizzato).

- `gol_storico_regionale`: storico GOL 2022-2025 ristretto ai temi con
  schema stabile (A1, B, F, H), `quality_flag == "ok"`, anchor regionale
  canonico.

- `cob_regionale_trimestrale`: flussi COB INPS 2017-Q1 -\> 2025-Q3, con
  nomi regionali armonizzati alle 21 etichette canoniche.

Ogni dataset viene salvato come file `.rda` compresso (`xz`) in
`output_dir`.
