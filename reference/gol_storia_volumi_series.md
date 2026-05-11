# Estrae una serie di volumi (presi in carico) per plot_timeline

Estrae una serie di volumi (presi in carico) per plot_timeline

## Usage

``` r
gol_storia_volumi_series(
  variabile,
  regione = NULL,
  percorso = NULL,
  min_confidenza = "medium"
)
```

## Arguments

- variabile:

  Nome della variabile (es. `"presi_in_carico_totale"`,
  `"presi_in_carico_ass"`, `"presi_in_carico_pc"`,
  `"individui_raggiunti"`).

- regione:

  Vettore di etichette regionali. `NULL` = tutte.

- percorso:

  Filtro sul percorso GOL. `NULL` = tutti.

- min_confidenza:

  Default `"medium"`.

## Value

Un `data.table` con colonne `data, valore, fonte` e (se multivalore)
`regione`, `percorso`. Emette warning se l'output contiene piu' di un
valore per stessa (data, group).
