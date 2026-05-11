# Estrae una serie di caratteristiche dei beneficiari

Estrae una serie di caratteristiche dei beneficiari

## Usage

``` r
gol_storia_caratteristiche_series(
  caratteristica,
  modalita = NULL,
  regione = NULL,
  percorso = NULL,
  min_confidenza = "medium"
)
```

## Arguments

- caratteristica:

  Nome della caratteristica (`"genere"`, `"classe_eta"`,
  `"cittadinanza"`, `"durata_disoccupazione"`,
  `"target_patto_servizio"`, `"vulnerabilita"`).

- modalita:

  Vettore di modalita' (`"Maschi"`, `"Femmine"`, `"15-29"` ...). `NULL`
  = tutte.

- regione:

  Filtro regionale. `NULL` = tutte.

- percorso:

  Filtro su percorso GOL (utile per `caratteristica = "vulnerabilita"`
  che e' disaggregata per percorso). `NULL` = tutti.

- min_confidenza:

  Default `"medium"`.

## Value

Un `data.table` pronto per `plot_timeline(group = "modalita")`. Emette
warning se l'output contiene piu' di un valore per stessa (data, group).
