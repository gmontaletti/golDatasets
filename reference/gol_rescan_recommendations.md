# Raccomandazioni di rescanning per le estrazioni storiche GOL

Snapshot del risultato di
[`gol_storico_quality()`](https://gmontaletti.github.io/golDatasets/reference/gol_storico_quality.md)
al momento della build di `gol_storico_regionale`, filtrato a
`severity != "ok"`. Identifica i PDF di origine la cui estrazione in
`dataset_long/` e' incompleta o rumorosa e che dovrebbero essere
ri-estratti dal PDF originale (o sostituiti da una fonte alternativa,
come gia' fatto per INAPP A1/1.2).

## Usage

``` r
gol_rescan_recommendations
```

## Format

Un `data.table` con una riga per `(file, tema, caption_num)`
problematico. Colonne come da output di
[`gol_storico_quality()`](https://gmontaletti.github.io/golDatasets/reference/gol_storico_quality.md).

## See also

[`gol_storico_quality()`](https://gmontaletti.github.io/golDatasets/reference/gol_storico_quality.md),
[`gol_quality_classify()`](https://gmontaletti.github.io/golDatasets/reference/gol_quality_classify.md).
