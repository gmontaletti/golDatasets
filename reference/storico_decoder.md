# Decoder semantico per `gol_storico_regionale`

Mappa `(tema, caption_num, col_index, era)` alla relativa semantica
(`variabile`, `caratteristica`, `modalita`, `percorso`, `unita`,
`confidenza`). Costruito via `data-raw/build_storico_decoder.R` con
regex auto-derivate da `header_above` modale + `caption_title` modale.
E' editabile manualmente via `inst/extdata/storico_decoder.csv`.

## Usage

``` r
storico_decoder
```

## Format

Un `data.table` con circa 230 righe e 15 colonne.

## See also

[`gol_decode_storico()`](https://gmontaletti.github.io/golDatasets/reference/gol_decode_storico.md).
