# Estrae una serie di esiti (occupazionali, LEP, politiche)

Estrae una serie di esiti (occupazionali, LEP, politiche)

## Usage

``` r
gol_storia_esiti_series(
  variabile,
  regione = NULL,
  percorso = NULL,
  min_confidenza = "medium"
)
```

## Arguments

- variabile:

  Nome della variabile (es. `"occupati_totale"`, `"raggiunti"`,
  `"con_politica"`, `"lep_e"`, `"tasso_occupati_60gg"`).

- regione, percorso, min_confidenza:

  Come negli altri estrattori.

## Value

Un `data.table` pronto per
[`plot_timeline()`](https://gmontaletti.github.io/golDatasets/reference/plot_timeline.md).
Emette warning se l'output contiene piu' di un valore per stessa (data,
group).
