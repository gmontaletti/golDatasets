# Calcola le metriche di qualita' per `gol_storico_regionale`

Per ogni `(file, tema, caption_num)` produce 4 metriche aggregate e
assegna una severita' usando
[`gol_quality_classify()`](https://gmontaletti.github.io/golDatasets/reference/gol_quality_classify.md).

## Usage

``` r
gol_storico_quality(data = NULL)
```

## Arguments

- data:

  Un `data.table` con la stessa struttura di `gol_storico_regionale`. Se
  `NULL` (default), usa il dataset esposto.

## Value

Un `data.table` con le colonne
`file, ente, data_riferimento, tema, caption_num, n_rows, n_anchor, n_col_index, n_header_variants, pct_na_valore, header_per_col, severity`.
Ordinato per severita' decrescente.

## Examples

``` r
q <- gol_storico_quality()
q[severity != "ok", .N, by = .(ente, severity)]
#>      ente   severity     N
#>    <char>     <char> <int>
#> 1:  ANPAL rescan_low     8
#> 2:  ALTRO rescan_low     1
```
