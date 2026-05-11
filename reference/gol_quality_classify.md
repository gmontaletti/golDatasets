# Classifica la qualita' di un'estrazione GOL storica

Applica una scala discreta di severita' a un insieme di metriche
aggregate per `(file, tema, caption_num)`. La scala e' calibrata sui
valori osservati nei 27 PDF di monitoraggio GOL 2022-2025.

## Usage

``` r
gol_quality_classify(n_anchor, pct_na_valore, n_header_variants, n_col_index)
```

## Arguments

- n_anchor:

  Numero di anchor regionali distinti riconosciuti (atteso: 21-22).

- pct_na_valore:

  Percentuale di righe con `valore_num` non parsabile (0-1).

- n_header_variants:

  Numero di stringhe `header_above` distinte.

- n_col_index:

  Numero di `col_index` distinti.

## Value

Un character vector della stessa lunghezza degli input con valori in
`c("ok", "review", "rescan_low", "rescan_high", "rescan_critical")`.
